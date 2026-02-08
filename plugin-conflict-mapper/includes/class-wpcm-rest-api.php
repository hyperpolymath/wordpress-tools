<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * REST API Class
 *
 * Provides REST API endpoints for external access
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_REST_API class
 */
class WPCM_REST_API {

    /**
     * API namespace
     *
     * @var string
     */
    private $namespace = 'wpcm/v1';

    /**
     * Initialize REST API
     *
     * @return void
     */
    public function init() {
        add_action('rest_api_init', array($this, 'register_routes'));
    }

    /**
     * Register REST API routes
     *
     * @return void
     */
    public function register_routes() {
        // Get all plugins
        register_rest_route($this->namespace, '/plugins', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_plugins'),
            'permission_callback' => array($this, 'check_permission'),
        ));

        // Scan for conflicts
        register_rest_route($this->namespace, '/scan', array(
            'methods' => 'POST',
            'callback' => array($this, 'run_scan'),
            'permission_callback' => array($this, 'check_permission'),
        ));

        // Get scan results
        register_rest_route($this->namespace, '/scan/(?P<id>\d+)', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_scan'),
            'permission_callback' => array($this, 'check_permission'),
            'args' => array(
                'id' => array(
                    'required' => true,
                    'type' => 'integer',
                ),
            ),
        ));

        // Get recent scans
        register_rest_route($this->namespace, '/scans', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_scans'),
            'permission_callback' => array($this, 'check_permission'),
        ));

        // Get statistics
        register_rest_route($this->namespace, '/stats', array(
            'methods' => 'GET',
            'callback' => array($this, 'get_stats'),
            'permission_callback' => array($this, 'check_permission'),
        ));
    }

    /**
     * Check API permission
     *
     * @return bool True if user has permission
     */
    public function check_permission() {
        return current_user_can('manage_options');
    }

    /**
     * Get all plugins endpoint
     *
     * @param WP_REST_Request $request Request object
     * @return WP_REST_Response Response object
     */
    public function get_plugins($request) {
        $scanner = new WPCM_Plugin_Scanner();
        $plugins = $scanner->get_all_plugins();

        return new WP_REST_Response(array(
            'success' => true,
            'data' => $plugins,
            'count' => count($plugins),
        ), 200);
    }

    /**
     * Run scan endpoint
     *
     * @param WP_REST_Request $request Request object
     * @return WP_REST_Response Response object
     */
    public function run_scan($request) {
        $scanner = new WPCM_Plugin_Scanner();
        $detector = new WPCM_Conflict_Detector();
        $overlap_analyzer = new WPCM_Overlap_Analyzer();

        $plugins = $scanner->get_active_plugins();
        $conflicts = $detector->detect_conflicts($plugins);
        $overlaps = $overlap_analyzer->analyze_overlaps($plugins);

        $scan_data = array(
            'plugin_count' => count($plugins),
            'conflict_count' => $this->count_conflicts($conflicts),
            'overlap_count' => count($overlaps),
            'scan_type' => 'api',
            'full_data' => array(
                'plugins' => $plugins,
                'conflicts' => $conflicts,
                'overlaps' => $overlaps,
            ),
        );

        $database = new WPCM_Database();
        $scan_id = $database->save_scan($scan_data);

        if ($scan_id) {
            $database->save_conflicts($scan_id, $conflicts);

            return new WP_REST_Response(array(
                'success' => true,
                'scan_id' => $scan_id,
                'summary' => array(
                    'plugins' => $scan_data['plugin_count'],
                    'conflicts' => $scan_data['conflict_count'],
                    'overlaps' => $scan_data['overlap_count'],
                ),
            ), 200);
        }

        return new WP_REST_Response(array(
            'success' => false,
            'message' => 'Failed to save scan results',
        ), 500);
    }

    /**
     * Get scan endpoint
     *
     * @param WP_REST_Request $request Request object
     * @return WP_REST_Response Response object
     */
    public function get_scan($request) {
        $scan_id = $request->get_param('id');
        $database = new WPCM_Database();
        $scan = $database->get_scan($scan_id);

        if ($scan) {
            return new WP_REST_Response(array(
                'success' => true,
                'data' => $scan,
            ), 200);
        }

        return new WP_REST_Response(array(
            'success' => false,
            'message' => 'Scan not found',
        ), 404);
    }

    /**
     * Get recent scans endpoint
     *
     * @param WP_REST_Request $request Request object
     * @return WP_REST_Response Response object
     */
    public function get_scans($request): WP_REST_Response {
        $limit_param = $request->get_param('limit');
        $limit = $limit_param ? absint($limit_param) : 10;
        $limit = min($limit, 100); // Cap at 100 for performance

        $database = new WPCM_Database();
        $scans = $database->get_recent_scans($limit);

        return new WP_REST_Response(array(
            'success' => true,
            'data' => $scans,
            'count' => count($scans),
        ), 200);
    }

    /**
     * Get statistics endpoint
     *
     * @param WP_REST_Request $request Request object
     * @return WP_REST_Response Response object
     */
    public function get_stats($request) {
        $database = new WPCM_Database();
        $stats = $database->get_statistics();

        return new WP_REST_Response(array(
            'success' => true,
            'data' => $stats,
        ), 200);
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
