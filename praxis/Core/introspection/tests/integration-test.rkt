#lang racket/base

(require rackunit
         "../main.rkt")

(test-case "End-to-end introspection workflow"
  ;; Note: This test would require a sample manifest file
  ;; For now, we test that functions are properly exported

  (check-true (procedure? introspect-workflow))
  (check-true (procedure? introspect-state))
  (check-true (procedure? trace-execution))
  (check-true (procedure? analyze-semantics))
  (check-true (procedure? generate-feedback))
  (check-true (procedure? run-meta-evaluation)))
