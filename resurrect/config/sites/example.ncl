# SPDX-License-Identifier: AGPL-3.0-or-later
# Example site configuration

let Site = import "../schema/site.ncl" in

{
  id = "example-production",
  domain = "example.com",
  name = "Example Production Site",
  environment = 'production,
  tags = ["wordpress", "woocommerce", "production"],

  webserver = {
    type = 'nginx,
    ssl = {
      provider = 'letsencrypt,
      hsts = true,
      hsts_max_age = 31536000,
      hsts_include_subdomains = true,
      hsts_preload = false,
      ocsp_stapling = true,
      min_tls_version = "1.2",
    },
    headers = [
      { name = "X-Frame-Options", value = "DENY" },
      { name = "X-Content-Type-Options", value = "nosniff" },
      { name = "Referrer-Policy", value = "strict-origin-when-cross-origin" },
      { name = "Permissions-Policy", value = "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()" },
    ],
    vhost = {
      root = "/var/www/example.com/public",
      server_names = ["www.example.com"],
    },
    gzip = true,
    brotli = true,
    http2 = true,
    http3 = false,
    client_max_body_size = "64M",
  },

  php = {
    version = "8.3",
    memory_limit = "256M",
    max_execution_time = 30,
    upload_max_filesize = "64M",
    post_max_size = "64M",
    display_errors = false,
    log_errors = true,
    timezone = "UTC",
    expose_php = false,
    opcache = {
      enable = true,
      memory = 128,
      validate_timestamps = false,  # Production: no timestamp checking
      jit = true,
      jit_buffer_size = "100M",
    },
    session = {
      handler = 'redis,
      save_path = "tcp://127.0.0.1:6379?database=1",
      cookie_secure = true,
      cookie_httponly = true,
      cookie_samesite = 'Lax,
    },
    pool = {
      pm = 'dynamic,
      max_children = 10,
      start_servers = 3,
      min_spare_servers = 2,
      max_spare_servers = 5,
      max_requests = 500,
    },
    disable_functions = ["exec", "passthru", "shell_exec", "system", "proc_open", "popen"],
  },

  wordpress = {
    multisite = { enabled = false },
    auto_update_core = 'minor,
    auto_update_plugins = false,
    auto_update_themes = false,
    plugins = {
      must_use = ["query-monitor", "wp-mail-smtp"],
      active = ["woocommerce", "yoast-seo", "wordfence", "redis-cache"],
      inactive = [],
      blocklist = ["hello-dolly"],
    },
    themes = {
      active = "storefront-child",
      parent = "storefront",
      installed = ["storefront", "twentytwentyfour"],
    },
    cron = {
      disable_wp_cron = true,
      system_cron_interval = "*/5 * * * *",
    },
    debug = {
      wp_debug = false,
      wp_debug_log = false,
      wp_debug_display = false,
      script_debug = false,
      savequeries = false,
    },
    security = {
      disallow_file_edit = true,
      disallow_file_mods = false,
      force_ssl_admin = true,
      block_xmlrpc = true,
      limit_revisions = 10,
    },
    performance = {
      concatenate_scripts = true,
      compress_scripts = true,
      compress_css = true,
      disable_emojis = true,
      disable_embeds = false,
    },
    wp_memory_limit = "256M",
    wp_max_memory_limit = "512M",
    table_prefix = "wp_ex_",
  },

  database = {
    type = 'mariadb,
    version = "11.4",
    name = "example_production",
    user_ref = "example_db_user",
    password_ref = "example_db_password",
    connection = {
      socket = "/var/run/mysqld/mysqld.sock",
      charset = "utf8mb4",
      collation = "utf8mb4_unicode_ci",
    },
    pool = {
      enabled = true,
      max_connections = 10,
    },
    backup = {
      enabled = true,
      schedule = "0 3 * * *",
      retention_days = 30,
      type = 'mariabackup,
      compress = true,
      encrypt = true,
    },
    tuning = {
      slow_query_log = true,
      long_query_time = 2,
    },
  },

  cache = {
    object_cache = 'redis,
    page_cache = 'none,  # Or 'fastcgi_cache for nginx
    redis = {
      socket = "/var/run/redis/redis.sock",
      database = 0,
      password_ref = "example_redis_password",
      prefix = "example_",
      maxmemory = "256mb",
      maxmemory_policy = 'allkeys-lru,
    },
    cdn = {
      enabled = false,
    },
    browser_cache_ttl = 2592000,
    warm_on_deploy = true,
    cache_bypass_cookies = ["wordpress_logged_in", "woocommerce_cart_hash", "woocommerce_items_in_cart"],
    cache_bypass_paths = ["/wp-admin", "/wp-login.php", "/cart", "/checkout", "/my-account"],
  },

  security = {
    waf = 'modsecurity,
    owasp_crs = {
      enabled = true,
      paranoia_level = 1,
      anomaly_threshold = 5,
      rules_exclude = [],
      paths_exclude = ["/wp-admin/admin-ajax.php"],
    },
    rate_limit = {
      enabled = true,
      requests_per_second = 50,
      burst = 100,
      by = 'ip,
    },
    fail2ban = {
      enabled = true,
      wordpress = {
        enabled = true,
        maxretry = 5,
        findtime = "10m",
        bantime = "1h",
      },
    },
    headers = {
      csp = [
        { directive = "default-src", sources = ["'self'"] },
        { directive = "script-src", sources = ["'self'", "'unsafe-inline'", "https://www.google.com", "https://www.gstatic.com"] },
        { directive = "style-src", sources = ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"] },
        { directive = "img-src", sources = ["'self'", "data:", "https:"] },
        { directive = "font-src", sources = ["'self'", "https://fonts.gstatic.com"] },
        { directive = "connect-src", sources = ["'self'"] },
        { directive = "frame-src", sources = ["https://www.google.com"] },
        { directive = "frame-ancestors", sources = ["'none'"] },
      ],
      csp_report_only = false,
      x_frame_options = 'DENY,
      x_content_type_options = true,
      referrer_policy = "strict-origin-when-cross-origin",
      cross_origin_opener_policy = "same-origin",
    },
    captcha = {
      provider = 'recaptcha_v3,
      site_key_ref = "recaptcha_site_key",
      secret_key_ref = "recaptcha_secret_key",
      score_threshold = 0.5,
      pages = ["login", "register", "comment", "checkout"],
    },
    block_bad_bots = true,
    scan_uploads = true,
  },

  dns = {
    zone = "example.com",
    provider = 'powerdns,
    records = [
      { type = 'A, name = "@", value = "203.0.113.10", ttl = 300 },
      { type = 'AAAA, name = "@", value = "2001:db8::1", ttl = 300 },
      { type = 'CNAME, name = "www", value = "example.com.", ttl = 3600 },
      { type = 'MX, name = "@", value = "mail.example.com.", priority = 10, ttl = 3600 },
      { type = 'TXT, name = "@", value = "v=spf1 include:_spf.google.com ~all", ttl = 3600 },
    ],
    caa = [
      { tag = 'issue, value = "letsencrypt.org" },
      { tag = 'issuewild, value = "letsencrypt.org" },
      { tag = 'iodef, value = "mailto:security@example.com" },
    ],
    dnssec = {
      enabled = true,
      algorithm = 'ECDSAP256SHA256,
    },
    mail_auth = {
      spf = "v=spf1 include:_spf.google.com ~all",
      dkim_selector = "google",
      dmarc = "v=DMARC1; p=reject; rua=mailto:dmarc@example.com",
    },
    hidden_primary = {
      enabled = true,
      notify = true,
    },
  },

  secrets_ref = [
    "example_db_user",
    "example_db_password",
    "example_redis_password",
    "recaptcha_site_key",
    "recaptcha_secret_key",
  ],
} | Site.Site
