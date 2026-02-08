<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Conflict Detector Class
 *
 * Detects conflicts between WordPress plugins
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Conflict_Detector class
 */
class WPCM_Conflict_Detector {

    /**
     * Plugin scanner instance
     *
     * @var WPCM_Plugin_Scanner
     */
    private $scanner;

    /**
     * Constructor
     */
    public function __construct() {
        $this->scanner = new WPCM_Plugin_Scanner();
    }

    /**
     * Detect all conflicts
     *
     * @param array $plugins Optional array of specific plugins to check
     * @return array Array of detected conflicts
     */
    public function detect_conflicts($plugins = null) {
        if ($plugins === null) {
            $plugins = $this->scanner->get_active_plugins();
        }

        $conflicts = array(
            'hook_conflicts' => $this->detect_hook_conflicts($plugins),
            'function_conflicts' => $this->detect_function_conflicts($plugins),
            'global_conflicts' => $this->detect_global_conflicts($plugins),
            'table_conflicts' => $this->detect_table_conflicts($plugins),
        );

        return $conflicts;
    }

    /**
     * Detect hook conflicts
     *
     * @param array $plugins Array of plugins to check
     * @return array Array of hook conflicts
     */
    public function detect_hook_conflicts($plugins) {
        $hook_usage = array();
        $conflicts = array();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $hooks = $this->scanner->scan_plugin_hooks($plugin_file);

            foreach ($hooks['actions'] as $hook) {
                if (!isset($hook_usage['actions'][$hook])) {
                    $hook_usage['actions'][$hook] = array();
                }
                $hook_usage['actions'][$hook][] = $plugin_data['name'];
            }

            foreach ($hooks['filters'] as $hook) {
                if (!isset($hook_usage['filters'][$hook])) {
                    $hook_usage['filters'][$hook] = array();
                }
                $hook_usage['filters'][$hook][] = $plugin_data['name'];
            }
        }

        // Find hooks used by multiple plugins
        foreach ($hook_usage as $type => $hooks) {
            foreach ($hooks as $hook_name => $plugin_list) {
                if (count($plugin_list) > 1) {
                    $conflicts[] = array(
                        'type' => $type,
                        'hook' => $hook_name,
                        'plugins' => $plugin_list,
                        'severity' => $this->calculate_hook_severity($hook_name, count($plugin_list)),
                    );
                }
            }
        }

