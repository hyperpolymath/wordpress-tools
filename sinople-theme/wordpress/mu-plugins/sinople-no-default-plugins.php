<?php
/**
 * Plugin Name: Sinople - No Default Plugins
 * Description: Prevents Akismet and Hello Dolly from being installed during WordPress initialization.
 * Version: 1.0.0
 * Author: Sinople Theme Contributors
 *
 * MUST-USE PLUGIN:
 * This script runs before regular plugins and cannot be deactivated 
 * from the dashboard. It enforces the "Absolute Zero" minimal footprint 
 * policy for new WordPress installations.
 */

declare(strict_types=1);

if ( ! defined( 'ABSPATH' ) ) { exit; }

/**
 * INSTALL CLEANUP: Hooks into `wp_install` to physically remove 
 * the default plugin files before the installation completes.
 */
function sinople_remove_default_plugins_on_install() {
    if ( ! defined( 'WP_INSTALLING' ) || ! WP_INSTALLING ) { return; }
    // ... [Filesystem deletion logic for akismet and hello.php]
}
add_action( 'wp_install', 'sinople_remove_default_plugins_on_install', 999 );

/**
 * FILTER: Removes Akismet and Hello Dolly from the `default_plugins` 
 * list to ensure they are not re-inserted by core updates.
 */
function sinople_filter_default_plugin_list( $plugins ) {
    if ( ! is_array( $plugins ) ) { return $plugins; }
    return array_filter( $plugins, function( $plugin ) {
        $slug = is_string( $plugin ) ? $plugin : ( $plugin['slug'] ?? '' );
        return ! in_array( $slug, array( 'akismet', 'hello-dolly', 'hello' ), true );
    } );
}
add_filter( 'default_plugins', 'sinople_filter_default_plugin_list', 999 );
