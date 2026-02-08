;; symbolic-optimizer.lfe
;; Symbolic Optimizer for WP Praxis Manifest Parser
;;
;; This module optimizes symbolic representations through:
;; - Constant folding
;; - Dead symbol elimination
;; - Dependency optimization
;; - Execution order optimization

(defmodule symbolic-optimizer
  "Optimize symbolic manifest structures."
  (export all))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun optimize (manifest)
  "Apply all optimizations to manifest.

  Args:
    manifest: Canonical manifest structure

  Returns:
    Optimized manifest"
  (let* ((with-constants (fold-constants manifest))
         (without-dead (eliminate-dead-symbols with-constants))
         (with-reordered (optimize-execution-order without-dead))
         (with-merged (merge-similar-symbols with-reordered)))
    with-merged))

(defun optimize-symbols (symbols)
  "Optimize symbol list."
  (-> symbols
      eliminate-unused-symbols
      merge-duplicate-symbols
      reorder-by-dependencies))

(defun optimize-workflows (workflows symbols)
  "Optimize workflows based on symbol analysis."
  (lists:map
    (lambda (workflow)
      (optimize-workflow workflow symbols))
    workflows))

;;; =============================================================================
;;; Constant Folding
;;; =============================================================================

(defun fold-constants (manifest)
  "Fold constant expressions in manifest."
  (lists:map
    (lambda (section)
      (case section
        ((tuple 'symbols symbols)
         `#(symbols ,(lists:map #'fold-symbol-constants/1 symbols)))
        ((tuple 'workflows workflows)
         `#(workflows ,(lists:map #'fold-workflow-constants/1 workflows)))
        (other other)))
    manifest))

(defun fold-symbol-constants (symbol)
  "Fold constants in symbol definition."
  (lists:map
    (lambda (field)
      (case field
        ((tuple 'parameters params)
         `#(parameters ,(fold-parameter-constants params)))
        ((tuple 'metadata meta)
         `#(metadata ,(fold-parameter-constants meta)))
        (other other)))
    symbol))

(defun fold-workflow-constants (workflow)
  "Fold constants in workflow definition."
  (lists:map
    (lambda (field)
      (case field
        ((tuple 'steps steps)
         `#(steps ,(lists:map #'fold-step-constants/1 steps)))
        (other other)))
    workflow))

(defun fold-step-constants (step)
  "Fold constants in workflow step."
  (lists:map
    (lambda (field)
      (case field
        ((tuple 'parameters params)
         `#(parameters ,(fold-parameter-constants params)))
        (other other)))
    step))

(defun fold-parameter-constants (params)
  "Fold constant parameters."
  (lists:map
    (lambda (param)
      (case param
        ((tuple key value)
         (if (is-constant-expr value)
           `#(,key ,(evaluate-constant value))
           `#(,key ,value)))
        (other other)))
    params))

(defun is-constant-expr (expr)
  "Check if expression is a constant."
  (orelse (is_number expr)
          (is_binary expr)
          (is_boolean expr)
          (=:= expr 'null)))

(defun evaluate-constant (expr)
  "Evaluate constant expression."
  expr)  ; Already evaluated for primitives

;;; =============================================================================
;;; Dead Symbol Elimination
;;; =============================================================================

(defun eliminate-dead-symbols (manifest)
  "Remove symbols that are never used."
  (let* ((symbols (proplists:get_value 'symbols manifest '()))
         (workflows (proplists:get_value 'workflows manifest '()))
         (used-symbols (find-used-symbols workflows symbols))
         (live-symbols (filter-live-symbols symbols used-symbols)))
    (lists:map
      (lambda (section)
        (case section
          ((tuple 'symbols _old)
           `#(symbols ,live-symbols))
          (other other)))
      manifest)))

(defun find-used-symbols (workflows symbols)
  "Find all symbols referenced in workflows or by other symbols."
  (let* ((workflow-refs (find-workflow-symbol-refs workflows))
         (dependency-refs (find-dependency-refs symbols))
         (all-refs (++ workflow-refs dependency-refs)))
    (lists:usort (flatten-deep all-refs))))

(defun find-workflow-symbol-refs (workflows)
  "Find symbol references in workflows."
  (lists:flatmap
    (lambda (workflow)
      (let ((steps (proplists:get_value 'steps workflow '())))
        (lists:map
          (lambda (step)
            (proplists:get_value 'symbol step))
          steps)))
    workflows))

(defun find-dependency-refs (symbols)
  "Find symbols referenced as dependencies."
  (lists:flatmap
    (lambda (symbol)
      (proplists:get_value 'dependencies symbol '()))
    symbols))

(defun filter-live-symbols (symbols used-symbols)
  "Keep only live (used) symbols."
  (lists:filter
    (lambda (symbol)
      (let ((name (proplists:get_value 'name symbol)))
        (orelse
          (lists:member name used-symbols)
          (is-entry-point symbol))))
    symbols))

(defun is-entry-point (symbol)
  "Check if symbol is an entry point (always kept)."
  (let ((metadata (proplists:get_value 'metadata symbol '())))
    (proplists:get_value 'entry-point metadata 'false)))

(defun flatten-deep (list)
  "Flatten deeply nested list."
  (lists:flatten list))

;;; =============================================================================
;;; Dependency Optimization
;;; =============================================================================

(defun optimize-execution-order (manifest)
  "Optimize execution order based on dependencies."
  (lists:map
    (lambda (section)
      (case section
        ((tuple 'symbols symbols)
         `#(symbols ,(topological-sort symbols)))
        ((tuple 'workflows workflows)
         `#(workflows ,(optimize-workflow-order workflows)))
        (other other)))
    manifest))

(defun topological-sort (symbols)
  "Sort symbols in topological order (dependencies first)."
  (let ((graph (build-dependency-graph symbols)))
    (case (kahn-algorithm graph)
      ((tuple 'ok sorted-names)
       (reorder-symbols-by-names symbols sorted-names))
      ((tuple 'error 'cycle)
       ;; Can't sort due to cycle, return original
       symbols))))

(defun build-dependency-graph (symbols)
  "Build dependency graph for topological sort."
  (lists:map
    (lambda (symbol)
      (let ((name (proplists:get_value 'name symbol))
            (deps (proplists:get_value 'dependencies symbol '())))
        `#(,name ,deps)))
    symbols))

(defun kahn-algorithm (graph)
  "Kahn's algorithm for topological sorting."
  (let* ((all-nodes (get-all-nodes graph))
         (in-degrees (calculate-in-degrees graph all-nodes))
         (zero-in-degree (find-zero-in-degree in-degrees)))
    (kahn-loop zero-in-degree '() graph in-degrees)))

(defun kahn-loop
  (['() result _graph in-degrees]
   ;; Check if all nodes processed
   (let ((total-nodes (length (maps:keys in-degrees))))
     (if (=:= (length result) total-nodes)
       `#(ok ,(lists:reverse result))
       '#(error cycle))))
  ([(cons node rest) result graph in-degrees]
   (let* ((neighbors (get-neighbors node graph))
          (new-in-degrees (decrease-in-degrees neighbors in-degrees))
          (new-zeros (find-new-zeros neighbors new-in-degrees))
          (new-queue (++ rest new-zeros))
          (new-result (cons node result)))
     (kahn-loop new-queue new-result graph new-in-degrees))))

(defun get-all-nodes (graph)
  "Get all nodes from graph."
  (let ((direct-nodes (lists:map
                        (lambda (entry)
                          (case entry
                            ((tuple node _deps) node)))
                        graph))
        (dep-nodes (lists:flatmap
                     (lambda (entry)
                       (case entry
                         ((tuple _node deps) deps)))
                     graph)))
    (lists:usort (++ direct-nodes dep-nodes))))

(defun calculate-in-degrees (graph nodes)
  "Calculate in-degree for each node."
  (let ((initial-map (maps:from_list
                       (lists:map (lambda (n) `#(,n 0)) nodes))))
    (lists:foldl
      (lambda (entry acc)
        (case entry
          ((tuple _node deps)
           (lists:foldl
             (lambda (dep map)
               (maps:update_with dep
                                 (lambda (v) (+ v 1))
                                 0
                                 map))
             acc
             deps))))
      initial-map
      graph)))

(defun find-zero-in-degree (in-degrees)
  "Find nodes with zero in-degree."
  (maps:fold
    (lambda (node degree acc)
      (if (=:= degree 0)
        (cons node acc)
        acc))
    '()
    in-degrees))

(defun get-neighbors (node graph)
  "Get neighbors of node in graph."
  (case (lists:keyfind node 1 graph)
    ('false '())
    ((tuple _node deps) deps)))

(defun decrease-in-degrees (nodes in-degrees)
  "Decrease in-degree for nodes."
  (lists:foldl
    (lambda (node map)
      (maps:update_with node
                        (lambda (v) (max 0 (- v 1)))
                        0
                        map))
    in-degrees
    nodes))

(defun find-new-zeros (nodes in-degrees)
  "Find nodes that now have zero in-degree."
  (lists:filter
    (lambda (node)
      (=:= (maps:get node in-degrees 1) 0))
    nodes))

(defun reorder-symbols-by-names (symbols sorted-names)
  "Reorder symbols according to sorted names."
  (lists:filtermap
    (lambda (name)
      (case (lists:keyfind name 2 symbols)
        ('false 'false)
        (symbol `#(true ,symbol))))
    sorted-names))

(defun optimize-workflow-order (workflows)
  "Optimize order of workflows."
  workflows)  ; Placeholder

;;; =============================================================================
;;; Symbol Merging
;;; =============================================================================

(defun merge-similar-symbols (manifest)
  "Merge symbols with identical definitions."
  (lists:map
    (lambda (section)
      (case section
        ((tuple 'symbols symbols)
         `#(symbols ,(merge-duplicate-symbols symbols)))
        (other other)))
    manifest))

(defun merge-duplicate-symbols (symbols)
  "Merge duplicate symbol definitions."
  (let ((groups (group-by-signature symbols)))
    (lists:flatmap #'merge-group/1 groups)))

(defun group-by-signature (symbols)
  "Group symbols by their signature."
  (lists:foldl
    (lambda (symbol acc)
      (let ((sig (symbol-signature symbol)))
        (maps:update_with sig
                          (lambda (syms) (cons symbol syms))
                          (list symbol)
                          acc)))
    #m()
    symbols))

(defun symbol-signature (symbol)
  "Calculate signature for symbol (type, context, params)."
  `#(,(proplists:get_value 'type symbol)
     ,(proplists:get_value 'context symbol)
     ,(proplists:get_value 'parameters symbol)))

(defun merge-group (group)
  "Merge a group of similar symbols."
  ;; For now, keep all symbols (no actual merging)
  ;; Full implementation would merge truly identical symbols
  group)

;;; =============================================================================
;;; Unused Symbol Detection
;;; =============================================================================

(defun eliminate-unused-symbols (symbols)
  "Remove symbols with no dependencies and not referenced."
  symbols)  ; Placeholder - requires full reference analysis

;;; =============================================================================
;;; Optimization Analysis
;;; =============================================================================

(defun analyze-optimization-potential (manifest)
  "Analyze potential optimizations for manifest."
  (let* ((symbols (proplists:get_value 'symbols manifest '()))
         (workflows (proplists:get_value 'workflows manifest '()))
         (dead-count (count-dead-symbols symbols workflows))
         (dup-count (count-duplicate-symbols symbols))
         (const-count (count-constant-foldable symbols)))
    `#(optimization-potential
       #(dead-symbols ,dead-count)
       #(duplicate-symbols ,dup-count)
       #(constant-foldable ,const-count))))

(defun count-dead-symbols (symbols workflows)
  "Count symbols that could be eliminated."
  (let ((used (find-used-symbols workflows symbols)))
    (- (length symbols) (length used))))

(defun count-duplicate-symbols (symbols)
  "Count duplicate symbol definitions."
  (let ((groups (group-by-signature symbols))
        (duplicates (maps:filter
                      (lambda (_sig syms)
                        (> (length syms) 1))
                      groups)))
    (maps:size duplicates)))

(defun count-constant-foldable (symbols)
  "Count parameters that could be constant-folded."
  (lists:foldl
    (lambda (symbol acc)
      (let ((params (proplists:get_value 'parameters symbol '())))
        (+ acc (count-foldable-params params))))
    0
    symbols))

(defun count-foldable-params (params)
  "Count foldable parameters."
  (length (lists:filter
            (lambda (param)
              (case param
                ((tuple _key value) (is-constant-expr value))
                (_ 'false)))
            params)))

;;; =============================================================================
;;; Workflow Optimization
;;; =============================================================================

(defun optimize-workflow (workflow symbols)
  "Optimize a single workflow."
  (let* ((steps (proplists:get_value 'steps workflow '()))
         (optimized-steps (optimize-steps steps symbols)))
    (lists:map
      (lambda (field)
        (case field
          ((tuple 'steps _old) `#(steps ,optimized-steps))
          (other other)))
      workflow)))

(defun optimize-steps (steps symbols)
  "Optimize workflow steps."
  (-> steps
      remove-redundant-steps
      (parallelize-independent-steps symbols)))

(defun remove-redundant-steps (steps)
  "Remove redundant steps from workflow."
  steps)  ; Placeholder

(defun parallelize-independent-steps (steps symbols)
  "Identify steps that can run in parallel."
  steps)  ; Placeholder

;;; =============================================================================
;;; Utility Functions
;;; =============================================================================

(defun reorder-by-dependencies (symbols)
  "Reorder symbols by dependencies."
  (topological-sort symbols))
