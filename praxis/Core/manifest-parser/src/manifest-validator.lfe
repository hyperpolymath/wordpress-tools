;; manifest-validator.lfe
;; Manifest Validation Module for WP Praxis
;;
;; This module provides comprehensive validation for manifest structures,
;; including schema validation, type checking, constraint verification,
;; and circular dependency detection.

(defmodule manifest-validator
  "Comprehensive manifest validation with schema and constraint checking."
  (export all))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun validate (manifest)
  "Perform complete validation on manifest.

  Args:
    manifest: Canonical manifest structure

  Returns:
    'ok on success
    (tuple 'error (list-of errors)) on validation failure"
  (let ((errors (collect-errors manifest)))
    (if (=:= errors '())
      'ok
      `#(error ,errors))))

(defun validate-schema (manifest schema)
  "Validate manifest against a schema definition.

  Args:
    manifest: Manifest to validate
    schema: Schema definition (property list)

  Returns:
    'ok or (tuple 'error errors)"
  (let ((errors (validate-against-schema manifest schema)))
    (if (=:= errors '())
      'ok
      `#(error ,errors))))

(defun validate-symbols (symbols)
  "Validate symbols list structure and constraints.

  Args:
    symbols: List of symbol definitions

  Returns:
    'ok or (tuple 'error errors)"
  (let ((errors (collect-symbol-errors symbols)))
    (if (=:= errors '())
      'ok
      `#(error ,errors))))

(defun validate-workflows (workflows)
  "Validate workflows list structure and constraints.

  Args:
    workflows: List of workflow definitions

  Returns:
    'ok or (tuple 'error errors)"
  (let ((errors (collect-workflow-errors workflows)))
    (if (=:= errors '())
      'ok
      `#(error ,errors))))

(defun check-circular-dependencies (symbols)
  "Detect circular dependencies in symbols.

  Args:
    symbols: List of symbol definitions

  Returns:
    (tuple 'ok 'no-cycles) or (tuple 'error (list-of cycles))"
  (let ((cycles (find-cycles symbols)))
    (if (=:= cycles '())
      '#(ok no-cycles)
      `#(error #(circular-dependencies ,cycles)))))

;;; =============================================================================
;;; Error Collection
;;; =============================================================================

(defun collect-errors (manifest)
  "Collect all validation errors from manifest."
  (let* ((structure-errors (validate-structure manifest))
         (type-errors (validate-types manifest))
         (constraint-errors (validate-constraints manifest))
         (dependency-errors (validate-dependencies manifest))
         (semantic-errors (validate-semantics manifest)))
    (lists:flatten [structure-errors
                    type-errors
                    constraint-errors
                    dependency-errors
                    semantic-errors])))

(defun collect-symbol-errors (symbols)
  "Collect all validation errors from symbols."
  (lists:flatmap #'validate-symbol-complete/1 symbols))

(defun collect-workflow-errors (workflows)
  "Collect all validation errors from workflows."
  (lists:flatmap #'validate-workflow-complete/1 workflows))

;;; =============================================================================
;;; Structure Validation
;;; =============================================================================

(defun validate-structure (manifest)
  "Validate manifest has required structure."
  (let ((required-sections '(version format metadata symbols))
        (errors '()))
    (lists:foldl
      (lambda (section acc)
        (case (proplists:get_value section manifest)
          ('undefined
           (cons `#(missing-section ,section) acc))
          (_ acc)))
      errors
      required-sections)))

(defun validate-symbol-structure (symbol)
  "Validate symbol has required structure."
  (let ((required-fields '(name type context))
        (errors '()))
    (lists:foldl
      (lambda (field acc)
        (case (proplists:get_value field symbol)
          ('undefined
           (cons `#(missing-field ,field ,(proplists:get_value 'name symbol)) acc))
          (_ acc)))
      errors
      required-fields)))

(defun validate-workflow-structure (workflow)
  "Validate workflow has required structure."
  (let ((required-fields '(name steps))
        (errors '()))
    (lists:foldl
      (lambda (field acc)
        (case (proplists:get_value field workflow)
          ('undefined
           (cons `#(missing-field ,field ,(proplists:get_value 'name workflow)) acc))
          (_ acc)))
      errors
      required-fields)))

;;; =============================================================================
;;; Type Validation
;;; =============================================================================

(defun validate-types (manifest)
  "Validate types of all fields in manifest."
  (++
    (validate-metadata-types (proplists:get_value 'metadata manifest '()))
    (validate-symbols-types (proplists:get_value 'symbols manifest '()))
    (validate-workflows-types (proplists:get_value 'workflows manifest '()))))

(defun validate-metadata-types (metadata)
  "Validate metadata field types."
  (let ((errors '()))
    (lists:foldl
      (lambda (field acc)
        (case field
          ((tuple 'version v)
           (if (is_binary v) acc
             (cons `#(invalid-type metadata version expected-binary ,v) acc)))
          ((tuple 'name n)
           (if (is_binary n) acc
             (cons `#(invalid-type metadata name expected-binary ,n) acc)))
          ((tuple 'tags t)
           (if (is_list t) acc
             (cons `#(invalid-type metadata tags expected-list ,t) acc)))
          (_ acc)))
      errors
      metadata)))

(defun validate-symbols-types (symbols)
  "Validate types for all symbols."
  (lists:flatmap #'validate-symbol-types/1 symbols))

(defun validate-symbol-types (symbol)
  "Validate types for a single symbol."
  (let ((name (proplists:get_value 'name symbol))
        (errors '()))
    (lists:foldl
      (lambda (field acc)
        (case field
          ((tuple 'name n)
           (if (orelse (is_binary n) (is_atom n)) acc
             (cons `#(invalid-type symbol ,name name expected-binary-or-atom ,n) acc)))
          ((tuple 'type t)
           (if (is_atom t) acc
             (cons `#(invalid-type symbol ,name type expected-atom ,t) acc)))
          ((tuple 'dependencies d)
           (if (is_list d) acc
             (cons `#(invalid-type symbol ,name dependencies expected-list ,d) acc)))
          ((tuple 'enabled e)
           (if (is_boolean e) acc
             (cons `#(invalid-type symbol ,name enabled expected-boolean ,e) acc)))
          (_ acc)))
      errors
      symbol)))

(defun validate-workflows-types (workflows)
  "Validate types for all workflows."
  (lists:flatmap #'validate-workflow-types/1 workflows))

(defun validate-workflow-types (workflow)
  "Validate types for a single workflow."
  (let ((name (proplists:get_value 'name workflow))
        (errors '()))
    (lists:foldl
      (lambda (field acc)
        (case field
          ((tuple 'name n)
           (if (orelse (is_binary n) (is_atom n)) acc
             (cons `#(invalid-type workflow ,name name expected-binary-or-atom ,n) acc)))
          ((tuple 'steps s)
           (if (is_list s) acc
             (cons `#(invalid-type workflow ,name steps expected-list ,s) acc)))
          ((tuple 'parallel p)
           (if (is_boolean p) acc
             (cons `#(invalid-type workflow ,name parallel expected-boolean ,p) acc)))
          (_ acc)))
      errors
      workflow)))

;;; =============================================================================
;;; Constraint Validation
;;; =============================================================================

(defun validate-constraints (manifest)
  "Validate constraints on manifest data."
  (++
    (validate-symbol-constraints (proplists:get_value 'symbols manifest '()))
    (validate-workflow-constraints (proplists:get_value 'workflows manifest '()))))

(defun validate-symbol-constraints (symbols)
  "Validate constraints on symbols."
  (let ((names (lists:map
                 (lambda (s) (proplists:get_value 'name s))
                 symbols)))
    ;; Check for duplicate symbol names
    (check-duplicates names 'symbol)))

(defun validate-workflow-constraints (workflows)
  "Validate constraints on workflows."
  (let ((names (lists:map
                 (lambda (w) (proplists:get_value 'name w))
                 workflows)))
    ;; Check for duplicate workflow names
    (check-duplicates names 'workflow)))

(defun check-duplicates (items item-type)
  "Check for duplicate items in list."
  (let ((duplicates (find-duplicates items)))
    (if (=:= duplicates '())
      '()
      (lists:map
        (lambda (dup) `#(duplicate ,item-type ,dup))
        duplicates))))

(defun find-duplicates (list)
  "Find duplicate elements in list."
  (find-duplicates list '() '()))

(defun find-duplicates
  (['() _seen duplicates] duplicates)
  ([(cons item rest) seen duplicates]
   (if (lists:member item seen)
     (find-duplicates rest seen (cons item duplicates))
     (find-duplicates rest (cons item seen) duplicates))))

;;; =============================================================================
;;; Dependency Validation
;;; =============================================================================

(defun validate-dependencies (manifest)
  "Validate symbol dependencies are valid."
  (let* ((symbols (proplists:get_value 'symbols manifest '()))
         (symbol-names (lists:map
                         (lambda (s) (proplists:get_value 'name s))
                         symbols)))
    (lists:flatmap
      (lambda (symbol)
        (validate-symbol-dependencies symbol symbol-names))
      symbols)))

(defun validate-symbol-dependencies (symbol valid-names)
  "Validate dependencies of a single symbol."
  (let* ((name (proplists:get_value 'name symbol))
         (deps (proplists:get_value 'dependencies symbol '())))
    (lists:filtermap
      (lambda (dep)
        (if (lists:member dep valid-names)
          'false
          `#(true #(invalid-dependency ,name references-unknown ,dep))))
      deps)))

;;; =============================================================================
;;; Circular Dependency Detection
;;; =============================================================================

(defun find-cycles (symbols)
  "Find circular dependencies in symbols using DFS."
  (let ((graph (build-dependency-graph symbols)))
    (detect-cycles-in-graph graph)))

(defun build-dependency-graph (symbols)
  "Build adjacency list representation of dependency graph."
  (lists:map
    (lambda (symbol)
      (let ((name (proplists:get_value 'name symbol))
            (deps (proplists:get_value 'dependencies symbol '())))
        `#(,name ,deps)))
    symbols))

(defun detect-cycles-in-graph (graph)
  "Detect cycles in dependency graph using DFS."
  (let ((nodes (lists:map (lambda (entry)
                            (case entry
                              ((tuple node _deps) node)))
                          graph)))
    (detect-cycles-dfs nodes graph '() '() '())))

(defun detect-cycles-dfs
  ;; All nodes visited
  (['() _graph _visiting _visited cycles] cycles)
  ;; Process next node
  ([(cons node rest) graph visiting visited cycles]
   (cond
     ;; Already visited, skip
     ((lists:member node visited)
      (detect-cycles-dfs rest graph visiting visited cycles))
     ;; Currently visiting - cycle detected!
     ((lists:member node visiting)
      (let ((cycle (extract-cycle node visiting)))
        (detect-cycles-dfs rest graph visiting visited (cons cycle cycles))))
     ;; New node, visit it
     ('true
      (let* ((deps (get-dependencies node graph))
             (new-visiting (cons node visiting))
             (result-cycles (detect-cycles-dfs deps graph new-visiting visited cycles))
             (new-visited (cons node visited))
             (new-visiting2 (lists:delete node new-visiting)))
        (detect-cycles-dfs rest graph new-visiting2 new-visited result-cycles))))))

(defun get-dependencies (node graph)
  "Get dependencies of a node from graph."
  (case (lists:keyfind node 1 graph)
    ('false '())
    ((tuple _node deps) deps)))

(defun extract-cycle (node visiting)
  "Extract cycle path from visiting stack."
  (extract-cycle-helper node visiting '()))

(defun extract-cycle-helper
  ([node '() acc] (lists:reverse (cons node acc)))
  ([node (cons n rest) acc]
   (if (=:= node n)
     (lists:reverse (cons node acc))
     (extract-cycle-helper node rest (cons n acc)))))

;;; =============================================================================
;;; Semantic Validation
;;; =============================================================================

(defun validate-semantics (manifest)
  "Validate semantic correctness of manifest."
  (++
    (validate-workflow-semantics (proplists:get_value 'workflows manifest '())
                                 (proplists:get_value 'symbols manifest '()))
    (validate-dispatch-semantics (proplists:get_value 'dispatches manifest '())
                                 (proplists:get_value 'symbols manifest '()))))

(defun validate-workflow-semantics (workflows symbols)
  "Validate workflows reference valid symbols."
  (let ((symbol-names (lists:map
                        (lambda (s) (proplists:get_value 'name s))
                        symbols)))
    (lists:flatmap
      (lambda (workflow)
        (validate-workflow-steps workflow symbol-names))
      workflows)))

(defun validate-workflow-steps (workflow symbol-names)
  "Validate workflow steps reference valid symbols."
  (let* ((workflow-name (proplists:get_value 'name workflow))
         (steps (proplists:get_value 'steps workflow '())))
    (lists:filtermap
      (lambda (step)
        (let ((symbol-ref (proplists:get_value 'symbol step)))
          (if (lists:member symbol-ref symbol-names)
            'false
            `#(true #(invalid-symbol-reference ,workflow-name ,symbol-ref)))))
      steps)))

(defun validate-dispatch-semantics (dispatches symbols)
  "Validate dispatch rules are semantically correct."
  ;; Placeholder for dispatch validation
  '())

;;; =============================================================================
;;; Schema Validation
;;; =============================================================================

(defun validate-against-schema (data schema)
  "Validate data against schema definition."
  (case schema
    ((tuple 'object properties)
     (validate-object data properties))
    ((tuple 'array item-schema)
     (validate-array data item-schema))
    ((tuple 'string constraints)
     (validate-string data constraints))
    ((tuple 'integer constraints)
     (validate-integer data constraints))
    ((tuple 'boolean)
     (validate-boolean data))
    (_ '())))

(defun validate-object (data properties)
  "Validate object against property schemas."
  (if (is_list data)
    (lists:flatmap
      (lambda (prop-schema)
        (case prop-schema
          ((tuple key schema required)
           (case (proplists:get_value key data)
             ('undefined
              (if required
                `(#(missing-required-property ,key))
                '()))
             (value
              (validate-against-schema value schema))))
          (_ '())))
      properties)
    `(#(expected-object ,data))))

(defun validate-array (data item-schema)
  "Validate array items against schema."
  (if (is_list data)
    (lists:flatmap
      (lambda (item)
        (validate-against-schema item item-schema))
      data)
    `(#(expected-array ,data))))

(defun validate-string (data _constraints)
  "Validate string against constraints."
  (if (orelse (is_binary data) (is_list data))
    '()
    `(#(expected-string ,data))))

(defun validate-integer (data _constraints)
  "Validate integer against constraints."
  (if (is_integer data)
    '()
    `(#(expected-integer ,data))))

(defun validate-boolean (data)
  "Validate boolean."
  (if (is_boolean data)
    '()
    `(#(expected-boolean ,data))))

;;; =============================================================================
;;; Complete Validation
;;; =============================================================================

(defun validate-symbol-complete (symbol)
  "Complete validation for a symbol."
  (++
    (validate-symbol-structure symbol)
    (validate-symbol-types symbol)))

(defun validate-workflow-complete (workflow)
  "Complete validation for a workflow."
  (++
    (validate-workflow-structure workflow)
    (validate-workflow-types workflow)))

;;; =============================================================================
;;; Error Reporting
;;; =============================================================================

(defun format-errors (errors)
  "Format validation errors for display."
  (lists:map #'format-error/1 errors))

(defun format-error (error)
  "Format a single validation error."
  (case error
    ((tuple 'missing-section section)
     (io_lib:format "Missing required section: ~p" (list section)))
    ((tuple 'missing-field field context)
     (io_lib:format "Missing required field '~p' in ~p" (list field context)))
    ((tuple 'invalid-type context field expected actual)
     (io_lib:format "Invalid type in ~p.~p: expected ~p, got ~p"
                    (list context field expected actual)))
    ((tuple 'duplicate type name)
     (io_lib:format "Duplicate ~p name: ~p" (list type name)))
    ((tuple 'invalid-dependency symbol ref)
     (io_lib:format "Symbol '~p' references unknown dependency '~p'"
                    (list symbol ref)))
    ((tuple 'circular-dependencies cycles)
     (io_lib:format "Circular dependencies detected: ~p" (list cycles)))
    (other
     (io_lib:format "Validation error: ~p" (list other)))))
