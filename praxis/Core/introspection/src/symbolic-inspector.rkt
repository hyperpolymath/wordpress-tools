#lang racket/base

;;; Symbolic Inspector
;;; Inspects symbolic state, performs recursive descent through symbol tree,
;;; extracts semantic metadata, and performs type inference and validation

(require racket/contract
         racket/match
         racket/list
         racket/hash
         racket/set
         json)

(provide inspect-symbolic-state
         extract-symbol-metadata
         infer-symbol-type
         validate-symbol-structure
         detect-symbolic-patterns
         find-symbols-by-predicate
         symbol-tree-depth
         symbol-tree-stats)

;; Data structures for symbolic state
(struct symbol-node
  (name type context metadata children)
  #:transparent)

(struct inspection-result
  (symbols
   metadata
   type-map
   patterns
   warnings
   statistics)
  #:transparent)

;; Main inspection function
(define/contract (inspect-symbolic-state manifest-data)
  (-> jsexpr? hash?)

  (define symbols (extract-symbols manifest-data))
  (define metadata (extract-all-metadata symbols))
  (define type-map (build-type-map symbols))
  (define patterns (detect-all-patterns symbols))
  (define warnings (validate-all-symbols symbols))
  (define stats (compute-statistics symbols))

  (make-hash
   (list (cons 'symbols symbols)
         (cons 'metadata metadata)
         (cons 'type-map type-map)
         (cons 'patterns patterns)
         (cons 'warnings warnings)
         (cons 'statistics stats))))

;; Extract symbols from manifest
(define/contract (extract-symbols manifest)
  (-> jsexpr? (listof symbol-node?))

  (match manifest
    [(hash-table ['symbols symbol-list] _ ...)
     (map parse-symbol symbol-list)]
    [_ '()]))

(define (parse-symbol sym-data)
  (match sym-data
    [(hash-table
      ['name name]
      ['type type]
      rest ...)
     (symbol-node
      name
      type
      (hash-ref sym-data 'context "global")
      (extract-symbol-metadata sym-data)
      (hash-ref sym-data 'children '()))]
    [_ (symbol-node "unknown" "unknown" "global" (hash) '())]))

;; Extract metadata from a symbol
(define/contract (extract-symbol-metadata sym-data)
  (-> jsexpr? hash?)

  (define metadata (make-hash))

  ;; Extract common metadata fields
  (for ([key '(dispatch parameters tags priority depends-on)])
    (when (hash-has-key? sym-data key)
      (hash-set! metadata key (hash-ref sym-data key))))

  ;; Extract custom metadata
  (when (hash-has-key? sym-data 'metadata)
    (define custom (hash-ref sym-data 'metadata))
    (when (hash? custom)
      (for ([(k v) (in-hash custom)])
        (hash-set! metadata k v))))

  metadata)

;; Extract metadata from all symbols
(define (extract-all-metadata symbols)
  (make-hash
   (map (λ (sym)
          (cons (symbol-node-name sym)
                (symbol-node-metadata sym)))
        symbols)))

;; Infer type of a symbol
(define/contract (infer-symbol-type sym)
  (-> symbol-node? symbol?)

  (define explicit-type (symbol-node-type sym))
  (define context (symbol-node-context sym))
  (define metadata (symbol-node-metadata sym))

  (cond
    [(equal? explicit-type "action") 'action]
    [(equal? explicit-type "filter") 'filter]
    [(equal? explicit-type "hook") 'hook]
    [(equal? explicit-type "query") 'query]
    [(equal? explicit-type "mutation") 'mutation]
    [(hash-has-key? metadata 'dispatch)
     (match (hash-ref metadata 'dispatch)
       ["rust_injector" 'injector]
       ["powershell" 'symbolic-operation]
       ["elixir" 'orchestration]
       [_ 'custom])]
    [(equal? context "wordpress") 'wordpress-integration]
    [else 'generic]))

;; Build type map for all symbols
(define (build-type-map symbols)
  (make-hash
   (map (λ (sym)
          (cons (symbol-node-name sym)
                (infer-symbol-type sym)))
        symbols)))

;; Validate symbol structure
(define/contract (validate-symbol-structure sym)
  (-> symbol-node? (listof string?))

  (define warnings '())

  ;; Check for required fields
  (when (equal? (symbol-node-name sym) "unknown")
    (set! warnings (cons "Symbol missing 'name' field" warnings)))

  (when (equal? (symbol-node-type sym) "unknown")
    (set! warnings (cons "Symbol missing 'type' field" warnings)))

  ;; Check metadata completeness
  (define meta (symbol-node-metadata sym))
  (when (and (equal? (symbol-node-type sym) "action")
             (not (hash-has-key? meta 'dispatch)))
    (set! warnings
          (cons "Action symbol missing 'dispatch' metadata" warnings)))

  ;; Check for circular dependencies
  (when (hash-has-key? meta 'depends-on)
    (define deps (hash-ref meta 'depends-on))
    (when (and (list? deps)
               (member (symbol-node-name sym) deps))
      (set! warnings
            (cons "Symbol has circular self-dependency" warnings))))

  warnings)

;; Validate all symbols
(define (validate-all-symbols symbols)
  (apply append
         (map (λ (sym)
                (map (λ (warning)
                       (format "~a: ~a"
                               (symbol-node-name sym)
                               warning))
                     (validate-symbol-structure sym)))
              symbols)))

;; Pattern detection
(define/contract (detect-symbolic-patterns symbols)
  (-> (listof symbol-node?) (listof hash?))

  (define patterns '())

  ;; Pattern 1: Chain pattern (A → B → C)
  (define chains (detect-chain-pattern symbols))
  (when (not (null? chains))
    (set! patterns (cons (make-hash '((type . "chain") (instances . chains)))
                         patterns)))

  ;; Pattern 2: Fan-out pattern (A → B, C, D)
  (define fan-outs (detect-fanout-pattern symbols))
  (when (not (null? fan-outs))
    (set! patterns (cons (make-hash '((type . "fan-out") (instances . fan-outs)))
                         patterns)))

  ;; Pattern 3: Aggregation pattern (A, B, C → D)
  (define aggregations (detect-aggregation-pattern symbols))
  (when (not (null? aggregations))
    (set! patterns (cons (make-hash '((type . "aggregation") (instances . aggregations)))
                         patterns)))

  patterns)

(define (detect-chain-pattern symbols)
  ;; Detect linear dependency chains
  (define dep-map (build-dependency-map symbols))
  (define chains '())

  (for ([sym symbols])
    (define name (symbol-node-name sym))
    (define chain (build-chain name dep-map (set)))
    (when (>= (length chain) 3)
      (set! chains (cons chain chains))))

  chains)

(define (build-chain name dep-map visited)
  (if (set-member? visited name)
      '()
      (let ([deps (hash-ref dep-map name '())])
        (if (= (length deps) 1)
            (cons name (build-chain (car deps) dep-map (set-add visited name)))
            (list name)))))

(define (detect-fanout-pattern symbols)
  ;; Detect symbols with multiple dependencies (fan-out)
  (define dep-map (build-dependency-map symbols))
  (filter (λ (entry)
            (> (length (cdr entry)) 2))
          (hash->list dep-map)))

(define (detect-aggregation-pattern symbols)
  ;; Detect symbols that are depended on by multiple others
  (define reverse-deps (make-hash))

  (for ([sym symbols])
    (define name (symbol-node-name sym))
    (define meta (symbol-node-metadata sym))
    (when (hash-has-key? meta 'depends-on)
      (define deps (hash-ref meta 'depends-on))
      (when (list? deps)
        (for ([dep deps])
          (hash-update! reverse-deps dep
                        (λ (current) (cons name current))
                        '())))))

  (filter (λ (entry) (> (length (cdr entry)) 2))
          (hash->list reverse-deps)))

(define (build-dependency-map symbols)
  (make-hash
   (map (λ (sym)
          (define name (symbol-node-name sym))
          (define meta (symbol-node-metadata sym))
          (define deps (if (hash-has-key? meta 'depends-on)
                           (hash-ref meta 'depends-on)
                           '()))
          (cons name (if (list? deps) deps (list deps))))
        symbols)))

(define (detect-all-patterns symbols)
  (detect-symbolic-patterns symbols))

;; Find symbols matching a predicate
(define/contract (find-symbols-by-predicate symbols predicate)
  (-> (listof symbol-node?) (-> symbol-node? boolean?) (listof symbol-node?))
  (filter predicate symbols))

;; Calculate tree depth
(define/contract (symbol-tree-depth symbols)
  (-> (listof symbol-node?) exact-nonnegative-integer?)

  (define dep-map (build-dependency-map symbols))

  (define (max-depth name visited)
    (if (set-member? visited name)
        0
        (let ([deps (hash-ref dep-map name '())])
          (if (null? deps)
              1
              (+ 1 (apply max (map (λ (dep)
                                     (max-depth dep (set-add visited name)))
                                   deps)))))))

  (if (null? symbols)
      0
      (apply max (map (λ (sym)
                        (max-depth (symbol-node-name sym) (set)))
                      symbols))))

;; Compute statistics
(define (compute-statistics symbols)
  (make-hash
   (list (cons 'total-symbols (length symbols))
         (cons 'max-depth (symbol-tree-depth symbols))
         (cons 'symbol-types (count-symbol-types symbols))
         (cons 'contexts (count-contexts symbols))
         (cons 'avg-dependencies (average-dependencies symbols)))))

(define (count-symbol-types symbols)
  (define type-counts (make-hash))
  (for ([sym symbols])
    (define type (symbol-node-type sym))
    (hash-update! type-counts type add1 0))
  type-counts)

(define (count-contexts symbols)
  (define context-counts (make-hash))
  (for ([sym symbols])
    (define context (symbol-node-context sym))
    (hash-update! context-counts context add1 0))
  context-counts)

(define (average-dependencies symbols)
  (if (null? symbols)
      0
      (let ([total-deps
             (apply + (map (λ (sym)
                             (define meta (symbol-node-metadata sym))
                             (if (hash-has-key? meta 'depends-on)
                                 (let ([deps (hash-ref meta 'depends-on)])
                                   (if (list? deps)
                                       (length deps)
                                       1))
                                 0))
                           symbols))])
        (/ total-deps (length symbols)))))
