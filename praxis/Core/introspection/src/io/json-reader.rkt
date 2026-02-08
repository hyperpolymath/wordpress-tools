#lang racket/base

;;; JSON Reader
;;; Reads and parses JSON state files for introspection

(require racket/contract
         racket/match
         racket/port
         json)

(provide read-json-file
         read-json-string
         parse-json-state
         validate-json-structure
         json->hash
         extract-json-field)

;; Read JSON from file
(define/contract (read-json-file path)
  (-> path-string? jsexpr?)

  (call-with-input-file path
    (λ (in)
      (read-json in))
    #:mode 'text))

;; Read JSON from string
(define/contract (read-json-string str)
  (-> string? jsexpr?)

  (call-with-input-string str
    (λ (in)
      (read-json in))))

;; Parse JSON state into structured format
(define/contract (parse-json-state json-data)
  (-> jsexpr? hash?)

  (cond
    [(hash? json-data)
     json-data]
    [(string? json-data)
     (read-json-string json-data)]
    [else
     (error 'parse-json-state "Invalid JSON data type: ~a" json-data)]))

;; Validate JSON structure against expected schema
(define/contract (validate-json-structure json-data expected-keys)
  (-> jsexpr? (listof symbol?) boolean?)

  (if (hash? json-data)
      (andmap (λ (key)
                (hash-has-key? json-data key))
              expected-keys)
      #f))

;; Convert JSON to hash (recursive)
(define/contract (json->hash json-data)
  (-> jsexpr? hash?)

  (cond
    [(hash? json-data)
     json-data]
    [(list? json-data)
     (make-hash
      (list (cons 'items (map json->hash json-data))))]
    [else
     (make-hash
      (list (cons 'value json-data)))]))

;; Extract field from JSON structure
(define/contract (extract-json-field json-data field-path)
  (-> jsexpr? (listof symbol?) any/c)

  (define (traverse data path)
    (match path
      ['() data]
      [(cons key rest)
       (if (hash? data)
           (if (hash-has-key? data key)
               (traverse (hash-ref data key) rest)
               #f)
           #f)]))

  (traverse json-data field-path))

;; Helper: Read multiple JSON files
(define/contract (read-json-files paths)
  (-> (listof path-string?) (listof jsexpr?))

  (map read-json-file paths))

(provide read-json-files)

;; Helper: Write JSON to file
(define/contract (write-json-file path data)
  (-> path-string? jsexpr? void?)

  (call-with-output-file path
    #:exists 'replace
    (λ (out)
      (write-json data out))
    #:mode 'text))

(provide write-json-file)

;; Helper: Pretty-print JSON
(define/contract (json->string data)
  (-> jsexpr? string?)

  (call-with-output-string
    (λ (out)
      (write-json data out))))

(provide json->string)
