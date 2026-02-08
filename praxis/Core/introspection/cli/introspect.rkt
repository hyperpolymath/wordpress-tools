#lang racket/base

;;; WP Praxis Introspection CLI
;;; Command-line interface for introspection system

(require racket/cmdline
         racket/match
         racket/contract
         "../main.rkt"
         "../src/reports/json-reporter.rkt"
         "../src/reports/html-reporter.rkt"
         "../src/viz/tree-printer.rkt")

;; CLI commands
(define current-command 'inspect)
(define manifest-path #f)
(define output-path #f)
(define output-format "text")
(define verbose? #f)

;; Main CLI entry point
(define (main)
  (command-line
   #:program "wp-introspect"
   #:once-each
   [("-m" "--manifest") path "Path to manifest file (required)"
    (set! manifest-path path)]
   [("-o" "--output") path "Output file path"
    (set! output-path path)]
   [("-f" "--format") fmt "Output format: text, json, html (default: text)"
    (set! output-format fmt)]
   [("-v" "--verbose") "Verbose output"
    (set! verbose? #t)]
   #:args command-args

   ;; Validate inputs
   (unless manifest-path
     (error "Manifest path required (-m or --manifest)"))

   ;; Determine command
   (when (not (null? command-args))
     (set! current-command (string->symbol (car command-args))))

   ;; Execute command
   (match current-command
     ['inspect (run-inspect)]
     ['trace (run-trace)]
     ['analyze (run-analyze)]
     ['report (run-report)]
     ['validate (run-validate)]
     [_ (error (format "Unknown command: ~a" current-command))])))

;; Commands

(define (run-inspect)
  (when verbose?
    (displayln "Running introspection..."))

  (define results (introspect-workflow manifest-path
                                       #:trace? #t
                                       #:analyze? #t
                                       #:feedback? #t))

  (output-results results))

(define (run-trace)
  (when verbose?
    (displayln "Tracing execution..."))

  (define trace (trace-execution manifest-path))

  (output-results (make-hash (list (cons 'trace trace)))))

(define (run-analyze)
  (when verbose?
    (displayln "Analyzing semantics..."))

  (define state (introspect-state
                 (read-toml-file manifest-path)))

  (define analysis (analyze-semantics state))

  (output-results (make-hash (list (cons 'analysis analysis)))))

(define (run-report)
  (when verbose?
    (displayln "Generating report..."))

  (run-inspect))

(define (run-validate)
  (when verbose?
    (displayln "Validating manifest..."))

  (define state (introspect-state
                 (read-toml-file manifest-path)))

  (define warnings (hash-ref state 'warnings '()))

  (if (null? warnings)
      (displayln "✓ Manifest is valid")
      (begin
        (displayln "✗ Validation warnings:")
        (for ([w warnings])
          (displayln (format "  - ~a" w))))))

;; Output handlers

(define (output-results results)
  (match output-format
    ["json" (output-json results)]
    ["html" (output-html results)]
    [_ (output-text results)]))

(define (output-json results)
  (if output-path
      (save-json-report results output-path)
      (display-json-report results)))

(define (output-html results)
  (if output-path
      (save-html-report results output-path)
      (displayln (generate-html-report results))))

(define (output-text results)
  (if output-path
      (with-output-to-file output-path
        #:exists 'replace
        (λ () (display-tree results)))
      (display-tree results)))

;; Run main
(module+ main
  (main))
