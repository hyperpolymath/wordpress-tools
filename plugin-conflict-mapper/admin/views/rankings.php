<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Rankings View
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}
?>

<div class="wrap wpcm-rankings">
    <h1><?php esc_html_e('Plugin Rankings', 'wp-plugin-conflict-mapper'); ?></h1>

    <p class="description">
        <?php esc_html_e('Plugins are ranked based on conflicts, overlaps, complexity, and performance impact. Higher scores indicate better compatibility and performance.', 'wp-plugin-conflict-mapper'); ?>
    </p>

    <?php if (empty($ranked_plugins)): ?>
        <div class="notice notice-info">
            <p><?php esc_html_e('No active plugins to rank. Activate some plugins first.', 'wp-plugin-conflict-mapper'); ?></p>
        </div>
    <?php else: ?>
        <div class="wpcm-rankings-filters">
            <label>
                <?php esc_html_e('Filter by score:', 'wp-plugin-conflict-mapper'); ?>
                <select id="wpcm-score-filter">
                    <option value="all"><?php esc_html_e('All Plugins', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="excellent"><?php esc_html_e('Excellent (80+)', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="good"><?php esc_html_e('Good (60-79)', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="fair"><?php esc_html_e('Fair (40-59)', 'wp-plugin-conflict-mapper'); ?></option>
                    <option value="poor"><?php esc_html_e('Poor (<40)', 'wp-plugin-conflict-mapper'); ?></option>
                </select>
            </label>
        </div>

        <table class="wp-list-table widefat fixed striped wpcm-rankings-table">
            <thead>
                <tr>
                    <th><?php esc_html_e('Rank', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Plugin Name', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Version', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Score', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Issues', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Status', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Actions', 'wp-plugin-conflict-mapper'); ?></th>
                </tr>
            </thead>
            <tbody>
                <?php
                $rank = 1;
                foreach ($ranked_plugins as $plugin_file => $plugin):
                    $score_class = '';
                    if ($plugin['score'] >= 80) {
                        $score_class = 'wpcm-score-excellent';
                    } elseif ($plugin['score'] >= 60) {
                        $score_class = 'wpcm-score-good';
                    } elseif ($plugin['score'] >= 40) {
                        $score_class = 'wpcm-score-fair';
                    } else {
                        $score_class = 'wpcm-score-poor';
                    }
                ?>
                    <tr data-score="<?php echo esc_attr($plugin['score']); ?>">
                        <td><strong><?php echo esc_html($rank++); ?></strong></td>
                        <td>
                            <strong><?php echo esc_html($plugin['name']); ?></strong>
                            <?php if (!empty($plugin['author'])): ?>
                                <br><small><?php echo esc_html__('by', 'wp-plugin-conflict-mapper') . ' ' . esc_html($plugin['author']); ?></small>
                            <?php endif; ?>
                        </td>
                        <td><?php echo esc_html($plugin['version']); ?></td>
                        <td>
                            <span class="wpcm-score-badge <?php echo esc_attr($score_class); ?>">
                                <?php echo esc_html(number_format($plugin['score'], 1)); ?>
                            </span>
                        </td>
                        <td>
                            <?php if (!empty($plugin['issues'])): ?>
                                <button class="button button-small wpcm-show-issues" data-plugin="<?php echo esc_attr($plugin['name']); ?>">
                                    <?php echo esc_html(count($plugin['issues'])); ?> <?php esc_html_e('issues', 'wp-plugin-conflict-mapper'); ?>
                                </button>
                                <div class="wpcm-issues-list" style="display: none;">
                                    <ul>
                                        <?php foreach ($plugin['issues'] as $issue): ?>
                                            <li><?php echo esc_html($issue); ?></li>
                                        <?php endforeach; ?>
                                    </ul>
                                </div>
                            <?php else: ?>
                                <span class="wpcm-badge wpcm-badge-success"><?php esc_html_e('No issues', 'wp-plugin-conflict-mapper'); ?></span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <?php if ($plugin['is_active']): ?>
                                <span class="wpcm-badge wpcm-badge-success"><?php esc_html_e('Active', 'wp-plugin-conflict-mapper'); ?></span>
                            <?php else: ?>
                                <span class="wpcm-badge wpcm-badge-inactive"><?php esc_html_e('Inactive', 'wp-plugin-conflict-mapper'); ?></span>
                            <?php endif; ?>
                        </td>
                        <td>
                            <button class="button button-small wpcm-analyze-plugin" data-plugin-file="<?php echo esc_attr($plugin_file); ?>">
                                <?php esc_html_e('Analyze', 'wp-plugin-conflict-mapper'); ?>
                            </button>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>

        <div class="wpcm-ranking-legend">
            <h3><?php esc_html_e('Score Legend', 'wp-plugin-conflict-mapper'); ?></h3>
            <ul>
                <li><span class="wpcm-score-badge wpcm-score-excellent">80+</span> <?php esc_html_e('Excellent - Well-behaved plugin with minimal conflicts', 'wp-plugin-conflict-mapper'); ?></li>
                <li><span class="wpcm-score-badge wpcm-score-good">60-79</span> <?php esc_html_e('Good - Minor issues that should be monitored', 'wp-plugin-conflict-mapper'); ?></li>
                <li><span class="wpcm-score-badge wpcm-score-fair">40-59</span> <?php esc_html_e('Fair - Several issues, review recommended', 'wp-plugin-conflict-mapper'); ?></li>
                <li><span class="wpcm-score-badge wpcm-score-poor">&lt;40</span> <?php esc_html_e('Poor - Significant issues, consider alternatives', 'wp-plugin-conflict-mapper'); ?></li>
            </ul>
        </div>
    <?php endif; ?>

    <div id="wpcm-plugin-analysis-modal" class="wpcm-modal" style="display: none;">
        <div class="wpcm-modal-content">
            <span class="wpcm-modal-close">&times;</span>
            <h2><?php esc_html_e('Plugin Analysis', 'wp-plugin-conflict-mapper'); ?></h2>
            <div id="wpcm-plugin-analysis-content"></div>
        </div>
    </div>
</div>
