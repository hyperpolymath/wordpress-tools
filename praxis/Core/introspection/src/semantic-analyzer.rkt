#lang racket/base

;;; Semantic Analyzer
;;; Compares input/output semantics at each layer, detects semantic drift,
;;; verifies symbolic contracts, performs type soundness checking

(require racket/contract
         racket/match
         racket/list
         racket/hash
         racket/set
         racket/string)

(provide analyze-semantic-integrity
         compare-layer-semantics
         detect-semantic-drift
         verify-symbolic-contracts
         check-type-soundness
         validate-invariants
         compute-semantic-distance
         semantic-equivalence?)

;; Data structures for semantic analysis
(struct semantic-context
  (layer
   input-semantics
   output-semantics
   preserved-properties
   lost-properties
   added-properties)
  #:transparent)

(struct contract-violation
  (symbol
   contract-type
   expected
   actual
   severity)
  #:transparent)

(struct type-error
  (location
   expected-type
   actual-type
   message)
  #:transparent)

;; Main semantic integrity analysis
(define/contract (analyze-semantic-integrity state)
  (-> hash? hash?)

  (define symbols (hash-ref state 'symbols '()))
  (define metadata (hash-ref state 'metadata (hash)))

  (define contracts (verify-symbolic-contracts symbols metadata))
  (define type-errors (check-type-soundness symbols metadata))
  (define invariant-violations (validate-invariants symbols metadata))
  (define drift-analysis (detect-semantic-drift symbols metadata))

  (make-hash
   (list (cons 'contract-violations contracts)
         (cons 'type-errors type-errors)
         (cons 'invariant-violations invariant-violations)
         (cons 'semantic-drift drift-analysis)
         (cons 'integrity-score (compute-integrity-score
                                  contracts type-errors invariant-violations))
         (cons 'recommendations (generate-recommendations
                                 contracts type-errors invariant-violations)))))

;; Compare semantics between layers
(define/contract (compare-layer-semantics input-layer output-layer)
  (-> hash? hash? hash?)

  (define input-props (extract-semantic-properties input-layer))
  (define output-props (extract-semantic-properties output-layer))

  (define preserved (set-intersect input-props output-props))
  (define lost (set-subtract input-props output-props))
  (define added (set-subtract output-props input-props))

  (make-hash
   (list (cons 'preserved (set->list preserved))
         (cons 'lost (set->list lost))
         (cons 'added (set->list added))
         (cons 'preservation-ratio (if (set-empty? input-props)
                                        1.0
                                        (/ (set-count preserved)
                                           (set-count input-props)))))))

;; Extract semantic properties from layer data
(define (extract-semantic-properties layer-data)
  (cond
    [(hash? layer-data)
     (define props (mutable-set))
     (for ([(k v) (in-hash layer-data)])
       (set-add! props k)
       (when (hash? v)
         (for ([sub-prop (set->list (extract-semantic-properties v))])
           (set-add! props (string->symbol
                            (format "~a.~a" k sub-prop))))))
     props]
    [(list? layer-data)
     (apply set-union (set) (map extract-semantic-properties layer-data))]
    [else (set)]))

;; Detect semantic drift across execution
(define/contract (detect-semantic-drift symbols metadata)
  (-> (listof any/c) hash? (listof hash?))

  (define drift-instances '())

  ;; Check each symbol for semantic consistency
  (for ([sym symbols])
    (when (hash? sym)
      (define symbol-name (hash-ref sym 'name "unknown"))
      (define symbol-type (hash-ref sym 'type "unknown"))
      (define context (hash-ref sym 'context "global"))

      ;; Check for type consistency
      (when (and (hash-has-key? metadata symbol-name)
                 (hash? (hash-ref metadata symbol-name)))
        (define meta (hash-ref metadata symbol-name))

        ;; Check dispatch vs type alignment
        (when (hash-has-key? meta 'dispatch)
          (define dispatch (hash-ref meta 'dispatch))
          (define expected-dispatch (get-expected-dispatch symbol-type))

          (when (and expected-dispatch
                     (not (equal? dispatch expected-dispatch)))
            (set! drift-instances
                  (cons (make-hash
                         (list (cons 'symbol symbol-name)
                               (cons 'type "dispatch-mismatch")
                               (cons 'expected expected-dispatch)
                               (cons 'actual dispatch)
                               (cons 'severity "medium")))
                        drift-instances)))))

      ;; Check context consistency
      (when (and (equal? context "wordpress")
                 (not (has-wordpress-metadata? sym)))
        (set! drift-instances
              (cons (make-hash
                     (list (cons 'symbol symbol-name)
                           (cons 'type "context-mismatch")
                           (cons 'message "WordPress context without WP metadata")
                           (cons 'severity "low")))
                    drift-instances)))))

  drift-instances)

(define (get-expected-dispatch symbol-type)
  (match symbol-type
    ["action" "rust_injector"]
    ["filter" "rust_injector"]
    ["hook" "powershell"]
    ["query" "elixir"]
    [_ #f]))

(define (has-wordpress-metadata? sym)
  (and (hash-has-key? sym 'metadata)
       (let ([meta (hash-ref sym 'metadata)])
         (and (hash? meta)
              (or (hash-has-key? meta 'hook-name)
                  (hash-has-key? meta 'filter-name)
                  (hash-has-key? meta 'post-type))))))

;; Verify symbolic contracts
(define/contract (verify-symbolic-contracts symbols metadata)
  (-> (listof any/c) hash? (listof contract-violation?))

  (define violations '())

  (for ([sym symbols])
    (when (hash? sym)
      (define symbol-name (hash-ref sym 'name "unknown"))
      (define symbol-type (hash-ref sym 'type "unknown"))

      ;; Contract: Actions must have dispatch metadata
      (when (equal? symbol-type "action")
        (unless (and (hash-has-key? metadata symbol-name)
                     (hash-has-key? (hash-ref metadata symbol-name) 'dispatch))
          (set! violations
                (cons (contract-violation
                       symbol-name
                       "action-dispatch"
                       "dispatch metadata required"
                       "missing"
                       "high")
                      violations))))

      ;; Contract: Symbols with dependencies must reference existing symbols
      (when (hash-has-key? sym 'depends-on)
        (define deps (hash-ref sym 'depends-on))
        (define dep-list (if (list? deps) deps (list deps)))
        (define symbol-names (map (λ (s)
                                    (if (hash? s)
                                        (hash-ref s 'name "")
                                        ""))
                                  symbols))

        (for ([dep dep-list])
          (unless (member dep symbol-names)
            (set! violations
                  (cons (contract-violation
                         symbol-name
                         "dependency-reference"
                         (format "existing symbol ~a" dep)
                         "non-existent symbol"
                         "high")
                        violations)))))

      ;; Contract: WordPress symbols must have valid hook types
      (when (and (hash-has-key? sym 'context)
                 (equal? (hash-ref sym 'context) "wordpress"))
        (unless (member symbol-type '("action" "filter" "hook"))
          (set! violations
                (cons (contract-violation
                       symbol-name
                       "wordpress-hook-type"
                       "action, filter, or hook"
                       symbol-type
                       "medium")
                      violations))))))

  violations)

;; Check type soundness
(define/contract (check-type-soundness symbols metadata)
  (-> (listof any/c) hash? (listof type-error?))

  (define errors '())

  (for ([sym symbols])
    (when (hash? sym)
      (define symbol-name (hash-ref sym 'name "unknown"))
      (define symbol-type (hash-ref sym 'type "unknown"))

      ;; Check parameter types if specified
      (when (and (hash-has-key? metadata symbol-name)
                 (hash-has-key? (hash-ref metadata symbol-name) 'parameters))
        (define params (hash-ref (hash-ref metadata symbol-name) 'parameters))

        (when (hash? params)
          (for ([(param-name param-value) (in-hash params)])
            ;; Type inference based on value
            (define inferred-type (infer-type param-value))
            (define expected-type (get-expected-param-type
                                   symbol-type param-name))

            (when (and expected-type
                       (not (type-compatible? inferred-type expected-type)))
              (set! errors
                    (cons (type-error
                           (format "~a.~a" symbol-name param-name)
                           expected-type
                           inferred-type
                           (format "Type mismatch for parameter ~a" param-name))
                          errors))))))))

  errors)

(define (infer-type value)
  (cond
    [(string? value) 'string]
    [(number? value) 'number]
    [(boolean? value) 'boolean]
    [(list? value) 'list]
    [(hash? value) 'hash]
    [else 'unknown]))

(define (get-expected-param-type symbol-type param-name)
  ;; Simplified type expectations - in real implementation,
  ;; this would be schema-driven
  (match (cons symbol-type param-name)
    [(cons "action" 'priority) 'number]
    [(cons "filter" 'priority) 'number]
    [(cons _ 'tags) 'list]
    [_ #f]))

(define (type-compatible? actual expected)
  (or (equal? actual expected)
      (equal? actual 'unknown)
      (equal? expected 'unknown)))

;; Validate invariants
(define/contract (validate-invariants symbols metadata)
  (-> (listof any/c) hash? (listof hash?))

  (define violations '())

  ;; Invariant 1: No symbol should have circular dependencies
  (define dep-graph (build-dep-graph symbols))
  (define cycles (find-cycles dep-graph))

  (for ([cycle cycles])
    (set! violations
          (cons (make-hash
                 (list (cons 'invariant "no-circular-dependencies")
                       (cons 'violation cycle)
                       (cons 'severity "high")))
                violations)))

  ;; Invariant 2: Symbol names must be unique
  (define name-counts (make-hash))
  (for ([sym symbols])
    (when (hash? sym)
      (define name (hash-ref sym 'name ""))
      (hash-update! name-counts name add1 0)))

  (for ([(name count) (in-hash name-counts)])
    (when (> count 1)
      (set! violations
            (cons (make-hash
                   (list (cons 'invariant "unique-symbol-names")
                         (cons 'violation (format "Symbol '~a' appears ~a times" name count))
                         (cons 'severity "high")))
                  violations))))

  ;; Invariant 3: All dependencies must be resolvable
  ;; (Already checked in contract verification, but worth double-checking)

  violations)

(define (build-dep-graph symbols)
  (make-hash
   (map (λ (sym)
          (if (hash? sym)
              (let ([name (hash-ref sym 'name "")]
                    [deps (if (hash-has-key? sym 'depends-on)
                              (let ([d (hash-ref sym 'depends-on)])
                                (if (list? d) d (list d)))
                              '())])
                (cons name deps))
              (cons "" '())))
        symbols)))

(define (find-cycles dep-graph)
  ;; Simple cycle detection using DFS
  (define cycles '())
  (define visited (mutable-set))

  (for ([(node _) (in-hash dep-graph)])
    (define path (mutable-set))
    (define cycle (detect-cycle node dep-graph visited path '()))
    (when cycle
      (set! cycles (cons cycle cycles))))

  (remove-duplicates cycles))

(define (detect-cycle node dep-graph visited path current-path)
  (cond
    [(set-member? path node)
     ;; Cycle detected
     (cons node current-path)]
    [(set-member? visited node)
     #f]
    [else
     (set-add! visited node)
     (set-add! path node)
     (define deps (hash-ref dep-graph node '()))
     (define result
       (for/or ([dep deps])
         (detect-cycle dep dep-graph visited path (cons node current-path))))
     (set-remove! path node)
     result]))

;; Compute semantic distance between two states
(define/contract (compute-semantic-distance state1 state2)
  (-> hash? hash? real?)

  (define props1 (extract-semantic-properties state1))
  (define props2 (extract-semantic-properties state2))

  ;; Jaccard distance: 1 - (intersection / union)
  (define intersection (set-intersect props1 props2))
  (define union (set-union props1 props2))

  (if (set-empty? union)
      0.0
      (- 1.0 (/ (set-count intersection) (set-count union)))))

;; Check semantic equivalence
(define/contract (semantic-equivalence? state1 state2 [threshold 0.1])
  (->* (hash? hash?) (real?) boolean?)

  (< (compute-semantic-distance state1 state2) threshold))

;; Helper: Compute integrity score
(define (compute-integrity-score contracts type-errors invariants)
  (define total-issues (+ (length contracts)
                          (length type-errors)
                          (length invariants)))

  ;; Score from 0.0 (many issues) to 1.0 (no issues)
  ;; Each issue reduces score by 0.1, minimum 0.0
  (max 0.0 (- 1.0 (* 0.1 total-issues))))

;; Helper: Generate recommendations
(define (generate-recommendations contracts type-errors invariants)
  (define recs '())

  (when (not (null? contracts))
    (set! recs (cons "Review and fix contract violations" recs)))

  (when (not (null? type-errors))
    (set! recs (cons "Add type annotations or fix type mismatches" recs)))

  (when (not (null? invariants))
    (set! recs (cons "Resolve invariant violations (cycles, duplicates)" recs)))

  (when (null? recs)
    (set! recs (cons "Semantic integrity looks good!" recs)))

  recs)
