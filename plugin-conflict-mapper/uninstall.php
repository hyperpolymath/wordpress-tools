<?php
/**
 * WP Plugin Conflict Mapper — Uninstallation Kernel.
 *
 * This script is executed by WordPress when the plugin is permanently 
 * deleted. It is responsible for a "Total Cleanup", ensuring that no 
 * traces of the plugin remain in the database or filesystem.
 *
 * CLEANUP SEQUENCE:
 * 1. **Data Wipe**: Drops the `wpcm_scans` and `wpcm_conflicts` tables.
 * 2. **Policy Wipe**: Deletes all `wpcm_`-prefixed options.
 * 3. **Cache Wipe**: Flushes all transients used by the diagnostic engine.
 * 4. **Hook Wipe**: Clears the scheduled daily cleanup event.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

// SECURITY: Only allow execution during an official plugin uninstall.
if (!defined('WP_UNINSTALL_PLUGIN')) { exit; }

global $wpdb;

// SCHEMA REMOVAL: Atomically drops the diagnostic tables.
$scans_table = $wpdb->prefix . 'wpcm_scans';
$conflicts_table = $wpdb->prefix . 'wpcm_conflicts';
$wpdb->query("DROP TABLE IF EXISTS {$conflicts_table}");
$wpdb->query("DROP TABLE IF EXISTS {$scans_table}");

// OPTION REMOVAL: Wipes the plugin's configuration space.
$wpdb->query("DELETE FROM {$wpdb->options} WHERE option_name LIKE 'wpcm_%'");

// TASK REMOVAL: Resets the WordPress cron schedule.
wp_clear_scheduled_hook('wpcm_cleanup_old_scans');
