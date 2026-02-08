<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Performance Analyzer Class
 *
 * Analyzes plugin performance impact
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Performance_Analyzer class
 */
class WPCM_Performance_Analyzer {

    /**
     * Analyze plugin performance metrics
     *
     * @param string $plugin_file Plugin file path
     * @return array Performance data
     */
    public function analyze_plugin($plugin_file) {
        $scanner = new WPCM_Plugin_Scanner();

        return array(
            'size' => $this->analyze_size($plugin_file, $scanner),
            'complexity' => $this->analyze_complexity($plugin_file, $scanner),
            'database_impact' => $this->analyze_database_impact($plugin_file, $scanner),
            'asset_impact' => $this->analyze_asset_impact($plugin_file),
            'hooks_count' => $this->analyze_hooks_count($plugin_file, $scanner),
            'overall_score' => 0, // Will be calculated
        );
    }

    /**
     * Analyze plugin size impact
     *
     * @param string $plugin_file Plugin file
     * @param WPCM_Plugin_Scanner $scanner Scanner instance
     * @return array Size analysis
     */
    private function analyze_size($plugin_file, $scanner) {
        $size = $scanner->get_plugin_size($plugin_file);
        $size_mb = $size / 1024 / 1024;

        $rating = 'excellent';
        if ($size_mb > 20) {
            $rating = 'poor';
        } elseif ($size_mb > 10) {
            $rating = 'fair';
        } elseif ($size_mb > 5) {
            $rating = 'good';
        }

        return array(
            'bytes' => $size,
            'megabytes' => round($size_mb, 2),
            'rating' => $rating,
            'score' => max(0, 100 - ($size_mb * 2)),
        );
    }

    /**
     * Analyze code complexity
     *
     * @param string $plugin_file Plugin file
     * @param WPCM_Plugin_Scanner $scanner Scanner instance
     * @return array Complexity analysis
     */
    private function analyze_complexity($plugin_file, $scanner) {
        $complexity = $scanner->get_plugin_complexity($plugin_file);

        $rating = 'excellent';
        if ($complexity > 10000) {
            $rating = 'poor';
        } elseif ($complexity > 5000) {
            $rating = 'fair';
        } elseif ($complexity > 2000) {
            $rating = 'good';
        }

        return array(
            'score_value' => $complexity,
            'rating' => $rating,
            'score' => max(0, 100 - ($complexity / 100)),
        );
    }

    /**
     * Analyze database impact
     *
     * @param string $plugin_file Plugin file
     * @param WPCM_Plugin_Scanner $scanner Scanner instance
     * @return array Database impact analysis
     */
    private function analyze_database_impact($plugin_file, $scanner) {
        $tables = $scanner->scan_plugin_tables($plugin_file);
        $table_count = count($tables);

        $rating = 'excellent';
        if ($table_count > 10) {
            $rating = 'poor';
        } elseif ($table_count > 5) {
            $rating = 'fair';
        } elseif ($table_count > 2) {
            $rating = 'good';
        }

        return array(
            'table_count' => $table_count,
            'tables' => $tables,
            'rating' => $rating,
            'score' => max(0, 100 - ($table_count * 5)),
        );
    }

    /**
     * Analyze asset loading impact
     *
     * @param string $plugin_file Plugin file
     * @return array Asset analysis
     */
    private function analyze_asset_impact($plugin_file) {
        $plugin_path = WP_PLUGIN_DIR . '/' . dirname($plugin_file);

        $css_files = $this->count_files($plugin_path, 'css');
        $js_files = $this->count_files($plugin_path, 'js');
        $total_assets = $css_files + $js_files;

        $rating = 'excellent';
        if ($total_assets > 20) {
            $rating = 'poor';
        } elseif ($total_assets > 10) {
            $rating = 'fair';
        } elseif ($total_assets > 5) {
            $rating = 'good';
        }

        return array(
            'css_files' => $css_files,
            'js_files' => $js_files,
            'total' => $total_assets,
            'rating' => $rating,
            'score' => max(0, 100 - ($total_assets * 3)),
        );
    }

    /**
     * Analyze hooks count
     *
     * @param string $plugin_file Plugin file
     * @param WPCM_Plugin_Scanner $scanner Scanner instance
     * @return array Hooks analysis
     */
    private function analyze_hooks_count($plugin_file, $scanner) {
        $hooks = $scanner->scan_plugin_hooks($plugin_file);
        $total_hooks = count($hooks['actions']) + count($hooks['filters']);

        $rating = 'excellent';
        if ($total_hooks > 100) {
            $rating = 'poor';
        } elseif ($total_hooks > 50) {
            $rating = 'fair';
        } elseif ($total_hooks > 25) {
            $rating = 'good';
        }

        return array(
            'actions' => count($hooks['actions']),
            'filters' => count($hooks['filters']),
            'total' => $total_hooks,
            'rating' => $rating,
            'score' => max(0, 100 - ($total_hooks / 2)),
        );
    }

    /**
     * Count files by extension
     *
     * @param string $dir Directory path
     * @param string $extension File extension
     * @return int File count
     */
    private function count_files($dir, $extension) {
        $count = 0;

        if (!is_dir($dir)) {
            return $count;
        }

        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS)
        );

        foreach ($iterator as $file) {
            if ($file->isFile() && $file->getExtension() === $extension) {
                $count++;
            }
        }

        return $count;
    }

    /**
     * Generate performance report
     *
     * @param array $analysis_data Analysis data
     * @return array Performance report
     */
    public function generate_report($analysis_data) {
        $scores = array(
            $analysis_data['size']['score'],
            $analysis_data['complexity']['score'],
            $analysis_data['database_impact']['score'],
            $analysis_data['asset_impact']['score'],
            $analysis_data['hooks_count']['score'],
        );

        $overall_score = array_sum($scores) / count($scores);

        $analysis_data['overall_score'] = round($overall_score, 2);
        $analysis_data['overall_rating'] = $this->get_overall_rating($overall_score);

        return $analysis_data;
    }

    /**
     * Get overall rating from score
     *
     * @param float $score Overall score
     * @return string Rating
     */
    private function get_overall_rating($score) {
        if ($score >= 90) {
            return 'excellent';
        } elseif ($score >= 75) {
            return 'good';
        } elseif ($score >= 60) {
            return 'fair';
        } else {
            return 'poor';
        }
    }
}
