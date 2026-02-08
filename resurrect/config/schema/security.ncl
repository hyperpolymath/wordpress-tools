# SPDX-License-Identifier: AGPL-3.0-or-later
# Security configuration schema

{
  WafType = [| 'modsecurity, 'naxsi, 'comodo, 'none |],

  RateLimitConfig = {
    enabled
      | Bool
      | default = true,
    requests_per_second
      | Number
      | default = 50,
    burst
      | Number
      | default = 100,
    by
      | [| 'ip, 'user, 'session |]
      | default = 'ip,
    paths
      | Array String
      | default = []
      | doc "Specific paths to rate limit (empty = all)",
  },

  Fail2banJail = {
    enabled
      | Bool
      | default = true,
    maxretry
      | Number
      | default = 5,
    findtime
      | String
      | default = "10m",
    bantime
      | String
      | default = "1h",
    action
      | [| 'iptables, 'iptables-multiport, 'cloudflare, 'route |]
      | default = 'iptables-multiport,
  },

  Fail2banConfig = {
    enabled
      | Bool
      | default = true,
    wordpress
      | Fail2banJail
      | default = {}
      | doc "WordPress login failures",
    ssh
      | Fail2banJail
      | default = {}
      | doc "SSH brute force",
    nginx_limit_req
      | Fail2banJail
      | default = {}
      | doc "Rate limit violations",
    recidive
      | Fail2banJail
      | default = { maxretry = 3, bantime = "1w" }
      | doc "Repeat offenders",
  },

  CspDirective = {
    directive | String,
    sources | Array String,
  },

  HeadersConfig = {
    # Content Security Policy
    csp
      | Array CspDirective
      | default = [
          { directive = "default-src", sources = ["'self'"] },
          { directive = "script-src", sources = ["'self'"] },
          { directive = "style-src", sources = ["'self'", "'unsafe-inline'"] },
          { directive = "img-src", sources = ["'self'", "data:", "https:"] },
          { directive = "font-src", sources = ["'self'"] },
          { directive = "connect-src", sources = ["'self'"] },
          { directive = "frame-ancestors", sources = ["'none'"] },
          { directive = "base-uri", sources = ["'self'"] },
          { directive = "form-action", sources = ["'self'"] },
        ],
    csp_report_only
      | Bool
      | default = false,
    csp_report_uri
      | String
      | optional,

    # Other security headers
    x_frame_options
      | [| 'DENY, 'SAMEORIGIN, 'disabled |]
      | default = 'DENY,
    x_content_type_options
      | Bool
      | default = true
      | doc "Send X-Content-Type-Options: nosniff",
    x_xss_protection
      | Bool
      | default = false
      | doc "Deprecated, but some scanners expect it",
    referrer_policy
      | String
      | default = "strict-origin-when-cross-origin",
    permissions_policy
      | String
      | default = "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()",

    # Cross-Origin policies
    cross_origin_embedder_policy
      | String
      | optional,
    cross_origin_opener_policy
      | String
      | default = "same-origin",
    cross_origin_resource_policy
      | String
      | default = "same-origin",
  },

  OwaspCrsConfig = {
    enabled
      | Bool
      | default = true,
    paranoia_level
      | Number
      | default = 1
      | doc "1-4, higher = more strict but more false positives",
    anomaly_threshold
      | Number
      | default = 5
      | doc "Score threshold for blocking",
    rules_exclude
      | Array Number
      | default = []
      | doc "Rule IDs to disable",
    paths_exclude
      | Array String
      | default = []
      | doc "Paths to exclude from WAF",
  },

  CaptchaConfig = {
    provider
      | [| 'recaptcha_v2, 'recaptcha_v3, 'hcaptcha, 'turnstile, 'none |]
      | default = 'none,
    site_key_ref
      | String
      | optional
      | doc "Secret reference for site key",
    secret_key_ref
      | String
      | optional
      | doc "Secret reference for secret key",
    score_threshold
      | Number
      | default = 0.5
      | doc "For v3/Turnstile: minimum score to pass",
    pages
      | Array String
      | default = ["login", "register", "comment"]
      | doc "Pages to protect",
  },

  Config = {
    # WAF
    waf
      | WafType
      | default = 'modsecurity,
    owasp_crs
      | OwaspCrsConfig
      | default = {},

    # Rate limiting
    rate_limit
      | RateLimitConfig
      | default = {},

    # Fail2ban
    fail2ban
      | Fail2banConfig
      | default = {},

    # Security headers
    headers
      | HeadersConfig
      | default = {},

    # CAPTCHA
    captcha
      | CaptchaConfig
      | default = {},

    # IP allowlist/blocklist
    ip_allowlist
      | Array String
      | default = []
      | doc "IPs that bypass security checks",
    ip_blocklist
      | Array String
      | default = []
      | doc "IPs to always block",

    # Geographic blocking
    geo_block
      | Array String
      | default = []
      | doc "Country codes to block (ISO 3166-1 alpha-2)",
    geo_allow
      | Array String
      | default = []
      | doc "Only allow these countries (empty = allow all)",

    # Bot protection
    block_bad_bots
      | Bool
      | default = true,
    bot_allowlist
      | Array String
      | default = ["Googlebot", "Bingbot", "DuckDuckBot"]
      | doc "Bots to always allow",

    # File upload security
    blocked_extensions
      | Array String
      | default = [".php", ".phtml", ".php3", ".php4", ".php5", ".phps", ".phar", ".exe", ".sh", ".bat", ".cmd"]
      | doc "File extensions to block in uploads",
    scan_uploads
      | Bool
      | default = true
      | doc "Scan uploads with ClamAV",
  },
}
