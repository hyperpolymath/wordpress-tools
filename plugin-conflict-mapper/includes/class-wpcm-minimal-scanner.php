<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Minimal Scanner Class
 *
 * Lightweight conflict scanner using known conflicts database.
 * Provides fast conflict detection without deep code analysis.
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.3.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Minimal_Scanner class
 *
 * Scans installed plugins against a curated database of known conflicts.
 */
class WPCM_Minimal_Scanner {

    /**
     * Known conflicts database
     *
     * @var array
     */
    private array $known_conflicts = array();

    /**
     * Plugin slug mapping cache
     *
     * @var array
     */
    private array $plugin_slugs = array();

    /**
     * Constructor
     *
     * @param string|null $data_file Optional path to known conflicts data file
     */
    public function __construct(?string $data_file = null) {
        $this->load_known_conflicts($data_file);
    }

    /**
     * Load known conflicts database
     *
     * @param string|null $data_file Path to data file
     * @return void
     */
    private function load_known_conflicts(?string $data_file = null): void {
        if ($data_file === null) {
            $data_file = dirname(__DIR__) . '/data/known-conflicts.php';
        }

        if (file_exists($data_file)) {
            $this->known_conflicts = include $data_file;
        }
    }

    /**
     * Get all known conflicts
     *
     * @return array Known conflicts database
     */
    public function get_known_conflicts(): array {
        return $this->known_conflicts;
    }

    /**
     * Get installed plugin slugs
     *
     * @return array Array of plugin slugs
     */
    public function get_installed_plugin_slugs(): array {
        if (!empty($this->plugin_slugs)) {
            return $this->plugin_slugs;
        }

        if (!function_exists('get_plugins')) {
            require_once ABSPATH . 'wp-admin/includes/plugin.php';
        }

        $plugins = get_plugins();
        $active_plugins = get_option('active_plugins', array());

        foreach ($plugins as $plugin_file => $plugin_data) {
            $slug = $this->extract_plugin_slug($plugin_file, $plugin_data);
            $this->plugin_slugs[$slug] = array(
                'file'      => $plugin_file,
                'name'      => $plugin_data['Name'],
                'version'   => $plugin_data['Version'],
                'is_active' => in_array($plugin_file, $active_plugins, true),
            );
        }

        return $this->plugin_slugs;
    }

    /**
     * Extract plugin slug from file path or data
     *
     * @param string $plugin_file Plugin file path
     * @param array  $plugin_data Plugin data array
     * @return string Plugin slug
     */
    private function extract_plugin_slug(string $plugin_file, array $plugin_data): string {
        // Use text domain if available
        if (!empty($plugin_data['TextDomain'])) {
            return $plugin_data['TextDomain'];
        }

        // Extract from directory name
        $parts = explode('/', $plugin_file);
        if (count($parts) > 1) {
            return $parts[0];
        }

        // Single file plugin - use filename without .php
        return str_replace('.php', '', $plugin_file);
    }

    /**
     * Scan for known conflicts
     *
     * @param bool $active_only Check only active plugins
     * @return array Array of detected conflicts
     */
    public function scan(bool $active_only = true): array {
        $installed_slugs = $this->get_installed_plugin_slugs();
        $detected_conflicts = array();

        // Filter to active plugins if requested
        if ($active_only) {
            $installed_slugs = array_filter($installed_slugs, function ($plugin) {
                return $plugin['is_active'];
            });
        }

        $slug_keys = array_keys($installed_slugs);

        foreach ($this->known_conflicts as $conflict) {
            $plugin_a = $conflict['plugin_a'];
            $plugin_b = $conflict['plugin_b'];

            // Check if both plugins are installed
            $has_a = $this->plugin_matches($plugin_a, $slug_keys);
            $has_b = $this->plugin_matches($plugin_b, $slug_keys);

            if ($has_a && $has_b) {
                $detected_conflicts[] = array(
                    'conflict'      => $conflict,
                    'plugin_a_info' => $this->get_plugin_info($plugin_a, $installed_slugs),
                    'plugin_b_info' => $this->get_plugin_info($plugin_b, $installed_slugs),
                    'detected_at'   => current_time('mysql'),
                );
            }
        }

        return $detected_conflicts;
    }

