;; yaml-parser.lfe
;; YAML Parsing Module for WP Praxis Manifest Parser
;;
;; This module provides YAML 1.2 parsing capabilities using the yamerl library,
;; converting YAML documents into LFE data structures suitable for symbolic
;; transformation and dispatch.

(defmodule yaml-parser
  "YAML parsing with semantic preservation for symbolic manifests."
  (export all))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun parse-file (filepath)
  "Parse a YAML file and return LFE data structure.

  Args:
    filepath: Path to YAML file (string or binary)

  Returns:
    (tuple 'ok data) on success
    (tuple 'error reason) on failure"
  (try
    (let* ((options (get-yaml-options))
           (parsed (yamerl_constr:file filepath options)))
      (case parsed
        ((cons doc _rest)
         `#(ok ,(yaml->lfe doc)))
        ('()
         `#(error "Empty YAML document"))
        (other
         `#(error #(unexpected_result ,other)))))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun parse-string (yaml-str)
  "Parse YAML from string.

  Args:
    yaml-str: YAML content as string or binary

  Returns:
    (tuple 'ok data) on success
    (tuple 'error reason) on failure"
  (try
    (let* ((options (get-yaml-options))
           (parsed (yamerl_constr:string yaml-str options)))
      (case parsed
        ((cons doc _rest)
         `#(ok ,(yaml->lfe doc)))
        ('()
         `#(error "Empty YAML document"))
        (other
         `#(error #(unexpected_result ,other)))))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun parse-stream (stream)
  "Parse YAML from a stream/IO device.

  Args:
    stream: IO device or stream

  Returns:
    (tuple 'ok data) on success
    (tuple 'error reason) on failure"
  (try
    (let ((content (read-stream stream)))
      (parse-string content))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun parse-multi-document (filepath)
  "Parse YAML file containing multiple documents.

  Args:
    filepath: Path to YAML file

  Returns:
    (tuple 'ok (list-of documents)) on success
    (tuple 'error reason) on failure"
  (try
    (let* ((options (get-yaml-options))
           (parsed (yamerl_constr:file filepath options)))
      `#(ok ,(lists:map #'yaml->lfe/1 parsed)))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun validate-yaml (filepath)
  "Validate YAML file without full parsing.

  Args:
    filepath: Path to YAML file

  Returns:
    'ok on valid YAML
    (tuple 'error reason) on invalid YAML"
  (try
    (let ((options (get-yaml-options)))
      (yamerl_constr:file filepath options)
      'ok)
    (catch
      ((tuple type reason _stacktrace)
       `#(error #(,type ,reason))))))

;;; =============================================================================
;;; YAML to LFE Conversion
;;; =============================================================================

(defun yaml->lfe (yaml-node)
  "Convert yamerl YAML node to LFE data structure.

  This preserves semantic information while converting to idiomatic LFE:
  - YAML maps -> property lists (for better symbolic manipulation)
  - YAML sequences -> lists
  - YAML scalars -> appropriate Erlang/LFE types
  - Tags and anchors are preserved as metadata"
  (case yaml-node
    ;; Map/Object
    ((tuple 'yamerl_map tag pairs)
     (let ((converted-pairs (lists:map #'convert-pair/1 pairs)))
       (if (=:= tag 'undefined)
         converted-pairs
         `#(tagged-map ,tag ,converted-pairs))))

    ;; Sequence/Array
    ((tuple 'yamerl_seq tag items)
     (let ((converted-items (lists:map #'yaml->lfe/1 items)))
       (if (=:= tag 'undefined)
         converted-items
         `#(tagged-seq ,tag ,converted-items))))

    ;; String
    ((tuple 'yamerl_str tag value)
     (let ((str (unicode:characters_to_binary value)))
       (if (=:= tag 'undefined)
         str
         `#(tagged-str ,tag ,str))))

    ;; Integer
    ((tuple 'yamerl_int tag value)
     (if (=:= tag 'undefined)
       value
       `#(tagged-int ,tag ,value)))

    ;; Float
    ((tuple 'yamerl_float tag value)
     (if (=:= tag 'undefined)
       value
       `#(tagged-float ,tag ,value)))

    ;; Boolean
    ((tuple 'yamerl_bool tag value)
     (if (=:= tag 'undefined)
       value
       `#(tagged-bool ,tag ,value)))

    ;; Null
    ((tuple 'yamerl_null _tag)
     'null)

    ;; Timestamp
    ((tuple 'yamerl_timestamp tag datetime)
     `#(timestamp ,tag ,datetime))

    ;; Binary
    ((tuple 'yamerl_binary tag data)
     `#(binary ,tag ,data))

    ;; Erlang term (custom)
    ((tuple 'yamerl_erlang_atom tag atom)
     `#(atom ,tag ,atom))

    ((tuple 'yamerl_erlang_fun tag fun)
     `#(function ,tag ,fun))

    ;; Unknown or unsupported
    (other
     `#(unknown ,other))))

(defun convert-pair (pair)
  "Convert a YAML key-value pair to LFE property list entry."
  (case pair
    ((tuple key-node value-node)
     (let ((key (yaml-key->atom key-node))
           (value (yaml->lfe value-node)))
       `#(,key ,value)))
    (other
     `#(error #(invalid-pair ,other)))))

(defun yaml-key->atom (key-node)
  "Convert YAML key to atom for property list.

  Keys are typically strings in YAML, but we convert them to atoms
  for easier pattern matching in LFE."
  (case key-node
    ((tuple 'yamerl_str _tag value)
     (binary_to_atom (unicode:characters_to_binary value) 'utf8))
    ((tuple 'yamerl_int _tag value)
     (binary_to_atom (integer_to_binary value) 'utf8))
    ((tuple 'yamerl_erlang_atom _tag atom)
     atom)
    (other
     ;; Fallback: convert to string and then atom
     (let ((str (lists:flatten (io_lib:format "~p" (list other)))))
       (binary_to_atom (list_to_binary str) 'utf8)))))

;;; =============================================================================
;;; Configuration
;;; =============================================================================

(defun get-yaml-options ()
  "Get YAML parser options from application environment."
  (let ((default-opts '(#(detailed_constr true)
                       #(str_node_as_binary false)
                       #(map_node_format proplist))))
    (case (application:get_env 'manifest_parser 'yaml_options)
      ((tuple 'ok opts) (merge-options default-opts opts))
      ('undefined default-opts))))

(defun merge-options (defaults custom)
  "Merge custom options with defaults."
  (lists:ukeymerge 1
                   (lists:ukeysort 1 custom)
                   (lists:ukeysort 1 defaults)))

;;; =============================================================================
;;; Utility Functions
;;; =============================================================================

(defun read-stream (stream)
  "Read entire content from stream."
  (read-stream stream (list)))

(defun read-stream (stream acc)
  "Tail-recursive stream reading."
  (case (io:get_line stream "")
    ('eof
     (iolist_to_binary (lists:reverse acc)))
    ((tuple 'error reason)
     (error `#(stream-read-error ,reason)))
    (line
     (read-stream stream (cons line acc)))))

(defun pretty-print-error (error)
  "Format YAML parsing error for human consumption."
  (case error
    ((tuple 'error (tuple type reason stacktrace))
     (io_lib:format "YAML Parse Error [~p]: ~p~nStacktrace: ~p"
                    (list type reason stacktrace)))
    ((tuple 'error reason)
     (io_lib:format "YAML Parse Error: ~p" (list reason)))
    (other
     (io_lib:format "Unknown error: ~p" (list other)))))

(defun get-yaml-type (data)
  "Determine the YAML type of converted data."
  (cond
    ((is_list data)
     (case data
       ((cons (tuple _k _v) _rest) 'map)
       (_ 'sequence)))
    ((is_binary data) 'string)
    ((is_integer data) 'integer)
    ((is_float data) 'float)
    ((is_boolean data) 'boolean)
    ((=:= data 'null) 'null)
    ((is_tuple data)
     (case data
       ((tuple 'tagged-map _ _) 'tagged-map)
       ((tuple 'tagged-seq _ _) 'tagged-sequence)
       ((tuple 'timestamp _ _) 'timestamp)
       ((tuple 'binary _ _) 'binary)
       (_ 'unknown)))
    ('true 'unknown)))

;;; =============================================================================
;;; Schema Validation Support
;;; =============================================================================

(defun extract-metadata (filepath)
  "Extract metadata from YAML file for validation."
  (case (parse-file filepath)
    ((tuple 'ok data)
     `#(ok #(file ,filepath
             type ,(get-yaml-type data)
             size ,(erlang:external_size data))))
    ((tuple 'error reason)
     `#(error ,reason))))

(defun get-symbols (parsed-data)
  "Extract symbols list from parsed YAML manifest."
  (proplists:get_value 'symbols parsed-data '()))

(defun get-workflows (parsed-data)
  "Extract workflows from parsed YAML manifest."
  (proplists:get_value 'workflows parsed-data '()))

(defun get-metadata (parsed-data)
  "Extract metadata section from parsed YAML manifest."
  (proplists:get_value 'metadata parsed-data '()))
