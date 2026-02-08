<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Ranking Engine Class
 *
 * Ranks plugins based on conflicts, performance, and best practices
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * WPCM_Ranking_Engine class
 */
class WPCM_Ranking_Engine {

    /**
     * Rank plugins based on multiple criteria
     *
     * @param array $plugins Array of plugins to rank
     * @param array $conflicts Detected conflicts
     * @param array $overlaps Detected overlaps
     * @return array Ranked plugin data
     */
    public function rank_plugins($plugins, $conflicts = array(), $overlaps = array()) {
        $ranked = array();
        $scanner = new WPCM_Plugin_Scanner();

        foreach ($plugins as $plugin_file => $plugin_data) {
            $score = $this->calculate_plugin_score(
                $plugin_file,
                $plugin_data,
                $conflicts,
                $overlaps,
                $scanner
            );

            $ranked[$plugin_file] = array_merge($plugin_data, array(
                'score' => $score['total'],
                'score_breakdown' => $score['breakdown'],
                'issues' => $score['issues'],
                'recommendations' => $this->get_recommendations($score),
            ));
        }

        // Sort by score (lower is worse)
        uasort($ranked, function($a, $b) {
            return $b['score'] <=> $a['score'];
        });

        return $ranked;
    }

    /**
     * Calculate comprehensive plugin score
     *
     * @param string $plugin_file Plugin file
     * @param array $plugin_data Plugin data
     * @param array $conflicts Conflicts data
     * @param array $overlaps Overlaps data
     * @param WPCM_Plugin_Scanner $scanner Scanner instance
     * @return array Score data
     */
    private function calculate_plugin_score($plugin_file, $plugin_data, $conflicts, $overlaps, $scanner) {
        $breakdown = array();
        $issues = array();
        $max_score = 100;

        // Base score
        $score = $max_score;

        // 1. Conflict penalties
        $conflict_penalty = $this->calculate_conflict_penalty($plugin_data['name'], $conflicts);
        $breakdown['conflicts'] = $max_score - $conflict_penalty;
        $score -= $conflict_penalty;
        if ($conflict_penalty > 0) {
            $issues[] = sprintf('Involved in conflicts (-%d points)', $conflict_penalty);
        }

        // 2. Overlap penalties
        $overlap_penalty = $this->calculate_overlap_penalty($plugin_data['name'], $overlaps);
        $breakdown['overlaps'] = $max_score - $overlap_penalty;
        $score -= $overlap_penalty;
        if ($overlap_penalty > 0) {
            $issues[] = sprintf('Functional overlap with other plugins (-%d points)', $overlap_penalty);
        }

        // 3. Complexity score
        $complexity = $scanner->get_plugin_complexity($plugin_file);
        $complexity_penalty = min(20, $complexity / 1000); // Max 20 points
        $breakdown['complexity'] = $max_score - round($complexity_penalty);
        $score -= $complexity_penalty;

        // 4. Size penalty (very large plugins may impact performance)
        $size = $scanner->get_plugin_size($plugin_file);
        $size_mb = $size / 1024 / 1024;
        $size_penalty = 0;
        if ($size_mb > 10) {
            $size_penalty = min(10, ($size_mb - 10) / 2);
            $issues[] = sprintf('Large plugin size: %.2f MB (-%d points)', $size_mb, round($size_penalty));
        }
        $breakdown['size'] = $max_score - round($size_penalty);
        $score -= $size_penalty;

        // 5. Update recency (if version info available)
        if (!empty($plugin_data['version'])) {
            $breakdown['maintenance'] = 100; // Assume maintained if has version
        } else {
            $breakdown['maintenance'] = 80;
            $score -= 20;
            $issues[] = 'No version information available (-20 points)';
        }

        // Ensure score doesn't go below 0
        $score = max(0, $score);

        return array(
            'total' => round($score, 2),
            'breakdown' => $breakdown,
            'issues' => $issues,
        );
    }

