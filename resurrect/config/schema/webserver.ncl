# SPDX-License-Identifier: AGPL-3.0-or-later
# Web server configuration schema

{
  ServerType = [| 'nginx, 'apache, 'litespeed, 'openlitespeed, 'caddy |],

  SslProvider = [| 'letsencrypt, 'zerossl, 'buypass, 'manual |],

  SslConfig = {
    provider
      | SslProvider
      | default = 'letsencrypt,
    hsts
      | Bool
      | default = true
      | doc "Enable HTTP Strict Transport Security",
    hsts_max_age
      | Number
      | default = 31536000
      | doc "HSTS max-age in seconds (default: 1 year)",
    hsts_include_subdomains
      | Bool
      | default = true,
    hsts_preload
      | Bool
      | default = false
      | doc "Include in HSTS preload list (requires careful consideration)",
    ocsp_stapling
      | Bool
      | default = true,
    min_tls_version
      | String
      | default = "1.2"
      | doc "Minimum TLS version (1.2 or 1.3)",
    certificate_path
      | String
      | optional
      | doc "Path to certificate (for manual provider)",
    key_path
      | String
      | optional
      | doc "Path to private key (for manual provider)",
  },

  HeaderValue = {
    name | String,
    value | String,
  },

  VhostConfig = {
    listen_port
      | Number
      | default = 443,
    listen_ipv4
      | Bool
      | default = true,
    listen_ipv6
      | Bool
      | default = true,
    server_names
      | Array String
      | optional
      | doc "Additional server names beyond primary domain",
    root
      | String
      | optional
      | doc "Document root path",
    index_files
      | Array String
      | default = ["index.php", "index.html"],
  },

  Config = {
    type
      | ServerType
      | doc "Web server software",

    ssl
      | SslConfig
      | default = {}
      | doc "SSL/TLS configuration",

    headers
      | Array HeaderValue
      | default = []
      | doc "Custom HTTP headers",

    vhost
      | VhostConfig
      | default = {}
      | doc "Virtual host configuration",

    gzip
      | Bool
      | default = true,

    brotli
      | Bool
      | default = true,

    http2
      | Bool
      | default = true,

    http3
      | Bool
      | default = false
      | doc "HTTP/3 (QUIC) support",

    client_max_body_size
      | String
      | default = "64M",

    keepalive_timeout
      | Number
      | default = 65,

    worker_connections
      | Number
      | optional
      | doc "Max connections per worker (nginx)",

    # LiteSpeed/OpenLiteSpeed specific
    lscache
      | Bool
      | default = false
      | doc "Enable LiteSpeed Cache module",

    # Apache specific
    mpm
      | [| 'event, 'worker, 'prefork |]
      | optional
      | doc "Apache MPM module",
  },
}
