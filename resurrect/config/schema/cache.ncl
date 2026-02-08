# SPDX-License-Identifier: AGPL-3.0-or-later
# Cache configuration schema

{
  ObjectCacheType = [| 'redis, 'memcached, 'apcu, 'file, 'none |],
  PageCacheType = [| 'litespeed, 'varnish, 'fastcgi_cache, 'wp_super_cache, 'w3tc, 'none |],

  RedisConfig = {
    host
      | String
      | default = "127.0.0.1",
    port
      | Number
      | default = 6379,
    socket
      | String
      | optional
      | doc "Unix socket (preferred over TCP)",
    database
      | Number
      | default = 0
      | doc "Redis database number (0-15)",
    password_ref
      | String
      | optional
      | doc "Reference to password in secrets",
    prefix
      | String
      | default = "wp_"
      | doc "Key prefix for namespacing",
    maxmemory
      | String
      | default = "256mb",
    maxmemory_policy
      | [| 'volatile-lru, 'allkeys-lru, 'volatile-lfu, 'allkeys-lfu, 'volatile-random, 'allkeys-random, 'volatile-ttl, 'noeviction |]
      | default = 'allkeys-lru,
    cluster
      | Bool
      | default = false,
    sentinel
      | Bool
      | default = false,
    sentinel_master
      | String
      | optional,
  },

  MemcachedConfig = {
    servers
      | Array String
      | default = ["127.0.0.1:11211"]
      | doc "Server addresses (host:port)",
    persistent
      | Bool
      | default = true,
    binary_protocol
      | Bool
      | default = true,
  },

  VarnishConfig = {
    enabled
      | Bool
      | default = false,
    port
      | Number
      | default = 6081,
    admin_port
      | Number
      | default = 6082,
    memory
      | String
      | default = "256M",
    ttl
      | Number
      | default = 120
      | doc "Default TTL in seconds",
    grace
      | Number
      | default = 300
      | doc "Grace period for stale content",
    purge_acl
      | Array String
      | default = ["127.0.0.1", "::1"]
      | doc "IPs allowed to purge cache",
  },

  FastcgiCacheConfig = {
    enabled
      | Bool
      | default = false,
    path
      | String
      | default = "/var/cache/nginx",
    levels
      | String
      | default = "1:2",
    keys_zone
      | String
      | default = "WORDPRESS:100m",
    max_size
      | String
      | default = "1g",
    inactive
      | String
      | default = "60m",
    bypass_cookies
      | Array String
      | default = ["wordpress_logged_in", "comment_author_", "wp-postpass_"],
  },

  LitespeedCacheConfig = {
    enabled
      | Bool
      | default = true,
    public_ttl
      | Number
      | default = 604800
      | doc "Public cache TTL (seconds)",
    private_ttl
      | Number
      | default = 1800,
    esi
      | Bool
      | default = false
      | doc "Edge Side Includes",
    browser_cache
      | Bool
      | default = true,
    browser_ttl
      | Number
      | default = 604800,
    object_cache
      | Bool
      | default = true
      | doc "Use LiteSpeed as object cache",
    crawler
      | Bool
      | default = true
      | doc "Enable cache crawler",
  },

  CdnConfig = {
    enabled
      | Bool
      | default = false,
    provider
      | [| 'cloudflare, 'bunny, 'fastly, 'keycdn, 'custom |]
      | optional,
    url
      | String
      | optional
      | doc "CDN URL for assets",
    zone_id_ref
      | String
      | optional
      | doc "Reference to zone ID in secrets",
    api_key_ref
      | String
      | optional
      | doc "Reference to API key in secrets",
    purge_on_update
      | Bool
      | default = true,
  },

  Config = {
    # Object cache (sessions, transients, etc.)
    object_cache
      | ObjectCacheType
      | default = 'redis,

    # Page cache
    page_cache
      | PageCacheType
      | default = 'none,

    # Redis settings (if object_cache = redis)
    redis
      | RedisConfig
      | default = {},

    # Memcached settings (if object_cache = memcached)
    memcached
      | MemcachedConfig
      | default = {},

    # Varnish settings (if page_cache = varnish)
    varnish
      | VarnishConfig
      | default = {},

    # FastCGI cache settings (if page_cache = fastcgi_cache)
    fastcgi_cache
      | FastcgiCacheConfig
      | default = {},

    # LiteSpeed cache settings
    litespeed
      | LitespeedCacheConfig
      | default = {},

    # CDN integration
    cdn
      | CdnConfig
      | default = {},

    # Browser caching for static assets
    browser_cache_ttl
      | Number
      | default = 2592000
      | doc "Browser cache TTL for static files (30 days)",

    # Cache warming
    warm_on_deploy
      | Bool
      | default = true
      | doc "Warm cache after deployments",

    # Exclusions
    cache_bypass_cookies
      | Array String
      | default = ["wordpress_logged_in", "woocommerce_cart_hash"]
      | doc "Cookies that bypass cache",
    cache_bypass_paths
      | Array String
      | default = ["/wp-admin", "/wp-login.php", "/cart", "/checkout", "/my-account"]
      | doc "Paths that bypass cache",
  },
}
