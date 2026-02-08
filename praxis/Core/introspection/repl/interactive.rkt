#lang racket/base

;;; Interactive Introspection REPL
;;; Exploratory analysis interface

(require racket/contract
         racket/match
         racket/list
         readline
         "../main.rkt"
         "../src/viz/tree-printer.rkt")

(provide start-repl
         repl-loop)

;; REPL state
(define current-state #f)
(define current-trace #f)
(define current-analysis #f)

;; Start REPL
(define/contract (start-repl)
  (-> void?)

  (displayln "=== WP Praxis Introspection REPL ===")
  (displayln "Type 'help' for available commands\n")

  (repl-loop))

;; Main REPL loop
(define/contract (repl-loop)
  (-> void?)

  (define input (readline "introspect> "))

  (unless (eof-object? input)
    (with-handlers ([exn:fail? (λ (e)
                                 (displayln (format "Error: ~a" (exn-message e))))])
      (process-command input))
    (repl-loop)))

;; Process REPL command
(define (process-command input)
  (define parts (string-split (string-trim input)))

  (match parts
    ['() (void)]
    [(list "help") (show-help)]
    [(list "quit") (exit)]
    [(list "exit") (exit)]
    [(list "load" path) (cmd-load path)]
    [(list "state") (cmd-show-state)]
    [(list "trace") (cmd-show-trace)]
    [(list "analyze") (cmd-analyze)]
    [(list "symbols") (cmd-list-symbols)]
    [(list "symbol" name) (cmd-show-symbol name)]
    [(list "deps" name) (cmd-show-dependencies name)]
    [(list "stats") (cmd-show-stats)]
    [(list "feedback") (cmd-show-feedback)]
    [_ (displayln "Unknown command. Type 'help' for available commands.")]))

;; Commands

(define (show-help)
  (displayln "Available commands:")
  (displayln "  load <path>     - Load manifest file")
  (displayln "  state           - Show current symbolic state")
  (displayln "  trace           - Show execution trace")
  (displayln "  analyze         - Run semantic analysis")
  (displayln "  symbols         - List all symbols")
  (displayln "  symbol <name>   - Show details of a symbol")
  (displayln "  deps <name>     - Show dependencies of a symbol")
  (displayln "  stats           - Show statistics")
  (displayln "  feedback        - Show feedback report")
  (displayln "  help            - Show this help")
  (displayln "  quit/exit       - Exit REPL"))

(define (cmd-load path)
  (displayln (format "Loading ~a..." path))

  (set! current-state (introspect-state
                       (read-toml-file path)))

  (displayln "✓ Loaded successfully"))

(define (cmd-show-state)
  (if current-state
      (display-tree current-state)
      (displayln "No state loaded. Use 'load <path>' first.")))

(define (cmd-show-trace)
  (if current-trace
      (display-tree current-trace)
      (displayln "No trace available. Run 'trace' command first.")))

(define (cmd-analyze)
  (if current-state
      (begin
        (displayln "Analyzing...")
        (set! current-analysis (analyze-semantics current-state))
        (displayln "✓ Analysis complete")
        (display-tree current-analysis))
      (displayln "No state loaded. Use 'load <path>' first.")))

(define (cmd-list-symbols)
  (if current-state
      (let ([symbols (hash-ref current-state 'symbols '())])
        (displayln (format "Found ~a symbols:" (length symbols)))
        (for ([sym symbols])
          (when (hash? sym)
            (displayln (format "  - ~a (~a)"
                               (hash-ref sym 'name "unknown")
                               (hash-ref sym 'type "unknown"))))))
      (displayln "No state loaded. Use 'load <path>' first.")))

(define (cmd-show-symbol name)
  (if current-state
      (let* ([symbols (hash-ref current-state 'symbols '())]
             [symbol (findf (λ (s)
                              (and (hash? s)
                                   (equal? (hash-ref s 'name "") name)))
                            symbols)])
        (if symbol
            (display-tree symbol)
            (displayln (format "Symbol '~a' not found" name))))
      (displayln "No state loaded. Use 'load <path>' first.")))

(define (cmd-show-dependencies name)
  (if current-state
      (let* ([symbols (hash-ref current-state 'symbols '())]
             [symbol (findf (λ (s)
                              (and (hash? s)
                                   (equal? (hash-ref s 'name "") name)))
                            symbols)])
        (if symbol
            (if (hash-has-key? symbol 'depends-on)
                (let ([deps (hash-ref symbol 'depends-on)])
                  (displayln (format "Dependencies of ~a:" name))
                  (for ([dep (if (list? deps) deps (list deps))])
                    (displayln (format "  - ~a" dep))))
                (displayln (format "Symbol '~a' has no dependencies" name)))
            (displayln (format "Symbol '~a' not found" name))))
      (displayln "No state loaded. Use 'load <path>' first.")))

(define (cmd-show-stats)
  (if current-state
      (let ([stats (hash-ref current-state 'statistics (hash))])
        (displayln "Statistics:")
        (for ([(k v) (in-hash stats)])
          (displayln (format "  ~a: ~a" k v))))
      (displayln "No state loaded. Use 'load <path>' first.")))

(define (cmd-show-feedback)
  (if current-state
      (begin
        (displayln "Generating feedback...")
        (define feedback (generate-feedback current-state #f current-analysis))
        (display-tree feedback))
      (displayln "No state loaded. Use 'load <path>' first.")))

;; Start REPL when run as main
(module+ main
  (start-repl))
