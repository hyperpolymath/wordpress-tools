#lang racket/base

;;; Type Checker
;;; Symbolic type checking and inference

(require racket/contract
         racket/match
         racket/hash)

(provide infer-type
         check-type
         type-compatible?
         type-errors
         validate-types)

;; Type inference
(define/contract (infer-type value)
  (-> any/c symbol?)

  (cond
    [(string? value) 'string]
    [(number? value) 'number]
    [(boolean? value) 'boolean]
    [(list? value) 'list]
    [(hash? value) 'hash]
    [(symbol? value) 'symbol]
    [else 'unknown]))

;; Type checking
(define/contract (check-type value expected-type)
  (-> any/c symbol? boolean?)

  (type-compatible? (infer-type value) expected-type))

;; Type compatibility
(define/contract (type-compatible? actual expected)
  (-> symbol? symbol? boolean?)

  (or (equal? actual expected)
      (equal? expected 'any)
      (equal? actual 'unknown)))

;; Find type errors
(define/contract (type-errors data expected-types)
  (-> hash? hash? (listof hash?))

  (define errors '())

  (for ([(k expected) (in-hash expected-types)])
    (when (hash-has-key? data k)
      (define actual (infer-type (hash-ref data k)))
      (unless (type-compatible? actual expected)
        (set! errors
              (cons (make-hash
                     (list (cons 'key k)
                           (cons 'expected expected)
                           (cons 'actual actual)))
                    errors)))))

  errors)

;; Validate all types
(define/contract (validate-types data type-schema)
  (-> hash? hash? boolean?)

  (null? (type-errors data type-schema)))
