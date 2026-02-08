#lang racket/base

;;; Introspection Configuration
;;; Configuration management for the introspection system

(require racket/contract
         racket/hash
         "../src/io/toml-reader.rkt")

(provide load-config
         get-config-value
         set-config-value!
         default-config
         config-file-path)

;; Global configuration state
(define current-config (make-hash))

;; Default configuration
(define default-config
  (make-hash
   (list
    ;; Analysis settings
    (cons 'analysis-depth 'full)
    (cons 'enable-trace #t)
    (cons 'enable-semantic-analysis #t)
    (cons 'enable-feedback #t)
    (cons 'enable-meta-evaluation #f)

    ;; Performance thresholds
    (cons 'bottleneck-threshold-multiplier 2.0)
    (cons 'max-dependency-depth 10)
    (cons 'max-symbols 1000)

    ;; Semantic analysis
    (cons 'semantic-preservation-threshold 0.7)
    (cons 'type-checking-enabled #t)
    (cons 'contract-verification-enabled #t)

    ;; Output settings
    (cons 'default-output-format 'text)
    (cons 'verbose-output #f)
    (cons 'color-output #t)

    ;; Database connection (optional)
    (cons 'db-host "localhost")
    (cons 'db-port 5432)
    (cons 'db-database "wp_praxis")
    (cons 'db-user "postgres")
    (cons 'db-password "")
    (cons 'db-enabled #f)

    ;; File paths
    (cons 'log-directory "/var/log/wp-praxis")
    (cons 'cache-directory "/tmp/wp-praxis-cache")
    (cons 'output-directory "./output"))))

;; Configuration file path
(define (config-file-path)
  (or (getenv "WP_PRAXIS_CONFIG")
      "./config/default-config.toml"))

;; Load configuration
(define/contract (load-config)
  (-> hash?)

  (define config-path (config-file-path))

  (set! current-config (hash-copy default-config))

  (when (file-exists? config-path)
    (with-handlers ([exn:fail? (λ (e)
                                 (displayln (format "Warning: Failed to load config: ~a"
                                                    (exn-message e))))])
      (define file-config (read-toml-file config-path))

      ;; Merge file config into current config
      (for ([(k v) (in-hash file-config)])
        (hash-set! current-config k v))))

  current-config)

;; Get configuration value
(define/contract (get-config-value key [default #f])
  (->* (symbol?) (any/c) any/c)

  (hash-ref current-config key default))

;; Set configuration value
(define/contract (set-config-value! key value)
  (-> symbol? any/c void?)

  (hash-set! current-config key value))

;; Configuration validation
(define/contract (validate-config config)
  (-> hash? (listof string?))

  (define errors '())

  ;; Validate numeric thresholds
  (when (hash-has-key? config 'bottleneck-threshold-multiplier)
    (define val (hash-ref config 'bottleneck-threshold-multiplier))
    (unless (and (number? val) (> val 0))
      (set! errors (cons "bottleneck-threshold-multiplier must be positive number"
                         errors))))

  ;; Validate max-dependency-depth
  (when (hash-has-key? config 'max-dependency-depth)
    (define val (hash-ref config 'max-dependency-depth))
    (unless (and (exact-nonnegative-integer? val) (> val 0))
      (set! errors (cons "max-dependency-depth must be positive integer"
                         errors))))

  ;; Validate semantic-preservation-threshold
  (when (hash-has-key? config 'semantic-preservation-threshold)
    (define val (hash-ref config 'semantic-preservation-threshold))
    (unless (and (number? val) (>= val 0) (<= val 1))
      (set! errors (cons "semantic-preservation-threshold must be between 0 and 1"
                         errors))))

  errors)

(provide validate-config)

;; Save configuration to file
(define/contract (save-config config path)
  (-> hash? path-string? void?)

  ;; Note: Would need TOML writer for full implementation
  ;; For now, just document the structure
  (displayln "Configuration saving not yet implemented"))

(provide save-config)
