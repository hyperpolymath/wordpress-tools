;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SOCP State Checkpoint
;; This file tracks the operational state of the control plane

(define socp-state
  `((metadata
     (project . "wp-resurrect")
     (type . "Site Operations Control Plane")
     (updated . "2025-12-28T12:00:00Z")
     (version . "0.1.0")
     (schema-version . 1))

    ;; Control plane status
    (control-plane
     (status . initializing)  ; initializing | healthy | degraded | offline
     (components
      ((name . "salt-master")
       (status . pending)
       (last-check . #f))
      ((name . "socp-api")
       (status . pending)
       (last-check . #f))
      ((name . "powerdns")
       (status . pending)
       (last-check . #f))
      ((name . "openziti")
       (status . pending)
       (last-check . #f))))

    ;; Managed sites (populated by sync)
    (sites ())

    ;; Pending configuration changes
    (pending-changes ())

    ;; Secret rotation schedule
    (secrets
     (rotation-schedule
      ;; Secrets are rotated on this schedule
      ((type . database-password)
       (interval-days . 90))
      ((type . redis-password)
       (interval-days . 90))
      ((type . api-key)
       (interval-days . 180))
      ((type . ssl-certificate)
       (interval-days . 60)))  ; Check 60 days before expiry
     (pending-rotations ())
     (last-rotation-check . #f))

    ;; Deployment history (last 100 entries)
    (deployment-history ())

    ;; Alert state
    (alerts
     (active ())
     (acknowledged ())
     (thresholds
      ((ssl-expiry-warning-days . 30)
       (ssl-expiry-critical-days . 7)
       (response-time-warning-ms . 500)
       (response-time-critical-ms . 2000)
       (config-drift-warning-hours . 24))))

    ;; Operator sessions (for access audit)
    (operator-sessions ())))
