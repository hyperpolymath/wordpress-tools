<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Admin Interface Class
 *
 * Handles WordPress admin interface for the plugin
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Admin class
 */
class WPCM_Admin {

    /**
     * Constructor
     */
    public function __construct() {
        add_action('admin_menu', array($this, 'add_admin_menu'));
        add_action('admin_enqueue_scripts', array($this, 'enqueue_assets'));
        add_action('admin_init', array($this, 'register_settings'));

        // Initialize AJAX handlers
        new WPCM_AJAX();
    }

    /**
     * Add admin menu pages
     *
     * @return void
     */
    public function add_admin_menu() {
        add_menu_page(
            __('Plugin Conflict Mapper', 'wp-plugin-conflict-mapper'),
            __('Conflict Mapper', 'wp-plugin-conflict-mapper'),
            'manage_options',
            'wpcm-dashboard',
            array($this, 'render_dashboard'),
            'dashicons-networking',
            80
        );

        add_submenu_page(
            'wpcm-dashboard',
            __('Dashboard', 'wp-plugin-conflict-mapper'),
            __('Dashboard', 'wp-plugin-conflict-mapper'),
            'manage_options',
            'wpcm-dashboard',
            array($this, 'render_dashboard')
        );

        add_submenu_page(
            'wpcm-dashboard',
            __('Scan Reports', 'wp-plugin-conflict-mapper'),
            __('Reports', 'wp-plugin-conflict-mapper'),
            'manage_options',
            'wpcm-reports',
            array($this, 'render_reports')
        );

        add_submenu_page(
            'wpcm-dashboard',
            __('Plugin Rankings', 'wp-plugin-conflict-mapper'),
            __('Rankings', 'wp-plugin-conflict-mapper'),
            'manage_options',
            'wpcm-rankings',
            array($this, 'render_rankings')
        );

        add_submenu_page(
            'wpcm-dashboard',
            __('Known Conflicts', 'wp-plugin-conflict-mapper'),
            __('Known Conflicts', 'wp-plugin-conflict-mapper'),
            'manage_options',
            'wpcm-known-conflicts',
            array($this, 'render_known_conflicts')
        );

        add_submenu_page(
            'wpcm-dashboard',
            __('Settings', 'wp-plugin-conflict-mapper'),
            __('Settings', 'wp-plugin-conflict-mapper'),
            'manage_options',
            'wpcm-settings',
            array($this, 'render_settings')
        );
    }

    /**
     * Enqueue admin assets
     *
     * @param string $hook Current admin page hook
     * @return void
     */
    public function enqueue_assets($hook) {
        // Only load on our plugin pages
        if (strpos($hook, 'wpcm-') === false && strpos($hook, 'conflict-mapper') === false) {
            return;
        }

        // CSS
        wp_enqueue_style(
            'wpcm-admin',
            WPCM_PLUGIN_URL . 'assets/css/admin.css',
            array(),
            WPCM_VERSION
        );

        // JavaScript
        wp_enqueue_script(
            'wpcm-admin',
            WPCM_PLUGIN_URL . 'assets/js/admin.js',
            array('jquery'),
            WPCM_VERSION,
            true
        );

        wp_localize_script('wpcm-admin', 'wpcmAdmin', array(
            'ajaxUrl' => admin_url('admin-ajax.php'),
            'nonce' => wp_create_nonce('wpcm_ajax_nonce'),
            'strings' => array(
                'scanning' => __('Scanning plugins...', 'wp-plugin-conflict-mapper'),
                'scanComplete' => __('Scan complete!', 'wp-plugin-conflict-mapper'),
                'scanError' => __('Scan failed. Please try again.', 'wp-plugin-conflict-mapper'),
            ),
        ));
    }

    /**
     * Register plugin settings
     *
     * @return void
     */
    public function register_settings() {
        register_setting('wpcm_settings', 'wpcm_scan_frequency');
        register_setting('wpcm_settings', 'wpcm_auto_scan');
        register_setting('wpcm_settings', 'wpcm_cleanup_days');
        register_setting('wpcm_settings', 'wpcm_email_reports');
        register_setting('wpcm_settings', 'wpcm_admin_email');
        register_setting('wpcm_settings', 'wpcm_severity_threshold');
    }

    /**
     * Render dashboard page
     *
     * @return void
     */
    public function render_dashboard() {
        $scanner = new WPCM_Plugin_Scanner();
        $database = new WPCM_Database();

        $plugins = $scanner->get_all_plugins();
        $active_plugins = $scanner->get_active_plugins();
        $stats = $database->get_statistics();

        include WPCM_PLUGIN_DIR . 'admin/views/dashboard.php';
    }

    /**
     * Render reports page
     *
     * @return void
     */
    public function render_reports() {
        $database = new WPCM_Database();
        $scans = $database->get_recent_scans(20);

        include WPCM_PLUGIN_DIR . 'admin/views/reports.php';
    }

    /**
     * Render rankings page
     *
     * @return void
     */
    public function render_rankings() {
        $cache = new WPCM_Cache();

        // Try to get from cache
        $ranked_plugins = $cache->get('plugin_rankings');

        if ($ranked_plugins === false) {
            $scanner = new WPCM_Plugin_Scanner();
            $detector = new WPCM_Conflict_Detector();
            $overlap_analyzer = new WPCM_Overlap_Analyzer();
            $ranking_engine = new WPCM_Ranking_Engine();

            $plugins = $scanner->get_active_plugins();
            $conflicts = $detector->detect_conflicts($plugins);
            $overlaps = $overlap_analyzer->analyze_overlaps($plugins);

            $ranked_plugins = $ranking_engine->rank_plugins($plugins, $conflicts, $overlaps);

            // Cache for 1 hour
            $cache->set('plugin_rankings', $ranked_plugins, 3600);
        }

        include WPCM_PLUGIN_DIR . 'admin/views/rankings.php';
    }

    /**
     * Render known conflicts page
     *
     * @return void
     */
    public function render_known_conflicts() {
        $minimal_scanner = new WPCM_Minimal_Scanner();

        $scan_results = $minimal_scanner->quick_scan(true);
        $db_stats = $minimal_scanner->get_database_stats();
        $recommendations = $minimal_scanner->get_recommendations($scan_results['conflicts']);

        include WPCM_PLUGIN_DIR . 'admin/views/known-conflicts.php';
    }

    /**
     * Render settings page
     *
     * @return void
     */
    public function render_settings() {
        include WPCM_PLUGIN_DIR . 'admin/views/settings.php';
    }
}
