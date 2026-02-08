;; symbol-registry.lfe
;; Symbol Registry Gen-Server for WP Praxis Manifest Parser
;;
;; This gen_server maintains a global registry of symbols, workflows,
;; contexts, and dispatch rules for runtime lookup and introspection.

(defmodule symbol-registry
  "Gen-server for global symbol and workflow registry."
  (behaviour gen_server)
  (export (start_link 0)
          (register-symbol 2)
          (register-workflow 2)
          (register-context 2)
          (register-dispatch 1)
          (lookup-symbol 1)
          (lookup-workflow 1)
          (list-symbols 0)
          (list-workflows 0)
          (clear 0))
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
  "Start the symbol registry server.

  Returns:
    {ok, Pid} | {error, Reason}"
  (gen_server:start_link `#(local symbol_registry)
                         (MODULE)
                         '()
                         '()))

(defun register-symbol (name metadata)
  "Register a symbol in the registry.

  Args:
    name: Symbol name (atom)
    metadata: Symbol metadata (property list)

  Returns:
    ok"
  (gen_server:call 'symbol_registry `#(register symbol ,name ,metadata)))

(defun register-workflow (name metadata)
  "Register a workflow in the registry.

  Args:
    name: Workflow name (atom)
    metadata: Workflow metadata (property list)

  Returns:
    ok"
  (gen_server:call 'symbol_registry `#(register workflow ,name ,metadata)))

(defun register-context (name config)
  "Register a context in the registry.

  Args:
    name: Context name (atom)
    config: Context configuration (property list)

  Returns:
    ok"
  (gen_server:call 'symbol_registry `#(register context ,name ,config)))

(defun register-dispatch (rule)
  "Register a dispatch rule.

  Args:
    rule: Dispatch rule (property list)

  Returns:
    ok"
  (gen_server:call 'symbol_registry `#(register dispatch ,rule)))

(defun lookup-symbol (name)
  "Lookup a symbol by name.

  Args:
    name: Symbol name (atom)

  Returns:
    {ok, metadata} | undefined"
  (gen_server:call 'symbol_registry `#(lookup symbol ,name)))

(defun lookup-workflow (name)
  "Lookup a workflow by name.

  Args:
    name: Workflow name (atom)

  Returns:
    {ok, metadata} | undefined"
  (gen_server:call 'symbol_registry `#(lookup workflow ,name)))

(defun list-symbols ()
  "List all registered symbols.

  Returns:
    List of symbol names"
  (gen_server:call 'symbol_registry 'list-symbols))

(defun list-workflows ()
  "List all registered workflows.

  Returns:
    List of workflow names"
  (gen_server:call 'symbol_registry 'list-workflows))

(defun clear ()
  "Clear all registry entries.

  Returns:
    ok"
  (gen_server:call 'symbol_registry 'clear))

;;; =============================================================================
;;; Gen-Server State
;;; =============================================================================

(defrecord state
  symbols          ;; ETS table for symbols
  workflows        ;; ETS table for workflows
  contexts         ;; ETS table for contexts
  dispatches       ;; ETS table for dispatch rules
  stats            ;; Statistics
  )

;;; =============================================================================
;;; Gen-Server Callbacks
;;; =============================================================================

(defun init (args)
  "Initialize symbol registry.

  Args:
    args: Initialization arguments

  Returns:
    {ok, State}"
  (lager:info "Initializing Symbol Registry: ~p" (list args))

  ;; Create ETS tables
  (let ((symbols-table (ets:new 'symbols_table
                               '(set public #(read_concurrency true))))
        (workflows-table (ets:new 'workflows_table
                                 '(set public #(read_concurrency true))))
        (contexts-table (ets:new 'contexts_table
                                '(set public #(read_concurrency true))))
        (dispatches-table (ets:new 'dispatches_table
                                   '(bag public #(read_concurrency true))))
        (initial-stats (init-statistics)))

    `#(ok ,(make-state symbols symbols-table
                      workflows workflows-table
                      contexts contexts-table
                      dispatches dispatches-table
                      stats initial-stats))))

(defun handle_call
  ;; Register
  ([`#(register ,type ,name ,data) _from state]
   (let ((new-state (handle-register type name data state)))
     `#(reply ok ,new-state)))

  ;; Lookup
  ([`#(lookup ,type ,name) _from state]
   (let ((result (handle-lookup type name state)))
     `#(reply ,result ,state)))

  ;; List symbols
  (['list-symbols _from state]
   (let ((symbols (ets:foldl
                    (lambda (entry acc)
                      (case entry
                        ((tuple name _metadata)
                         (cons name acc))
                        (_ acc)))
                    '()
                    (state-symbols state))))
     `#(reply ,symbols ,state)))

  ;; List workflows
  (['list-workflows _from state]
   (let ((workflows (ets:foldl
                      (lambda (entry acc)
                        (case entry
                          ((tuple name _metadata)
                           (cons name acc))
                          (_ acc)))
                      '()
                      (state-workflows state))))
     `#(reply ,workflows ,state)))

  ;; Get all registry data
  (['get-all _from state]
   (let ((data `(#(symbols ,(get-all-symbols state))
                 #(workflows ,(get-all-workflows state))
                 #(contexts ,(get-all-contexts state))
                 #(dispatches ,(get-all-dispatches state)))))
     `#(reply ,data ,state)))

  ;; Get definition
  ([`#(get-definition ,name) _from state]
   (let ((result (handle-lookup 'symbol name state)))
     `#(reply ,result ,state)))

  ;; Set definition
  ([`#(set-definition ,name ,definition) _from state]
   (ets:insert (state-symbols state) `#(,name ,definition))
   `#(reply ok ,state))

  ;; Get workflow
  ([`#(get-workflow ,name) _from state]
   (let ((result (handle-lookup 'workflow name state)))
     `#(reply ,result ,state)))

  ;; Find dispatch rule
  ([`#(find-dispatch ,symbol) _from state]
   (let ((result (find-matching-dispatch symbol state)))
     `#(reply ,result ,state)))

  ;; Clear registry
  (['clear _from state]
   (ets:delete_all_objects (state-symbols state))
   (ets:delete_all_objects (state-workflows state))
   (ets:delete_all_objects (state-contexts state))
   (ets:delete_all_objects (state-dispatches state))
   (lager:info "Symbol registry cleared")
   `#(reply ok ,(set-state-stats state (init-statistics))))

  ;; Get statistics
  (['get-statistics _from state]
   `#(reply ,(state-stats state) ,state))

  ;; Unknown call
  ([request _from state]
   (lager:warn "Unknown call: ~p" (list request))
   `#(reply #(error unknown-request) ,state)))

(defun handle_cast
  ;; Async register
  ([`#(register ,type ,name ,data) state]
   (let ((new-state (handle-register type name data state)))
     `#(noreply ,new-state)))

  ;; Unknown cast
  ([msg state]
   (lager:warn "Unknown cast: ~p" (list msg))
   `#(noreply ,state)))

(defun handle_info
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
  (lager:info "Symbol Registry terminating: ~p" (list reason))
  ;; Delete ETS tables
  (ets:delete (state-symbols state))
  (ets:delete (state-workflows state))
  (ets:delete (state-contexts state))
  (ets:delete (state-dispatches state))
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

(defun handle-register (type name data state)
  "Handle registration of symbols/workflows/contexts/dispatches.

  Returns:
    Updated state"
  (let ((table (case type
                 ('symbol (state-symbols state))
                 ('workflow (state-workflows state))
                 ('context (state-contexts state))
                 ('dispatch (state-dispatches state))
                 (_ (error `#(unknown-type ,type))))))
    (case type
      ('dispatch
       ;; Dispatch rules use bag table
       (ets:insert table data))
      (_
       ;; Others use set table
       (ets:insert table `#(,name ,data))))
    ;; Update statistics
    (let ((stat-key (list_to_atom (++ (atom_to_list type) "s-registered")))
          (new-stats (increment-stat (state-stats state) stat-key)))
      (set-state-stats state new-stats))))

(defun handle-lookup (type name state)
  "Handle lookup of symbols/workflows/contexts.

  Returns:
    {ok, data} | undefined"
  (let ((table (case type
                 ('symbol (state-symbols state))
                 ('workflow (state-workflows state))
                 ('context (state-contexts state))
                 (_ (error `#(unknown-type ,type))))))
    (case (ets:lookup table name)
      ('() 'undefined)
      ((cons (tuple _name data) _rest)
       `#(ok ,data)))))

(defun find-matching-dispatch (symbol state)
  "Find dispatch rule matching symbol.

  Returns:
    {dispatch, executor, priority} | undefined"
  (let ((all-rules (ets:tab2list (state-dispatches state))))
    (find-best-match symbol all-rules)))

(defun find-best-match (symbol rules)
  "Find best matching dispatch rule.

  Returns:
    {dispatch, executor, priority} | undefined"
  ;; Simplified implementation - would have complex pattern matching
  (case rules
    ('() 'undefined)
    ((cons rule _rest)
     (let ((executor (proplists:get_value 'executor rule))
           (priority (proplists:get_value 'priority (proplists:get_value 'options rule '()) 0)))
       `#(dispatch ,executor ,priority)))))

;;; =============================================================================
;;; Retrieval Functions
;;; =============================================================================

(defun get-all-symbols (state)
  "Get all registered symbols."
  (ets:tab2list (state-symbols state)))

(defun get-all-workflows (state)
  "Get all registered workflows."
  (ets:tab2list (state-workflows state)))

(defun get-all-contexts (state)
  "Get all registered contexts."
  (ets:tab2list (state-contexts state)))

(defun get-all-dispatches (state)
  "Get all dispatch rules."
  (ets:tab2list (state-dispatches state)))

;;; =============================================================================
;;; Statistics
;;; =============================================================================

(defun init-statistics ()
  "Initialize statistics map."
  `#m(symbols-registered 0
      workflows-registered 0
      contexts-registered 0
      dispatches-registered 0
      lookups 0))

(defun increment-stat (stats key)
  "Increment a statistic counter."
  (maps:update_with key
                    (lambda (v) (+ v 1))
                    1
                    stats))
