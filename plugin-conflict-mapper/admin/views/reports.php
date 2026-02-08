<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Reports View
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}
?>

<div class="wrap wpcm-reports">
    <h1><?php esc_html_e('Scan Reports', 'wp-plugin-conflict-mapper'); ?></h1>

    <?php if (empty($scans)): ?>
        <div class="notice notice-info">
            <p><?php esc_html_e('No scan reports available. Run a scan from the dashboard to generate reports.', 'wp-plugin-conflict-mapper'); ?></p>
        </div>
        <p>
            <a href="<?php echo esc_url(admin_url('admin.php?page=wpcm-dashboard')); ?>" class="button button-primary">
                <?php esc_html_e('Go to Dashboard', 'wp-plugin-conflict-mapper'); ?>
            </a>
        </p>
    <?php else: ?>
        <table class="wp-list-table widefat fixed striped wpcm-reports-table">
            <thead>
                <tr>
                    <th><?php esc_html_e('Scan ID', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Date', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Plugins', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Conflicts', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Overlaps', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Type', 'wp-plugin-conflict-mapper'); ?></th>
                    <th><?php esc_html_e('Actions', 'wp-plugin-conflict-mapper'); ?></th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($scans as $scan): ?>
                    <tr>
                        <td><strong>#<?php echo esc_html($scan->id); ?></strong></td>
                        <td><?php echo esc_html(mysql2date(get_option('date_format') . ' ' . get_option('time_format'), $scan->scan_date)); ?></td>
                        <td><?php echo esc_html($scan->plugin_count); ?></td>
                        <td>
                            <?php if ($scan->conflict_count > 0): ?>
                                <span class="wpcm-badge wpcm-badge-warning"><?php echo esc_html($scan->conflict_count); ?></span>
                            <?php else: ?>
                                <span class="wpcm-badge wpcm-badge-success">0</span>
                            <?php endif; ?>
                        </td>
                        <td><?php echo esc_html($scan->overlap_count); ?></td>
                        <td><?php echo esc_html(ucfirst($scan->scan_type)); ?></td>
                        <td>
                            <button class="button button-small wpcm-view-scan" data-scan-id="<?php echo esc_attr($scan->id); ?>">
                                <?php esc_html_e('View', 'wp-plugin-conflict-mapper'); ?>
                            </button>
                            <button class="button button-small wpcm-export-scan" data-scan-id="<?php echo esc_attr($scan->id); ?>" data-format="json">
                                <?php esc_html_e('Export JSON', 'wp-plugin-conflict-mapper'); ?>
                            </button>
                            <button class="button button-small wpcm-export-scan" data-scan-id="<?php echo esc_attr($scan->id); ?>" data-format="csv">
                                <?php esc_html_e('Export CSV', 'wp-plugin-conflict-mapper'); ?>
                            </button>
                            <button class="button button-small button-link-delete wpcm-delete-scan" data-scan-id="<?php echo esc_attr($scan->id); ?>">
                                <?php esc_html_e('Delete', 'wp-plugin-conflict-mapper'); ?>
                            </button>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>

    <div id="wpcm-scan-details-modal" class="wpcm-modal" style="display: none;">
        <div class="wpcm-modal-content">
            <span class="wpcm-modal-close">&times;</span>
            <h2><?php esc_html_e('Scan Details', 'wp-plugin-conflict-mapper'); ?></h2>
            <div id="wpcm-scan-details-content"></div>
        </div>
    </div>
</div>
