<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * AJAX Handlers Class
 *
 * Handles all AJAX requests from the admin interface
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_AJAX class
 */
class WPCM_AJAX {

    /**
     * Constructor
     */
    public function __construct() {
        add_action('wp_ajax_wpcm_run_scan', array($this, 'run_scan'));
        add_action('wp_ajax_wpcm_get_scan', array($this, 'get_scan'));
        add_action('wp_ajax_wpcm_export_report', array($this, 'export_report'));
        add_action('wp_ajax_wpcm_delete_scan', array($this, 'delete_scan'));
        add_action('wp_ajax_wpcm_clear_cache', array($this, 'clear_cache'));
        add_action('wp_ajax_wpcm_analyze_plugin', array($this, 'analyze_plugin'));
    }

    /**
     * Verify AJAX nonce
     *
     * @return bool True if valid
     */
    private function verify_nonce() {
        if (!check_ajax_referer('wpcm_ajax_nonce', 'nonce', false)) {
            wp_send_json_error(array(
                'message' => __('Security check failed', 'wp-plugin-conflict-mapper'),
            ));
            return false;
        }

        if (!current_user_can('manage_options')) {
            wp_send_json_error(array(
                'message' => __('Insufficient permissions', 'wp-plugin-conflict-mapper'),
            ));
            return false;
        }

        return true;
    }

    /**
     * Run conflict scan via AJAX
     *
     * @return void
     */
    public function run_scan() {
        $this->verify_nonce();

        try {
            $scanner = new WPCM_Plugin_Scanner();
            $detector = new WPCM_Conflict_Detector();
            $overlap_analyzer = new WPCM_Overlap_Analyzer();
            $ranking_engine = new WPCM_Ranking_Engine();

            $plugins = $scanner->get_active_plugins();
            $conflicts = $detector->detect_conflicts($plugins);
            $overlaps = $overlap_analyzer->analyze_overlaps($plugins);
            $ranked = $ranking_engine->rank_plugins($plugins, $conflicts, $overlaps);

            $scan_data = array(
                'plugin_count' => count($plugins),
                'conflict_count' => $this->count_conflicts($conflicts),
                'overlap_count' => count($overlaps),
                'scan_type' => 'ajax',
                'full_data' => array(
                    'plugins' => $plugins,
                    'conflicts' => $conflicts,
                    'overlaps' => $overlaps,
                    'ranked' => $ranked,
                ),
            );

            $database = new WPCM_Database();
            $scan_id = $database->save_scan($scan_data);
            $database->save_conflicts($scan_id, $conflicts);

            // Clear rankings cache
            $cache = new WPCM_Cache();
            $cache->delete('plugin_rankings');

            wp_send_json_success(array(
                'scan_id' => $scan_id,
                'summary' => array(
                    'plugins' => $scan_data['plugin_count'],
                    'conflicts' => $scan_data['conflict_count'],
                    'overlaps' => $scan_data['overlap_count'],
                ),
                'conflicts' => $conflicts,
                'overlaps' => $overlaps,
                'message' => __('Scan completed successfully', 'wp-plugin-conflict-mapper'),
            ));
        } catch (Exception $e) {
            wp_send_json_error(array(
                'message' => $e->getMessage(),
            ));
        }
    }

    /**
     * Get scan results via AJAX
     *
     * @return void
     */
    public function get_scan() {
        $this->verify_nonce();

        $scan_id = isset($_POST['scan_id']) ? absint($_POST['scan_id']) : 0;

        if (!$scan_id) {
            wp_send_json_error(array(
                'message' => __('Invalid scan ID', 'wp-plugin-conflict-mapper'),
            ));
        }

        $database = new WPCM_Database();
        $scan = $database->get_scan($scan_id);

        if ($scan) {
            $conflicts = $database->get_scan_conflicts($scan_id);

            wp_send_json_success(array(
                'scan' => $scan,
                'conflicts' => $conflicts,
            ));
        } else {
            wp_send_json_error(array(
                'message' => __('Scan not found', 'wp-plugin-conflict-mapper'),
            ));
        }
    }

