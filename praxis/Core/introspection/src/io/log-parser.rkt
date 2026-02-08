#lang racket/base

;;; Log Parser
;;; Parses execution logs from all WP Praxis layers
;;; Supports PowerShell, Elixir, Rust, and PHP log formats

(require racket/contract
         racket/match
         racket/string
         racket/list
         racket/port
         racket/date)

(provide parse-log-file
         parse-log-string
         parse-multi-layer-logs
         extract-log-entries
         filter-log-by-level
         filter-log-by-layer
         group-logs-by-timestamp
         detect-errors
         detect-warnings
         extract-execution-timeline)

;; Data structures for log entries
(struct log-entry
  (timestamp
   level
   layer
   message
   metadata)
  #:transparent)

;; Log level enumeration
(define log-levels
  '(debug info warning error critical))

;; Layer identifiers
(define wp-praxis-layers
  '(manifest parser orchestrator symbolic injector wordpress introspection))

;; Parse log file
(define/contract (parse-log-file path)
  (-> path-string? (listof log-entry?))

  (define content (file->string path))
  (parse-log-string content))

;; Parse log string
(define/contract (parse-log-string log-str)
  (-> string? (listof log-entry?))

  (define lines (string-split log-str "\n"))
  (filter-map parse-log-line lines))

;; Parse individual log line
(define (parse-log-line line)
  (cond
    ;; PowerShell log format: [TIMESTAMP] [LEVEL] Layer: Message
    [(regexp-match #px"^\\[([^\\]]+)\\]\\s+\\[([^\\]]+)\\]\\s+([^:]+):\\s+(.+)$" line)
     => (λ (m)
          (match-define (list _ timestamp level layer message) m)
          (log-entry
           (parse-timestamp timestamp)
           (parse-log-level level)
           (parse-layer-name layer)
           message
           (make-hash)))]

    ;; Elixir log format: timestamp [level] [layer] message
    [(regexp-match #px"^([\\d\\-:]+)\\s+\\[([^\\]]+)\\]\\s+\\[([^\\]]+)\\]\\s+(.+)$" line)
     => (λ (m)
          (match-define (list _ timestamp level layer message) m)
          (log-entry
           (parse-timestamp timestamp)
           (parse-log-level level)
           (parse-layer-name layer)
           message
           (make-hash)))]

    ;; Rust log format: [timestamp] LEVEL layer: message
    [(regexp-match #px"^\\[([^\\]]+)\\]\\s+([A-Z]+)\\s+([^:]+):\\s+(.+)$" line)
     => (λ (m)
          (match-define (list _ timestamp level layer message) m)
          (log-entry
           (parse-timestamp timestamp)
           (parse-log-level level)
           (parse-layer-name layer)
           message
           (make-hash)))]

    ;; PHP error_log format: [timestamp] PHP Level: message
    [(regexp-match #px"^\\[([^\\]]+)\\]\\s+PHP\\s+([^:]+):\\s+(.+)$" line)
     => (λ (m)
          (match-define (list _ timestamp level message) m)
          (log-entry
           (parse-timestamp timestamp)
           (parse-log-level level)
           'wordpress
           message
           (make-hash)))]

    ;; Generic format: timestamp - level - message
    [(regexp-match #px"^([\\d\\-:T]+)\\s+-\\s+([A-Z]+)\\s+-\\s+(.+)$" line)
     => (λ (m)
          (match-define (list _ timestamp level message) m)
          (log-entry
           (parse-timestamp timestamp)
           (parse-log-level level)
           'unknown
           message
           (make-hash)))]

    ;; Unable to parse - skip
    [else #f]))

;; Parse timestamp string
(define (parse-timestamp timestamp-str)
  (with-handlers ([exn:fail? (λ (e) (current-seconds))])
    ;; Simplified timestamp parsing
    ;; In production, use a proper date parsing library
    (cond
      ;; ISO 8601 format: 2025-11-22T01:23:45
      [(regexp-match #px"^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})" timestamp-str)
       => (λ (m)
            (match-define (list _ year month day hour minute second) m)
            (find-seconds (string->number second)
                          (string->number minute)
                          (string->number hour)
                          (string->number day)
                          (string->number month)
                          (string->number year)))]

      ;; Date format: 2025-11-22 01:23:45
      [(regexp-match #px"^(\\d{4})-(\\d{2})-(\\d{2})\\s+(\\d{2}):(\\d{2}):(\\d{2})" timestamp-str)
       => (λ (m)
            (match-define (list _ year month day hour minute second) m)
            (find-seconds (string->number second)
                          (string->number minute)
                          (string->number hour)
                          (string->number day)
                          (string->number month)
                          (string->number year)))]

      ;; Default: current time
      [else (current-seconds)])))

;; Parse log level
(define (parse-log-level level-str)
  (define normalized (string-downcase (string-trim level-str)))
  (cond
    [(or (string-contains? normalized "debug") (string-contains? normalized "trace"))
     'debug]
    [(or (string-contains? normalized "info") (string-contains? normalized "information"))
     'info]
    [(or (string-contains? normalized "warn") (string-contains? normalized "warning"))
     'warning]
    [(or (string-contains? normalized "error") (string-contains? normalized "err"))
     'error]
    [(or (string-contains? normalized "critical") (string-contains? normalized "fatal"))
     'critical]
    [else 'info]))

;; Parse layer name
(define (parse-layer-name layer-str)
  (define normalized (string-downcase (string-trim layer-str)))
  (cond
    [(string-contains? normalized "manifest") 'manifest]
    [(string-contains? normalized "parser") 'parser]
    [(or (string-contains? normalized "orchestrator")
         (string-contains? normalized "elixir"))
     'orchestrator]
    [(or (string-contains? normalized "symbolic")
         (string-contains? normalized "powershell"))
     'symbolic]
    [(or (string-contains? normalized "injector")
         (string-contains? normalized "rust"))
     'injector]
    [(or (string-contains? normalized "wordpress")
         (string-contains? normalized "php"))
     'wordpress]
    [(string-contains? normalized "introspection") 'introspection]
    [else 'unknown]))

;; Parse logs from multiple layer log files
(define/contract (parse-multi-layer-logs log-files)
  (-> (listof (cons/c symbol? path-string?)) (listof log-entry?))

  (define all-entries
    (apply append
           (map (λ (layer-file-pair)
                  (match-define (cons layer path) layer-file-pair)
                  (define entries (parse-log-file path))
                  ;; Override layer if specified
                  (map (λ (entry)
                         (struct-copy log-entry entry [layer layer]))
                       entries))
                log-files)))

  ;; Sort by timestamp
  (sort all-entries
        (λ (a b)
          (< (log-entry-timestamp a)
             (log-entry-timestamp b)))))

;; Extract log entries matching criteria
(define/contract (extract-log-entries logs predicate)
  (-> (listof log-entry?) (-> log-entry? boolean?) (listof log-entry?))

  (filter predicate logs))

;; Filter logs by level
(define/contract (filter-log-by-level logs level)
  (-> (listof log-entry?) symbol? (listof log-entry?))

  (filter (λ (entry)
            (equal? (log-entry-level entry) level))
          logs))

;; Filter logs by layer
(define/contract (filter-log-by-layer logs layer)
  (-> (listof log-entry?) symbol? (listof log-entry?))

  (filter (λ (entry)
            (equal? (log-entry-layer entry) layer))
          logs))

;; Group logs by timestamp window
(define/contract (group-logs-by-timestamp logs window-seconds)
  (-> (listof log-entry?) exact-nonnegative-integer? (listof (listof log-entry?)))

  (if (null? logs)
      '()
      (let* ([sorted (sort logs < #:key log-entry-timestamp)]
             [groups '()]
             [current-group '()]
             [current-window-start (log-entry-timestamp (car sorted))])

        (for ([entry sorted])
          (define entry-time (log-entry-timestamp entry))

          (if (<= entry-time (+ current-window-start window-seconds))
              ;; Within current window
              (set! current-group (cons entry current-group))
              ;; Start new window
              (begin
                (set! groups (cons (reverse current-group) groups))
                (set! current-group (list entry))
                (set! current-window-start entry-time))))

        ;; Add final group
        (when (not (null? current-group))
          (set! groups (cons (reverse current-group) groups)))

        (reverse groups))))

;; Detect errors in logs
(define/contract (detect-errors logs)
  (-> (listof log-entry?) (listof log-entry?))

  (filter (λ (entry)
            (or (equal? (log-entry-level entry) 'error)
                (equal? (log-entry-level entry) 'critical)))
          logs))

;; Detect warnings in logs
(define/contract (detect-warnings logs)
  (-> (listof log-entry?) (listof log-entry?))

  (filter (λ (entry)
            (equal? (log-entry-level entry) 'warning))
          logs))

;; Extract execution timeline
(define/contract (extract-execution-timeline logs)
  (-> (listof log-entry?) hash?)

  (define sorted-logs (sort logs < #:key log-entry-timestamp))

  (define timeline
    (for/list ([entry sorted-logs])
      (make-hash
       (list (cons 'timestamp (log-entry-timestamp entry))
             (cons 'layer (log-entry-layer entry))
             (cons 'level (log-entry-level entry))
             (cons 'message (log-entry-message entry))))))

  (make-hash
   (list (cons 'timeline timeline)
         (cons 'start-time (if (null? sorted-logs)
                               0
                               (log-entry-timestamp (car sorted-logs))))
         (cons 'end-time (if (null? sorted-logs)
                             0
                             (log-entry-timestamp (last sorted-logs))))
         (cons 'total-entries (length sorted-logs)))))

;; Helper: Get log statistics
(define/contract (get-log-statistics logs)
  (-> (listof log-entry?) hash?)

  (define level-counts (make-hash))
  (define layer-counts (make-hash))

  (for ([entry logs])
    (hash-update! level-counts (log-entry-level entry) add1 0)
    (hash-update! layer-counts (log-entry-layer entry) add1 0))

  (make-hash
   (list (cons 'total-entries (length logs))
         (cons 'by-level level-counts)
         (cons 'by-layer layer-counts)
         (cons 'error-count (hash-ref level-counts 'error 0))
         (cons 'warning-count (hash-ref level-counts 'warning 0)))))

(provide get-log-statistics)

;; Helper: Format log entry for display
(define/contract (format-log-entry entry)
  (-> log-entry? string?)

  (format "[~a] [~a] ~a: ~a"
          (seconds->date-string (log-entry-timestamp entry))
          (log-entry-level entry)
          (log-entry-layer entry)
          (log-entry-message entry)))

(provide format-log-entry)

(define (seconds->date-string seconds)
  (define d (seconds->date seconds))
  (format "~a-~a-~a ~a:~a:~a"
          (date-year d)
          (pad-zero (date-month d))
          (pad-zero (date-day d))
          (pad-zero (date-hour d))
          (pad-zero (date-minute d))
          (pad-zero (date-second d))))

(define (pad-zero n)
  (~r n #:min-width 2 #:pad-string "0"))
