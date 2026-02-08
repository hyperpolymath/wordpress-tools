#lang racket/base

(require rackunit
         "../src/recursive-tracer.rkt")

(test-case "Build execution DAG"
  (define trace-data '())
  (define dag (build-execution-dag trace-data))

  (check-true (directed-graph? dag)))

(test-case "Measure semantic preservation"
  (define trace-data
    (list (execution-step 'manifest 'parse '() '(symbols) (hash) 0 5.0 0.1)
          (execution-step 'parser 'validate '(symbols) '(validated) (hash) 5 10.0 0.2)))

  (define score (measure-semantic-preservation trace-data))

  (check-true (<= 0.0 score 1.0)))

(test-case "Execution trace stats"
  (define trace-data
    (list (execution-step 'manifest 'parse '() '(symbols) (hash) 0 5.0 0.0)
          (execution-step 'parser 'validate '(symbols) '(validated) (hash) 5 10.0 0.0)))

  (define stats (execution-trace-stats trace-data))

  (check-equal? (hash-ref stats 'total-steps) 2)
  (check-equal? (hash-ref stats 'total-duration-ms) 15.0))
