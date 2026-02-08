;; parser-server.lfe
;; Parser Server Gen-Server for WP Praxis Manifest Parser
;;
;; This gen_server provides stateful manifest parsing with caching,
;; concurrent request handling, and parse result management.

(defmodule parser-server
  "Gen-server for stateful manifest parsing."
  (behaviour gen_server)
  (export (start_link 0)
          (parse-file 1)
          (parse-string 2)
          (validate 1)
          (clear-cache 0)
          (get-statistics 0))
  (export (init 1)
          (handle_call 3)
          (handle_cast 2)
          (handle_info 2)
          (terminate 2)
          (code_change 3)))

;;; =============================================================================
;;; Public API
;;; =============================================================================

(defun start_link ()
  "Start the parser server.

  Returns:
    {ok, Pid} | {error, Reason}"
  (gen_server:start_link `#(local parser_server)
                         (MODULE)
                         '()
                         '()))

(defun parse-file (filepath)
  "Parse manifest file through server.

  Args:
    filepath: Path to manifest file

  Returns:
    {ok, manifest} | {error, reason}"
  (gen_server:call 'parser_server `#(parse-file ,filepath)))

(defun parse-string (content format)
  "Parse manifest from string through server.

  Args:
    content: Manifest content (binary)
    format: Format atom ('yaml or 'toml)

  Returns:
    {ok, manifest} | {error, reason}"
  (gen_server:call 'parser_server `#(parse-string ,content ,format)))

(defun validate (manifest)
  "Validate manifest through server.

  Args:
    manifest: Manifest structure

  Returns:
    ok | {error, errors}"
  (gen_server:call 'parser_server `#(validate ,manifest)))

(defun clear-cache ()
  "Clear manifest cache.

  Returns:
    ok"
  (gen_server:call 'parser_server 'clear-cache))

(defun get-statistics ()
  "Get parser statistics.

  Returns:
    Property list with statistics"
  (gen_server:call 'parser_server 'get-statistics))

;;; =============================================================================
;;; Gen-Server State
;;; =============================================================================

(defrecord state
  cache            ;; ETS table for caching parsed manifests
  cache-ttl        ;; Cache TTL in seconds
  stats            ;; Statistics map
  max-cache-size   ;; Maximum cache entries
  )

;;; =============================================================================
;;; Gen-Server Callbacks
;;; =============================================================================

(defun init (args)
  "Initialize parser server.

  Args:
    args: Initialization arguments

  Returns:
    {ok, State} | {ok, State, Timeout} | ignore | {stop, Reason}"
  (lager:info "Initializing Parser Server: ~p" (list args))

  ;; Create ETS table for cache
  (let* ((cache-table (ets:new 'manifest_cache
                               '(set public #(read_concurrency true))))
         (cache-ttl (application:get_env 'manifest_parser
                                        'cache_ttl_seconds
                                        300))
         (max-size (application:get_env 'manifest_parser
                                       'symbol_registry_size
                                       1000))
         (initial-stats (init-statistics)))

    `#(ok ,(make-state cache cache-table
                      cache-ttl cache-ttl
                      stats initial-stats
                      max-cache-size max-size))))

(defun handle_call
  ;; Parse file
  ([`#(parse-file ,filepath) _from state]
   (let ((result (handle-parse-file filepath state)))
     (case result
       ((tuple 'ok manifest new-state)
        `#(reply #(ok ,manifest) ,new-state))
       ((tuple 'error reason new-state)
        `#(reply #(error ,reason) ,new-state)))))

  ;; Parse string
  ([`#(parse-string ,content ,format) _from state]
   (let ((result (handle-parse-string content format state)))
     (case result
       ((tuple 'ok manifest new-state)
        `#(reply #(ok ,manifest) ,new-state))
       ((tuple 'error reason new-state)
        `#(reply #(error ,reason) ,new-state)))))

  ;; Validate
  ([`#(validate ,manifest) _from state]
   (let ((result (manifest-validator:validate manifest)))
     `#(reply ,result ,state)))

  ;; Clear cache
  (['clear-cache _from state]
   (ets:delete_all_objects (state-cache state))
   (lager:info "Manifest cache cleared")
   `#(reply ok ,state))

  ;; Get statistics
  (['get-statistics _from state]
   `#(reply ,(state-stats state) ,state))

  ;; Reset statistics
  (['reset-statistics _from state]
   (let ((new-state (set-state-stats state (init-statistics))))
     `#(reply ok ,new-state)))

  ;; Unknown call
  ([request _from state]
   (lager:warn "Unknown call: ~p" (list request))
   `#(reply #(error unknown-request) ,state)))

(defun handle_cast
  ;; Async cache clear
  (['clear-cache state]
   (ets:delete_all_objects (state-cache state))
   `#(noreply ,state))

  ;; Unknown cast
  ([msg state]
   (lager:warn "Unknown cast: ~p" (list msg))
   `#(noreply ,state)))

(defun handle_info
  ;; Cache cleanup timer
  (['cleanup-cache state]
   (cleanup-expired-cache state)
   ;; Schedule next cleanup
   (erlang:send_after (* 60 1000) (self) 'cleanup-cache)
   `#(noreply ,state))

  ;; Unknown message
  ([msg state]
   (lager:warn "Unknown info: ~p" (list msg))
   `#(noreply ,state)))

(defun terminate (reason state)
  "Cleanup on termination.

  Args:
    reason: Termination reason
    state: Current state

  Returns:
    ok"
  (lager:info "Parser Server terminating: ~p" (list reason))
  ;; Delete ETS table
  (ets:delete (state-cache state))
  'ok)

(defun code_change (old-vsn state extra)
  "Handle code changes.

  Args:
    old-vsn: Old version
    state: Current state
    extra: Extra data

  Returns:
    {ok, NewState}"
  (lager:info "Code change from ~p with ~p" (list old-vsn extra))
  `#(ok ,state))

;;; =============================================================================
;;; Internal Functions
;;; =============================================================================

(defun handle-parse-file (filepath state)
  "Handle file parsing with caching.

  Returns:
    {ok, manifest, new-state} | {error, reason, new-state}"
  ;; Check cache first
  (case (lookup-cache filepath state)
    ((tuple 'hit manifest)
     (let ((new-stats (increment-stat (state-stats state) 'cache-hits)))
       `#(ok ,manifest ,(set-state-stats state new-stats))))

    ('miss
     ;; Parse file
     (case (manifest-transformer:transform-file filepath)
       ((tuple 'ok manifest)
        ;; Cache result
        (cache-manifest filepath manifest state)
        (let ((new-stats (increment-stat (state-stats state) 'parses)))
          `#(ok ,manifest ,(set-state-stats state new-stats))))

       ((tuple 'error reason)
        (let ((new-stats (increment-stat (state-stats state) 'errors)))
          `#(error ,reason ,(set-state-stats state new-stats))))))))

(defun handle-parse-string (content format state)
  "Handle string parsing (no caching).

  Returns:
    {ok, manifest, new-state} | {error, reason, new-state}"
  (let ((result (case format
                  ('yaml (yaml-parser:parse-string content))
                  ('toml (toml-parser:parse-string content))
                  (_ `#(error #(invalid-format ,format))))))
    (case result
      ((tuple 'ok parsed)
       (case (manifest-transformer:transform parsed format)
         ((tuple 'ok manifest)
          (let ((new-stats (increment-stat (state-stats state) 'parses)))
            `#(ok ,manifest ,(set-state-stats state new-stats))))
         ((tuple 'error reason)
          (let ((new-stats (increment-stat (state-stats state) 'errors)))
            `#(error ,reason ,(set-state-stats state new-stats))))))
      ((tuple 'error reason)
       (let ((new-stats (increment-stat (state-stats state) 'errors)))
         `#(error ,reason ,(set-state-stats state new-stats)))))))

;;; =============================================================================
;;; Caching
;;; =============================================================================

(defun lookup-cache (key state)
  "Lookup key in cache.

  Returns:
    {hit, value} | miss"
  (case (ets:lookup (state-cache state) key)
    ('()
     'miss)
    ((cons (tuple _key value timestamp) _rest)
     (let ((now (erlang:system_time 'second))
           (ttl (state-cache-ttl state)))
       (if (< (- now timestamp) ttl)
         `#(hit ,value)
         (progn
           ;; Expired, remove from cache
           (ets:delete (state-cache state) key)
           'miss))))))

(defun cache-manifest (key manifest state)
  "Cache parsed manifest.

  Args:
    key: Cache key (filepath)
    manifest: Parsed manifest
    state: Server state

  Returns:
    ok"
  (let ((timestamp (erlang:system_time 'second))
        (cache-table (state-cache state)))
    ;; Check cache size limit
    (when (> (ets:info cache-table 'size) (state-max-cache-size state))
      (evict-oldest-entry cache-table))
    ;; Insert into cache
    (ets:insert cache-table `#(,key ,manifest ,timestamp))
    'ok))

(defun evict-oldest-entry (cache-table)
  "Evict oldest cache entry."
  (case (ets:first cache-table)
    ('$end_of_table 'ok)
    (key
     (ets:delete cache-table key)
     'ok)))

(defun cleanup-expired-cache (state)
  "Remove expired cache entries.

  Args:
    state: Server state

  Returns:
    ok"
  (let ((now (erlang:system_time 'second))
        (ttl (state-cache-ttl state))
        (cache-table (state-cache state)))
    (ets:foldl
      (lambda (entry acc)
        (case entry
          ((tuple key _value timestamp)
           (when (>= (- now timestamp) ttl)
             (ets:delete cache-table key)))
          (_ 'ok))
        acc)
      'ok
      cache-table)))

;;; =============================================================================
;;; Statistics
;;; =============================================================================

(defun init-statistics ()
  "Initialize statistics map."
  `#m(parses 0
      errors 0
      cache-hits 0
      cache-misses 0
      validations 0))

(defun increment-stat (stats key)
  "Increment a statistic counter."
  (maps:update_with key
                    (lambda (v) (+ v 1))
                    1
                    stats))
