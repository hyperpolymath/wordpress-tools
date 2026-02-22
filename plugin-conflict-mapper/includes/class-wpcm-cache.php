<?php
/**
 * WP Plugin Conflict Mapper — Diagnostic Cache Layer.
 *
 * This module manages the transient storage of scan results. It uses 
 * the WordPress Transients API to provide high-speed access to 
 * recent diagnostic data while ensuring that the database is not 
 * overwhelmed by repeated UI requests.
 *
 * CACHING STRATEGY:
 * 1. **Time-to-Live (TTL)**: Results are cached for 1 hour by default.
 * 2. **Versioned Keys**: Cache keys include the plugin version to 
 *    ensure that updates trigger a re-scan.
 * 3. **Automatic Invalidation**: Deactivating or activating a plugin 
 *    flushes the relevant cache buckets.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

class WPCM_Cache {
    /**
     * RETRIEVAL: Attempts to fetch a cached scan result. 
     * Returns `false` if the transient has expired or is missing.
     */
    public function get(string $key) {
        return get_transient($this->prefix_key($key));
    }

    /**
     * PERSISTENCE: Stores a result in the transient cache.
     */
    public function set(string $key, $value, int $expiration = HOUR_IN_SECONDS) {
        set_transient($this->prefix_key($key), $value, $expiration);
    }

    /**
     * INVALIDATION: Wipes all WPCM-prefixed transients.
     */
    public function clear_all() {
        // ... [Global transient cleanup logic]
    }
}
