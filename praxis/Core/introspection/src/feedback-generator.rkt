#lang racket/base

;;; Feedback Generator
;;; Generates actionable recommendations, suggests optimizations,
;;; identifies anti-patterns, proposes refactorings

(require racket/contract
         racket/match
         racket/list
         racket/hash
         racket/string
         racket/format)

(provide generate-feedback-report
         suggest-optimizations
         identify-antipatterns
         propose-refactorings
         generate-actionable-items
         prioritize-feedback
         format-feedback-report)

;; Data structures for feedback
(struct feedback-item
  (category
   priority
   title
   description
   actionable-steps
   impact
   effort)
  #:transparent)

(struct optimization-suggestion
  (type
   target
   current-metric
   suggested-metric
   rationale)
  #:transparent)

(struct antipattern-detection
  (pattern-name
   location
   description
   fix-suggestion)
  #:transparent)

;; Main feedback generation function
(define/contract (generate-feedback-report state trace analysis)
  (-> hash? (or/c hash? #f) (or/c hash? #f) hash?)

  (define feedback-items '())

  ;; Generate feedback from state analysis
  (when state
    (set! feedback-items
          (append feedback-items (analyze-state-feedback state))))

  ;; Generate feedback from trace analysis
  (when trace
    (set! feedback-items
          (append feedback-items (analyze-trace-feedback trace))))

  ;; Generate feedback from semantic analysis
  (when analysis
    (set! feedback-items
          (append feedback-items (analyze-semantic-feedback analysis))))

  ;; Identify optimizations
  (define optimizations (suggest-optimizations state trace))

  ;; Identify anti-patterns
  (define antipatterns (identify-antipatterns state))

  ;; Propose refactorings
  (define refactorings (propose-refactorings state analysis))

  ;; Prioritize all feedback
  (define prioritized (prioritize-feedback feedback-items))

  (make-hash
   (list (cons 'feedback-items prioritized)
         (cons 'optimizations optimizations)
         (cons 'antipatterns antipatterns)
         (cons 'refactorings refactorings)
         (cons 'summary (generate-summary prioritized optimizations antipatterns))
         (cons 'actionable-items (generate-actionable-items prioritized)))))

;; Analyze state for feedback
(define (analyze-state-feedback state)
  (define items '())

  ;; Check symbol count
  (when (hash-has-key? state 'statistics)
    (define stats (hash-ref state 'statistics))
    (when (hash-has-key? stats 'total-symbols)
      (define total (hash-ref stats 'total-symbols))

      (when (> total 50)
        (set! items
              (cons (feedback-item
                     'complexity
                     'medium
                     "High symbol count"
                     (format "Manifest contains ~a symbols. Consider breaking into smaller modules." total)
                     '("Split manifest into logical groups"
                       "Use imports/includes for modularity"
                       "Review if all symbols are necessary")
                     'medium
                     'medium)
                    items)))))

  ;; Check for warnings
  (when (hash-has-key? state 'warnings)
    (define warnings (hash-ref state 'warnings))
    (when (not (null? warnings))
      (set! items
            (cons (feedback-item
                   'validation
                   'high
                   "Manifest validation warnings"
                   (format "Found ~a validation warnings" (length warnings))
                   (list "Review and fix all warnings"
                         "Ensure all required fields are present"
                         "Validate symbol references")
                   'high
                   'low)
                  items))))

  ;; Check dependency depth
  (when (hash-has-key? state 'statistics)
    (define stats (hash-ref state 'statistics))
    (when (hash-has-key? stats 'max-depth)
      (define depth (hash-ref stats 'max-depth))

      (when (> depth 5)
        (set! items
              (cons (feedback-item
                     'complexity
                     'medium
                     "Deep dependency chains"
                     (format "Maximum dependency depth is ~a. Deep chains are harder to debug." depth)
                     '("Flatten dependency structure where possible"
                       "Consider aggregating intermediate steps"
                       "Review if all dependencies are necessary")
                     'medium
                     'high)
                    items)))))

  items)

;; Analyze trace for feedback
(define (analyze-trace-feedback trace)
  (define items '())

  ;; Check for bottlenecks
  (when (hash-has-key? trace 'bottlenecks)
    (define bottlenecks (hash-ref trace 'bottlenecks))
    (when (not (null? bottlenecks))
      (set! items
            (cons (feedback-item
                   'performance
                   'high
                   "Performance bottlenecks detected"
                   (format "Found ~a bottlenecks in execution" (length bottlenecks))
                   (map (λ (b)
                          (format "Optimize ~a in ~a layer"
                                  (hash-ref b 'operation)
                                  (hash-ref b 'layer)))
                        bottlenecks)
                   'high
                   'high)
                  items))))

  ;; Check for cycles
  (when (hash-has-key? trace 'cycles)
    (define cycles (hash-ref trace 'cycles))
    (when (not (null? cycles))
      (set! items
            (cons (feedback-item
                   'correctness
                   'critical
                   "Recursion cycles detected"
                   (format "Found ~a recursion cycles" (length cycles))
                   '("Review and eliminate circular dependencies"
                     "Restructure workflow to avoid cycles"
                     "Use memoization if recursion is intentional")
                   'critical
                   'high)
                  items))))

  ;; Check preservation score
  (when (hash-has-key? trace 'preservation-score)
    (define score (hash-ref trace 'preservation-score))
    (when (< score 0.7)
      (set! items
            (cons (feedback-item
                   'semantics
                   'high
                   "Low semantic preservation"
                   (format "Semantic preservation score is ~a (below 0.7 threshold)" (~r score #:precision 2))
                   '("Review semantic transformations at each layer"
                     "Ensure context is properly propagated"
                     "Validate that output matches expected semantics")
                   'high
                   'high)
                  items))))

  items)

;; Analyze semantic analysis for feedback
(define (analyze-semantic-feedback analysis)
  (define items '())

  ;; Check contract violations
  (when (hash-has-key? analysis 'contract-violations)
    (define violations (hash-ref analysis 'contract-violations))
    (when (not (null? violations))
      (set! items
            (cons (feedback-item
                   'correctness
                   'critical
                   "Contract violations detected"
                   (format "Found ~a contract violations" (length violations))
                   '("Fix all contract violations"
                     "Ensure symbols meet their contracts"
                     "Add missing required metadata")
                   'critical
                   'medium)
                  items))))

  ;; Check type errors
  (when (hash-has-key? analysis 'type-errors)
    (define errors (hash-ref analysis 'type-errors))
    (when (not (null? errors))
      (set! items
            (cons (feedback-item
                   'correctness
                   'high
                   "Type errors detected"
                   (format "Found ~a type errors" (length errors))
                   '("Fix type mismatches"
                     "Add type annotations"
                     "Validate parameter types")
                   'high
                   'medium)
                  items))))

  ;; Check invariant violations
  (when (hash-has-key? analysis 'invariant-violations)
    (define violations (hash-ref analysis 'invariant-violations))
    (when (not (null? violations))
      (set! items
            (cons (feedback-item
                   'correctness
                   'critical
                   "Invariant violations"
                   (format "Found ~a invariant violations" (length violations))
                   '("Resolve all invariant violations"
                     "Fix circular dependencies"
                     "Ensure symbol name uniqueness")
                   'critical
                   'high)
                  items))))

  items)

;; Suggest optimizations
(define/contract (suggest-optimizations state trace)
  (-> hash? (or/c hash? #f) (listof optimization-suggestion?))

  (define suggestions '())

  ;; Optimization 1: Parallel execution opportunities
  (when (and trace (hash-has-key? trace 'dag))
    (define independent-symbols (find-independent-symbols state))
    (when (> (length independent-symbols) 1)
      (set! suggestions
            (cons (optimization-suggestion
                   'parallelization
                   'execution
                   "Sequential"
                   "Parallel"
                   (format "~a symbols can be executed in parallel"
                           (length independent-symbols)))
                  suggestions))))

  ;; Optimization 2: Caching opportunities
  (when state
    (define cacheable-symbols (find-cacheable-symbols state))
    (when (not (null? cacheable-symbols))
      (set! suggestions
            (cons (optimization-suggestion
                   'caching
                   'symbols
                   "No caching"
                   "Cached results"
                   (format "~a symbols are good candidates for caching"
                           (length cacheable-symbols)))
                  suggestions))))

  ;; Optimization 3: Reduce layer transitions
  (when (and trace (hash-has-key? trace 'statistics))
    (define stats (hash-ref trace 'statistics))
    (when (hash-has-key? stats 'total-steps)
      (define steps (hash-ref stats 'total-steps))
      (when (> steps 10)
        (set! suggestions
              (cons (optimization-suggestion
                     'layer-consolidation
                     'architecture
                     (format "~a layer transitions" steps)
                     "Fewer transitions"
                     "Consider consolidating operations within layers")
                    suggestions)))))

  suggestions)

(define (find-independent-symbols state)
  ;; Find symbols with no dependencies
  (if (hash-has-key? state 'symbols)
      (filter (λ (sym)
                (and (hash? sym)
                     (not (hash-has-key? sym 'depends-on))))
              (hash-ref state 'symbols))
      '()))

(define (find-cacheable-symbols state)
  ;; Find symbols that are pure (no side effects) and could be cached
  (if (hash-has-key? state 'symbols)
      (filter (λ (sym)
                (and (hash? sym)
                     (or (equal? (hash-ref sym 'type #f) "query")
                         (equal? (hash-ref sym 'type #f) "filter"))))
              (hash-ref state 'symbols))
      '()))

;; Identify anti-patterns
(define/contract (identify-antipatterns state)
  (-> hash? (listof antipattern-detection?))

  (define patterns '())

  (when (hash-has-key? state 'symbols)
    (define symbols (hash-ref state 'symbols))

    ;; Anti-pattern 1: God symbol (too many responsibilities)
    (for ([sym symbols])
      (when (hash? sym)
        (define meta (hash-ref sym 'metadata (hash)))
        (define param-count (if (hash-has-key? meta 'parameters)
                                (hash-count (hash-ref meta 'parameters))
                                0))
        (when (> param-count 10)
          (set! patterns
                (cons (antipattern-detection
                       "God Symbol"
                       (hash-ref sym 'name "unknown")
                       "Symbol has too many parameters (> 10), indicating too many responsibilities"
                       "Split into multiple smaller symbols with focused responsibilities")
                      patterns)))))

    ;; Anti-pattern 2: Shotgun surgery (symbol depends on too many others)
    (for ([sym symbols])
      (when (hash? sym)
        (define deps (hash-ref sym 'depends-on '()))
        (define dep-count (if (list? deps) (length deps) 1))
        (when (> dep-count 5)
          (set! patterns
                (cons (antipattern-detection
                       "Shotgun Surgery"
                       (hash-ref sym 'name "unknown")
                       "Symbol depends on too many other symbols (> 5)"
                       "Introduce intermediate aggregation symbols to reduce coupling")
                      patterns)))))

    ;; Anti-pattern 3: Primitive obsession (using strings for structured data)
    (for ([sym symbols])
      (when (hash? sym)
        (define meta (hash-ref sym 'metadata (hash)))
        (when (hash-has-key? meta 'parameters)
          (define params (hash-ref meta 'parameters))
          (when (hash? params)
            (for ([(k v) (in-hash params)])
              (when (and (string? v)
                         (or (string-contains? v ",")
                             (string-contains? v "|")
                             (string-contains? v ";")))
                (set! patterns
                      (cons (antipattern-detection
                             "Primitive Obsession"
                             (format "~a.~a" (hash-ref sym 'name "unknown") k)
                             "Using delimited strings instead of structured data"
                             "Use arrays or objects for structured data instead of delimited strings")
                            patterns)))))))))

  patterns)

;; Propose refactorings
(define/contract (propose-refactorings state analysis)
  (-> hash? (or/c hash? #f) (listof hash?))

  (define refactorings '())

  ;; Refactoring 1: Extract module (for large manifests)
  (when (and (hash-has-key? state 'statistics)
             (hash-has-key? (hash-ref state 'statistics) 'total-symbols))
    (define total (hash-ref (hash-ref state 'statistics) 'total-symbols))
    (when (> total 30)
      (set! refactorings
            (cons (make-hash
                   (list (cons 'type "Extract Module")
                         (cons 'description "Split large manifest into smaller modules")
                         (cons 'benefits '("Improved maintainability"
                                           "Better organization"
                                           "Easier testing"))
                         (cons 'effort 'medium)))
                  refactorings))))

  ;; Refactoring 2: Introduce abstraction (for repeated patterns)
  (when (hash-has-key? state 'patterns)
    (define patterns (hash-ref state 'patterns))
    (when (> (length patterns) 0)
      (set! refactorings
            (cons (make-hash
                   (list (cons 'type "Introduce Abstraction")
                         (cons 'description "Create reusable templates for repeated patterns")
                         (cons 'benefits '("Reduced duplication"
                                           "Consistent behavior"
                                           "Easier updates"))
                         (cons 'effort 'high)))
                  refactorings))))

  ;; Refactoring 3: Simplify dependencies (for deep chains)
  (when (and (hash-has-key? state 'statistics)
             (hash-has-key? (hash-ref state 'statistics) 'max-depth))
    (define depth (hash-ref (hash-ref state 'statistics) 'max-depth))
    (when (> depth 5)
      (set! refactorings
            (cons (make-hash
                   (list (cons 'type "Simplify Dependencies")
                         (cons 'description "Flatten deep dependency chains")
                         (cons 'benefits '("Easier debugging"
                                           "Better performance"
                                           "Clearer data flow"))
                         (cons 'effort 'high)))
                  refactorings))))

  refactorings)

;; Generate actionable items
(define/contract (generate-actionable-items feedback-items)
  (-> (listof feedback-item?) (listof hash?))

  (map (λ (item)
         (make-hash
          (list (cons 'priority (feedback-item-priority item))
                (cons 'title (feedback-item-title item))
                (cons 'actions (feedback-item-actionable-steps item))
                (cons 'impact (feedback-item-impact item))
                (cons 'effort (feedback-item-effort item)))))
       feedback-items))

;; Prioritize feedback
(define/contract (prioritize-feedback feedback-items)
  (-> (listof feedback-item?) (listof feedback-item?))

  (define priority-order '(critical high medium low))

  (sort feedback-items
        (λ (a b)
          (define a-idx (index-of priority-order (feedback-item-priority a)))
          (define b-idx (index-of priority-order (feedback-item-priority b)))
          (< (or a-idx 999) (or b-idx 999)))))

;; Generate summary
(define (generate-summary feedback optimizations antipatterns)
  (make-hash
   (list (cons 'total-items (length feedback))
         (cons 'critical (count-by-priority feedback 'critical))
         (cons 'high (count-by-priority feedback 'high))
         (cons 'medium (count-by-priority feedback 'medium))
         (cons 'low (count-by-priority feedback 'low))
         (cons 'optimization-opportunities (length optimizations))
         (cons 'antipatterns-detected (length antipatterns)))))

(define (count-by-priority items priority)
  (length (filter (λ (item)
                    (equal? (feedback-item-priority item) priority))
                  items)))

;; Format feedback report
(define/contract (format-feedback-report report)
  (-> hash? string?)

  (define summary (hash-ref report 'summary))
  (define items (hash-ref report 'feedback-items))
  (define optimizations (hash-ref report 'optimizations))
  (define antipatterns (hash-ref report 'antipatterns))

  (string-append
   "=== WP Praxis Introspection Feedback Report ===\n\n"
   (format "Total Issues: ~a\n" (hash-ref summary 'total-items))
   (format "  Critical: ~a\n" (hash-ref summary 'critical))
   (format "  High:     ~a\n" (hash-ref summary 'high))
   (format "  Medium:   ~a\n" (hash-ref summary 'medium))
   (format "  Low:      ~a\n\n" (hash-ref summary 'low))
   (format "Optimization Opportunities: ~a\n" (hash-ref summary 'optimization-opportunities))
   (format "Anti-patterns Detected:     ~a\n\n" (hash-ref summary 'antipatterns-detected))
   (if (null? items)
       "No issues found!\n"
       (string-join (map format-feedback-item items) "\n\n"))))

(define (format-feedback-item item)
  (format "[~a] ~a\n~a\nActions:\n~a"
          (string-upcase (symbol->string (feedback-item-priority item)))
          (feedback-item-title item)
          (feedback-item-description item)
          (string-join (map (λ (step) (format "  - ~a" step))
                            (feedback-item-actionable-steps item))
                       "\n")))
