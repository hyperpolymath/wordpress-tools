<?php
/**
 * Span Custom Post Types
 *
 * Registers custom post types for narrative spans: field notes,
 * constructs, glosses, and portals.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Register Field Notes post type
 */
function sinople_register_field_notes() {
	$labels = array(
		'name'                  => _x( 'Field Notes', 'Post type general name', 'sinople' ),
		'singular_name'         => _x( 'Field Note', 'Post type singular name', 'sinople' ),
		'menu_name'             => _x( 'Field Notes', 'Admin Menu text', 'sinople' ),
		'name_admin_bar'        => _x( 'Field Note', 'Add New on Toolbar', 'sinople' ),
		'add_new'               => __( 'Add New', 'sinople' ),
		'add_new_item'          => __( 'Add New Field Note', 'sinople' ),
		'new_item'              => __( 'New Field Note', 'sinople' ),
		'edit_item'             => __( 'Edit Field Note', 'sinople' ),
		'view_item'             => __( 'View Field Note', 'sinople' ),
		'all_items'             => __( 'All Field Notes', 'sinople' ),
		'search_items'          => __( 'Search Field Notes', 'sinople' ),
		'parent_item_colon'     => __( 'Parent Field Notes:', 'sinople' ),
		'not_found'             => __( 'No field notes found.', 'sinople' ),
		'not_found_in_trash'    => __( 'No field notes found in Trash.', 'sinople' ),
		'featured_image'        => _x( 'Field Note Image', 'Overrides the "Featured Image" phrase', 'sinople' ),
		'set_featured_image'    => _x( 'Set field note image', 'Overrides the "Set featured image" phrase', 'sinople' ),
		'remove_featured_image' => _x( 'Remove field note image', 'Overrides the "Remove featured image" phrase', 'sinople' ),
		'use_featured_image'    => _x( 'Use as field note image', 'Overrides the "Use as featured image" phrase', 'sinople' ),
		'archives'              => _x( 'Field Note archives', 'The post type archive label', 'sinople' ),
		'insert_into_item'      => _x( 'Insert into field note', 'Overrides the "Insert into post" phrase', 'sinople' ),
		'uploaded_to_this_item' => _x( 'Uploaded to this field note', 'Overrides the "Uploaded to this post" phrase', 'sinople' ),
		'filter_items_list'     => _x( 'Filter field notes list', 'Screen reader text', 'sinople' ),
		'items_list_navigation' => _x( 'Field notes list navigation', 'Screen reader text', 'sinople' ),
		'items_list'            => _x( 'Field notes list', 'Screen reader text', 'sinople' ),
	);

	$args = array(
		'labels'             => $labels,
		'public'             => true,
		'publicly_queryable' => true,
		'show_ui'            => true,
		'show_in_menu'       => true,
		'query_var'          => true,
		'rewrite'            => array( 'slug' => 'field-note' ),
		'capability_type'    => 'post',
		'has_archive'        => true,
		'hierarchical'       => false,
		'menu_position'      => 5,
		'menu_icon'          => 'dashicons-edit-page',
		'supports'           => array( 'title', 'editor', 'author', 'thumbnail', 'excerpt', 'comments', 'custom-fields', 'revisions' ),
		'show_in_rest'       => true,
		'taxonomies'         => array( 'emotion', 'motif', 'color' ),
	);

	register_post_type( 'field_note', $args );
}
add_action( 'init', 'sinople_register_field_notes' );

/**
 * Register Constructs post type
 */
function sinople_register_constructs() {
	$labels = array(
		'name'                  => _x( 'Constructs', 'Post type general name', 'sinople' ),
		'singular_name'         => _x( 'Construct', 'Post type singular name', 'sinople' ),
		'menu_name'             => _x( 'Constructs', 'Admin Menu text', 'sinople' ),
		'name_admin_bar'        => _x( 'Construct', 'Add New on Toolbar', 'sinople' ),
		'add_new'               => __( 'Add New', 'sinople' ),
		'add_new_item'          => __( 'Add New Construct', 'sinople' ),
		'new_item'              => __( 'New Construct', 'sinople' ),
		'edit_item'             => __( 'Edit Construct', 'sinople' ),
		'view_item'             => __( 'View Construct', 'sinople' ),
		'all_items'             => __( 'All Constructs', 'sinople' ),
		'search_items'          => __( 'Search Constructs', 'sinople' ),
		'not_found'             => __( 'No constructs found.', 'sinople' ),
		'not_found_in_trash'    => __( 'No constructs found in Trash.', 'sinople' ),
	);

	$args = array(
		'labels'             => $labels,
		'public'             => true,
		'publicly_queryable' => true,
		'show_ui'            => true,
		'show_in_menu'       => true,
		'query_var'          => true,
		'rewrite'            => array( 'slug' => 'construct' ),
		'capability_type'    => 'post',
		'has_archive'        => true,
		'hierarchical'       => false,
		'menu_position'      => 6,
		'menu_icon'          => 'dashicons-admin-users',
		'supports'           => array( 'title', 'editor', 'thumbnail', 'excerpt', 'custom-fields', 'revisions' ),
		'show_in_rest'       => true,
		'taxonomies'         => array( 'archetype', 'symbol' ),
	);

	register_post_type( 'construct', $args );
}
add_action( 'init', 'sinople_register_constructs' );

/**
 * Register Glosses post type
 */
