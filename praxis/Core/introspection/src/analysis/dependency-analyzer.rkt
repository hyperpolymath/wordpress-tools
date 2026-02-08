#lang racket/base

;;; Dependency Analyzer
;;; Analyzes dependency graphs and relationships

(require racket/contract
         racket/match
         racket/list
         racket/hash
         racket/set)

(provide analyze-dependencies
         find-dependency-cycles
         topological-sort
         dependency-depth
         find-roots
         find-leaves)

;; Analyze dependency structure
(define/contract (analyze-dependencies symbols)
  (-> (listof any/c) hash?)

  (define dep-graph (build-dependency-graph symbols))
  (define cycles (find-dependency-cycles dep-graph))
  (define depth (dependency-depth dep-graph))
  (define roots (find-roots dep-graph))
  (define leaves (find-leaves dep-graph))

  (make-hash
   (list (cons 'total-nodes (hash-count dep-graph))
         (cons 'cycles cycles)
         (cons 'max-depth depth)
         (cons 'roots roots)
         (cons 'leaves leaves))))

;; Build dependency graph
(define (build-dependency-graph symbols)
  (make-hash
   (for/list ([sym symbols])
     (if (hash? sym)
         (let ([name (hash-ref sym 'name "")]
               [deps (if (hash-has-key? sym 'depends-on)
                         (let ([d (hash-ref sym 'depends-on)])
                           (if (list? d) d (list d)))
                         '())])
           (cons name deps))
         (cons "" '())))))

;; Find dependency cycles
(define/contract (find-dependency-cycles dep-graph)
  (-> hash? (listof (listof any/c)))

  (define cycles '())
  (define visited (mutable-set))

  (for ([(node _) (in-hash dep-graph)])
    (define cycle (detect-cycle node dep-graph visited (mutable-set) '()))
    (when cycle
      (set! cycles (cons cycle cycles))))

  (remove-duplicates cycles))

(define (detect-cycle node graph visited path current-path)
  (cond
    [(set-member? path node) (cons node current-path)]
    [(set-member? visited node) #f]
    [else
     (set-add! visited node)
     (set-add! path node)
     (define deps (hash-ref graph node '()))
     (define result
       (for/or ([dep deps])
         (detect-cycle dep graph visited path (cons node current-path))))
     (set-remove! path node)
     result]))

;; Topological sort
(define/contract (topological-sort dep-graph)
  (-> hash? (or/c (listof any/c) #f))

  (define visited (mutable-set))
  (define stack '())

  (define (visit node)
    (unless (set-member? visited node)
      (set-add! visited node)
      (for ([dep (hash-ref dep-graph node '())])
        (visit dep))
      (set! stack (cons node stack))))

  (with-handlers ([exn:fail? (λ (e) #f)])
    (for ([(node _) (in-hash dep-graph)])
      (visit node))
    stack))

;; Calculate dependency depth
(define/contract (dependency-depth dep-graph)
  (-> hash? exact-nonnegative-integer?)

  (define (max-depth node visited)
    (if (set-member? visited node)
        0
        (let ([deps (hash-ref dep-graph node '())])
          (if (null? deps)
              1
              (+ 1 (apply max (map (λ (d) (max-depth d (set-add visited node)))
                                   deps)))))))

  (if (hash-empty? dep-graph)
      0
      (apply max (map (λ (n) (max-depth n (set))) (hash-keys dep-graph)))))

;; Find root nodes (no dependencies)
(define/contract (find-roots dep-graph)
  (-> hash? (listof any/c))

  (filter (λ (node)
            (define deps (hash-ref dep-graph node '()))
            (null? deps))
          (hash-keys dep-graph)))

;; Find leaf nodes (not depended upon)
(define/contract (find-leaves dep-graph)
  (-> hash? (listof any/c))

  (define all-nodes (list->set (hash-keys dep-graph)))
  (define referenced
    (apply set-union (set)
           (map list->set (filter list? (hash-values dep-graph)))))

  (set->list (set-subtract all-nodes referenced)))
