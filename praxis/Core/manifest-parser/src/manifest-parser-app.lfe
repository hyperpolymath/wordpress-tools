;; manifest-parser-app.lfe
;; OTP Application Callback for WP Praxis Manifest Parser
;;
;; This module implements the application behavior, starting the
;; supervision tree and initializing the manifest parser system.

(defmodule manifest-parser-app
  "OTP application callback for manifest parser."
  (behaviour application)
  (export (start 2) (stop 1)))

;;; =============================================================================
;;; Application Callbacks
;;; =============================================================================

(defun start (start-type start-args)
  "Start the manifest parser application.

  Args:
    start-type: normal | {takeover, Node} | {failover, Node}
    start-args: Application start arguments

  Returns:
    {ok, Pid} | {ok, Pid, State} | {error, Reason}"
  (lager:info "Starting WP Praxis Manifest Parser application: ~p ~p"
              (list start-type start-args))

  ;; Initialize application environment
  (initialize-environment)

  ;; Start supervisor
  (case (manifest-parser-sup:start_link)
    ((tuple 'ok pid)
     (lager:info "Manifest Parser supervisor started: ~p" (list pid))
     ;; Perform any additional initialization
     (post-start-initialization)
     `#(ok ,pid))

    ((tuple 'error reason)
     (lager:error "Failed to start Manifest Parser supervisor: ~p"
                  (list reason))
     `#(error ,reason))))

(defun stop (state)
  "Stop the manifest parser application.

  Args:
    state: Application state from start callback

  Returns:
    'ok"
  (lager:info "Stopping WP Praxis Manifest Parser application: ~p" (list state))

  ;; Cleanup
  (cleanup-resources)

  'ok)

;;; =============================================================================
;;; Initialization
;;; =============================================================================

(defun initialize-environment ()
  "Initialize application environment and settings."
  ;; Set default configuration if not present
  (set-default-env 'max_recursion_depth 100)
  (set-default-env 'enable_macro_expansion 'true)
  (set-default-env 'validate_on_parse 'true)
  (set-default-env 'cache_parsed_manifests 'true)
  (set-default-env 'cache_ttl_seconds 300)
  (set-default-env 'symbol_registry_size 1000)
  (set-default-env 'default_manifest_format 'yaml)
  (set-default-env 'strict_validation 'false)
  (set-default-env 'log_level 'info)

  ;; Initialize logging
  (configure-logging)

  'ok)

(defun set-default-env (key default-value)
  "Set application environment variable if not already set."
  (case (application:get_env 'manifest_parser key)
    ('undefined
     (application:set_env 'manifest_parser key default-value))
    (_
     'ok)))

(defun configure-logging ()
  "Configure logging for the application."
  (let ((log-level (application:get_env 'manifest_parser 'log_level 'info)))
    (lager:set_loglevel 'lager_console_backend log-level))
  'ok)

(defun post-start-initialization ()
  "Perform additional initialization after supervisor starts."
  ;; Initialize symbol registry
  (initialize-symbol-registry)

  ;; Load any precompiled schemas
  (load-schemas)

  ;; Register with other applications if needed
  (register-with-cluster)

  'ok)

(defun initialize-symbol-registry ()
  "Initialize the symbol registry."
  (case (whereis 'symbol_registry)
    ('undefined
     (lager:warn "Symbol registry not started yet, will initialize on demand"))
    (pid
     (lager:info "Symbol registry running: ~p" (list pid))))
  'ok)

(defun load-schemas ()
  "Load manifest schemas from priv directory."
  (let ((schemas-dir (code:priv_dir 'manifest_parser)))
    (case schemas-dir
      ((tuple 'error 'bad_name)
       (lager:warn "No priv directory found, skipping schema loading"))
      (dir
       (let ((schema-path (filename:join dir "schemas")))
         (case (file:list_dir schema-path)
           ((tuple 'ok files)
            (lager:info "Found ~p schema files" (list (length files))))
           ((tuple 'error 'enoent)
            (lager:info "No schemas directory, skipping schema loading"))
           ((tuple 'error reason)
            (lager:warn "Error loading schemas: ~p" (list reason)))))))
  'ok)

(defun register-with-cluster ()
  "Register this node with cluster if clustering is enabled."
  ;; Placeholder for cluster registration
  'ok)

;;; =============================================================================
;;; Cleanup
;;; =============================================================================

(defun cleanup-resources ()
  "Cleanup application resources on shutdown."
  ;; Clear caches
  (clear-manifest-cache)

  ;; Flush logs
  (flush-logs)

  'ok)

(defun clear-manifest-cache ()
  "Clear manifest parsing cache."
  (case (whereis 'parser_server)
    ('undefined 'ok)
    (pid
     (try
       (gen_server:call pid 'clear-cache)
       (catch
         (_ 'ok)))))
  'ok)

(defun flush-logs ()
  "Flush any pending log messages."
  (lager:info "Flushing logs before shutdown")
  'ok)

;;; =============================================================================
;;; Application Information
;;; =============================================================================

(defun get-version ()
  "Get application version."
  (case (application:get_key 'manifest_parser 'vsn)
    ((tuple 'ok version) version)
    ('undefined "unknown")))

(defun get-description ()
  "Get application description."
  (case (application:get_key 'manifest_parser 'description)
    ((tuple 'ok desc) desc)
    ('undefined "WP Praxis Manifest Parser")))

(defun get-info ()
  "Get application information."
  `#(application manifest_parser
     #(version ,(get-version))
     #(description ,(get-description))
     #(status ,(get-status))))

(defun get-status ()
  "Get application status."
  (case (application:get_application)
    ((tuple 'ok 'manifest_parser) 'running)
    (_ 'stopped)))

;;; =============================================================================
;;; Health Check
;;; =============================================================================

(defun health-check ()
  "Perform health check on application.

  Returns:
    'ok | {error, Reason}"
  (try
    ;; Check supervisor is alive
    (case (whereis 'manifest_parser_sup)
      ('undefined
       '#(error "Supervisor not running"))
      (sup-pid
       (if (is_process_alive sup-pid)
         ;; Check parser server
         (case (whereis 'parser_server)
           ('undefined
            '#(error "Parser server not running"))
           (parser-pid
            (if (is_process_alive parser-pid)
              ;; Check symbol registry
              (case (whereis 'symbol_registry)
                ('undefined
                 ;; Registry is optional
                 'ok)
                (reg-pid
                 (if (is_process_alive reg-pid)
                   'ok
                   '#(error "Symbol registry not responding"))))
              '#(error "Parser server not responding"))))
         '#(error "Supervisor not responding"))))
    (catch
      ((tuple type reason _stacktrace)
       `#(error #(,type ,reason))))))

;;; =============================================================================
;;; Configuration Management
;;; =============================================================================

(defun get-config (key)
  "Get configuration value.

  Args:
    key: Configuration key (atom)

  Returns:
    Value | 'undefined"
  (application:get_env 'manifest_parser key 'undefined))

(defun set-config (key value)
  "Set configuration value.

  Args:
    key: Configuration key (atom)
    value: Configuration value

  Returns:
    'ok"
  (application:set_env 'manifest_parser key value))

(defun reload-config ()
  "Reload configuration from sys.config.

  Returns:
    'ok | {error, Reason}"
  (case (application:get_all_env 'manifest_parser)
    (env
     (lager:info "Reloading configuration: ~p keys" (list (length env)))
     'ok)))

;;; =============================================================================
;;; Metrics and Statistics
;;; =============================================================================

(defun get-statistics ()
  "Get application statistics.

  Returns:
    Property list with statistics"
  (case (whereis 'parser_server)
    ('undefined
     '())
    (pid
     (try
       (gen_server:call pid 'get-statistics)
       (catch
         (_ '()))))))

(defun reset-statistics ()
  "Reset application statistics.

  Returns:
    'ok"
  (case (whereis 'parser_server)
    ('undefined 'ok)
    (pid
     (try
       (gen_server:call pid 'reset-statistics)
       (catch
         (_ 'ok))))))
