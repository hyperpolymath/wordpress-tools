#lang racket/base

;;; PowerShell Bridge
;;; Allows PowerShell to call introspection system

(require racket/cmdline
         racket/port
         "../main.rkt"
         "../src/reports/json-reporter.rkt")

;; Parse command-line arguments
(define manifest-path #f)
(define trace? #t)
(define analyze? #t)
(define feedback? #t)

(command-line
 #:program "powershell-bridge"
 #:once-each
 [("-m" "--manifest") path "Manifest path"
  (set! manifest-path path)]
 [("--no-trace") "Disable tracing"
  (set! trace? #f)]
 [("--no-analyze") "Disable analysis"
  (set! analyze? #f)]
 [("--no-feedback") "Disable feedback"
  (set! feedback? #f)])

(unless manifest-path
  (error "Manifest path required"))

;; Run introspection
(define results
  (introspect-workflow manifest-path
                       #:trace? trace?
                       #:analyze? analyze?
                       #:feedback? feedback?))

;; Output JSON to stdout for PowerShell to parse
(display-json-report results)

;; Exit with code based on critical issues
(define feedback-data (hash-ref results 'feedback #f))
(when feedback-data
  (define summary (hash-ref feedback-data 'summary (hash)))
  (define critical-count (hash-ref summary 'critical 0))
  (when (> critical-count 0)
    (exit 1)))

(exit 0)
