<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Dashboard View
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}
?>

<div class="wrap wpcm-dashboard">
    <h1><?php esc_html_e('Plugin Conflict Mapper - Dashboard', 'wp-plugin-conflict-mapper'); ?></h1>

    <div class="wpcm-stats-grid">
        <div class="wpcm-stat-box">
            <div class="wpcm-stat-icon dashicons dashicons-admin-plugins"></div>
            <div class="wpcm-stat-content">
                <h3><?php echo esc_html(count($plugins)); ?></h3>
                <p><?php esc_html_e('Total Plugins', 'wp-plugin-conflict-mapper'); ?></p>
            </div>
        </div>

        <div class="wpcm-stat-box">
            <div class="wpcm-stat-icon dashicons dashicons-yes-alt"></div>
            <div class="wpcm-stat-content">
                <h3><?php echo esc_html(count($active_plugins)); ?></h3>
                <p><?php esc_html_e('Active Plugins', 'wp-plugin-conflict-mapper'); ?></p>
            </div>
        </div>

        <div class="wpcm-stat-box">
            <div class="wpcm-stat-icon dashicons dashicons-chart-bar"></div>
            <div class="wpcm-stat-content">
                <h3><?php echo esc_html($stats['total_scans'] ?? 0); ?></h3>
                <p><?php esc_html_e('Total Scans', 'wp-plugin-conflict-mapper'); ?></p>
            </div>
        </div>

        <div class="wpcm-stat-box <?php echo ($stats['high_severity_conflicts'] ?? 0) > 0 ? 'wpcm-stat-warning' : ''; ?>">
            <div class="wpcm-stat-icon dashicons dashicons-warning"></div>
            <div class="wpcm-stat-content">
                <h3><?php echo esc_html($stats['high_severity_conflicts'] ?? 0); ?></h3>
                <p><?php esc_html_e('High Severity Conflicts', 'wp-plugin-conflict-mapper'); ?></p>
            </div>
        </div>
    </div>

    <div class="wpcm-actions">
        <button id="wpcm-run-scan" class="button button-primary button-hero">
            <span class="dashicons dashicons-update"></span>
            <?php esc_html_e('Run New Scan', 'wp-plugin-conflict-mapper'); ?>
        </button>
    </div>

    <div id="wpcm-scan-results" class="wpcm-scan-results" style="display: none;">
        <h2><?php esc_html_e('Latest Scan Results', 'wp-plugin-conflict-mapper'); ?></h2>
        <div id="wpcm-results-content"></div>
    </div>

    <div class="wpcm-recent-activity">
        <h2><?php esc_html_e('Recent Activity', 'wp-plugin-conflict-mapper'); ?></h2>

        <?php if (!empty($stats['last_scan'])): ?>
            <p>
                <?php
                echo sprintf(
                    esc_html__('Last scan: %s', 'wp-plugin-conflict-mapper'),
                    esc_html(mysql2date(get_option('date_format') . ' ' . get_option('time_format'), $stats['last_scan']))
                );
                ?>
            </p>
        <?php else: ?>
            <p><?php esc_html_e('No scans yet. Click "Run New Scan" to get started.', 'wp-plugin-conflict-mapper'); ?></p>
        <?php endif; ?>

        <p>
            <a href="<?php echo esc_url(admin_url('admin.php?page=wpcm-reports')); ?>" class="button">
                <?php esc_html_e('View All Reports', 'wp-plugin-conflict-mapper'); ?>
            </a>
            <a href="<?php echo esc_url(admin_url('admin.php?page=wpcm-rankings')); ?>" class="button">
                <?php esc_html_e('View Plugin Rankings', 'wp-plugin-conflict-mapper'); ?>
            </a>
        </p>
    </div>

    <div class="wpcm-quick-tips">
        <h2><?php esc_html_e('Quick Tips', 'wp-plugin-conflict-mapper'); ?></h2>
        <ul>
            <li><?php esc_html_e('Run scans regularly to catch new conflicts early', 'wp-plugin-conflict-mapper'); ?></li>
            <li><?php esc_html_e('Review high-severity conflicts first', 'wp-plugin-conflict-mapper'); ?></li>
            <li><?php esc_html_e('Keep only one plugin per function (e.g., one SEO plugin, one caching plugin)', 'wp-plugin-conflict-mapper'); ?></li>
            <li><?php esc_html_e('Check plugin rankings to identify poorly-performing plugins', 'wp-plugin-conflict-mapper'); ?></li>
        </ul>
    </div>
</div>
