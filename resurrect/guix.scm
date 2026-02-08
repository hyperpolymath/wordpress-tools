;; SPDX-License-Identifier: PMPL-1.0-or-later
;; Guix package definition for wp-resurrect (SOCP)

(use-modules (guix packages)
             (guix gexp)
             (guix git-download)
             (guix build-system cargo)
             (guix build-system copy)
             ((guix licenses) #:prefix license:)
             (gnu packages crates-io)
             (gnu packages crates-graphics)
             (gnu packages rust-apps)
             (gnu packages tls)
             (gnu packages pkg-config)
             (gnu packages admin)
             (gnu packages dns)
             (gnu packages guile))

;; Main SOCP TUI package
(define-public socp-tui
  (package
    (name "socp-tui")
    (version "0.1.0")
    (source (local-file "." "socp-source"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs
       (("rust-ratatui" ,rust-ratatui-0.29)
        ("rust-crossterm" ,rust-crossterm-0.28)
        ("rust-tokio" ,rust-tokio-1)
        ("rust-reqwest" ,rust-reqwest-0.12)
        ("rust-serde" ,rust-serde-1)
        ("rust-serde-json" ,rust-serde-json-1)
        ("rust-clap" ,rust-clap-4)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3)
        ("rust-anyhow" ,rust-anyhow-1)
        ("rust-thiserror" ,rust-thiserror-2)
        ("rust-chrono" ,rust-chrono-0.4)
        ("rust-toml" ,rust-toml-0.8))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'chdir
           (lambda _
             (chdir "src/socp-tui"))))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list openssl))
    (home-page "https://github.com/hyperpolymath/wp-resurrect")
    (synopsis "Site Operations Control Plane - TUI Dashboard")
    (description
     "A terminal-based dashboard for managing multiple web sites through
a centralized, security-hardened control plane. Features real-time monitoring,
configuration management, and deployment controls.")
    (license license:agpl3+)))

;; SOCP configuration files
(define-public socp-config
  (package
    (name "socp-config")
    (version "0.1.0")
    (source (local-file "." "socp-config-source"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system copy-build-system)
    (arguments
     `(#:install-plan
       '(("config" "share/socp/config")
         ("salt" "share/socp/salt")
         ("sdp" "share/socp/sdp")
         ("state" "share/socp/state"))))
    (home-page "https://github.com/hyperpolymath/wp-resurrect")
    (synopsis "SOCP configuration files and templates")
    (description
     "Configuration schemas, SaltStack states, SDP configs, and state
management files for the Site Operations Control Plane.")
    (license license:agpl3+)))

;; Development environment
(define-public socp-dev-environment
  (package
    (name "socp-dev-environment")
    (version "0.1.0")
    (source #f)
    (build-system copy-build-system)
    (arguments '(#:builder (mkdir %output)))
    (propagated-inputs
     (list ;; Rust development
           rust
           rust-analyzer

           ;; Salt (Python allowed for SaltStack)
           salt

           ;; DNS
           powerdns

           ;; Guile for state management
           guile-3.0

           ;; Nickel for configuration
           ;; nickel  ; TODO: Package nickel for Guix

           ;; OpenZiti for SDP
           ;; openziti  ; TODO: Package OpenZiti for Guix
           ))
    (home-page "https://github.com/hyperpolymath/wp-resurrect")
    (synopsis "Development environment for SOCP")
    (description "Development dependencies for the Site Operations Control Plane.")
    (license license:agpl3+)))

;; Export for development shell
socp-tui
