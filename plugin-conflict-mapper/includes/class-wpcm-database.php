<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Database Class
 *
 * Handles all database operations for the plugin
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Database class
 */
class WPCM_Database {

    /**
     * Table name for scan results
     *
     * @var string
     */
    private $scan_table;

    /**
     * Table name for conflicts
     *
     * @var string
     */
    private $conflicts_table;

    /**
     * Constructor
     */
    public function __construct() {
        global $wpdb;
        $this->scan_table = $wpdb->prefix . 'wpcm_scans';
        $this->conflicts_table = $wpdb->prefix . 'wpcm_conflicts';
    }

    /**
     * Save scan results
     *
     * @param array $scan_data Scan data to save
     * @return int|false Scan ID or false on failure
     */
    public function save_scan($scan_data) {
        global $wpdb;

        $result = $wpdb->insert(
            $this->scan_table,
            array(
                'scan_date' => current_time('mysql'),
                'plugin_count' => $scan_data['plugin_count'],
                'conflict_count' => $scan_data['conflict_count'],
                'overlap_count' => $scan_data['overlap_count'],
                'scan_data' => maybe_serialize($scan_data['full_data']),
                'scan_type' => $scan_data['scan_type'],
            ),
            array('%s', '%d', '%d', '%d', '%s', '%s')
        );

        if ($result) {
            return $wpdb->insert_id;
        }

        return false;
    }

    /**
     * Get scan by ID
     *
     * @param int $scan_id Scan ID
     * @return object|null Scan data or null
     */
    public function get_scan($scan_id) {
        global $wpdb;

        $scan = $wpdb->get_row(
            $wpdb->prepare(
                "SELECT * FROM {$this->scan_table} WHERE id = %d",
                $scan_id
            )
        );

        if ($scan && !empty($scan->scan_data)) {
            $scan->scan_data = maybe_unserialize($scan->scan_data);
        }

        return $scan;
    }

    /**
     * Get recent scans
     *
     * @param int $limit Number of scans to retrieve
     * @return array Array of scan objects
     */
    public function get_recent_scans($limit = 10) {
        global $wpdb;

        $scans = $wpdb->get_results(
            $wpdb->prepare(
                "SELECT * FROM {$this->scan_table} ORDER BY scan_date DESC LIMIT %d",
                $limit
            )
        );

        return $scans;
    }

    /**
     * Save conflict data
     *
     * @param int $scan_id Scan ID
     * @param array $conflicts Conflicts to save
     * @return bool True on success
     */
    public function save_conflicts($scan_id, $conflicts) {
        global $wpdb;

        foreach ($conflicts as $conflict_type => $conflict_list) {
            foreach ($conflict_list as $conflict) {
                $wpdb->insert(
                    $this->conflicts_table,
                    array(
                        'scan_id' => $scan_id,
                        'conflict_type' => $conflict_type,
                        'severity' => isset($conflict['severity']) ? $conflict['severity'] : 'low',
                        'affected_plugins' => maybe_serialize($conflict['plugins']),
                        'conflict_data' => maybe_serialize($conflict),
                        'created_at' => current_time('mysql'),
                    ),
                    array('%d', '%s', '%s', '%s', '%s', '%s')
                );
            }
        }

        return true;
    }

    /**
     * Get conflicts for a scan
     *
     * @param int $scan_id Scan ID
     * @return array Array of conflicts
     */
    public function get_scan_conflicts($scan_id) {
        global $wpdb;

        $conflicts = $wpdb->get_results(
            $wpdb->prepare(
                "SELECT * FROM {$this->conflicts_table} WHERE scan_id = %d ORDER BY severity DESC",
                $scan_id
            )
        );

        foreach ($conflicts as $conflict) {
            $conflict->affected_plugins = maybe_unserialize($conflict->affected_plugins);
            $conflict->conflict_data = maybe_unserialize($conflict->conflict_data);
        }

        return $conflicts;
    }

    /**
     * Delete old scans
     *
     * @param int $days Number of days to keep
     * @return int Number of deleted scans
     */
    public function cleanup_old_scans($days = 30) {
        global $wpdb;

        $result = $wpdb->query(
            $wpdb->prepare(
                "DELETE FROM {$this->scan_table} WHERE scan_date < DATE_SUB(NOW(), INTERVAL %d DAY)",
                $days
            )
        );

        // Also clean up orphaned conflicts
        $wpdb->query(
            "DELETE FROM {$this->conflicts_table}
             WHERE scan_id NOT IN (SELECT id FROM {$this->scan_table})"
        );

        return $result;
    }

    /**
     * Get scan statistics
     *
     * @return array Statistics data
     */
    public function get_statistics() {
        global $wpdb;

        $stats = array();

        // Total scans
        $stats['total_scans'] = $wpdb->get_var(
            "SELECT COUNT(*) FROM {$this->scan_table}"
        );

        // Average conflicts per scan
        $stats['avg_conflicts'] = $wpdb->get_var(
            "SELECT AVG(conflict_count) FROM {$this->scan_table}"
        );

        // Last scan date
        $stats['last_scan'] = $wpdb->get_var(
            "SELECT scan_date FROM {$this->scan_table} ORDER BY scan_date DESC LIMIT 1"
        );

        // High severity conflicts
        $stats['high_severity_conflicts'] = $wpdb->get_var(
            "SELECT COUNT(*) FROM {$this->conflicts_table} WHERE severity = 'high'"
        );

        return $stats;
    }
}