    /**
     * Export report via AJAX
     *
     * @return void
     */
    public function export_report() {
        $this->verify_nonce();

        $scan_id = isset($_POST['scan_id']) ? absint($_POST['scan_id']) : 0;
        $format = isset($_POST['format']) ? sanitize_text_field($_POST['format']) : 'json';

        if (!$scan_id) {
            wp_send_json_error(array(
                'message' => __('Invalid scan ID', 'wp-plugin-conflict-mapper'),
            ));
        }

        $database = new WPCM_Database();
        $scan = $database->get_scan($scan_id);

        if (!$scan) {
            wp_send_json_error(array(
                'message' => __('Scan not found', 'wp-plugin-conflict-mapper'),
            ));
        }

        $conflicts = $database->get_scan_conflicts($scan_id);

        $export_data = array(
            'scan_id' => $scan->id,
            'scan_date' => $scan->scan_date,
            'plugin_count' => $scan->plugin_count,
            'conflict_count' => $scan->conflict_count,
            'overlap_count' => $scan->overlap_count,
            'conflicts' => $conflicts,
        );

        if ($format === 'csv') {
            $csv_data = $this->generate_csv($export_data);
            wp_send_json_success(array(
                'data' => $csv_data,
                'filename' => 'conflict-scan-' . $scan_id . '.csv',
            ));
        } else {
            wp_send_json_success(array(
                'data' => wp_json_encode($export_data, JSON_PRETTY_PRINT),
                'filename' => 'conflict-scan-' . $scan_id . '.json',
            ));
        }
    }

    /**
     * Delete scan via AJAX
     *
     * @return void
     */
    public function delete_scan() {
        $this->verify_nonce();

        $scan_id = isset($_POST['scan_id']) ? absint($_POST['scan_id']) : 0;

        if (!$scan_id) {
            wp_send_json_error(array(
                'message' => __('Invalid scan ID', 'wp-plugin-conflict-mapper'),
            ));
        }

        global $wpdb;
        $scans_table = $wpdb->prefix . 'wpcm_scans';
        $conflicts_table = $wpdb->prefix . 'wpcm_conflicts';

        // Delete conflicts first
        $wpdb->delete($conflicts_table, array('scan_id' => $scan_id), array('%d'));

        // Delete scan
        $result = $wpdb->delete($scans_table, array('id' => $scan_id), array('%d'));

        if ($result) {
            wp_send_json_success(array(
                'message' => __('Scan deleted successfully', 'wp-plugin-conflict-mapper'),
            ));
        } else {
            wp_send_json_error(array(
                'message' => __('Failed to delete scan', 'wp-plugin-conflict-mapper'),
            ));
        }
    }

    /**
     * Clear cache via AJAX
     *
     * @return void
     */
    public function clear_cache() {
        $this->verify_nonce();

        $cache = new WPCM_Cache();
        $cache->clear_all();

        wp_send_json_success(array(
            'message' => __('Cache cleared successfully', 'wp-plugin-conflict-mapper'),
        ));
    }

    /**
     * Analyze specific plugin via AJAX
     *
     * @return void
     */
    public function analyze_plugin() {
        $this->verify_nonce();

        $plugin_file = isset($_POST['plugin_file']) ? sanitize_text_field($_POST['plugin_file']) : '';

        if (!$plugin_file) {
            wp_send_json_error(array(
                'message' => __('Invalid plugin file', 'wp-plugin-conflict-mapper'),
            ));
        }

        $security_scanner = new WPCM_Security_Scanner();
        $perf_analyzer = new WPCM_Performance_Analyzer();

        $security_report = $security_scanner->scan_plugin($plugin_file);
        $perf_analysis = $perf_analyzer->analyze_plugin($plugin_file);
        $perf_report = $perf_analyzer->generate_report($perf_analysis);

        wp_send_json_success(array(
            'security' => $security_report,
            'performance' => $perf_report,
        ));
    }

    /**
     * Generate CSV from export data
     *
     * @param array $data Export data
     * @return string CSV content
     */
    private function generate_csv($data) {
        $csv = "Plugin Conflict Mapper - Scan Report\n";
        $csv .= "Scan ID:,{$data['scan_id']}\n";
        $csv .= "Scan Date:,{$data['scan_date']}\n";
        $csv .= "Total Plugins:,{$data['plugin_count']}\n";
        $csv .= "Total Conflicts:,{$data['conflict_count']}\n";
        $csv .= "Total Overlaps:,{$data['overlap_count']}\n\n";

        $csv .= "Conflicts:\n";
        $csv .= "Type,Severity,Affected Plugins\n";

        foreach ($data['conflicts'] as $conflict) {
            $plugins = implode(' | ', maybe_unserialize($conflict->affected_plugins));
            $csv .= "\"{$conflict->conflict_type}\",\"{$conflict->severity}\",\"{$plugins}\"\n";
        }

        return $csv;
    }

    /**
     * Count total conflicts
     *
     * @param array $conflicts Conflicts array
     * @return int Total count
     */
    private function count_conflicts($conflicts) {
        $total = 0;
        foreach ($conflicts as $conflict_list) {
            $total += count($conflict_list);
        }
        return $total;
    }
}
