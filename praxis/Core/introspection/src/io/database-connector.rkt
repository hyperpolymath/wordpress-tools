#lang racket/base

;;; Database Connector
;;; Connects to PostgreSQL database to read Ecto schema and execution data

(require racket/contract
         racket/match
         racket/list
         db)

(provide connect-database
         disconnect-database
         query-symbolic-state
         query-execution-history
         query-symbol-metadata
         get-workflow-runs
         get-layer-statistics
         db-connection?)

;; Database connection parameters
(struct db-config
  (host port database user password)
  #:transparent)

;; Create database connection
(define/contract (connect-database config)
  (-> db-config? connection?)

  (postgresql-connect
   #:server (db-config-host config)
   #:port (db-config-port config)
   #:database (db-config-database config)
   #:user (db-config-user config)
   #:password (db-config-password config)))

;; Disconnect from database
(define/contract (disconnect-database conn)
  (-> connection? void?)

  (disconnect conn))

;; Query symbolic state from database
(define/contract (query-symbolic-state conn [workflow-id #f])
  (->* (connection?) ((or/c integer? #f)) (listof hash?))

  (define query
    (if workflow-id
        "SELECT id, name, type, context, metadata, created_at
         FROM symbols
         WHERE workflow_id = $1
         ORDER BY created_at"
        "SELECT id, name, type, context, metadata, created_at
         FROM symbols
         ORDER BY created_at DESC
         LIMIT 100"))

  (define rows
    (if workflow-id
        (query-rows conn query workflow-id)
        (query-rows conn query)))

  (map row->hash rows))

;; Query execution history
(define/contract (query-execution-history conn [limit 50])
  (->* (connection?) (exact-nonnegative-integer?) (listof hash?))

  (define query
    "SELECT e.id, e.workflow_id, e.layer, e.operation,
            e.started_at, e.completed_at, e.duration_ms, e.status
     FROM executions e
     ORDER BY e.started_at DESC
     LIMIT $1")

  (define rows (query-rows conn query limit))

  (map row->hash rows))

;; Query symbol metadata from database
(define/contract (query-symbol-metadata conn symbol-name)
  (-> connection? string? (or/c hash? #f))

  (define query
    "SELECT id, name, type, context, metadata, dependencies
     FROM symbols
     WHERE name = $1
     LIMIT 1")

  (define rows (query-rows conn query symbol-name))

  (if (null? rows)
      #f
      (row->hash (car rows))))

;; Get workflow runs
(define/contract (get-workflow-runs conn [limit 20])
  (->* (connection?) (exact-nonnegative-integer?) (listof hash?))

  (define query
    "SELECT w.id, w.manifest_path, w.started_at, w.completed_at,
            w.status, w.total_symbols, w.success_count, w.error_count
     FROM workflows w
     ORDER BY w.started_at DESC
     LIMIT $1")

  (define rows (query-rows conn query limit))

  (map row->hash rows))

;; Get layer statistics
(define/contract (get-layer-statistics conn workflow-id)
  (-> connection? integer? (listof hash?))

  (define query
    "SELECT layer,
            COUNT(*) as execution_count,
            AVG(duration_ms) as avg_duration,
            MAX(duration_ms) as max_duration,
            MIN(duration_ms) as min_duration
     FROM executions
     WHERE workflow_id = $1
     GROUP BY layer
     ORDER BY layer")

  (define rows (query-rows conn query workflow-id))

  (map row->hash rows))

;; Helper: Convert database row to hash
(define (row->hash row)
  (define field-names (vector->list (sql-data-row-names row)))
  (define values (vector->list row))

  (make-hash
   (map cons field-names values)))

;; Helper: Execute query with parameters
(define/contract (execute-query conn query-str . params)
  (->* (connection? string?) () #:rest list? any)

  (apply query conn query-str params))

(provide execute-query)

;; Helper: Get table schema information
(define/contract (get-table-schema conn table-name)
  (-> connection? string? (listof hash?))

  (define query
    "SELECT column_name, data_type, is_nullable, column_default
     FROM information_schema.columns
     WHERE table_name = $1
     ORDER BY ordinal_position")

  (define rows (query-rows conn query table-name))

  (map row->hash rows))

(provide get-table-schema)

;; Helper: Check if table exists
(define/contract (table-exists? conn table-name)
  (-> connection? string? boolean?)

  (define query
    "SELECT EXISTS (
       SELECT FROM information_schema.tables
       WHERE table_name = $1
     )")

  (define result (query-value conn query table-name))

  (equal? result #t))

(provide table-exists?)

;; Helper: Get database version
(define/contract (get-db-version conn)
  (-> connection? string?)

  (query-value conn "SELECT version()"))

(provide get-db-version)

;; Helper: Create default database configuration
(define/contract (make-db-config #:host [host "localhost"]
                                 #:port [port 5432]
                                 #:database [database "wp_praxis"]
                                 #:user [user "postgres"]
                                 #:password [password ""])
  (->* ()
       (#:host string?
        #:port exact-nonnegative-integer?
        #:database string?
        #:user string?
        #:password string?)
       db-config?)

  (db-config host port database user password))

(provide make-db-config)

;; Helper: Test database connection
(define/contract (test-connection config)
  (-> db-config? boolean?)

  (with-handlers ([exn:fail? (λ (e) #f)])
    (define conn (connect-database config))
    (define result (connected? conn))
    (disconnect-database conn)
    result))

(provide test-connection)

;; Helper: Query with error handling
(define/contract (safe-query conn query-str . params)
  (->* (connection? string?) () #:rest list? (or/c list? #f))

  (with-handlers ([exn:fail:sql? (λ (e) #f)])
    (apply query-rows conn query-str params)))

(provide safe-query)
