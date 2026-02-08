#lang racket/base

;;; Tree Printer
;;; Pretty-prints symbolic trees and hierarchical data structures

(require racket/contract
         racket/match
         racket/list
         racket/string
         racket/hash
         racket/format)

(provide display-tree
         tree->string
         print-symbol-tree
         print-dependency-tree
         format-tree-node
         tree-stats)

;; Display tree structure
(define/contract (display-tree data [indent 0])
  (->* (any/c) (exact-nonnegative-integer?) void?)

  (display (tree->string data indent)))

;; Convert tree to string representation
(define/contract (tree->string data [indent 0])
  (->* (any/c) (exact-nonnegative-integer?) string?)

  (define prefix (make-string indent #\space))

  (cond
    [(hash? data)
     (string-append
      prefix "{\n"
      (string-join
       (for/list ([(k v) (in-hash data)])
         (format "~a  ~a: ~a"
                 prefix
                 k
                 (string-trim (tree->string v (+ indent 2)))))
       "\n")
      "\n" prefix "}")]

    [(list? data)
     (if (null? data)
         "[]"
         (string-append
          prefix "[\n"
          (string-join
           (for/list ([item data])
             (tree->string item (+ indent 2)))
           "\n")
          "\n" prefix "]"))]

    [(string? data)
     (format "~a\"~a\"" prefix data)]

    [(number? data)
     (format "~a~a" prefix data)]

    [(boolean? data)
     (format "~a~a" prefix data)]

    [else
     (format "~a~a" prefix data)]))

;; Print symbol tree
(define/contract (print-symbol-tree symbols)
  (-> (listof any/c) void?)

  (displayln "=== Symbol Tree ===\n")

  (for ([sym symbols])
    (when (hash? sym)
      (define name (hash-ref sym 'name "unknown"))
      (define type (hash-ref sym 'type "unknown"))
      (define context (hash-ref sym 'context "global"))

      (displayln (format "📦 ~a (~a) [~a]" name type context))

      (when (hash-has-key? sym 'depends-on)
        (define deps (hash-ref sym 'depends-on))
        (define dep-list (if (list? deps) deps (list deps)))

        (for ([dep dep-list])
          (displayln (format "   └─→ ~a" dep))))

      (displayln ""))))

;; Print dependency tree
(define/contract (print-dependency-tree symbols root-name)
  (-> (listof any/c) string? void?)

  (define dep-map (build-dep-map symbols))

  (define (print-node name level visited)
    (unless (set-member? visited name)
      (define indent (make-string (* 2 level) #\space))
      (displayln (format "~a├─ ~a" indent name))

      (define deps (hash-ref dep-map name '()))
      (for ([dep deps])
        (print-node dep (+ level 1) (set-add visited name)))))

  (displayln (format "=== Dependency Tree (root: ~a) ===\n" root-name))
  (print-node root-name 0 (set)))

(define (build-dep-map symbols)
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

;; Format tree node for display
(define/contract (format-tree-node node [depth 0])
  (->* (any/c) (exact-nonnegative-integer?) string?)

  (define indent (make-string (* 2 depth) #\space))

  (cond
    [(hash? node)
     (format "~a{hash: ~a keys}" indent (hash-count node))]
    [(list? node)
     (format "~a[list: ~a items]" indent (length node))]
    [(string? node)
     (format "~a\"~a\"" indent node)]
    [else
     (format "~a~a" indent node)]))

;; Compute tree statistics
(define/contract (tree-stats data)
  (-> any/c hash?)

  (define (count-nodes d)
    (cond
      [(hash? d) (+ 1 (apply + (map count-nodes (hash-values d))))]
      [(list? d) (+ 1 (apply + (map count-nodes d)))]
      [else 1]))

  (define (max-depth d level)
    (cond
      [(hash? d)
       (if (hash-empty? d)
           level
           (apply max (map (λ (v) (max-depth v (+ level 1)))
                           (hash-values d))))]
      [(list? d)
       (if (null? d)
           level
           (apply max (map (λ (v) (max-depth v (+ level 1))) d)))]
      [else level]))

  (make-hash
   (list (cons 'total-nodes (count-nodes data))
         (cons 'max-depth (max-depth data 0)))))
