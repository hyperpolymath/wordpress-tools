# SPDX-License-Identifier: AGPL-3.0-or-later
# Site schema definition for SOCP

let Webserver = import "webserver.ncl" in
let Php = import "php.ncl" in
let Wordpress = import "wordpress.ncl" in
let Database = import "database.ncl" in
let Cache = import "cache.ncl" in
let Security = import "security.ncl" in
let Dns = import "dns.ncl" in

{
  Site = {
    # Required fields
    id
      | String
      | doc "Unique site identifier (lowercase, alphanumeric, hyphens)",
    domain
      | String
      | doc "Primary domain for the site",

    # Optional display name
    name
      | String
      | optional
      | doc "Human-readable site name",

    # Component configurations
    webserver
      | Webserver.Config
      | doc "Web server configuration",

    php
      | Php.Config
      | optional
      | doc "PHP configuration (if applicable)",

    wordpress
      | Wordpress.Config
      | optional
      | doc "WordPress-specific configuration",

    database
      | Database.Config
      | optional
      | doc "Database configuration",

    cache
      | Cache.Config
      | optional
      | doc "Caching configuration",

    security
      | Security.Config
      | doc "Security configuration",

    dns
      | Dns.Config
      | optional
      | doc "DNS record configuration",

    # Secret references (actual values in Salt pillars)
    secrets_ref
      | Array String
      | default = []
      | doc "List of secret names this site requires",

    # Tags for grouping and filtering
    tags
      | Array String
      | default = []
      | doc "Tags for categorization",

    # Environment designation
    environment
      | [| 'production, 'staging, 'development, 'testing |]
      | default = 'production
      | doc "Deployment environment",

    # Enabled/disabled state
    enabled
      | Bool
      | default = true
      | doc "Whether the site is actively managed",
  },
}
