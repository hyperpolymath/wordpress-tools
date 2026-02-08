#lang racket/base

(require rackunit
         "../src/semantic-analyzer.rkt")

(test-case "Type compatibility"
  (check-true (type-compatible? 'string 'string))
  (check-true (type-compatible? 'unknown 'string))
  (check-true (type-compatible? 'string 'unknown))
  (check-false (type-compatible? 'string 'number)))

(test-case "Compute semantic distance"
  (define state1 (make-hash '((a . 1) (b . 2))))
  (define state2 (make-hash '((a . 1) (c . 3))))

  (define distance (compute-semantic-distance state1 state2))

  (check-true (>= distance 0.0))
  (check-true (<= distance 1.0)))

(test-case "Semantic equivalence"
  (define state1 (make-hash '((a . 1) (b . 2))))
  (define state2 (make-hash '((a . 1) (b . 2))))

  (check-true (semantic-equivalence? state1 state2 0.1)))
