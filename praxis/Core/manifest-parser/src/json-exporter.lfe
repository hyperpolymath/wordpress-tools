;; json-exporter.lfe
;; JSON Export Module for WP Praxis Manifest Parser
;;
;; This module exports LFE manifest structures to JSON format
;; for consumption by Rust, TypeScript, PHP, and other components.

(defmodule json-exporter
  "Export manifest structures to JSON."
  (export all))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun to-json (data)
  "Convert LFE data structure to JSON string.

  Args:
    data: LFE data structure (property list, list, etc.)

  Returns:
    (tuple 'ok json-string) on success
    (tuple 'error reason) on failure"
  (try
    (let* ((erlang-data (lfe->jsx data))
           (json (jsx:encode erlang-data (get-json-options))))
      `#(ok ,json))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun to-json-pretty (data)
  "Convert LFE data to pretty-printed JSON.

  Args:
    data: LFE data structure

  Returns:
    (tuple 'ok pretty-json-string) | (tuple 'error reason)"
  (try
    (let* ((erlang-data (lfe->jsx data))
           (options (get-pretty-json-options))
           (json (jsx:encode erlang-data options)))
      `#(ok ,json))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun from-json (json-string)
  "Parse JSON string to LFE data structure.

  Args:
    json-string: JSON as binary or string

  Returns:
    (tuple 'ok data) | (tuple 'error reason)"
  (try
    (let* ((json-bin (ensure-binary json-string))
           (erlang-data (jsx:decode json-bin (get-decode-options)))
           (lfe-data (jsx->lfe erlang-data)))
      `#(ok ,lfe-data))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun export-manifest-to-file (manifest filepath)
  "Export manifest to JSON file.

  Args:
    manifest: Manifest data structure
    filepath: Output file path

  Returns:
    'ok | (tuple 'error reason)"
  (case (to-json-pretty manifest)
    ((tuple 'ok json)
     (file:write_file filepath json))
    ((tuple 'error reason)
     `#(error ,reason))))

(defun import-manifest-from-file (filepath)
  "Import manifest from JSON file.

  Args:
    filepath: JSON file path

  Returns:
    (tuple 'ok manifest) | (tuple 'error reason)"
  (case (file:read_file filepath)
    ((tuple 'ok content)
     (from-json content))
    ((tuple 'error reason)
     `#(error #(file-read-error ,reason)))))

;;; =============================================================================
;;; LFE to JSX Conversion
;;; =============================================================================

(defun lfe->jsx (data)
  "Convert LFE data structures to jsx-compatible Erlang terms.

  jsx expects:
  - Maps (not property lists)
  - Lists
  - Binaries (not lists for strings)
  - Numbers, booleans, null"
  (cond
    ;; Property list -> map
    ((is_proplist data)
     (proplist->map data))

    ;; List of items
    ((is_list data)
     (lists:map #'lfe->jsx/1 data))

    ;; Atom special cases
    ((=:= data 'true) 'true)
    ((=:= data 'false) 'false)
    ((=:= data 'null) 'null)
    ((=:= data 'nil) 'null)
    ((=:= data 'undefined) 'null)

    ;; Other atoms -> binary string
    ((is_atom data)
     (atom_to_binary data 'utf8))

    ;; String list -> binary
    ((andalso (is_list data) (io_lib:printable_latin1 data))
     (list_to_binary data))

    ;; Tuple -> convert to map with special key
    ((is_tuple data)
     (tuple->map data))

    ;; Map -> convert values
    ((is_map data)
     (maps:map (lambda (_k v) (lfe->jsx v)) data))

    ;; Binary, number, boolean pass through
    ((orelse (is_binary data)
             (is_number data)
             (is_boolean data))
     data)

    ;; Unknown -> convert to string
    ('true
     (list_to_binary (io_lib:format "~p" (list data))))))

(defun proplist->map (proplist)
  "Convert property list to Erlang map for JSON."
  (maps:from_list
    (lists:map
      (lambda (pair)
        (case pair
          ((tuple key value)
           (let ((json-key (atom-to-json-key key))
                 (json-value (lfe->jsx value)))
             `#(,json-key ,json-value)))
          (other
           `#(<<"unknown">> ,(lfe->jsx other)))))
      proplist)))

(defun atom-to-json-key (atom)
  "Convert atom to JSON key (binary)."
  (if (is_atom atom)
    (atom_to_binary atom 'utf8)
    (ensure-binary atom)))

(defun tuple->map (tuple)
  "Convert tuple to JSON object.

  Strategy: Create a map with '_tuple' key indicating it was a tuple."
  (let ((elements (tuple_to_list tuple)))
    (case elements
      ;; Tagged tuple like #(ok value)
      ((cons tag (cons value '()))
       (when (is_atom tag))
       `#m(<<"_tagged">> ,(atom_to_binary tag 'utf8)
           <<"value">> ,(lfe->jsx value)))

      ;; General tuple
      (_
       `#m(<<"_tuple">> ,(lists:map #'lfe->jsx/1 elements))))))

(defun is_proplist (data)
  "Check if data is a property list."
  (andalso
    (is_list data)
    (not (=:= data '()))
    (not (io_lib:printable_latin1 data))
    (lists:all
      (lambda (item)
        (andalso (is_tuple item)
                 (=:= (tuple_size item) 2)
                 (is_atom (element 1 item))))
      data)))

;;; =============================================================================
;;; JSX to LFE Conversion
;;; =============================================================================

(defun jsx->lfe (data)
  "Convert jsx data back to LFE structures.

  Maps -> property lists (for consistency with internal format)
  Lists -> lists
  Null -> 'null atom"
  (cond
    ;; Map -> property list
    ((is_map data)
     (map->proplist data))

    ;; List
    ((is_list data)
     (lists:map #'jsx->lfe/1 data))

    ;; Null
    ((=:= data 'null) 'null)

    ;; Primitives pass through
    ((orelse (is_binary data)
             (is_number data)
             (is_boolean data))
     data)

    ;; Unknown
    ('true data)))

(defun map->proplist (map)
  "Convert JSON map back to property list."
  ;; Check for special tuple encoding
  (case (maps:get <<"_tuple">> map 'undefined)
    ('undefined
     (case (maps:get <<"_tagged">> map 'undefined)
       ('undefined
        ;; Regular map -> property list
        (lists:map
          (lambda (key)
            (let ((atom-key (binary-to-atom-safe key))
                  (value (jsx->lfe (maps:get key map))))
              `#(,atom-key ,value)))
          (maps:keys map)))
       (tag
        ;; Tagged tuple
        (let ((tag-atom (binary-to-atom-safe tag))
              (value (jsx->lfe (maps:get <<"value">> map))))
          `#(,tag-atom ,value)))))
    (elements
     ;; Tuple encoding
     (list_to_tuple (lists:map #'jsx->lfe/1 elements)))))

(defun binary-to-atom-safe (bin)
  "Safely convert binary to atom."
  (try
    (binary_to_existing_atom bin 'utf8)
    (catch
      ('error 'badarg
       (binary_to_atom bin 'utf8)))))

;;; =============================================================================
;;; JSON Options
;;; =============================================================================

(defun get-json-options ()
  "Get JSON encoding options."
  (case (application:get_env 'manifest_parser 'json_export_format)
    ((tuple 'ok 'pretty) (get-pretty-json-options))
    ((tuple 'ok 'compact) '(#(space 0) #(indent 0)))
    ('undefined '())))

(defun get-pretty-json-options ()
  "Get pretty-print JSON options."
  '(#(space 1) #(indent 2) pretty))

(defun get-decode-options ()
  "Get JSON decoding options."
  '(return_maps))

;;; =============================================================================
;;; Specialized Exporters
;;; =============================================================================

(defun export-symbols-to-json (symbols)
  "Export symbols list to JSON.

  Args:
    symbols: List of symbol structures

  Returns:
    (tuple 'ok json) | (tuple 'error reason)"
  (to-json-pretty symbols))

(defun export-workflows-to-json (workflows)
  "Export workflows list to JSON."
  (to-json-pretty workflows))

(defun export-symbol-registry-to-json ()
  "Export entire symbol registry to JSON.

  Returns:
    (tuple 'ok json) | (tuple 'error reason)"
  (case (whereis 'symbol_registry)
    ('undefined
     `#(error "Symbol registry not running"))
    (pid
     (try
       (let ((registry-data (gen_server:call pid 'get-all)))
         (to-json-pretty registry-data))
       (catch
         ((tuple type reason _stacktrace)
          `#(error #(,type ,reason))))))))

;;; =============================================================================
;;; Schema Export
;;; =============================================================================

(defun export-json-schema ()
  "Export JSON schema definition for manifests.

  Useful for validation in TypeScript/JavaScript/other languages."
  (let ((schema
          `(#(<<"$schema">> <<"http://json-schema.org/draft-07/schema#">>)
            #(<<"title">> <<"WP Praxis Manifest">>)
            #(<<"type">> <<"object">>)
            #(<<"required">> (<<"version">> <<"symbols">>))
            #(<<"properties">>
              #m(<<"version">> #m(<<"type">> <<"string">>)
                 <<"format">> #m(<<"type">> <<"string">>
                                <<"enum">> (<<"yaml">> <<"toml">>))
                 <<"metadata">> #m(<<"type">> <<"object">>)
                 <<"symbols">> #m(<<"type">> <<"array">>
                                 <<"items">> ,(symbol-schema))
                 <<"workflows">> #m(<<"type">> <<"array">>
                                   <<"items">> ,(workflow-schema)))))))
    (to-json-pretty schema)))

(defun symbol-schema ()
  "JSON schema for a symbol."
  `#m(<<"type">> <<"object">>
      <<"required">> (<<"name">> <<"type">> <<"context">>)
      <<"properties">>
      #m(<<"name">> #m(<<"type">> <<"string">>)
         <<"type">> #m(<<"type">> <<"string">>)
         <<"context">> #m(<<"type">> <<"string">>)
         <<"dispatch">> #m(<<"type">> <<"string">>)
         <<"dependencies">> #m(<<"type">> <<"array">>
                              <<"items">> #m(<<"type">> <<"string">>))
         <<"parameters">> #m(<<"type">> <<"object">>)
         <<"enabled">> #m(<<"type">> <<"boolean">>))))

(defun workflow-schema ()
  "JSON schema for a workflow."
  `#m(<<"type">> <<"object">>
      <<"required">> (<<"name">> <<"steps">>)
      <<"properties">>
      #m(<<"name">> #m(<<"type">> <<"string">>)
         <<"description">> #m(<<"type">> <<"string">>)
         <<"steps">> #m(<<"type">> <<"array">>
                       <<"items">> ,(step-schema))
         <<"parallel">> #m(<<"type">> <<"boolean">>))))

(defun step-schema ()
  "JSON schema for a workflow step."
  `#m(<<"type">> <<"object">>
      <<"required">> (<<"symbol">>)
      <<"properties">>
      #m(<<"symbol">> #m(<<"type">> <<"string">>)
         <<"parameters">> #m(<<"type">> <<"object">>)
         <<"continue-on-error">> #m(<<"type">> <<"boolean">>))))

;;; =============================================================================
;;; Utility Functions
;;; =============================================================================

(defun ensure-binary (value)
  "Ensure value is binary."
  (cond
    ((is_binary value) value)
    ((is_list value) (list_to_binary value))
    ((is_atom value) (atom_to_binary value 'utf8))
    ('true (error `#(cannot-convert-to-binary ,value)))))

(defun pretty-print-error (error)
  "Format JSON export error."
  (case error
    ((tuple 'error (tuple type reason stacktrace))
     (io_lib:format "JSON Export Error [~p]: ~p~nStacktrace: ~p"
                    (list type reason stacktrace)))
    ((tuple 'error reason)
     (io_lib:format "JSON Export Error: ~p" (list reason)))
    (other
     (io_lib:format "Unknown error: ~p" (list other)))))