function sinople_register_glosses() {
	$labels = array(
		'name'               => _x( 'Glosses', 'Post type general name', 'sinople' ),
		'singular_name'      => _x( 'Gloss', 'Post type singular name', 'sinople' ),
		'menu_name'          => _x( 'Glosses', 'Admin Menu text', 'sinople' ),
		'add_new'            => __( 'Add New', 'sinople' ),
		'add_new_item'       => __( 'Add New Gloss', 'sinople' ),
		'new_item'           => __( 'New Gloss', 'sinople' ),
		'edit_item'          => __( 'Edit Gloss', 'sinople' ),
		'view_item'          => __( 'View Gloss', 'sinople' ),
		'all_items'          => __( 'All Glosses', 'sinople' ),
		'search_items'       => __( 'Search Glosses', 'sinople' ),
		'not_found'          => __( 'No glosses found.', 'sinople' ),
		'not_found_in_trash' => __( 'No glosses found in Trash.', 'sinople' ),
	);

	$args = array(
		'labels'             => $labels,
		'public'             => true,
		'publicly_queryable' => true,
		'show_ui'            => true,
		'show_in_menu'       => true,
		'query_var'          => true,
		'rewrite'            => array( 'slug' => 'gloss' ),
		'capability_type'    => 'post',
		'has_archive'        => false,
		'hierarchical'       => false,
		'menu_position'      => 7,
		'menu_icon'          => 'dashicons-editor-quote',
		'supports'           => array( 'title', 'editor', 'custom-fields' ),
		'show_in_rest'       => true,
	);

	register_post_type( 'gloss', $args );
}
add_action( 'init', 'sinople_register_glosses' );

/**
 * Register Portals post type
 */
function sinople_register_portals() {
	$labels = array(
		'name'               => _x( 'Portals', 'Post type general name', 'sinople' ),
		'singular_name'      => _x( 'Portal', 'Post type singular name', 'sinople' ),
		'menu_name'          => _x( 'Portals', 'Admin Menu text', 'sinople' ),
		'add_new'            => __( 'Add New', 'sinople' ),
		'add_new_item'       => __( 'Add New Portal', 'sinople' ),
		'new_item'           => __( 'New Portal', 'sinople' ),
		'edit_item'          => __( 'Edit Portal', 'sinople' ),
		'view_item'          => __( 'View Portal', 'sinople' ),
		'all_items'          => __( 'All Portals', 'sinople' ),
		'search_items'       => __( 'Search Portals', 'sinople' ),
		'not_found'          => __( 'No portals found.', 'sinople' ),
		'not_found_in_trash' => __( 'No portals found in Trash.', 'sinople' ),
	);

	$args = array(
		'labels'             => $labels,
		'public'             => true,
		'publicly_queryable' => true,
		'show_ui'            => true,
		'show_in_menu'       => true,
		'query_var'          => true,
		'rewrite'            => array( 'slug' => 'portal' ),
		'capability_type'    => 'post',
		'has_archive'        => true,
		'hierarchical'       => false,
		'menu_position'      => 8,
		'menu_icon'          => 'dashicons-admin-links',
		'supports'           => array( 'title', 'editor', 'thumbnail', 'excerpt', 'custom-fields' ),
		'show_in_rest'       => true,
		'taxonomies'         => array( 'inspiration_type' ),
	);

	register_post_type( 'portal', $args );
}
add_action( 'init', 'sinople_register_portals' );

/**
 * Get span type for current post
 */
function sinople_get_span_type( $post_id = null ) {
	if ( ! $post_id ) {
		$post_id = get_the_ID();
	}

	$post_type = get_post_type( $post_id );

	$span_types = array(
		'field_note' => 'field-note',
		'construct'  => 'construct',
		'gloss'      => 'gloss',
		'portal'     => 'portal',
	);

	return isset( $span_types[ $post_type ] ) ? $span_types[ $post_type ] : null;
}

/**
 * Get span schema for JSON-LD
 */
function sinople_get_span_schema( $post_id ) {
	$span_type = sinople_get_span_type( $post_id );

	if ( ! $span_type ) {
		return null;
	}

	$schemas = array(
		'field-note' => array(
			'@type'       => 'Article',
			'articleBody' => get_the_content( null, false, $post_id ),
			'wordCount'   => str_word_count( wp_strip_all_tags( get_the_content( null, false, $post_id ) ) ),
		),
		'construct'  => array(
			'@type'       => 'Person',
			'name'        => get_the_title( $post_id ),
			'description' => get_the_excerpt( $post_id ),
		),
		'gloss'      => array(
			'@type'    => 'Comment',
			'text'     => get_the_content( null, false, $post_id ),
		),
		'portal'     => array(
			'@type'       => 'WebPage',
			'name'        => get_the_title( $post_id ),
			'description' => get_the_excerpt( $post_id ),
		),
	);

	return isset( $schemas[ $span_type ] ) ? $schemas[ $span_type ] : null;
}

/**
 * Get all registered span types
 */
function sinople_get_span_types() {
	return array(
		array(
			'name'  => 'field_note',
			'label' => __( 'Field Notes', 'sinople' ),
			'uri'   => home_url( '/field-note/' ),
		),
		array(
			'name'  => 'construct',
			'label' => __( 'Constructs', 'sinople' ),
			'uri'   => home_url( '/construct/' ),
		),
		array(
			'name'  => 'gloss',
			'label' => __( 'Glosses', 'sinople' ),
			'uri'   => home_url( '/gloss/' ),
		),
		array(
			'name'  => 'portal',
			'label' => __( 'Portals', 'sinople' ),
			'uri'   => home_url( '/portal/' ),
		),
	);
}
