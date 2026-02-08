#lang racket/base

;;; Performance Profiler
;;; Detects performance bottlenecks and analyzes execution metrics

(require racket/contract
         racket/match
         racket/list
         racket/hash)

(provide profile-execution
         find-bottlenecks
         analyze-layer-performance
         calculate-percentiles
         identify-slow-operations)

;; Profile execution trace
(define/contract (profile-execution trace-data)
  (-> hash? hash?)

  (define stats (hash-ref trace-data 'statistics (hash)))
  (define bottlenecks (hash-ref trace-data 'bottlenecks '()))

  (make-hash
   (list (cons 'total-duration (hash-ref stats 'total-duration-ms 0))
         (cons 'avg-step-duration (hash-ref stats 'avg-step-duration-ms 0))
         (cons 'bottleneck-count (length bottlenecks))
         (cons 'layer-performance (analyze-layer-performance trace-data)))))

;; Find performance bottlenecks
(define/contract (find-bottlenecks durations threshold-percentile)
  (-> (listof number?) real? (listof number?))

  (define threshold (calculate-percentile durations threshold-percentile))

  (filter (λ (d) (> d threshold)) durations))

;; Analyze layer performance
(define/contract (analyze-layer-performance trace-data)
  (-> hash? hash?)

  (if (hash-has-key? trace-data 'statistics)
      (let ([stats (hash-ref trace-data 'statistics)])
        (if (hash-has-key? stats 'layer-durations)
            (hash-ref stats 'layer-durations)
            (hash)))
      (hash)))

;; Calculate percentile
(define/contract (calculate-percentile values percentile)
  (-> (listof number?) real? number?)

  (if (null? values)
      0
      (let* ([sorted (sort values <)]
             [idx (inexact->exact (floor (* (/ percentile 100) (length sorted))))])
        (list-ref sorted (min idx (- (length sorted) 1))))))

;; Calculate multiple percentiles
(define/contract (calculate-percentiles values percentiles)
  (-> (listof number?) (listof real?) hash?)

  (make-hash
   (map (λ (p) (cons p (calculate-percentile values p)))
        percentiles)))

;; Identify slow operations
(define/contract (identify-slow-operations operations threshold)
  (-> (listof hash?) number? (listof hash?))

  (filter (λ (op)
            (> (hash-ref op 'duration-ms 0) threshold))
          operations))
