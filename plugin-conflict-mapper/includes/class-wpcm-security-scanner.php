<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Security Scanner Class
 *
 * Scans plugins for potential security issues
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Security_Scanner class
 */
class WPCM_Security_Scanner {

    /**
     * Dangerous function patterns
     *
     * @var array
     */
    private $dangerous_functions = array(
        'eval',
        'base64_decode',
        'system',
        'exec',
        'shell_exec',
        'passthru',
        'proc_open',
        'popen',
        'curl_exec',
        'curl_multi_exec',
        'parse_str',
        'file_get_contents',
        'file_put_contents',
    );

    /**
     * Scan plugin for security issues
     *
     * @param string $plugin_file Plugin file path
     * @return array Security scan results
     */
    public function scan_plugin($plugin_file) {
        $issues = array();
        $scanner = new WPCM_Plugin_Scanner();
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);
        $files = $this->get_php_files($plugin_path);

        foreach ($files as $file) {
            $content = file_get_contents($file);

            // Check for dangerous functions
            $dangerous = $this->scan_dangerous_functions($content, $file);
            if (!empty($dangerous)) {
                $issues = array_merge($issues, $dangerous);
            }

            // Check for SQL injection risks
            $sql_risks = $this->scan_sql_injection($content, $file);
            if (!empty($sql_risks)) {
                $issues = array_merge($issues, $sql_risks);
            }

            // Check for XSS risks
            $xss_risks = $this->scan_xss_risks($content, $file);
            if (!empty($xss_risks)) {
                $issues = array_merge($issues, $xss_risks);
            }

            // Check for insecure file operations
            $file_risks = $this->scan_file_operations($content, $file);
            if (!empty($file_risks)) {
                $issues = array_merge($issues, $file_risks);
            }
        }

        return array(
            'total_issues' => count($issues),
            'issues' => $issues,
            'risk_level' => $this->calculate_risk_level($issues),
        );
    }

    /**
     * Scan for dangerous function usage
     *
     * @param string $content File content
     * @param string $file File path
     * @return array Found issues
     */
    private function scan_dangerous_functions($content, $file) {
        $issues = array();

        foreach ($this->dangerous_functions as $function) {
            if (preg_match_all('/\b' . preg_quote($function, '/') . '\s*\(/i', $content, $matches, PREG_OFFSET_CAPTURE)) {
                foreach ($matches[0] as $match) {
                    $line = substr_count(substr($content, 0, $match[1]), "\n") + 1;
                    $issues[] = array(
                        'type' => 'dangerous_function',
                        'severity' => 'high',
                        'function' => $function,
                        'file' => basename($file),
                        'line' => $line,
                        'message' => "Potentially dangerous function '{$function}' found",
                    );
                }
            }
        }

        return $issues;
    }

    /**
     * Scan for SQL injection risks
     *
     * @param string $content File content
     * @param string $file File path
     * @return array Found issues
     */
    private function scan_sql_injection($content, $file) {
        $issues = array();

        // Check for direct SQL without $wpdb->prepare
        if (preg_match_all('/\$wpdb->(query|get_results|get_row|get_var|get_col)\s*\(\s*["\'].*?\$.*?["\']/', $content, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[0] as $match) {
                $line = substr_count(substr($content, 0, $match[1]), "\n") + 1;
                $issues[] = array(
                    'type' => 'sql_injection',
                    'severity' => 'high',
                    'file' => basename($file),
                    'line' => $line,
                    'message' => 'Possible SQL injection: direct variable in query without prepare()',
                );
            }
        }

        // Check for $_GET/$_POST in SQL
        if (preg_match_all('/\$_(GET|POST|REQUEST)\[.*?\].*?(query|SELECT|INSERT|UPDATE|DELETE)/i', $content, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[0] as $match) {
                $line = substr_count(substr($content, 0, $match[1]), "\n") + 1;
                $issues[] = array(
                    'type' => 'sql_injection',
                    'severity' => 'critical',
                    'file' => basename($file),
                    'line' => $line,
                    'message' => 'Critical: User input directly in SQL query',
                );
            }
        }

        return $issues;
    }

    /**
     * Scan for XSS risks
     *
     * @param string $content File content
     * @param string $file File path
     * @return array Found issues
     */
    private function scan_xss_risks($content, $file) {
        $issues = array();

        // Check for echo without escaping
        if (preg_match_all('/echo\s+\$_(GET|POST|REQUEST)\[/', $content, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[0] as $match) {
                $line = substr_count(substr($content, 0, $match[1]), "\n") + 1;
                $issues[] = array(
                    'type' => 'xss',
                    'severity' => 'high',
                    'file' => basename($file),
                    'line' => $line,
                    'message' => 'Possible XSS: unescaped user input in echo',
                );
            }
        }

        return $issues;
    }

    /**
     * Scan for insecure file operations
     *
     * @param string $content File content
     * @param string $file File path
     * @return array Found issues
     */
    private function scan_file_operations($content, $file) {
        $issues = array();

        // Check for file operations with user input
        if (preg_match_all('/(file_get_contents|file_put_contents|fopen|unlink)\s*\(\s*\$_(GET|POST|REQUEST)/', $content, $matches, PREG_OFFSET_CAPTURE)) {
            foreach ($matches[0] as $match) {
                $line = substr_count(substr($content, 0, $match[1]), "\n") + 1;
                $issues[] = array(
                    'type' => 'file_operation',
                    'severity' => 'high',
                    'file' => basename($file),
                    'line' => $line,
                    'message' => 'Insecure file operation with user input',
                );
            }
        }

        return $issues;
    }

    /**
     * Calculate overall risk level
     *
     * @param array $issues Array of issues
     * @return string Risk level
     */
    private function calculate_risk_level($issues) {
        $critical = 0;
        $high = 0;

        foreach ($issues as $issue) {
            if ($issue['severity'] === 'critical') {
                $critical++;
            } elseif ($issue['severity'] === 'high') {
                $high++;
            }
        }

        if ($critical > 0) {
            return 'critical';
        } elseif ($high > 2) {
            return 'high';
        } elseif ($high > 0) {
            return 'medium';
        } elseif (count($issues) > 0) {
            return 'low';
        }

        return 'safe';
    }

    /**
     * Get PHP files recursively
     *
     * @param string $dir Directory path
     * @return array Array of file paths
     */
    private function get_php_files($dir) {
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

                if (count($files) >= 100) { // Limit for performance
                    break;
                }
            }
        }

        return $files;
    }
}
