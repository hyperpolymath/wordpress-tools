<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Cache Class
 *
 * Handles caching using WordPress transients
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Cache class
 */
class WPCM_Cache {

    /**
     * Cache prefix
     *
     * @var string
     */
    private $prefix = 'wpcm_';

    /**
     * Default cache duration (1 hour)
     *
     * @var int
     */
    private $default_expiration = 3600;

    /**
     * Get cached data
     *
     * @param string $key Cache key
     * @return mixed|false Cached data or false if not found
     */
    public function get($key) {
        return get_transient($this->prefix . $key);
    }

    /**
     * Set cached data
     *
     * @param string $key Cache key
     * @param mixed $data Data to cache
     * @param int $expiration Expiration time in seconds
     * @return bool True on success
     */
    public function set($key, $data, $expiration = null) {
        if ($expiration === null) {
            $expiration = $this->default_expiration;
        }

        return set_transient($this->prefix . $key, $data, $expiration);
    }

    /**
     * Delete cached data
     *
     * @param string $key Cache key
     * @return bool True on success
     */
    public function delete($key) {
        return delete_transient($this->prefix . $key);
    }

    /**
     * Clear all plugin caches
     *
     * @return void
     */
    public function clear_all() {
        global $wpdb;

        $wpdb->query(
            $wpdb->prepare(
                "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s",
                $wpdb->esc_like('_transient_' . $this->prefix) . '%'
            )
        );

        $wpdb->query(
            $wpdb->prepare(
                "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s",
                $wpdb->esc_like('_transient_timeout_' . $this->prefix) . '%'
            )
        );
    }

    /**
     * Get or set cached data with callback
     *
     * @param string $key Cache key
     * @param callable $callback Function to generate data if not cached
     * @param int $expiration Expiration time in seconds
     * @return mixed Cached or generated data
     */
    public function remember($key, $callback, $expiration = null) {
        $cached = $this->get($key);

        if ($cached !== false) {
            return $cached;
        }

        $data = call_user_func($callback);
        $this->set($key, $data, $expiration);

        return $data;
    }
}
