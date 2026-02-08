<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Settings View
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

// Save settings if form submitted
if (isset($_POST['wpcm_save_settings'])) {
    check_admin_referer('wpcm_settings_nonce');

    if (current_user_can('manage_options')) {
        update_option('wpcm_scan_frequency', sanitize_text_field($_POST['wpcm_scan_frequency']));
        update_option('wpcm_auto_scan', sanitize_text_field($_POST['wpcm_auto_scan']));
        update_option('wpcm_cleanup_days', absint($_POST['wpcm_cleanup_days']));
        update_option('wpcm_email_reports', sanitize_text_field($_POST['wpcm_email_reports']));
        update_option('wpcm_admin_email', sanitize_email($_POST['wpcm_admin_email']));
        update_option('wpcm_severity_threshold', sanitize_text_field($_POST['wpcm_severity_threshold']));

        echo '<div class="notice notice-success is-dismissible"><p>' . esc_html__('Settings saved successfully.', 'wp-plugin-conflict-mapper') . '</p></div>';
    }
}

$settings = WPCM_Settings::get_all();
?>

<div class="wrap wpcm-settings">
    <h1><?php esc_html_e('Plugin Conflict Mapper - Settings', 'wp-plugin-conflict-mapper'); ?></h1>

    <form method="post" action="">
        <?php wp_nonce_field('wpcm_settings_nonce'); ?>

        <table class="form-table">
            <tbody>
                <tr>
                    <th scope="row">
                        <label for="wpcm_auto_scan"><?php esc_html_e('Automatic Scanning', 'wp-plugin-conflict-mapper'); ?></label>
                    </th>
                    <td>
                        <select name="wpcm_auto_scan" id="wpcm_auto_scan">
                            <option value="no" <?php selected($settings['auto_scan'], 'no'); ?>><?php esc_html_e('Disabled', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="yes" <?php selected($settings['auto_scan'], 'yes'); ?>><?php esc_html_e('Enabled', 'wp-plugin-conflict-mapper'); ?></option>
                        </select>
                        <p class="description"><?php esc_html_e('Automatically run scans on a schedule', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>

                <tr>
                    <th scope="row">
                        <label for="wpcm_scan_frequency"><?php esc_html_e('Scan Frequency', 'wp-plugin-conflict-mapper'); ?></label>
                    </th>
                    <td>
                        <select name="wpcm_scan_frequency" id="wpcm_scan_frequency">
                            <option value="daily" <?php selected($settings['scan_frequency'], 'daily'); ?>><?php esc_html_e('Daily', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="weekly" <?php selected($settings['scan_frequency'], 'weekly'); ?>><?php esc_html_e('Weekly', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="monthly" <?php selected($settings['scan_frequency'], 'monthly'); ?>><?php esc_html_e('Monthly', 'wp-plugin-conflict-mapper'); ?></option>
                        </select>
                        <p class="description"><?php esc_html_e('How often to run automatic scans', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>

                <tr>
                    <th scope="row">
                        <label for="wpcm_cleanup_days"><?php esc_html_e('Data Retention', 'wp-plugin-conflict-mapper'); ?></label>
                    </th>
                    <td>
                        <input type="number" name="wpcm_cleanup_days" id="wpcm_cleanup_days" value="<?php echo esc_attr($settings['cleanup_days']); ?>" min="7" max="365" class="small-text">
                        <?php esc_html_e('days', 'wp-plugin-conflict-mapper'); ?>
                        <p class="description"><?php esc_html_e('Automatically delete scan results older than this many days', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>

                <tr>
                    <th scope="row">
                        <label for="wpcm_severity_threshold"><?php esc_html_e('Alert Threshold', 'wp-plugin-conflict-mapper'); ?></label>
                    </th>
                    <td>
                        <select name="wpcm_severity_threshold" id="wpcm_severity_threshold">
                            <option value="low" <?php selected($settings['severity_threshold'], 'low'); ?>><?php esc_html_e('Low', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="medium" <?php selected($settings['severity_threshold'], 'medium'); ?>><?php esc_html_e('Medium', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="high" <?php selected($settings['severity_threshold'], 'high'); ?>><?php esc_html_e('High', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="critical" <?php selected($settings['severity_threshold'], 'critical'); ?>><?php esc_html_e('Critical', 'wp-plugin-conflict-mapper'); ?></option>
                        </select>
                        <p class="description"><?php esc_html_e('Only show conflicts at or above this severity level', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>

                <tr>
                    <th scope="row">
                        <label for="wpcm_email_reports"><?php esc_html_e('Email Reports', 'wp-plugin-conflict-mapper'); ?></label>
                    </th>
                    <td>
                        <select name="wpcm_email_reports" id="wpcm_email_reports">
                            <option value="no" <?php selected($settings['email_reports'], 'no'); ?>><?php esc_html_e('Disabled', 'wp-plugin-conflict-mapper'); ?></option>
                            <option value="yes" <?php selected($settings['email_reports'], 'yes'); ?>><?php esc_html_e('Enabled', 'wp-plugin-conflict-mapper'); ?></option>
                        </select>
                        <p class="description"><?php esc_html_e('Send email notifications when high-severity conflicts are detected', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>

                <tr>
                    <th scope="row">
                        <label for="wpcm_admin_email"><?php esc_html_e('Notification Email', 'wp-plugin-conflict-mapper'); ?></label>
                    </th>
                    <td>
                        <input type="email" name="wpcm_admin_email" id="wpcm_admin_email" value="<?php echo esc_attr($settings['admin_email']); ?>" class="regular-text">
                        <p class="description"><?php esc_html_e('Email address for receiving scan reports', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>
            </tbody>
        </table>

        <h2><?php esc_html_e('Maintenance', 'wp-plugin-conflict-mapper'); ?></h2>

        <table class="form-table">
            <tbody>
                <tr>
                    <th scope="row"><?php esc_html_e('Cache', 'wp-plugin-conflict-mapper'); ?></th>
                    <td>
                        <button type="button" id="wpcm-clear-cache-btn" class="button">
                            <?php esc_html_e('Clear Cache', 'wp-plugin-conflict-mapper'); ?>
                        </button>
                        <p class="description"><?php esc_html_e('Clear all cached scan data and rankings', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>

                <tr>
                    <th scope="row"><?php esc_html_e('Database', 'wp-plugin-conflict-mapper'); ?></th>
                    <td>
                        <button type="button" id="wpcm-cleanup-old-scans-btn" class="button" data-days="<?php echo esc_attr($settings['cleanup_days']); ?>">
                            <?php esc_html_e('Clean Up Old Scans Now', 'wp-plugin-conflict-mapper'); ?>
                        </button>
                        <p class="description"><?php esc_html_e('Delete scan results older than the configured retention period', 'wp-plugin-conflict-mapper'); ?></p>
                    </td>
                </tr>
            </tbody>
        </table>

        <p class="submit">
            <input type="submit" name="wpcm_save_settings" class="button button-primary" value="<?php esc_attr_e('Save Settings', 'wp-plugin-conflict-mapper'); ?>">
        </p>
    </form>

    <div class="wpcm-settings-info">
        <h2><?php esc_html_e('About Plugin Conflict Mapper', 'wp-plugin-conflict-mapper'); ?></h2>
        <p><?php esc_html_e('Version:', 'wp-plugin-conflict-mapper'); ?> <strong><?php echo esc_html(WPCM_VERSION); ?></strong></p>
        <p><?php esc_html_e('Plugin Conflict Mapper helps you identify and resolve conflicts between WordPress plugins, improving site stability and performance.', 'wp-plugin-conflict-mapper'); ?></p>
    </div>
</div>
