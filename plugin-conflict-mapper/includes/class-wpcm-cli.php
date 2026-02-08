<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * WP-CLI Commands Class
 *
 * Provides command-line interface for plugin scanning
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH') || !defined('WP_CLI')) {
    return;
}

/**
 * Manage plugin conflict scanning via WP-CLI
 */
class WPCM_CLI {

    /**
     * Scan for plugin conflicts
     *
     * ## OPTIONS
     *
     * [--format=<format>]
     * : Output format (table, json, csv). Default: table
     *
     * [--save]
     * : Save scan results to database
     *
     * ## EXAMPLES
     *
     *     wp conflict-mapper scan
     *     wp conflict-mapper scan --format=json
     *     wp conflict-mapper scan --save
     *
     * @param array $args Positional arguments
     * @param array $assoc_args Associative arguments
     */
    public function scan($args, $assoc_args) {
        $format = isset($assoc_args['format']) ? $assoc_args['format'] : 'table';
        $save = isset($assoc_args['save']);

        WP_CLI::line('Scanning plugins for conflicts...');

        $scanner = new WPCM_Plugin_Scanner();
        $detector = new WPCM_Conflict_Detector();
        $overlap_analyzer = new WPCM_Overlap_Analyzer();

        $plugins = $scanner->get_active_plugins();
        $conflicts = $detector->detect_conflicts($plugins);
        $overlaps = $overlap_analyzer->analyze_overlaps($plugins);

        $summary = array(
            'total_plugins' => count($plugins),
            'total_conflicts' => $this->count_conflicts($conflicts),
            'total_overlaps' => count($overlaps),
        );

        if ($save) {
            $database = new WPCM_Database();
            $scan_data = array(
                'plugin_count' => $summary['total_plugins'],
                'conflict_count' => $summary['total_conflicts'],
                'overlap_count' => $summary['total_overlaps'],
                'scan_type' => 'cli',
                'full_data' => array(
                    'plugins' => $plugins,
                    'conflicts' => $conflicts,
                    'overlaps' => $overlaps,
                ),
            );

            $scan_id = $database->save_scan($scan_data);
            $database->save_conflicts($scan_id, $conflicts);

            WP_CLI::success("Scan saved with ID: {$scan_id}");
        }

        WP_CLI::line("\nScan Summary:");
        WP_CLI\Utils\format_items($format, array($summary), array('total_plugins', 'total_conflicts', 'total_overlaps'));

        if ($summary['total_conflicts'] > 0) {
            WP_CLI::warning("Found {$summary['total_conflicts']} conflicts!");
        } else {
            WP_CLI::success('No conflicts detected!');
        }
    }

    /**
     * List all plugins with their scores
     *
     * ## OPTIONS
     *
     * [--format=<format>]
     * : Output format (table, json, csv). Default: table
     *
     * ## EXAMPLES
     *
     *     wp conflict-mapper list
     *     wp conflict-mapper list --format=json
     *
     * @param array $args Positional arguments
     * @param array $assoc_args Associative arguments
     */
    public function list_plugins($args, $assoc_args) {
        $format = isset($assoc_args['format']) ? $assoc_args['format'] : 'table';

        $scanner = new WPCM_Plugin_Scanner();
        $detector = new WPCM_Conflict_Detector();
        $overlap_analyzer = new WPCM_Overlap_Analyzer();
        $ranking = new WPCM_Ranking_Engine();

        $plugins = $scanner->get_active_plugins();
        $conflicts = $detector->detect_conflicts($plugins);
        $overlaps = $overlap_analyzer->analyze_overlaps($plugins);

        $ranked = $ranking->rank_plugins($plugins, $conflicts, $overlaps);

        $output = array();
        foreach ($ranked as $plugin_file => $data) {
            $output[] = array(
                'name' => $data['name'],
                'version' => $data['version'],
                'score' => $data['score'],
                'issues' => count($data['issues']),
            );
        }

        WP_CLI\Utils\format_items($format, $output, array('name', 'version', 'score', 'issues'));
    }

    /**
     * Show detailed report for a specific plugin
     *
     * ## OPTIONS
     *
     * <plugin>
     * : Plugin slug or name
     *
     * ## EXAMPLES
     *
     *     wp conflict-mapper report akismet
     *
     * @param array $args Positional arguments
     * @param array $assoc_args Associative arguments
     */
    public function report($args, $assoc_args) {
        if (empty($args[0])) {
            WP_CLI::error('Please specify a plugin name or slug');
        }

        $plugin_search = $args[0];
        $scanner = new WPCM_Plugin_Scanner();
        $plugins = $scanner->get_all_plugins();

        $plugin_file = null;
        foreach ($plugins as $file => $data) {
            if (stripos($file, $plugin_search) !== false || stripos($data['name'], $plugin_search) !== false) {
                $plugin_file = $file;
                break;
            }
        }

        if (!$plugin_file) {
            WP_CLI::error("Plugin '{$plugin_search}' not found");
        }

        $plugin_data = $plugins[$plugin_file];

        WP_CLI::line("Plugin Report: {$plugin_data['name']}");
        WP_CLI::line(str_repeat('-', 50));
        WP_CLI::line("Version: {$plugin_data['version']}");
        WP_CLI::line("Author: {$plugin_data['author']}");
        WP_CLI::line("Status: " . ($plugin_data['is_active'] ? 'Active' : 'Inactive'));

        // Performance analysis
        $perf_analyzer = new WPCM_Performance_Analyzer();
        $perf = $perf_analyzer->analyze_plugin($plugin_file);
        $perf_report = $perf_analyzer->generate_report($perf);

        WP_CLI::line("\nPerformance Analysis:");
        WP_CLI::line("Overall Score: {$perf_report['overall_score']} ({$perf_report['overall_rating']})");
        WP_CLI::line("Size: {$perf_report['size']['megabytes']} MB ({$perf_report['size']['rating']})");
        WP_CLI::line("Complexity: {$perf_report['complexity']['rating']}");
        WP_CLI::line("Database Tables: {$perf_report['database_impact']['table_count']}");

        // Security scan
        $security = new WPCM_Security_Scanner();
        $security_report = $security->scan_plugin($plugin_file);

        WP_CLI::line("\nSecurity Analysis:");
        WP_CLI::line("Risk Level: {$security_report['risk_level']}");
        WP_CLI::line("Issues Found: {$security_report['total_issues']}");

        if ($security_report['total_issues'] > 0) {
            WP_CLI::warning("Security issues detected!");
            foreach (array_slice($security_report['issues'], 0, 5) as $issue) {
                WP_CLI::line("  - {$issue['type']}: {$issue['message']} ({$issue['file']}:{$issue['line']})");
            }
        } else {
            WP_CLI::success('No obvious security issues detected');
        }
    }

    /**
     * Clear scan cache
     *
     * ## EXAMPLES
     *
     *     wp conflict-mapper clear-cache
     */
    public function clear_cache() {
        $cache = new WPCM_Cache();
        $cache->clear_all();
        WP_CLI::success('Cache cleared successfully');
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

WP_CLI::add_command('conflict-mapper', 'WPCM_CLI');
