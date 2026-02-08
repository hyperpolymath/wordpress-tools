#lang racket/base

;;; WP Praxis Introspection System
;;; Main entry point module

(require racket/contract)

;; Core introspection modules
(require "src/symbolic-inspector.rkt"
         "src/recursive-tracer.rkt"
         "src/semantic-analyzer.rkt"
         "src/feedback-generator.rkt"
         "src/meta-evaluator.rkt")

;; I/O modules
(require "src/io/json-reader.rkt"
         "src/io/toml-reader.rkt"
         "src/io/database-connector.rkt"
         "src/io/log-parser.rkt")

;; Visualization and reporting
(require "src/viz/graph-generator.rkt"
         "src/viz/tree-printer.rkt"
         "src/reports/html-reporter.rkt"
         "src/reports/json-reporter.rkt")

;; Analysis algorithms
(require "src/analysis/pattern-matcher.rkt"
         "src/analysis/type-checker.rkt"
         "src/analysis/dependency-analyzer.rkt"
         "src/analysis/performance-profiler.rkt")

;; Configuration
(require "config/introspection-config.rkt")

;; Provide all public APIs
(provide (all-from-out "src/symbolic-inspector.rkt")
         (all-from-out "src/recursive-tracer.rkt")
         (all-from-out "src/semantic-analyzer.rkt")
         (all-from-out "src/feedback-generator.rkt")
         (all-from-out "src/meta-evaluator.rkt")
         (all-from-out "src/io/json-reader.rkt")
         (all-from-out "src/io/toml-reader.rkt")
         (all-from-out "src/io/database-connector.rkt")
         (all-from-out "src/io/log-parser.rkt")
         (all-from-out "src/viz/graph-generator.rkt")
         (all-from-out "src/viz/tree-printer.rkt")
         (all-from-out "src/reports/html-reporter.rkt")
         (all-from-out "src/reports/json-reporter.rkt")
         (all-from-out "src/analysis/pattern-matcher.rkt")
         (all-from-out "src/analysis/type-checker.rkt")
         (all-from-out "src/analysis/dependency-analyzer.rkt")
         (all-from-out "src/analysis/performance-profiler.rkt")
         (all-from-out "config/introspection-config.rkt"))

;; Main introspection workflow
(provide introspect-workflow
         introspect-state
         trace-execution
         analyze-semantics
         generate-feedback
         run-meta-evaluation)

(define/contract (introspect-workflow manifest-path
                                      #:trace? [trace? #t]
                                      #:analyze? [analyze? #t]
                                      #:feedback? [feedback? #t])
  (->* (path-string?)
       (#:trace? boolean?
        #:analyze? boolean?
        #:feedback? boolean?)
       hash?)

  (define config (load-config))
  (define manifest (read-toml-file manifest-path))
  (define state (inspect-symbolic-state manifest))

  (define results (make-hash))
  (hash-set! results 'state state)

  (when trace?
    (define trace (trace-symbolic-execution manifest))
    (hash-set! results 'trace trace))

  (when analyze?
    (define analysis (analyze-semantic-integrity state))
    (hash-set! results 'analysis analysis))

  (when feedback?
    (define feedback (generate-feedback-report
                      state
                      (hash-ref results 'trace #f)
                      (hash-ref results 'analysis #f)))
    (hash-set! results 'feedback feedback))

  results)

(define/contract (introspect-state state-data)
  (-> jsexpr? hash?)
  (inspect-symbolic-state state-data))

(define/contract (trace-execution manifest-path)
  (-> path-string? hash?)
  (trace-symbolic-execution manifest-path))

(define/contract (analyze-semantics state)
  (-> hash? hash?)
  (analyze-semantic-integrity state))

(define/contract (generate-feedback state trace analysis)
  (-> hash? (or/c hash? #f) (or/c hash? #f) hash?)
  (generate-feedback-report state trace analysis))

(define/contract (run-meta-evaluation introspection-results)
  (-> hash? hash?)
  (meta-evaluate introspection-results))

(module+ main
  (require racket/cmdline)

  (define manifest-path #f)
  (define output-format "text")
  (define trace? #t)
  (define analyze? #t)
  (define feedback? #t)

  (command-line
   #:program "wp-praxis-introspection"
   #:once-each
   [("-m" "--manifest") path "Path to manifest file"
    (set! manifest-path path)]
   [("-f" "--format") fmt "Output format (text, json, html)"
    (set! output-format fmt)]
   [("--no-trace") "Skip execution tracing"
    (set! trace? #f)]
   [("--no-analyze") "Skip semantic analysis"
    (set! analyze? #f)]
   [("--no-feedback") "Skip feedback generation"
    (set! feedback? #f)])

  (unless manifest-path
    (error "Manifest path required (-m)"))

  (define results (introspect-workflow manifest-path
                                       #:trace? trace?
                                       #:analyze? analyze?
                                       #:feedback? feedback?))

  (match output-format
    ["json" (display-json-report results)]
    ["html" (generate-html-report results)]
    [_ (display-tree results)]))
