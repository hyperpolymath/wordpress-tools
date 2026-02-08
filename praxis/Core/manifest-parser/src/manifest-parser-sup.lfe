;; manifest-parser-sup.lfe
;; OTP Supervisor for WP Praxis Manifest Parser
;;
;; This module implements the supervision tree for the manifest parser,
;; managing the parser server and symbol registry processes.

(defmodule manifest-parser-sup
  "OTP supervisor for manifest parser processes."
  (behaviour supervisor)
  (export (start_link 0)
          (init 1)))

;;; =============================================================================
;;; Supervisor API
;;; =============================================================================

(defun start_link ()
  "Start the manifest parser supervisor.

  Returns:
    {ok, Pid} | {error, Reason}"
  (supervisor:start_link `#(local manifest_parser_sup)
                         (MODULE)
                         '()))

;;; =============================================================================
;;; Supervisor Callbacks
;;; =============================================================================

(defun init (args)
  "Initialize the supervisor.

  Args:
    args: Initialization arguments

  Returns:
    {ok, {SupFlags, ChildSpecs}} | ignore | {error, Reason}"
  (lager:info "Initializing Manifest Parser supervisor: ~p" (list args))

  ;; Supervisor flags
  (let ((sup-flags `#m(strategy one_for_one
                       intensity 10
                       period 60))

        ;; Child specifications
        (child-specs (list (parser-server-child-spec)
                          (symbol-registry-child-spec))))

    `#(ok #(,sup-flags ,child-specs))))

;;; =============================================================================
;;; Child Specifications
;;; =============================================================================

(defun parser-server-child-spec ()
  "Child spec for parser server process."
  `#m(id parser_server
      start #(parser-server start_link ())
      restart permanent
      shutdown 5000
      type worker
      modules (parser-server)))

(defun symbol-registry-child-spec ()
  "Child spec for symbol registry process."
  `#m(id symbol_registry
      start #(symbol-registry start_link ())
      restart permanent
      shutdown 5000
      type worker
      modules (symbol-registry)))

;;; =============================================================================
;;; Child Management
;;; =============================================================================

(defun start-child (child-spec)
  "Dynamically start a child process.

  Args:
    child-spec: Child specification map

  Returns:
    {ok, Child} | {ok, Child, Info} | {error, Reason}"
  (supervisor:start_child 'manifest_parser_sup child-spec))

(defun terminate-child (child-id)
  "Terminate a child process.

  Args:
    child-id: Child ID (atom)

  Returns:
    ok | {error, Reason}"
  (supervisor:terminate_child 'manifest_parser_sup child-id))

(defun restart-child (child-id)
  "Restart a child process.

  Args:
    child-id: Child ID (atom)

  Returns:
    {ok, Child} | {ok, Child, Info} | {error, Reason}"
  (supervisor:restart_child 'manifest_parser_sup child-id))

(defun delete-child (child-id)
  "Delete a child specification.

  Args:
    child-id: Child ID (atom)

  Returns:
    ok | {error, Reason}"
  (supervisor:delete_child 'manifest_parser_sup child-id))

(defun which-children ()
  "Get list of child processes.

  Returns:
    List of {Id, Child, Type, Modules}"
  (supervisor:which_children 'manifest_parser_sup))

(defun count-children ()
  "Count child processes by status.

  Returns:
    Property list with counts"
  (supervisor:count_children 'manifest_parser_sup))

;;; =============================================================================
;;; Utility Functions
;;; =============================================================================

(defun get-child-pid (child-id)
  "Get PID of a child process.

  Args:
    child-id: Child ID (atom)

  Returns:
    Pid | 'undefined"
  (case (lists:keyfind child-id 1 (which-children))
    ('false 'undefined)
    ((tuple _id pid _type _modules) pid)))

(defun is-child-alive (child-id)
  "Check if child process is alive.

  Args:
    child-id: Child ID (atom)

  Returns:
    true | false"
  (case (get-child-pid child-id)
    ('undefined 'false)
    (pid (is_process_alive pid))))
