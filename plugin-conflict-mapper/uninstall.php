<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Uninstaller
 *
 * Handles plugin uninstallation and cleanup
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.0.0
 */

declare(strict_types=1);

// Exit if accessed directly or not uninstalling
if (!defined('WP_UNINSTALL_PLUGIN')) {
    exit;
}

global $wpdb;

// Delete database tables
$scans_table = $wpdb->prefix . 'wpcm_scans';
$conflicts_table = $wpdb->prefix . 'wpcm_conflicts';

$wpdb->query("DROP TABLE IF EXISTS {$conflicts_table}");
$wpdb->query("DROP TABLE IF EXISTS {$scans_table}");

// Delete options
$wpdb->query("DELETE FROM {$wpdb->options} WHERE option_name LIKE 'wpcm_%'");

// Delete transients
$wpdb->query(
    $wpdb->prepare(
        "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s",
        $wpdb->esc_like('_transient_wpcm_') . '%'
    )
);

$wpdb->query(
    $wpdb->prepare(
        "DELETE FROM {$wpdb->options} WHERE option_name LIKE %s",
        $wpdb->esc_like('_transient_timeout_wpcm_') . '%'
    )
);

// Clear scheduled events
wp_clear_scheduled_hook('wpcm_scheduled_scan');
wp_clear_scheduled_hook('wpcm_cleanup_old_scans');

// Flush rewrite rules
flush_rewrite_rules();
