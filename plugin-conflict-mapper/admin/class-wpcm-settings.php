<?php
/**
 * WP Plugin Conflict Mapper — Policy and Settings Manager.
 *
 * This module provides a high-level API for managing plugin configuration. 
 * It ensures that settings are correctly prefixed and provides 
 * default values for the diagnostic engine.
 *
 * KEY SETTINGS:
 * - `scan_frequency`: Determines the automated audit interval.
 * - `auto_scan`: Toggles the background conflict detector.
 * - `cleanup_days`: The retention period for historical scan data.
 * - `severity_threshold`: Filters which conflicts trigger admin alerts.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

class WPCM_Settings {

    /**
     * RETRIEVAL: Fetches a configuration value from the WordPress 
     * options table. Prepend the `wpcm_` namespace to all keys.
     */
    public static function get($key, $default = null) {
        return get_option('wpcm_' . $key, $default);
    }

    /**
     * UPDATE: Persists a setting change. Returns true if the value 
     * was successfully updated.
     */
    public static function update($key, $value) {
        return update_option('wpcm_' . $key, $value);
    }

    /**
     * SNAPSHOT: Returns all plugin settings as a single associative array.
     * Useful for the admin dashboard and API export.
     */
    public static function get_all() {
        return array(
            'scan_frequency' => self::get('scan_frequency', 'weekly'),
            'auto_scan' => self::get('auto_scan', 'no'),
            // ... [other settings]
        );
    }
}
