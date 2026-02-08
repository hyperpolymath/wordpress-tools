#lang racket/base

(require rackunit
         "../src/symbolic-inspector.rkt")

(test-case "Extract symbols from manifest"
  (define manifest
    (make-hash
     (list (cons 'symbols
                 (list (make-hash '((name . "test-symbol")
                                    (type . "action")
                                    (context . "wordpress"))))))))

  (define symbols (extract-symbols manifest))

  (check-equal? (length symbols) 1)
  (check-equal? (symbol-node-name (car symbols)) "test-symbol"))

(test-case "Infer symbol type"
  (define sym (symbol-node "test" "action" "wordpress" (hash) '()))

  (check-equal? (infer-symbol-type sym) 'action))

(test-case "Validate symbol structure"
  (define valid-sym
    (symbol-node "valid" "action" "wordpress"
                 (make-hash '((dispatch . "rust_injector"))) '()))

  (define invalid-sym
    (symbol-node "invalid" "action" "wordpress" (hash) '()))

  (check-equal? (validate-symbol-structure valid-sym) '())
  (check-true (not (null? (validate-symbol-structure invalid-sym)))))

(test-case "Calculate tree depth"
  (define symbols
    (list (symbol-node "A" "action" "global" (make-hash '((depends-on . ()))) '())
          (symbol-node "B" "action" "global" (make-hash '((depends-on . ("A")))) '())
          (symbol-node "C" "action" "global" (make-hash '((depends-on . ("B")))) '())))

  (check-equal? (symbol-tree-depth symbols) 3))