    /**
     * Calculate conflict penalty
     *
     * @param string $plugin_name Plugin name
     * @param array $conflicts All conflicts
     * @return int Penalty points
     */
    private function calculate_conflict_penalty($plugin_name, $conflicts) {
        $penalty = 0;

        foreach ($conflicts as $conflict_type => $conflict_list) {
            foreach ($conflict_list as $conflict) {
                if (isset($conflict['plugins']) && in_array($plugin_name, $conflict['plugins'])) {
                    $severity = isset($conflict['severity']) ? $conflict['severity'] : 'low';

                    switch ($severity) {
                        case 'high':
                            $penalty += 15;
                            break;
                        case 'medium':
                            $penalty += 8;
                            break;
                        case 'low':
                            $penalty += 3;
                            break;
                    }
                }
            }
        }

        return min(40, $penalty); // Cap at 40 points
    }

    /**
     * Calculate overlap penalty
     *
     * @param string $plugin_name Plugin name
     * @param array $overlaps All overlaps
     * @return int Penalty points
     */
    private function calculate_overlap_penalty($plugin_name, $overlaps) {
        $penalty = 0;

        foreach ($overlaps as $overlap) {
            if (isset($overlap['plugins']) && in_array($plugin_name, $overlap['plugins'])) {
                $severity = isset($overlap['severity']) ? $overlap['severity'] : 'low';

                switch ($severity) {
                    case 'high':
                        $penalty += 12;
                        break;
                    case 'medium':
                        $penalty += 6;
                        break;
                    case 'low':
                        $penalty += 2;
                        break;
                }
            }
        }

        return min(30, $penalty); // Cap at 30 points
    }

    /**
     * Get recommendations based on score
     *
     * @param array $score_data Score data
     * @return array Array of recommendations
     */
    private function get_recommendations($score_data) {
        $recommendations = array();
        $score = $score_data['total'];

        if ($score >= 80) {
            $recommendations[] = array(
                'type' => 'success',
                'message' => 'This plugin appears to be well-behaved with minimal conflicts.',
            );
        } elseif ($score >= 60) {
            $recommendations[] = array(
                'type' => 'warning',
                'message' => 'This plugin has some minor issues that should be monitored.',
            );
        } else {
            $recommendations[] = array(
                'type' => 'error',
                'message' => 'This plugin has significant issues. Consider finding an alternative.',
            );
        }

        // Add specific recommendations based on breakdown
        if (isset($score_data['breakdown']['conflicts']) && $score_data['breakdown']['conflicts'] < 70) {
            $recommendations[] = array(
                'type' => 'warning',
                'message' => 'High conflict potential. Review conflicting plugins and consider deactivating one.',
            );
        }

        if (isset($score_data['breakdown']['overlaps']) && $score_data['breakdown']['overlaps'] < 70) {
            $recommendations[] = array(
                'type' => 'info',
                'message' => 'Functional overlap detected. You may be able to consolidate functionality.',
            );
        }

        return $recommendations;
    }

    /**
     * Get comparative ranking
     *
     * @param array $ranked_plugins Ranked plugins array
     * @return array Comparative data
     */
    public function get_comparative_ranking($ranked_plugins) {
        $total = count($ranked_plugins);
        $index = 0;
        $comparative = array();

        foreach ($ranked_plugins as $plugin_file => $data) {
            $index++;
            $percentile = (($total - $index) / $total) * 100;

            $comparative[$plugin_file] = array(
                'rank' => $index,
                'percentile' => round($percentile, 1),
                'total_plugins' => $total,
            );
        }

        return $comparative;
    }

    /**
     * Get priority actions
     *
     * @param array $ranked_plugins Ranked plugins
     * @return array Priority actions to take
     */
    public function get_priority_actions($ranked_plugins) {
        $actions = array();

        foreach ($ranked_plugins as $plugin_file => $data) {
            if ($data['score'] < 50) {
                $actions[] = array(
                    'priority' => 'high',
                    'plugin' => $data['name'],
                    'action' => 'review',
                    'reason' => 'Low compatibility score',
                    'score' => $data['score'],
                );
            }
        }

        return $actions;
    }
}
