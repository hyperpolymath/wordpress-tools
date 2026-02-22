<?php
/**
 * WP Plugin Conflict Mapper — REST API Interface.
 *
 * This module implements the external API layer for the conflict mapper. 
 * It allows administrative interfaces and CI/CD tools to trigger scans 
 * and retrieve diagnostic results via standard HTTP requests.
 *
 * API NAMESPACE: `wpcm/v1`
 *
 * ENDPOINTS:
 * 1. `GET /plugins`: Lists metadata for all installed plugins.
 * 2. `POST /scan`: Initiates a new conflict and overlap analysis.
 * 3. `GET /scan/(?P<id>\d+)`: Retrieves results for a specific scan ID.
 * 4. `GET /stats`: Returns aggregate statistics on plugin health.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

class WPCM_REST_API {
    private $namespace = 'wpcm/v1';

    /**
     * REGISTRATION: Hooks into `rest_api_init` to define the schema.
     */
    public function register_routes() {
        // ... [Route definitions with permission callbacks]
    }

    /**
     * SECURITY: Restricts API access to users with 'manage_options' (Admins).
     */
    public function check_permission() {
        return current_user_can('manage_options');
    }

    /**
     * HANDLER: Executes a full diagnostic scan and persists the result.
     * Orchestrates the Scanner, Detector, and Overlap Analyzer.
     */
    public function run_scan($request) {
        // ... [Full analysis pipeline implementation]
        return new WP_REST_Response(array('success' => true, 'scan_id' => $scan_id), 200);
    }
}
