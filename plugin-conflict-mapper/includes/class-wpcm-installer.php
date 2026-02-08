<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Installer Class
 *
 * Handles plugin installation and database setup
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Installer class
 */
class WPCM_Installer {

    /**
     * Run installation
     *
     * @return void
     */
    public static function activate() {
        self::create_tables();
        self::set_default_options();
        self::schedule_cleanup();

        // Set installed version
        update_option('wpcm_version', WPCM_VERSION);
        update_option('wpcm_installed_date', current_time('mysql'));
    }

    /**
     * Create database tables
     *
     * @return void
     */
    private static function create_tables() {
        global $wpdb;

        $charset_collate = $wpdb->get_charset_collate();

        // Scans table
        $scans_table = $wpdb->prefix . 'wpcm_scans';
        $sql_scans = "CREATE TABLE IF NOT EXISTS {$scans_table} (
            id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            scan_date datetime NOT NULL,
            plugin_count int(11) NOT NULL DEFAULT 0,
            conflict_count int(11) NOT NULL DEFAULT 0,
            overlap_count int(11) NOT NULL DEFAULT 0,
            scan_data longtext,
            scan_type varchar(50) NOT NULL DEFAULT 'manual',
            PRIMARY KEY (id),
            KEY scan_date (scan_date),
            KEY scan_type (scan_type)
        ) {$charset_collate};";

        // Conflicts table
        $conflicts_table = $wpdb->prefix . 'wpcm_conflicts';
        $sql_conflicts = "CREATE TABLE IF NOT EXISTS {$conflicts_table} (
            id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            scan_id bigint(20) UNSIGNED NOT NULL,
            conflict_type varchar(50) NOT NULL,
            severity varchar(20) NOT NULL DEFAULT 'low',
            affected_plugins text,
            conflict_data longtext,
            created_at datetime NOT NULL,
            PRIMARY KEY (id),
            KEY scan_id (scan_id),
            KEY severity (severity),
            KEY conflict_type (conflict_type)
        ) {$charset_collate};";

        require_once ABSPATH . 'wp-admin/includes/upgrade.php';
        dbDelta($sql_scans);
        dbDelta($sql_conflicts);
    }

    /**
     * Set default plugin options
     *
     * @return void
     */
    private static function set_default_options() {
        $defaults = array(
            'wpcm_scan_frequency' => 'weekly',
            'wpcm_auto_scan' => 'no',
            'wpcm_cleanup_days' => 30,
            'wpcm_email_reports' => 'no',
            'wpcm_admin_email' => get_option('admin_email'),
            'wpcm_severity_threshold' => 'medium',
        );

        foreach ($defaults as $key => $value) {
            if (get_option($key) === false) {
                add_option($key, $value);
            }
        }
    }

    /**
     * Schedule cleanup tasks
     *
     * @return void
     */
    private static function schedule_cleanup() {
        if (!wp_next_scheduled('wpcm_cleanup_old_scans')) {
            wp_schedule_event(time(), 'daily', 'wpcm_cleanup_old_scans');
        }
    }
}
