#lang racket/base

;;; HTTP Server
;;; Provides HTTP API for introspection system

(require racket/cmdline
         racket/match
         web-server/servlet
         web-server/servlet-env
         json
         "../main.rkt"
         "../src/reports/json-reporter.rkt"
         "../src/reports/html-reporter.rkt")

;; Configuration
(define port 8080)
(define host "localhost")

;; Parse command line
(command-line
 #:once-each
 [("-p" "--port") p "Port number (default: 8080)"
  (set! port (string->number p))]
 [("-h" "--host") h "Host (default: localhost)"
  (set! host h)])

;; Request handlers

(define (handle-introspect req)
  (define post-data (request-post-data/raw req))
  (define json-data (bytes->jsexpr post-data))

  (define manifest-path (hash-ref json-data 'manifest))
  (define options (hash-ref json-data 'options (hash)))

  (define results
    (introspect-workflow manifest-path
                         #:trace? (hash-ref options 'trace #t)
                         #:analyze? (hash-ref options 'analyze #t)
                         #:feedback? (hash-ref options 'feedback #t)))

  (response/json (results->json results)))

(define (handle-inspect req)
  (define post-data (request-post-data/raw req))
  (define json-data (bytes->jsexpr post-data))

  (define manifest-path (hash-ref json-data 'manifest))

  (define state (introspect-state (read-toml-file manifest-path)))

  (response/json state))

(define (handle-report req)
  (define post-data (request-post-data/raw req))
  (define json-data (bytes->jsexpr post-data))

  (define manifest-path (hash-ref json-data 'manifest))
  (define format (hash-ref json-data 'format "html"))

  (define results
    (introspect-workflow manifest-path
                         #:trace? #t
                         #:analyze? #t
                         #:feedback? #t))

  (match format
    ["html" (response/html (generate-html-report results))]
    ["json" (response/json (results->json results))]
    [_ (response/json (make-hash (list (cons 'error "Invalid format"))))]))

;; Response helpers

(define (response/json data)
  (response/full
   200 #"OK"
   (current-seconds)
   #"application/json; charset=utf-8"
   '()
   (list (string->bytes/utf-8 (jsexpr->string data)))))

(define (response/html html-str)
  (response/full
   200 #"OK"
   (current-seconds)
   #"text/html; charset=utf-8"
   '()
   (list (string->bytes/utf-8 html-str))))

;; Main servlet

(define (main-servlet req)
  (define path (request-uri req))
  (define method (request-method req))

  (match* (method (url-path path))
    [('post (list (path/param "introspect" _)))
     (handle-introspect req)]
    [('post (list (path/param "inspect" _)))
     (handle-inspect req)]
    [('post (list (path/param "report" _)))
     (handle-report req)]
    [('get (list))
     (response/html
      "<html><body><h1>WP Praxis Introspection API</h1>
       <p>Available endpoints:</p>
       <ul>
         <li>POST /introspect - Full introspection</li>
         <li>POST /inspect - State inspection only</li>
         <li>POST /report - Generate report</li>
       </ul></body></html>")]
    [_
     (response/json (make-hash (list (cons 'error "Not found"))))]))

;; Start server
(displayln (format "Starting WP Praxis Introspection HTTP server on ~a:~a" host port))

(serve/servlet main-servlet
               #:launch-browser? #f
               #:quit? #f
               #:listen-ip host
               #:port port
               #:servlet-path "/")
