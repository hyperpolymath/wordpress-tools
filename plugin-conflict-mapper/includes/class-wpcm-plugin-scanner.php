<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Plugin Scanner Class
 *
 * Scans and analyzes all installed WordPress plugins
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Plugin_Scanner class
 */
class WPCM_Plugin_Scanner {

    /**
     * Get all installed plugins
     *
     * @return array Array of plugin data
     */
    public function get_all_plugins() {
        if (!function_exists('get_plugins')) {
            require_once ABSPATH . 'wp-admin/includes/plugin.php';
        }

        $all_plugins = get_plugins();
        $active_plugins = get_option('active_plugins', array());

        $plugin_data = array();

        foreach ($all_plugins as $plugin_file => $plugin_info) {
            $plugin_data[$plugin_file] = array(
                'name' => $plugin_info['Name'],
                'version' => $plugin_info['Version'],
                'author' => $plugin_info['Author'],
                'description' => $plugin_info['Description'],
                'plugin_uri' => $plugin_info['PluginURI'],
                'is_active' => in_array($plugin_file, $active_plugins),
                'file' => $plugin_file,
                'path' => WP_PLUGIN_DIR . '/' . dirname($plugin_file),
                'main_file' => WP_PLUGIN_DIR . '/' . $plugin_file,
                'text_domain' => $plugin_info['TextDomain'],
            );
        }

        return $plugin_data;
    }

    /**
     * Get active plugins only
     *
     * @return array Array of active plugin data
     */
    public function get_active_plugins() {
        $all_plugins = $this->get_all_plugins();
        return array_filter($all_plugins, function($plugin) {
            return $plugin['is_active'];
        });
    }

    /**
     * Scan plugin for hooks
     *
     * @param string $plugin_file Plugin file path
     * @return array Array of hooks used by the plugin
     */
    public function scan_plugin_hooks($plugin_file) {
        $hooks = array(
            'actions' => array(),
            'filters' => array(),
        );

        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        $files = $this->get_php_files($plugin_path);

        foreach ($files as $file) {
            $content = file_get_contents($file);

            // Find add_action calls
            preg_match_all('/add_action\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $actions);
            if (!empty($actions[1])) {
                $hooks['actions'] = array_merge($hooks['actions'], $actions[1]);
            }

            // Find add_filter calls
            preg_match_all('/add_filter\s*\(\s*[\'"]([^\'"]+)[\'"]/i', $content, $filters);
            if (!empty($filters[1])) {
                $hooks['filters'] = array_merge($hooks['filters'], $filters[1]);
            }
        }

        $hooks['actions'] = array_unique($hooks['actions']);
        $hooks['filters'] = array_unique($hooks['filters']);

        return $hooks;
    }

    /**
     * Scan plugin for defined functions
     *
     * @param string $plugin_file Plugin file path
     * @return array Array of function names
     */
    public function scan_plugin_functions($plugin_file) {
        $functions = array();
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        $files = $this->get_php_files($plugin_path);

        foreach ($files as $file) {
            $content = file_get_contents($file);

            // Find function definitions
            preg_match_all('/function\s+([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)\s*\(/i', $content, $matches);
            if (!empty($matches[1])) {
                $functions = array_merge($functions, $matches[1]);
            }
        }

        return array_unique($functions);
    }

    /**
     * Scan plugin for global variables
     *
     * @param string $plugin_file Plugin file path
     * @return array Array of global variable names
     */
    public function scan_plugin_globals($plugin_file) {
        $globals = array();
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        $files = $this->get_php_files($plugin_path);

        foreach ($files as $file) {
            $content = file_get_contents($file);

            // Find global declarations
            preg_match_all('/global\s+\$([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*)/i', $content, $matches);
            if (!empty($matches[1])) {
                $globals = array_merge($globals, $matches[1]);
            }
        }

        return array_unique($globals);
    }

    /**
     * Get plugin file size
     *
     * @param string $plugin_file Plugin file path
     * @return int Size in bytes
     */
    public function get_plugin_size($plugin_file) {
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        return $this->get_directory_size($plugin_path);
    }

    /**
     * Get plugin complexity score
     *
     * @param string $plugin_file Plugin file path
     * @return int Complexity score
     */
    public function get_plugin_complexity($plugin_file) {
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        $files = $this->get_php_files($plugin_path);

        $total_lines = 0;
        $total_functions = 0;
        $total_classes = 0;

        foreach ($files as $file) {
            $content = file_get_contents($file);
            $lines = substr_count($content, "\n");
            $total_lines += $lines;

            preg_match_all('/function\s+/i', $content, $functions);
            $total_functions += count($functions[0]);

            preg_match_all('/class\s+/i', $content, $classes);
            $total_classes += count($classes[0]);
        }

        // Simple complexity score: lines + functions*10 + classes*20
        return $total_lines + ($total_functions * 10) + ($total_classes * 20);
    }

    /**
     * Get all PHP files in a directory recursively
     *
     * @param string $dir Directory path
     * @param int $max_files Maximum number of files to scan
     * @return array Array of file paths
     */
    private function get_php_files($dir, $max_files = 500) {
        $files = array();

        if (!is_dir($dir)) {
            return $files;
        }

        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS),
            RecursiveIteratorIterator::SELF_FIRST
        );

        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === 'php') {
                $files[] = $file->getPathname();

                if (count($files) >= $max_files) {
                    break;
                }
            }
        }

        return $files;
    }

    /**
     * Get directory size recursively
     *
     * @param string $dir Directory path
     * @return int Size in bytes
     */
    private function get_directory_size($dir) {
        $size = 0;

        if (!is_dir($dir)) {
            return $size;
        }

        foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS)) as $file) {
            $size += $file->getSize();
        }

        return $size;
    }

    /**
     * Get plugin database tables
     *
     * @param string $plugin_file Plugin file path
     * @return array Array of table names
     */
    public function scan_plugin_tables($plugin_file) {
        global $wpdb;

        $tables = array();
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        $files = $this->get_php_files($plugin_path);

        foreach ($files as $file) {
            $content = file_get_contents($file);

            // Find CREATE TABLE statements
            preg_match_all('/CREATE\s+TABLE\s+[IF NOT EXISTS\s+]*[`\'"]*([a-zA-Z0-9_]+)[`\'"]*\s*/i', $content, $matches);
            if (!empty($matches[1])) {
                $tables = array_merge($tables, $matches[1]);
            }

            // Find wpdb->prefix usage
            preg_match_all('/\$wpdb->prefix\s*\.\s*[\'"]([a-zA-Z0-9_]+)[\'"]/i', $content, $prefix_matches);
            if (!empty($prefix_matches[1])) {
                $tables = array_merge($tables, $prefix_matches[1]);
            }
        }

        return array_unique($tables);
    }
}
