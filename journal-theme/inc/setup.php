<?php
/**
 * Additional Theme Setup
 *
 * Extended configuration beyond core setup.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Add body classes for modern feature detection
 */
function sinople_body_classes( $classes ) {
	// Add class for singular/archive distinction
	if ( is_singular() ) {
		$classes[] = 'singular';
	} else {
		$classes[] = 'archive-view';
	}

	// Add span type class if applicable
	if ( function_exists( 'sinople_get_span_type' ) ) {
		$span_type = sinople_get_span_type();
		if ( $span_type ) {
			$classes[] = 'span-' . sanitize_html_class( $span_type );
		}
	}

	// Add accessibility class for high contrast mode
	if ( isset( $_COOKIE['sinople_high_contrast'] ) && $_COOKIE['sinople_high_contrast'] === 'true' ) {
		$classes[] = 'high-contrast';
	}

	// Add class for reduced motion preference
	$classes[] = 'respects-motion-preference';

	// Add class for color scheme preference
	$classes[] = 'supports-color-scheme';

	return $classes;
}
add_filter( 'body_class', 'sinople_body_classes' );

/**
 * Add post classes with semantic information
 */
function sinople_post_classes( $classes, $class, $post_id ) {
	// Add microformats2 h-entry class
	if ( in_array( get_post_type( $post_id ), array( 'post', 'page' ), true ) ) {
		$classes[] = 'h-entry';
	}

	// Add Schema.org type
	$classes[] = 'schema-article';

	// Add reading time class
	$reading_time = sinople_get_reading_time( $post_id );
	if ( $reading_time ) {
		$classes[] = 'reading-time-' . absint( ceil( $reading_time ) ) . '-min';
	}

	return $classes;
}
add_filter( 'post_class', 'sinople_post_classes', 10, 3 );

/**
 * Calculate reading time for post
 */
function sinople_get_reading_time( $post_id = null ) {
	if ( ! $post_id ) {
		$post_id = get_the_ID();
	}

	$content    = get_post_field( 'post_content', $post_id );
	$word_count = str_word_count( wp_strip_all_tags( $content ) );

	// Average reading speed: 200 words per minute
	$reading_time = $word_count / 200;

	return apply_filters( 'sinople_reading_time', $reading_time, $post_id );
}

/**
 * Custom excerpt length
 */
function sinople_excerpt_length( $length ) {
	return apply_filters( 'sinople_excerpt_length', 40 );
}
add_filter( 'excerpt_length', 'sinople_excerpt_length' );

/**
 * Custom excerpt more link
 */
function sinople_excerpt_more( $more ) {
	return '&hellip; <a class="read-more" href="' . esc_url( get_permalink() ) . '">' . esc_html__( 'Continue reading', 'sinople' ) . '<span class="screen-reader-text"> ' . esc_html( get_the_title() ) . '</span></a>';
}
add_filter( 'excerpt_more', 'sinople_excerpt_more' );

/**
 * Add custom query vars for semantic endpoints
 */
function sinople_query_vars( $vars ) {
	$vars[] = 'void';
	$vars[] = 'ndjson';
	$vars[] = 'capnproto';
	$vars[] = 'semantic_format';
	return $vars;
}
add_filter( 'query_vars', 'sinople_query_vars' );

/**
 * Register custom rewrite rules for semantic endpoints
 */
function sinople_rewrite_rules() {
	add_rewrite_rule( '^void\.rdf$', 'index.php?void=1', 'top' );
	add_rewrite_rule( '^feed/ndjson/?$', 'index.php?ndjson=1', 'top' );
	add_rewrite_rule( '^feed/capnproto/?$', 'index.php?capnproto=1', 'top' );
	add_rewrite_rule( '^\.well-known/void$', 'index.php?void=1', 'top' );
}
add_action( 'init', 'sinople_rewrite_rules' );

/**
 * Flush rewrite rules on theme activation
 */
function sinople_activate() {
	sinople_rewrite_rules();
	flush_rewrite_rules();
}
add_action( 'after_switch_theme', 'sinople_activate' );
