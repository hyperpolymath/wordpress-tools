#lang racket/base

;;; Pattern Matcher
;;; Advanced pattern matching on symbolic structures

(require racket/contract
         racket/match
         racket/list)

(provide match-pattern
         find-all-patterns
         pattern-matches?
         extract-pattern-instances
         common-patterns)

;; Pattern matching function
(define/contract (match-pattern data pattern)
  (-> any/c any/c (or/c hash? #f))

  (match* (data pattern)
    [(_ '_) (make-hash (list (cons 'matched data)))]
    [((? symbol? s) (? symbol? p))
     (if (equal? s p)
         (make-hash (list (cons 'matched s)))
         #f)]
    [((? hash? h) (? hash? p))
     (if (andmap (λ (k) (hash-has-key? h k)) (hash-keys p))
         (make-hash (list (cons 'matched h)))
         #f)]
    [(_ _) #f]))

;; Find all pattern instances
(define/contract (find-all-patterns data pattern-list)
  (-> any/c (listof any/c) (listof hash?))

  (filter values
          (map (λ (p) (match-pattern data p)) pattern-list)))

;; Check if data matches pattern
(define/contract (pattern-matches? data pattern)
  (-> any/c any/c boolean?)

  (if (match-pattern data pattern) #t #f))

;; Extract pattern instances from data
(define/contract (extract-pattern-instances data patterns)
  (-> any/c (listof any/c) (listof any/c))

  (filter (λ (item) (ormap (λ (p) (pattern-matches? item p)) patterns))
          (if (list? data) data (list data))))

;; Common pattern definitions
(define common-patterns
  (list
   (make-hash '((type . "action")))
   (make-hash '((type . "filter")))
   (make-hash '((context . "wordpress")))))