    /**
     * Check if a plugin slug matches any installed plugin
     *
     * @param string $search_slug Slug to search for
     * @param array  $installed_slugs Array of installed plugin slugs
     * @return bool True if plugin is installed
     */
    private function plugin_matches(string $search_slug, array $installed_slugs): bool {
        // Direct match
        if (in_array($search_slug, $installed_slugs, true)) {
            return true;
        }

        // Partial match (handles slug variations)
        foreach ($installed_slugs as $slug) {
            if (strpos($slug, $search_slug) !== false || strpos($search_slug, $slug) !== false) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get plugin info by slug
     *
     * @param string $search_slug Slug to find
     * @param array  $installed_slugs Installed plugins data
     * @return array|null Plugin info or null
     */
    private function get_plugin_info(string $search_slug, array $installed_slugs): ?array {
        if (isset($installed_slugs[$search_slug])) {
            return $installed_slugs[$search_slug];
        }

        foreach ($installed_slugs as $slug => $info) {
            if (strpos($slug, $search_slug) !== false || strpos($search_slug, $slug) !== false) {
                return $info;
            }
        }

        return null;
    }

    /**
     * Quick scan with summary
     *
     * @param bool $active_only Check only active plugins
     * @return array Scan summary
     */
    public function quick_scan(bool $active_only = true): array {
        $conflicts = $this->scan($active_only);

        $summary = array(
            'total_conflicts'      => count($conflicts),
            'critical_conflicts'   => 0,
            'high_conflicts'       => 0,
            'medium_conflicts'     => 0,
            'low_conflicts'        => 0,
            'conflicts_by_type'    => array(
                'overlap'       => 0,
                'conflict'      => 0,
                'incompatible'  => 0,
                'performance'   => 0,
            ),
            'conflicts'            => $conflicts,
            'scan_time'            => current_time('mysql'),
            'plugins_checked'      => count($this->plugin_slugs),
            'known_conflicts_db'   => count($this->known_conflicts),
        );

        foreach ($conflicts as $detected) {
            $severity = $detected['conflict']['severity'] ?? 'low';
            $type = $detected['conflict']['type'] ?? 'conflict';

            $summary[$severity . '_conflicts']++;

            if (isset($summary['conflicts_by_type'][$type])) {
                $summary['conflicts_by_type'][$type]++;
            }
        }

        return $summary;
    }

    /**
     * Get conflicts for a specific plugin
     *
     * @param string $plugin_slug Plugin slug to check
     * @return array Conflicts involving this plugin
     */
    public function get_conflicts_for_plugin(string $plugin_slug): array {
        $conflicts = array();

        foreach ($this->known_conflicts as $conflict) {
            if ($conflict['plugin_a'] === $plugin_slug || $conflict['plugin_b'] === $plugin_slug) {
                $conflicts[] = $conflict;
            }
        }

        return $conflicts;
    }

    /**
     * Check if two specific plugins conflict
     *
     * @param string $plugin_a First plugin slug
     * @param string $plugin_b Second plugin slug
     * @return array|null Conflict info or null if no conflict
     */
    public function check_pair(string $plugin_a, string $plugin_b): ?array {
        foreach ($this->known_conflicts as $conflict) {
            $matches_forward = ($conflict['plugin_a'] === $plugin_a && $conflict['plugin_b'] === $plugin_b);
            $matches_reverse = ($conflict['plugin_a'] === $plugin_b && $conflict['plugin_b'] === $plugin_a);

            if ($matches_forward || $matches_reverse) {
                return $conflict;
            }
        }

        return null;
    }

    /**
     * Get recommended alternatives for conflicting plugins
     *
     * @param array $conflicts Detected conflicts
     * @return array Recommendations
     */
    public function get_recommendations(array $conflicts): array {
        $recommendations = array();

        foreach ($conflicts as $detected) {
            $conflict = $detected['conflict'];

            $recommendations[] = array(
                'plugins'     => array($conflict['plugin_a'], $conflict['plugin_b']),
                'type'        => $conflict['type'],
                'severity'    => $conflict['severity'],
                'action'      => $conflict['resolution'] ?? 'Review plugin compatibility.',
                'description' => $conflict['description'],
            );
        }

        // Sort by severity
        usort($recommendations, function ($a, $b) {
            $severity_order = array('critical' => 0, 'high' => 1, 'medium' => 2, 'low' => 3);
            return ($severity_order[$a['severity']] ?? 4) <=> ($severity_order[$b['severity']] ?? 4);
        });

        return $recommendations;
    }

    /**
     * Export scan results as JSON
     *
     * @param array $scan_result Scan results
     * @return string JSON string
     */
    public function export_json(array $scan_result): string {
        return wp_json_encode($scan_result, JSON_PRETTY_PRINT);
    }

    /**
     * Get statistics about the known conflicts database
     *
     * @return array Database statistics
     */
    public function get_database_stats(): array {
        $stats = array(
            'total_entries'      => count($this->known_conflicts),
            'by_severity'        => array(
                'critical' => 0,
                'high'     => 0,
                'medium'   => 0,
                'low'      => 0,
            ),
            'by_type'            => array(
                'overlap'      => 0,
                'conflict'     => 0,
                'incompatible' => 0,
                'performance'  => 0,
            ),
            'verified_count'     => 0,
            'unique_plugins'     => array(),
        );

        foreach ($this->known_conflicts as $conflict) {
            $severity = $conflict['severity'] ?? 'low';
            $type = $conflict['type'] ?? 'conflict';

            if (isset($stats['by_severity'][$severity])) {
                $stats['by_severity'][$severity]++;
            }

            if (isset($stats['by_type'][$type])) {
                $stats['by_type'][$type]++;
            }

            if (!empty($conflict['verified'])) {
                $stats['verified_count']++;
            }

            $stats['unique_plugins'][$conflict['plugin_a']] = true;
            $stats['unique_plugins'][$conflict['plugin_b']] = true;
        }

        $stats['unique_plugins'] = count($stats['unique_plugins']);

        return $stats;
    }
}
