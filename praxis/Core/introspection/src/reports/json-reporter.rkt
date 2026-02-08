#lang racket/base

;;; JSON Reporter
;;; Generates JSON output for machine consumption

(require racket/contract
         racket/hash
         json)

(provide display-json-report
         save-json-report
         results->json
         format-json-output)

;; Display JSON report to stdout
(define/contract (display-json-report results)
  (-> hash? void?)

  (write-json (results->json results))
  (newline))

;; Save JSON report to file
(define/contract (save-json-report results path)
  (-> hash? path-string? void?)

  (call-with-output-file path
    #:exists 'replace
    (λ (out)
      (write-json (results->json results) out)
      (newline out))))

;; Convert results to JSON-serializable format
(define/contract (results->json results)
  (-> hash? jsexpr?)

  (sanitize-for-json results))

;; Sanitize data structure for JSON serialization
(define (sanitize-for-json data)
  (cond
    [(hash? data)
     (make-hash
      (for/list ([(k v) (in-hash data)])
        (cons k (sanitize-for-json v))))]
    [(list? data)
     (map sanitize-for-json data)]
    [(symbol? data)
     (symbol->string data)]
    [(boolean? data) data]
    [(number? data) data]
    [(string? data) data]
    [(void? data) null]
    [else (format "~a" data)]))

;; Format JSON output with options
(define/contract (format-json-output results #:pretty? [pretty? #t])
  (->* (hash?) (#:pretty? boolean?) string?)

  (if pretty?
      (jsexpr->string (results->json results))
      (with-output-to-string
        (λ () (write-json (results->json results))))))
