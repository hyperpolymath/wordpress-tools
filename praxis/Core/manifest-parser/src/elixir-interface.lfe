;; elixir-interface.lfe
;; Elixir Integration Interface for WP Praxis Manifest Parser
;;
;; This module provides seamless interop between LFE manifest parser
;; and Elixir CLI wrapper through Erlang/Elixir data conversion.

(defmodule elixir-interface
  "Elixir interop for manifest parsing."
  (export all))

;;; =============================================================================
;;; Public API for Elixir
;;; =============================================================================

(defun parse_file (filepath)
  "Parse manifest file - callable from Elixir.

  Returns Elixir-compatible tuple:
    {:ok, manifest} | {:error, reason}"
  (case (manifest-transformer:transform-file filepath)
    ((tuple 'ok manifest)
     `#(ok ,(lfe->elixir manifest)))
    ((tuple 'error reason)
     `#(error ,(lfe->elixir reason)))))

(defun parse_string (content format)
  "Parse manifest from string - callable from Elixir.

  Args:
    content: Binary string with manifest content
    format: Atom 'yaml' or 'toml'

  Returns:
    {:ok, manifest} | {:error, reason}"
  (let ((result (case format
                  ('yaml (yaml-parser:parse-string content))
                  ('toml (toml-parser:parse-string content))
                  (_ `#(error #(invalid-format ,format))))))
    (case result
      ((tuple 'ok parsed)
       (case (manifest-transformer:transform parsed format)
         ((tuple 'ok manifest) `#(ok ,(lfe->elixir manifest)))
         ((tuple 'error reason) `#(error ,(lfe->elixir reason)))))
      ((tuple 'error reason)
       `#(error ,(lfe->elixir reason))))))

(defun validate_manifest (manifest)
  "Validate manifest structure - callable from Elixir.

  Args:
    manifest: Elixir map or keyword list

  Returns:
    :ok | {:error, errors}"
  (let ((lfe-manifest (elixir->lfe manifest)))
    (case (manifest-validator:validate lfe-manifest)
      ('ok 'ok)
      ((tuple 'error errors)
       `#(error ,(lfe->elixir errors))))))

(defun optimize_manifest (manifest)
  "Optimize manifest - callable from Elixir.

  Args:
    manifest: Elixir map or keyword list

  Returns:
    {:ok, optimized_manifest}"
  (let* ((lfe-manifest (elixir->lfe manifest))
         (optimized (symbolic-optimizer:optimize lfe-manifest)))
    `#(ok ,(lfe->elixir optimized))))

(defun get_symbols (manifest)
  "Extract symbols from manifest - callable from Elixir.

  Returns list of symbols as Elixir maps."
  (let* ((lfe-manifest (elixir->lfe manifest))
         (symbols (proplists:get_value 'symbols lfe-manifest '())))
    (lfe->elixir symbols)))

(defun get_workflows (manifest)
  "Extract workflows from manifest - callable from Elixir.

  Returns list of workflows as Elixir maps."
  (let* ((lfe-manifest (elixir->lfe manifest))
         (workflows (proplists:get_value 'workflows lfe-manifest '())))
    (lfe->elixir workflows)))

;;; =============================================================================
;;; Data Conversion: LFE -> Elixir
;;; =============================================================================

(defun lfe->elixir (data)
  "Convert LFE data structures to Elixir-compatible format.

  Property lists -> Keyword lists (list of 2-tuples with atom keys)
  Lists -> Lists
  Atoms -> Atoms
  Binaries -> Binaries
  Numbers -> Numbers"
  (cond
    ;; Property list -> Elixir keyword list
    ((is_proplist data)
     (proplist->elixir data))

    ;; Regular list
    ((is_list data)
     (lists:map #'lfe->elixir/1 data))

    ;; Tuple -> keep as tuple but convert contents
    ((is_tuple data)
     (list_to_tuple (lists:map #'lfe->elixir/1 (tuple_to_list data))))

    ;; Map -> convert values
    ((is_map data)
     (maps:map (lambda (_k v) (lfe->elixir v)) data))

    ;; Primitives pass through
    ((orelse (is_atom data)
             (is_binary data)
             (is_number data)
             (is_boolean data))
     data)

    ;; Unknown
    ('true data)))

(defun proplist->elixir (proplist)
  "Convert LFE property list to Elixir keyword list."
  (lists:map
    (lambda (pair)
      (case pair
        ((tuple key value)
         `#(,key ,(lfe->elixir value)))
        (other other)))
    proplist))

(defun is_proplist (data)
  "Check if data is a property list."
  (andalso
    (is_list data)
    (not (=:= data '()))
    (lists:all
      (lambda (item)
        (andalso (is_tuple item)
                 (=:= (tuple_size item) 2)
                 (is_atom (element 1 item))))
      data)))

;;; =============================================================================
;;; Data Conversion: Elixir -> LFE
;;; =============================================================================

(defun elixir->lfe (data)
  "Convert Elixir data structures to LFE format.

  Elixir keyword lists -> Property lists
  Elixir maps -> Property lists (for consistency)
  Lists -> Lists
  Atoms -> Atoms"
  (cond
    ;; Elixir map -> property list
    ((is_map data)
     (map->proplist data))

    ;; Keyword list (stays as property list)
    ((is_proplist data)
     (lists:map
       (lambda (pair)
         (case pair
           ((tuple key value)
            `#(,key ,(elixir->lfe value)))
           (other other)))
       data))

    ;; Regular list
    ((is_list data)
     (lists:map #'elixir->lfe/1 data))

    ;; Tuple
    ((is_tuple data)
     (list_to_tuple (lists:map #'elixir->lfe/1 (tuple_to_list data))))

    ;; Primitives
    ('true data)))

(defun map->proplist (map)
  "Convert Erlang/Elixir map to property list."
  (lists:map
    (lambda (key)
      `#(,key ,(elixir->lfe (maps:get key map))))
    (maps:keys map)))

;;; =============================================================================
;;; Introspection Interface for Elixir
;;; =============================================================================

(defun inspect_symbol (symbol_name)
  "Inspect symbol - callable from Elixir.

  Returns {:ok, info} | {:error, reason}"
  (case (symbolic-introspection:inspect-symbol symbol_name)
    ((tuple 'ok info)
     `#(ok ,(lfe->elixir info)))
    ((tuple 'error reason)
     `#(error ,(lfe->elixir reason)))))

(defun inspect_workflow (workflow_name)
  "Inspect workflow - callable from Elixir."
  (case (symbolic-introspection:inspect-workflow workflow_name)
    ((tuple 'ok info)
     `#(ok ,(lfe->elixir info)))
    ((tuple 'error reason)
     `#(error ,(lfe->elixir reason)))))

(defun analyze_dependencies (manifest)
  "Analyze manifest dependencies - callable from Elixir.

  Returns dependency graph as Elixir keyword list."
  (let* ((lfe-manifest (elixir->lfe manifest))
         (graph (symbolic-introspection:build-dependency-graph lfe-manifest)))
    (lfe->elixir graph)))

(defun check_circular_deps (manifest)
  "Check for circular dependencies - callable from Elixir.

  Returns :ok | {:error, {:circular_dependencies, cycles}}"
  (let* ((lfe-manifest (elixir->lfe manifest))
         (symbols (proplists:get_value 'symbols lfe-manifest '())))
    (case (manifest-validator:check-circular-dependencies symbols)
      ((tuple 'ok 'no-cycles) 'ok)
      ((tuple 'error reason) `#(error ,(lfe->elixir reason))))))

;;; =============================================================================
;;; Batch Operations for Elixir
;;; =============================================================================

(defun parse_multiple_files (filepaths)
  "Parse multiple manifest files - callable from Elixir.

  Args:
    filepaths: List of file paths

  Returns:
    List of {:ok, manifest} | {:error, reason} tuples"
  (lists:map
    (lambda (filepath)
      (parse_file filepath))
    filepaths))

(defun validate_multiple (manifests)
  "Validate multiple manifests - callable from Elixir.

  Args:
    manifests: List of manifest structures

  Returns:
    List of validation results"
  (lists:map
    (lambda (manifest)
      (validate_manifest manifest))
    manifests))

;;; =============================================================================
;;; Registry Operations for Elixir
;;; =============================================================================

(defun register_symbol (name metadata)
  "Register symbol in global registry - callable from Elixir."
  (symbolic-macros:register-symbol
    (ensure-atom name)
    (elixir->lfe metadata)))

(defun register_workflow (name metadata)
  "Register workflow in global registry - callable from Elixir."
  (symbolic-macros:register-workflow
    (ensure-atom name)
    (elixir->lfe metadata)))

(defun list_registered_symbols ()
  "List all registered symbols - callable from Elixir.

  Returns list of symbol names."
  (case (whereis 'symbol_registry)
    ('undefined '())
    (pid
     (try
       (lfe->elixir (gen_server:call pid 'list-symbols))
       (catch
         (_ '()))))))

(defun list_registered_workflows ()
  "List all registered workflows - callable from Elixir."
  (case (whereis 'symbol_registry)
    ('undefined '())
    (pid
     (try
       (lfe->elixir (gen_server:call pid 'list-workflows))
       (catch
         (_ '()))))))

;;; =============================================================================
;;; Utility Functions
;;; =============================================================================

(defun ensure-atom (value)
  "Ensure value is an atom."
  (cond
    ((is_atom value) value)
    ((is_binary value) (binary_to_atom value 'utf8))
    ((is_list value) (list_to_atom value))
    ('true (error `#(cannot-convert-to-atom ,value)))))

(defun ensure-binary (value)
  "Ensure value is a binary."
  (cond
    ((is_binary value) value)
    ((is_list value) (list_to_binary value))
    ((is_atom value) (atom_to_binary value 'utf8))
    ('true (error `#(cannot-convert-to-binary ,value)))))

;;; =============================================================================
;;; Elixir Function Naming Conventions
;;; =============================================================================

;; The following are aliases for Elixir naming conventions
;; Elixir uses snake_case, which we support above
;; These are exported as part of the module's API

(defun ParseFile (filepath)
  "Alias for parse_file (PascalCase for Elixir modules)."
  (parse_file filepath))

(defun ParseString (content format)
  "Alias for parse_string."
  (parse_string content format))

(defun ValidateManifest (manifest)
  "Alias for validate_manifest."
  (validate_manifest manifest))

(defun OptimizeManifest (manifest)
  "Alias for optimize_manifest."
  (optimize_manifest manifest))
