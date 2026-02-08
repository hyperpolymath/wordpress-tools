#lang info

;; Package information for WP Praxis Introspection System

(define collection "wp-praxis-introspection")

(define version "0.1.0")

(define pkg-desc
  "Recursive introspection and semantic feedback system for WP Praxis symbolic workflows")

(define pkg-authors '("WP Praxis Project"))

(define license 'AGPL-3.0-or-later)

(define deps
  '("base"
    "rackunit-lib"
    "json"
    "db-lib"
    "web-server-lib"
    "plot-lib"
    "graph"
    "data-lib"
    "compatibility-lib"))

(define build-deps
  '("scribble-lib"
    "racket-doc"))

(define scribblings '())

(define racket-launcher-names '("wp-introspect"))

(define racket-launcher-libraries '("cli/introspect.rkt"))
