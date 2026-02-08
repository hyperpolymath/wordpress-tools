;; SPDX-License-Identifier: PMPL-1.0-or-later
;; State management utilities for SOCP

(define-module (socp state-utils)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-19)
  #:export (state-get
            state-set
            state-update
            load-state
            save-state
            validate-state
            state-diff))

;; Get a nested value from state
;; (state-get state '(control-plane status)) => 'healthy
(define (state-get state path)
  (match path
    (() state)
    ((key . rest)
     (let ((entry (assoc key state)))
       (if entry
           (state-get (cdr entry) rest)
           #f)))))

;; Set a nested value in state (returns new state)
(define (state-set state path value)
  (match path
    (() value)
    ((key . rest)
     (let ((entry (assoc key state)))
       (if entry
           (assoc-set! (alist-copy state) key
                       (state-set (cdr entry) rest value))
           (cons (cons key (state-set '() rest value)) state))))))

;; Update a nested value using a function
(define (state-update state path fn)
  (let ((current (state-get state path)))
    (state-set state path (fn current))))

;; Load state from file
(define (load-state filename)
  (with-input-from-file filename
    (lambda ()
      (let ((expr (read)))
        (if (eof-object? expr)
            (error "Empty state file")
            (eval expr (interaction-environment)))))))

;; Save state to file
(define (save-state state filename)
  (with-output-to-file filename
    (lambda ()
      (display ";; SPDX-License-Identifier: AGPL-3.0-or-later\n")
      (display ";; SOCP State - Auto-generated, do not edit manually\n")
      (display ";; Updated: ")
      (display (date->string (current-date) "~Y-~m-~dT~H:~M:~SZ"))
      (newline)
      (newline)
      (write `(define socp-state ',state))
      (newline))))

;; Validate state structure
(define (validate-state state)
  (and (list? state)
       (assoc 'metadata state)
       (assoc 'control-plane state)
       (assoc 'sites state)))

;; Compute diff between two states
(define (state-diff old-state new-state)
  (define (diff-alist old new path)
    (let ((changes '()))
      ;; Check for modified/added
      (for-each
       (lambda (pair)
         (let* ((key (car pair))
                (new-val (cdr pair))
                (old-entry (assoc key old)))
           (cond
            ((not old-entry)
             (set! changes (cons `(added ,@path ,key ,new-val) changes)))
            ((not (equal? (cdr old-entry) new-val))
             (if (and (list? (cdr old-entry)) (list? new-val))
                 (set! changes (append (diff-alist (cdr old-entry) new-val
                                                   (append path (list key)))
                                       changes))
                 (set! changes (cons `(modified ,@path ,key
                                                ,(cdr old-entry) ,new-val)
                                     changes)))))))
       new)
      ;; Check for removed
      (for-each
       (lambda (pair)
         (let ((key (car pair)))
           (unless (assoc key new)
             (set! changes (cons `(removed ,@path ,key) changes)))))
       old)
      changes))
  (diff-alist old-state new-state '()))
