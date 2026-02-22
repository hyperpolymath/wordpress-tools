<?php
/**
 * Sinople Taxonomies — Semantic Categorization.
 *
 * This module defines the custom taxonomies used to organize semantic 
 * knowledge within the Sinople theme.
 *
 * PRIMARY TAXONOMY:
 * - `construct_type`: Hierarchical classification for Constructs 
 *   (e.g. Philosophical, Linguistic, Mathematical).
 *
 * @package Sinople
 */

declare(strict_types=1);

if ( ! defined( 'ABSPATH' ) ) { exit; }

/**
 * REGISTRATION: Hooks into WordPress `init` to define taxonomies.
 * Enables REST API visibility for use in the ReScript frontend and 
 * the Block Editor.
 */
function sinople_register_taxonomies() {
    register_taxonomy( 'construct_type', 'sinople_construct', array(
        'hierarchical' => true,
        'labels' => array( 'name' => 'Construct Types' ),
        'show_in_rest' => true, // REQUIRED for Gutenberg and API integration.
    ));
}
add_action( 'init', 'sinople_register_taxonomies' );
