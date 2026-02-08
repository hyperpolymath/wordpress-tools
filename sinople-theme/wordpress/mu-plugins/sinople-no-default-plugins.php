<?php
/**
 * Plugin Name: Sinople - No Default Plugins
 * Description: Prevents Akismet and Hello Dolly from being installed during WordPress initialization (users can still install them later)
 * Version: 1.0.0
 * Author: Sinople Theme Contributors
 * License: GPL-2.0-or-later
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

/**
 * Remove default plugins from WordPress core installation
 *
 * This only affects the initial WordPress installation.
 * Users can still install these plugins later if they choose.
 */
function sinople_remove_default_plugins_on_install() {
    // Only run during WordPress installation
    if ( ! defined( 'WP_INSTALLING' ) || ! WP_INSTALLING ) {
        return;
    }

    $default_plugins = array(
        'akismet/akismet.php',
        'hello.php'
    );

    foreach ( $default_plugins as $plugin ) {
        $plugin_file = WP_PLUGIN_DIR . '/' . $plugin;

        if ( file_exists( $plugin_file ) ) {
            // Delete without deactivating (not installed yet during WP_INSTALLING)
            @unlink( $plugin_file );

            // If it's in a directory, remove the directory
            $plugin_dir = dirname( $plugin_file );
            if ( $plugin_dir !== WP_PLUGIN_DIR && is_dir( $plugin_dir ) ) {
                $files = glob( $plugin_dir . '/*' );
                foreach ( $files as $file ) {
                    @unlink( $file );
                }
                @rmdir( $plugin_dir );
            }
        }
    }
}
add_action( 'wp_install', 'sinople_remove_default_plugins_on_install', 999 );

/**
 * Filter default plugins list during installation
 *
 * Removes Akismet and Hello Dolly from the default plugin list
 * that WordPress installs on new sites.
 */
function sinople_filter_default_plugin_list( $plugins ) {
    if ( ! is_array( $plugins ) ) {
        return $plugins;
    }

    return array_filter( $plugins, function( $plugin ) {
        $plugin_slug = is_string( $plugin ) ? $plugin : ( $plugin['slug'] ?? '' );
        return ! in_array( $plugin_slug, array( 'akismet', 'hello-dolly', 'hello' ), true );
    } );
}
add_filter( 'default_plugins', 'sinople_filter_default_plugin_list', 999 );