        return $conflicts;
    }

    /**
     * Detect function name conflicts
     *
     * @param array $plugins Array of plugins to check
     * @return array Array of function conflicts
     */
    public function detect_function_conflicts($plugins) {
        $function_usage = array();
        $conflicts = array();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $functions = $this->scanner->scan_plugin_functions($plugin_file);

            foreach ($functions as $function_name) {
                // Skip WordPress core functions and common prefixes
                if ($this->is_wordpress_function($function_name)) {
                    continue;
                }

                if (!isset($function_usage[$function_name])) {
                    $function_usage[$function_name] = array();
                }
                $function_usage[$function_name][] = $plugin_data['name'];
            }
        }

        // Find functions defined by multiple plugins
        foreach ($function_usage as $function_name => $plugin_list) {
            if (count($plugin_list) > 1) {
                $conflicts[] = array(
                    'function' => $function_name,
                    'plugins' => $plugin_list,
                    'severity' => 'high', // Function conflicts are always high severity
                );
            }
        }

        return $conflicts;
    }

    /**
     * Detect global variable conflicts
     *
     * @param array $plugins Array of plugins to check
     * @return array Array of global conflicts
     */
    public function detect_global_conflicts($plugins) {
        $global_usage = array();
        $conflicts = array();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $globals = $this->scanner->scan_plugin_globals($plugin_file);

            foreach ($globals as $global_name) {
                // Skip WordPress core globals
                if ($this->is_wordpress_global($global_name)) {
                    continue;
                }

                if (!isset($global_usage[$global_name])) {
                    $global_usage[$global_name] = array();
                }
                $global_usage[$global_name][] = $plugin_data['name'];
            }
        }

        // Find globals used by multiple plugins
        foreach ($global_usage as $global_name => $plugin_list) {
            if (count($plugin_list) > 1) {
                $conflicts[] = array(
                    'global' => $global_name,
                    'plugins' => $plugin_list,
                    'severity' => 'medium',
                );
            }
        }

        return $conflicts;
    }

    /**
     * Detect database table conflicts
     *
     * @param array $plugins Array of plugins to check
     * @return array Array of table conflicts
     */
    public function detect_table_conflicts($plugins) {
        $table_usage = array();
        $conflicts = array();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $tables = $this->scanner->scan_plugin_tables($plugin_file);

            foreach ($tables as $table_name) {
                if (!isset($table_usage[$table_name])) {
                    $table_usage[$table_name] = array();
                }
                $table_usage[$table_name][] = $plugin_data['name'];
            }
        }

        // Find tables used by multiple plugins
        foreach ($table_usage as $table_name => $plugin_list) {
            if (count($plugin_list) > 1) {
                $conflicts[] = array(
                    'table' => $table_name,
                    'plugins' => $plugin_list,
                    'severity' => 'high',
                );
            }
        }

        return $conflicts;
    }

    /**
     * Calculate hook conflict severity
     *
     * @param string $hook_name Hook name
     * @param int $usage_count Number of plugins using the hook
     * @return string Severity level
     */
    private function calculate_hook_severity($hook_name, $usage_count) {
        // High priority hooks
        $high_priority_hooks = array('init', 'wp_head', 'wp_footer', 'admin_init', 'admin_menu');

        if (in_array($hook_name, $high_priority_hooks) && $usage_count > 3) {
            return 'high';
        } elseif ($usage_count > 5) {
            return 'medium';
        } else {
            return 'low';
        }
    }

    /**
     * Check if function is a WordPress core function
     *
     * @param string $function_name Function name
     * @return bool True if WordPress function
     */
    private function is_wordpress_function($function_name) {
        $wp_prefixes = array('wp_', 'get_', 'add_', 'remove_', 'do_', 'apply_', 'is_', 'has_');

        foreach ($wp_prefixes as $prefix) {
            if (strpos($function_name, $prefix) === 0) {
                return true;
            }
        }

        return function_exists($function_name);
    }

    /**
     * Check if global is a WordPress core global
     *
     * @param string $global_name Global variable name
     * @return bool True if WordPress global
     */
    private function is_wordpress_global($global_name) {
        $wp_globals = array(
            'wpdb', 'wp_query', 'wp_rewrite', 'wp', 'post', 'wp_the_query',
            'wp_version', 'wp_db_version', 'tinymce_version', 'required_php_version',
            'required_mysql_version', 'wp_local_package'
        );

        return in_array($global_name, $wp_globals);
    }

    /**
     * Get conflict summary
     *
     * @param array $conflicts Array of conflicts
     * @return array Summary statistics
     */
    public function get_conflict_summary($conflicts) {
        $summary = array(
            'total_conflicts' => 0,
            'high_severity' => 0,
            'medium_severity' => 0,
            'low_severity' => 0,
            'by_type' => array(
                'hooks' => 0,
                'functions' => 0,
                'globals' => 0,
                'tables' => 0,
            ),
        );

        foreach ($conflicts as $type => $conflict_list) {
            $summary['total_conflicts'] += count($conflict_list);

            foreach ($conflict_list as $conflict) {
                $severity = isset($conflict['severity']) ? $conflict['severity'] : 'low';
                $summary[$severity . '_severity']++;
            }

            $type_key = str_replace('_conflicts', '', $type);
            $type_key = rtrim($type_key, 's');
            if (isset($summary['by_type'][$type_key])) {
                $summary['by_type'][$type_key] = count($conflict_list);
            }
        }

        return $summary;
    }
}
