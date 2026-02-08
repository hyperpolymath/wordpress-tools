;; manifest-transformer.lfe
;; Manifest Transformation Module for WP Praxis
;;
;; This module transforms parsed manifest data (YAML/TOML) into canonical
;; symbolic format for dispatch and execution. It normalizes different
;; manifest formats and extracts semantic information.

(defmodule manifest-transformer
  "Transform parsed manifests into canonical symbolic format."
  (export all))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun transform (parsed-data format)
  "Transform parsed manifest data to canonical symbolic format.

  Args:
    parsed-data: Parsed manifest (property list)
    format: Source format ('yaml or 'toml)

  Returns:
    (tuple 'ok canonical-manifest) on success
    (tuple 'error reason) on failure"
  (try
    (let ((canonical (case format
                       ('yaml (transform-yaml parsed-data))
                       ('toml (transform-toml parsed-data))
                       ('auto (auto-detect-and-transform parsed-data))
                       (_ `#(error #(unknown-format ,format))))))
      (case canonical
        ((tuple 'error _reason) canonical)
        (data `#(ok ,data))))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun transform-file (filepath)
  "Auto-detect format and transform manifest file.

  Args:
    filepath: Path to manifest file

  Returns:
    (tuple 'ok canonical-manifest) on success
    (tuple 'error reason) on failure"
  (let ((format (detect-format filepath)))
    (case format
      ('yaml
       (case (yaml-parser:parse-file filepath)
         ((tuple 'ok data) (transform data 'yaml))
         (error error)))
      ('toml
       (case (toml-parser:parse-file filepath)
         ((tuple 'ok data) (transform data 'toml))
         (error error)))
      ('unknown
       `#(error #(unknown-format ,filepath))))))

(defun normalize (canonical-manifest)
  "Normalize canonical manifest structure.

  This performs additional normalization:
  - Resolve relative paths
  - Expand environment variables
  - Apply defaults
  - Sort by dependency order"
  (try
    (let* ((with-defaults (apply-defaults canonical-manifest))
           (with-expanded-vars (expand-variables with-defaults))
           (with-resolved-paths (resolve-paths with-expanded-vars))
           (sorted (sort-by-dependencies with-resolved-paths)))
      `#(ok ,sorted))
    (catch
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

;;; =============================================================================
;;; Format-Specific Transformation
;;; =============================================================================

(defun transform-yaml (yaml-data)
  "Transform YAML-parsed data to canonical format."
  (let* ((metadata (extract-metadata yaml-data))
         (symbols (extract-symbols yaml-data))
         (workflows (extract-workflows yaml-data))
         (contexts (extract-contexts yaml-data))
         (dispatches (extract-dispatches yaml-data)))
    `(#(version ,(get-version metadata "1.0"))
      #(format yaml)
      #(metadata ,metadata)
      #(symbols ,symbols)
      #(workflows ,workflows)
      #(contexts ,contexts)
      #(dispatches ,dispatches))))

(defun transform-toml (toml-data)
  "Transform TOML-parsed data to canonical format."
  (let* ((metadata (extract-metadata toml-data))
         (symbols (extract-symbols toml-data))
         (workflows (extract-workflows toml-data))
         (contexts (extract-contexts toml-data))
         (dispatches (extract-dispatches toml-data)))
    `(#(version ,(get-version metadata "1.0"))
      #(format toml)
      #(metadata ,metadata)
      #(symbols ,symbols)
      #(workflows ,workflows)
      #(contexts ,contexts)
      #(dispatches ,dispatches))))

(defun auto-detect-and-transform (data)
  "Auto-detect format from data structure and transform."
  ;; YAML and TOML parsed data have similar structures,
  ;; so we treat them uniformly
  (transform-yaml data))

;;; =============================================================================
;;; Extraction Functions
;;; =============================================================================

(defun extract-metadata (data)
  "Extract and normalize metadata section."
  (let ((meta (proplists:get_value 'metadata data '())))
    `(#(name ,(get-value 'name meta "unnamed"))
      #(description ,(get-value 'description meta ""))
      #(version ,(get-value 'version meta "0.1.0"))
      #(author ,(get-value 'author meta "unknown"))
      #(license ,(get-value 'license meta "AGPL-3.0"))
      #(tags ,(get-value 'tags meta '()))
      #(created ,(get-value 'created meta (get-timestamp)))
      #(modified ,(get-value 'modified meta (get-timestamp))))))

(defun extract-symbols (data)
  "Extract and normalize symbols list."
  (let ((symbols (proplists:get_value 'symbols data '())))
    (lists:map #'normalize-symbol/1 symbols)))

(defun extract-workflows (data)
  "Extract and normalize workflows."
  (let ((workflows (proplists:get_value 'workflows data '())))
    (lists:map #'normalize-workflow/1 workflows)))

(defun extract-contexts (data)
  "Extract and normalize contexts."
  (let ((contexts (proplists:get_value 'contexts data '())))
    (lists:map #'normalize-context/1 contexts)))

(defun extract-dispatches (data)
  "Extract and normalize dispatch rules."
  (let ((dispatches (proplists:get_value 'dispatches data '())))
    (lists:map #'normalize-dispatch/1 dispatches)))

;;; =============================================================================
;;; Normalization Functions
;;; =============================================================================

(defun normalize-symbol (symbol-data)
  "Normalize a symbol definition to canonical format."
  `(#(name ,(get-required 'name symbol-data))
    #(type ,(get-value 'type symbol-data 'action))
    #(context ,(get-value 'context symbol-data 'default))
    #(dispatch ,(get-value 'dispatch symbol-data 'auto))
    #(parameters ,(get-value 'parameters symbol-data '()))
    #(dependencies ,(get-value 'dependencies symbol-data '()))
    #(metadata ,(get-value 'metadata symbol-data '()))
    #(enabled ,(get-value 'enabled symbol-data 'true))))

(defun normalize-workflow (workflow-data)
  "Normalize a workflow definition to canonical format."
  `(#(name ,(get-required 'name workflow-data))
    #(description ,(get-value 'description workflow-data ""))
    #(steps ,(normalize-steps (get-value 'steps workflow-data '())))
    #(triggers ,(get-value 'triggers workflow-data '()))
    #(conditions ,(get-value 'conditions workflow-data '()))
    #(error-handling ,(get-value 'error-handling workflow-data 'stop))
    #(parallel ,(get-value 'parallel workflow-data 'false))
    #(metadata ,(get-value 'metadata workflow-data '()))))

(defun normalize-context (context-data)
  "Normalize a context definition."
  `(#(name ,(get-required 'name context-data))
    #(type ,(get-value 'type context-data 'runtime))
    #(configuration ,(get-value 'configuration context-data '()))
    #(variables ,(get-value 'variables context-data '()))
    #(inherits ,(get-value 'inherits context-data '()))))

(defun normalize-dispatch (dispatch-data)
  "Normalize a dispatch rule."
  `(#(pattern ,(get-required 'pattern dispatch-data))
    #(executor ,(get-required 'executor dispatch-data))
    #(priority ,(get-value 'priority dispatch-data 0))
    #(conditions ,(get-value 'conditions dispatch-data '()))
    #(metadata ,(get-value 'metadata dispatch-data '()))))

(defun normalize-steps (steps)
  "Normalize workflow steps list."
  (lists:map #'normalize-step/1 steps))

(defun normalize-step (step-data)
  "Normalize a single workflow step."
  `(#(symbol ,(get-required 'symbol step-data))
    #(name ,(get-value 'name step-data (get-required 'symbol step-data)))
    #(parameters ,(get-value 'parameters step-data '()))
    #(continue-on-error ,(get-value 'continue-on-error step-data 'false))
    #(timeout ,(get-value 'timeout step-data 'infinity))
    #(retry ,(get-value 'retry step-data 0))))

;;; =============================================================================
;;; Helper Functions
;;; =============================================================================

(defun get-value (key data default)
  "Get value from property list with default."
  (case (proplists:get_value key data)
    ('undefined default)
    (value value)))

(defun get-required (key data)
  "Get required value from property list, error if missing."
  (case (proplists:get_value key data)
    ('undefined
     (error `#(missing-required-field ,key)))
    (value value)))

(defun get-version (metadata default)
  "Extract version from metadata."
  (proplists:get_value 'version metadata default))

(defun get-timestamp ()
  "Get current timestamp."
  (erlang:system_time 'second))

;;; =============================================================================
;;; Advanced Normalization
;;; =============================================================================

(defun apply-defaults (canonical-manifest)
  "Apply default values to manifest."
  (lists:map
    (lambda (section)
      (case section
        ((tuple 'symbols symbols)
         `#(symbols ,(lists:map #'apply-symbol-defaults/1 symbols)))
        (other other)))
    canonical-manifest))

(defun apply-symbol-defaults (symbol)
  "Apply defaults to symbol if fields are missing."
  ;; Symbols are already normalized with defaults
  symbol)

(defun expand-variables (canonical-manifest)
  "Expand environment variables and references in manifest."
  (lists:map
    (lambda (section)
      (case section
        ((tuple 'symbols symbols)
         `#(symbols ,(lists:map #'expand-symbol-vars/1 symbols)))
        ((tuple 'workflows workflows)
         `#(workflows ,(lists:map #'expand-workflow-vars/1 workflows)))
        (other other)))
    canonical-manifest))

(defun expand-symbol-vars (symbol)
  "Expand variables in symbol definition."
  (lists:map
    (lambda (field)
      (case field
        ((tuple 'parameters params)
         `#(parameters ,(expand-params params)))
        (other other)))
    symbol))

(defun expand-workflow-vars (workflow)
  "Expand variables in workflow definition."
  workflow)  ; Placeholder for now

(defun expand-params (params)
  "Expand environment variables in parameters."
  (lists:map
    (lambda (param)
      (case param
        ((tuple key value)
         (if (is_binary value)
           `#(,key ,(expand-env-var value))
           `#(,key ,value)))
        (other other)))
    params))

(defun expand-env-var (value)
  "Expand environment variable references like ${VAR} or $VAR."
  (if (is_binary value)
    (let ((str (binary_to_list value)))
      (case (re:run str "\\$\\{([^}]+)\\}|\\$([A-Za-z_][A-Za-z0-9_]*)")
        ('nomatch value)
        ((tuple 'match matches)
         ;; For now, just return original value
         ;; Full implementation would replace with env var
         value)))
    value))

(defun resolve-paths (canonical-manifest)
  "Resolve relative paths in manifest."
  ;; Placeholder - would resolve file paths relative to manifest location
  canonical-manifest)

(defun sort-by-dependencies (canonical-manifest)
  "Sort symbols by dependency order (topological sort)."
  (lists:map
    (lambda (section)
      (case section
        ((tuple 'symbols symbols)
         `#(symbols ,(topological-sort symbols)))
        (other other)))
    canonical-manifest))

(defun topological-sort (symbols)
  "Perform topological sort on symbols based on dependencies."
  ;; Simple implementation - proper topological sort would detect cycles
  (let ((with-deps (lists:filter
                     (lambda (sym)
                       (not (=:= (proplists:get_value 'dependencies sym) '())))
                     symbols))
        (without-deps (lists:filter
                        (lambda (sym)
                          (=:= (proplists:get_value 'dependencies sym) '()))
                        symbols)))
    (++ without-deps with-deps)))

;;; =============================================================================
;;; Format Detection
;;; =============================================================================

(defun detect-format (filepath)
  "Detect manifest format from file extension."
  (let ((ext (filename:extension filepath)))
    (case ext
      (".yaml" 'yaml)
      (".yml" 'yaml)
      (".toml" 'toml)
      (".tml" 'toml)
      (".dhall" 'dhall)
      (_ 'unknown))))

;;; =============================================================================
;;; Validation Support
;;; =============================================================================

(defun validate-canonical (canonical-manifest)
  "Validate canonical manifest structure."
  (try
    (progn
      (validate-required-sections canonical-manifest)
      (validate-symbols (proplists:get_value 'symbols canonical-manifest))
      (validate-workflows (proplists:get_value 'workflows canonical-manifest))
      'ok)
    (catch
      ((tuple 'error reason)
       `#(error ,reason))
      ((tuple type reason stacktrace)
       `#(error #(,type ,reason ,stacktrace))))))

(defun validate-required-sections (manifest)
  "Ensure required sections exist."
  (let ((required-keys '(version format metadata symbols)))
    (lists:foreach
      (lambda (key)
        (case (proplists:get_value key manifest)
          ('undefined
           (error `#(missing-section ,key)))
          (_ 'ok)))
      required-keys)))

(defun validate-symbols (symbols)
  "Validate symbols list."
  (when (is_list symbols)
    (lists:foreach #'validate-symbol/1 symbols)))

(defun validate-symbol (symbol)
  "Validate individual symbol."
  (let ((required-fields '(name type context)))
    (lists:foreach
      (lambda (field)
        (case (proplists:get_value field symbol)
          ('undefined
           (error `#(missing-symbol-field ,field)))
          (_ 'ok)))
      required-fields)))

(defun validate-workflows (workflows)
  "Validate workflows list."
  (when (is_list workflows)
    (lists:foreach #'validate-workflow/1 workflows)))

(defun validate-workflow (workflow)
  "Validate individual workflow."
  (let ((required-fields '(name steps)))
    (lists:foreach
      (lambda (field)
        (case (proplists:get_value field workflow)
          ('undefined
           (error `#(missing-workflow-field ,field)))
          (_ 'ok)))
      required-fields)))
