<?php
/**
 * WP Plugin Conflict Mapper — AJAX Request Handlers.
 *
 * This module implements the asynchronous backend logic for the admin 
 * interface. it handles the high-latency diagnostic operations (scanning, 
 * analyzing) without blocking the main browser thread.
 *
 * SECURITY:
 * Every handler MUST call `verify_nonce()` to prevent Cross-Site Request 
 * Forgery (CSRF) and verify that the user has `manage_options` permissions.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

class WPCM_AJAX {

    /**
     * REGISTRATION: Hooks into `wp_ajax_wpcm_*` to define the 
     * available async endpoints.
     */
    public function __construct() {
        add_action('wp_ajax_wpcm_run_scan', array($this, 'run_scan'));
        add_action('wp_ajax_wpcm_get_scan', array($this, 'get_scan'));
        // ... [Remaining AJAX hooks]
    }

    /**
     * HANDLER (run_scan): Triggers the full diagnostic pipeline.
     * 1. SCRAPE: Scans active plugins.
     * 2. DETECT: Identifies conflicts and overlaps.
     * 3. RANK: Computes compatibility scores.
     * 4. PERSIST: Saves results to DB and flushes UI cache.
     */
    public function run_scan() {
        if (!$this->verify_nonce()) { return; }
        // ... [Implementation of the scan orchestration]
        wp_send_json_success(array('message' => 'Scan successful'));
    }

    /**
     * HANDLER (analyze_plugin): Performs a deep-dive security and 
     * performance analysis for a specific plugin file.
     */
    public function analyze_plugin() {
        // ... [Implementation using Security_Scanner and Performance_Analyzer]
    }
}
