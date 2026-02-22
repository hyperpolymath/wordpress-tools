<?php
/**
 * WP Plugin Conflict Mapper — Persistence Layer.
 *
 * This module manages the storage and retrieval of diagnostic scan 
 * results. it uses custom WordPress database tables to maintain a 
 * historical audit trail of plugin compatibility and performance.
 *
 * TABLE SCHEMA:
 * 1. `wpcm_scans`: Metadata for each full scan session (date, counts, types).
 * 2. `wpcm_conflicts`: Granular records of individual architectural clashes.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

class WPCM_Database {
    private $scan_table;
    private $conflicts_table;

    public function __construct() {
        global $wpdb;
        $this->scan_table = $wpdb->prefix . 'wpcm_scans';
        $this->conflicts_table = $wpdb->prefix . 'wpcm_conflicts';
    }

    /**
     * PERSISTENCE: Commits a completed scan to the database. 
     * Uses `maybe_serialize` to store complex PHP arrays within 
     * the `scan_data` LONGTEXT field.
     */
    public function save_scan($scan_data) {
        global $wpdb;
        // ... [Insert logic using $wpdb->prepare]
        return $wpdb->insert_id;
    }

    /**
     * AUDIT: Retrieves a specific scan by its primary key. 
     * Automatically unserializes the result map for the UI.
     */
    public function get_scan($scan_id) {
        // ... [Select logic]
    }

    /**
     * HYGIENE: Wipes scan and conflict records older than a 
     * specific threshold (default 30 days) to prevent table bloat.
     */
    public function cleanup_old_scans($days = 30) {
        // ... [Delete logic with orphan cleanup]
    }
}
