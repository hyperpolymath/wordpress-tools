#lang racket/base

;;; Elixir Port Protocol Bridge
;;; Implements Erlang port protocol for Elixir integration

(require racket/match
         racket/port
         json
         "../main.rkt"
         "../src/reports/json-reporter.rkt")

;; Port protocol: {packet, 4} - 4-byte length prefix
(define (read-packet)
  (define len-bytes (read-bytes 4))
  (if (eof-object? len-bytes)
      eof
      (let ([len (integer-bytes->integer len-bytes #f #t)])
        (read-bytes len))))

(define (write-packet data)
  (define data-bytes (string->bytes/utf-8 data))
  (define len (bytes-length data-bytes))
  (define len-bytes (integer->integer-bytes len 4 #f #t))
  (write-bytes len-bytes)
  (write-bytes data-bytes)
  (flush-output))

;; Message handling
(define (handle-command cmd)
  (match cmd
    [(hash-table ['command "introspect"]
                 ['manifest manifest-path]
                 rest ...)
     (define options (make-hash rest))
     (define results
       (introspect-workflow manifest-path
                            #:trace? (hash-ref options 'trace #t)
                            #:analyze? (hash-ref options 'analyze #t)
                            #:feedback? (hash-ref options 'feedback #t)))
     (results->json results)]

    [(hash-table ['command "inspect"]
                 ['manifest manifest-path])
     (define state (introspect-state (read-toml-file manifest-path)))
     (results->json (make-hash (list (cons 'state state))))]

    [(hash-table ['command "trace"]
                 ['manifest manifest-path])
     (define trace (trace-execution manifest-path))
     (results->json (make-hash (list (cons 'trace trace))))]

    [_
     (make-hash (list (cons 'error "Unknown command")))]))

;; Main loop
(define (port-loop)
  (define packet (read-packet))

  (unless (eof-object? packet)
    (with-handlers ([exn:fail?
                     (λ (e)
                       (write-packet
                        (jsexpr->string
                         (make-hash
                          (list (cons 'error (exn-message e)))))))])

      (define cmd-str (bytes->string/utf-8 packet))
      (define cmd (string->jsexpr cmd-str))
      (define result (handle-command cmd))
      (write-packet (jsexpr->string result)))

    (port-loop)))

;; Start port loop
(port-loop)
