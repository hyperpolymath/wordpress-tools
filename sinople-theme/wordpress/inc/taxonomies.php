<?php
/**
 * Custom Taxonomies for Sinople Theme
 *
 * @package Sinople
 * @since 1.0.0
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function sinople_register_taxonomies() {
    register_taxonomy( 'construct_type', 'sinople_construct', array(
        'hierarchical' => true,
        'labels' => array( 'name' => 'Construct Types' ),
        'show_in_rest' => true,
    ));
}
add_action( 'init', 'sinople_register_taxonomies' );
