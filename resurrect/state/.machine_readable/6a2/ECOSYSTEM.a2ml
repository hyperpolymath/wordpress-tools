;; SPDX-License-Identifier: PMPL-1.0-or-later
;; SOCP Ecosystem Definition
;; Defines the relationships between sites and groups

(define socp-ecosystem
  `((metadata
     (updated . "2025-12-28T12:00:00Z")
     (version . "0.1.0"))

    ;; Site groups for batch operations
    (groups
     ((id . "production")
      (description . "Production sites with strict change management")
      (deployment-window . ((days . (saturday sunday))
                            (hours . ((start . 2) (end . 6)))))
      (approval-required . #t)
      (sites . ()))  ; Populated from config/groups/

     ((id . "staging")
      (description . "Staging sites for pre-production testing")
      (deployment-window . #f)  ; Any time
      (approval-required . #f)
      (sites . ()))

     ((id . "development")
      (description . "Development sites")
      (deployment-window . #f)
      (approval-required . #f)
      (sites . ())))

    ;; Shared configuration inheritance
    (config-inheritance
     ;; Base configs applied to all sites
     ((base . "includes/security-headers-strict.ncl")
      (applies-to . all))
     ((base . "includes/php-wordpress-defaults.ncl")
      (applies-to . (tag . "wordpress"))))

    ;; Cross-site dependencies
    (dependencies
     ;; Example: CDN depends on all origin sites
     ;; ((dependent . "cdn-config")
     ;;  (depends-on . (group . "production")))
     )

    ;; DNS zones managed by this control plane
    (dns-zones ())

    ;; External integrations
    (integrations
     ((type . cloudflare)
      (enabled . #f)
      (api-key-ref . "cloudflare-api-key"))
     ((type . google-recaptcha)
      (enabled . #f)
      (site-key-ref . "recaptcha-site-key")
      (secret-key-ref . "recaptcha-secret-key"))
     ((type . dropbox)
      (enabled . #f)
      (app-key-ref . "dropbox-app-key"))
     ((type . google-maps)
      (enabled . #f)
      (api-key-ref . "google-maps-key")))))
