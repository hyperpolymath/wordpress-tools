<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Settings Class
 *
 * Handles plugin settings and configuration
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Settings class
 */
class WPCM_Settings {

    /**
     * Get setting value
     *
     * @param string $key Setting key
     * @param mixed $default Default value
     * @return mixed Setting value
     */
    public static function get($key, $default = null) {
        return get_option('wpcm_' . $key, $default);
    }

    /**
     * Update setting value
     *
     * @param string $key Setting key
     * @param mixed $value Setting value
     * @return bool True on success
     */
    public static function update($key, $value) {
        return update_option('wpcm_' . $key, $value);
    }

    /**
     * Delete setting
     *
     * @param string $key Setting key
     * @return bool True on success
     */
    public static function delete($key) {
        return delete_option('wpcm_' . $key);
    }

    /**
     * Get all settings
     *
     * @return array All settings
     */
    public static function get_all() {
        return array(
            'scan_frequency' => self::get('scan_frequency', 'weekly'),
            'auto_scan' => self::get('auto_scan', 'no'),
            'cleanup_days' => self::get('cleanup_days', 30),
            'email_reports' => self::get('email_reports', 'no'),
            'admin_email' => self::get('admin_email', get_option('admin_email')),
            'severity_threshold' => self::get('severity_threshold', 'medium'),
        );
    }
}
