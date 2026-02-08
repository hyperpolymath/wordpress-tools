#lang racket/base

;;; TOML Reader
;;; Reads and parses TOML manifest files for introspection

(require racket/contract
         racket/match
         racket/string
         racket/port
         racket/hash)

(provide read-toml-file
         parse-toml-string
         toml-get
         toml-has-key?
         toml->hash
         validate-toml-manifest)

;; Simple TOML parser (basic implementation)
;; For production, consider using a full TOML library if available

;; Read TOML from file
(define/contract (read-toml-file path)
  (-> path-string? hash?)

  (define content (file->string path))
  (parse-toml-string content))

;; Parse TOML string into hash structure
(define/contract (parse-toml-string toml-str)
  (-> string? hash?)

  (define lines (string-split toml-str "\n"))
  (define result (make-hash))
  (define current-section '())

  (for ([line lines])
    (define trimmed (string-trim line))

    (cond
      ;; Skip comments and empty lines
      [(or (string=? trimmed "")
           (string-prefix? trimmed "#"))
       (void)]

      ;; Section headers [section]
      [(regexp-match #rx"^\\[([^\\]]+)\\]$" trimmed)
       => (λ (m)
            (define section-name (second m))
            (set! current-section (parse-section-name section-name))
            (ensure-section-exists result current-section))]

      ;; Key-value pairs
      [(regexp-match #rx"^([^=]+)=(.+)$" trimmed)
       => (λ (m)
            (define key (string-trim (second m)))
            (define value-str (string-trim (third m)))
            (define value (parse-toml-value value-str))
            (set-toml-value! result current-section key value))]

      ;; Unknown line format - skip
      [else (void)]))

  result)

;; Parse section name (supports dotted notation)
(define (parse-section-name section-str)
  (map string->symbol (string-split section-str ".")))

;; Parse TOML value
(define (parse-toml-value value-str)
  (cond
    ;; Boolean values
    [(equal? value-str "true") #t]
    [(equal? value-str "false") #f]

    ;; String values (quoted)
    [(regexp-match #rx"^\"(.*)\"$" value-str)
     => (λ (m) (second m))]

    [(regexp-match #rx"^'(.*)'$" value-str)
     => (λ (m) (second m))]

    ;; Array values
    [(regexp-match #rx"^\\[(.*)\\]$" value-str)
     => (λ (m)
          (define array-content (second m))
          (if (string=? array-content "")
              '()
              (map (λ (item)
                     (parse-toml-value (string-trim item)))
                   (string-split array-content ","))))]

    ;; Number values
    [(regexp-match #rx"^-?[0-9]+(\\.[0-9]+)?$" value-str)
     (string->number value-str)]

    ;; Default: treat as string
    [else value-str]))

;; Ensure section path exists in hash
(define (ensure-section-exists h section-path)
  (unless (null? section-path)
    (define key (car section-path))
    (define rest-path (cdr section-path))

    (unless (hash-has-key? h key)
      (hash-set! h key (make-hash)))

    (unless (null? rest-path)
      (ensure-section-exists (hash-ref h key) rest-path))))

;; Set value in nested hash structure
(define (set-toml-value! h section-path key value)
  (define target
    (if (null? section-path)
        h
        (let loop ([current h]
                   [path section-path])
          (if (null? (cdr path))
              (hash-ref current (car path))
              (loop (hash-ref current (car path))
                    (cdr path))))))

  (hash-set! target (string->symbol key) value))

;; Get value from TOML hash
(define/contract (toml-get toml-hash key-path [default #f])
  (->* (hash? (or/c symbol? (listof symbol?)))
       (any/c)
       any/c)

  (define path (if (symbol? key-path)
                   (list key-path)
                   key-path))

  (let loop ([current toml-hash]
             [remaining path])
    (cond
      [(null? remaining) current]
      [(not (hash? current)) default]
      [(hash-has-key? current (car remaining))
       (loop (hash-ref current (car remaining))
             (cdr remaining))]
      [else default])))

;; Check if key exists in TOML hash
(define/contract (toml-has-key? toml-hash key-path)
  (-> hash? (or/c symbol? (listof symbol?)) boolean?)

  (not (equal? (toml-get toml-hash key-path 'not-found) 'not-found)))

;; Convert TOML to standard hash (flatten structure if needed)
(define/contract (toml->hash toml-data)
  (-> hash? hash?)

  ;; Already a hash, return as-is
  toml-data)

;; Validate TOML manifest structure
(define/contract (validate-toml-manifest toml-hash)
  (-> hash? (listof string?))

  (define errors '())

  ;; Check for required top-level sections
  (define required-sections '(symbols))

  (for ([section required-sections])
    (unless (hash-has-key? toml-hash section)
      (set! errors
            (cons (format "Missing required section: ~a" section)
                  errors))))

  ;; Validate symbols section if present
  (when (hash-has-key? toml-hash 'symbols)
    (define symbols-section (hash-ref toml-hash 'symbols))

    ;; If symbols is a hash, it should have entries
    (when (and (hash? symbols-section)
               (hash-empty? symbols-section))
      (set! errors
            (cons "Symbols section is empty"
                  errors))))

  errors)

;; Helper: Read multiple TOML files
(define/contract (read-toml-files paths)
  (-> (listof path-string?) (listof hash?))

  (map read-toml-file paths))

(provide read-toml-files)

;; Helper: TOML to JSON conversion
(define/contract (toml->json toml-hash)
  (-> hash? jsexpr?)

  (define (convert-value v)
    (cond
      [(hash? v) (hash-map v (λ (k v) (cons k (convert-value v))))]
      [(list? v) (map convert-value v)]
      [else v]))

  (convert-value toml-hash))

(provide toml->json)
