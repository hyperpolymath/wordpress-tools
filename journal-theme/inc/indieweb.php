<?php
/**
 * IndieWeb Integration
 *
 * Microformats v2, Webmentions, POSSE, and IndieAuth support.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Add microformats2 classes to post
 */
function sinople_add_microformats( $classes ) {
	if ( is_singular() ) {
		$classes[] = 'h-entry';
	}
	return $classes;
}
add_filter( 'post_class', 'sinople_add_microformats' );

/**
 * Get rel=me links for author
 */
function sinople_get_rel_me_links() {
	$author_id = get_the_author_meta( 'ID' );
	$links     = get_user_meta( $author_id, 'sinople_rel_me_links', true );

	if ( empty( $links ) ) {
		return;
	}

	echo '<ul class="rel-me-links">';
	foreach ( $links as $link ) {
		printf(
			'<li><a href="%s" rel="me">%s</a></li>',
			esc_url( $link['url'] ),
			esc_html( $link['label'] )
		);
	}
	echo '</ul>';
}

/**
 * Add webmention endpoint to head
 */
function sinople_webmention_endpoint() {
	if ( function_exists( 'webmention_discovery' ) ) {
		echo '<link rel="webmention" href="' . esc_url( home_url( '/webmention' ) ) . '">' . "\n";
	}
}
add_action( 'wp_head', 'sinople_webmention_endpoint', 1 );

/**
 * Add IndieAuth endpoint
 */
function sinople_indieauth_endpoint() {
	echo '<link rel="authorization_endpoint" href="https://indieauth.com/auth">' . "\n";
	echo '<link rel="token_endpoint" href="https://tokens.indieauth.com/token">' . "\n";
}
add_action( 'wp_head', 'sinople_indieauth_endpoint', 1 );

/**
 * Add micropub endpoint
 */
function sinople_micropub_endpoint() {
	echo '<link rel="micropub" href="' . esc_url( home_url( '/micropub' ) ) . '">' . "\n";
}
add_action( 'wp_head', 'sinople_micropub_endpoint', 1 );

/**
 * Add microsub endpoint
 */
function sinople_microsub_endpoint() {
	echo '<link rel="microsub" href="' . esc_url( home_url( '/microsub' ) ) . '">' . "\n";
}
add_action( 'wp_head', 'sinople_microsub_endpoint', 1 );

/**
 * Add h-card to author bio
 */
function sinople_author_hcard( $content ) {
	if ( ! is_singular() || ! is_main_query() ) {
		return $content;
	}

	$author_id = get_the_author_meta( 'ID' );

	$hcard = '<div class="h-card author-bio" itemscope itemtype="https://schema.org/Person">';
	$hcard .= '<a class="u-url" href="' . esc_url( get_author_posts_url( $author_id ) ) . '">';
	$hcard .= get_avatar( $author_id, 80, '', get_the_author(), array( 'class' => 'u-photo' ) );
	$hcard .= '</a>';
	$hcard .= '<p class="p-name" itemprop="name">' . esc_html( get_the_author() ) . '</p>';
	$hcard .= '<p class="p-note" itemprop="description">' . wp_kses_post( get_the_author_meta( 'description' ) ) . '</p>';
	$hcard .= '</div>';

	return $content . $hcard;
}
add_filter( 'the_content', 'sinople_author_hcard', 20 );

/**
 * Add u-syndication links for POSSE
 */
function sinople_syndication_links( $post_id = null ) {
	if ( ! $post_id ) {
		$post_id = get_the_ID();
	}

	$syndication_links = get_post_meta( $post_id, 'syndication_links', true );

	if ( empty( $syndication_links ) ) {
		return;
	}

	echo '<div class="syndication-links">';
	echo '<p>' . esc_html__( 'Also posted on:', 'sinople' ) . '</p>';
	echo '<ul>';

	foreach ( $syndication_links as $link ) {
		printf(
			'<li><a class="u-syndication" href="%s" rel="syndication">%s</a></li>',
			esc_url( $link['url'] ),
			esc_html( $link['service'] )
		);
	}

	echo '</ul>';
	echo '</div>';
}

/**
 * Support for Post Kinds plugin
 */
function sinople_post_kind_support() {
	if ( ! function_exists( 'get_post_kind' ) ) {
		return;
	}

	$kind = get_post_kind();

	if ( ! $kind || 'article' === $kind ) {
		return;
	}

	// Add kind-specific microformats
	$kind_classes = array(
		'note'     => 'h-entry',
		'reply'    => 'h-entry u-in-reply-to',
		'repost'   => 'h-entry u-repost-of',
		'like'     => 'h-entry u-like-of',
		'bookmark' => 'h-entry u-bookmark-of',
	);

	if ( isset( $kind_classes[ $kind ] ) ) {
		add_filter(
			'post_class',
			function ( $classes ) use ( $kind_classes, $kind ) {
				$classes[] = $kind_classes[ $kind ];
				return $classes;
			}
		);
	}
}
add_action( 'wp_head', 'sinople_post_kind_support' );

/**
 * Add JSON Feed support
 */
function sinople_json_feed_url() {
	return home_url( '/feed/json/' );
}

/**
 * Generate JSON Feed
 */
function sinople_generate_json_feed() {
	if ( ! get_query_var( 'json_feed' ) ) {
		return;
	}

	$posts = get_posts( array( 'posts_per_page' => 10 ) );

	$feed = array(
		'version'       => 'https://jsonfeed.org/version/1.1',
		'title'         => get_bloginfo( 'name' ),
		'home_page_url' => home_url( '/' ),
		'feed_url'      => home_url( '/feed/json/' ),
		'description'   => get_bloginfo( 'description' ),
		'items'         => array(),
	);

	foreach ( $posts as $post ) {
		$item = array(
			'id'             => get_permalink( $post->ID ),
			'url'            => get_permalink( $post->ID ),
			'title'          => get_the_title( $post->ID ),
			'content_html'   => apply_filters( 'the_content', $post->post_content ),
			'date_published' => get_the_date( 'c', $post->ID ),
			'date_modified'  => get_the_modified_date( 'c', $post->ID ),
			'author'         => array(
				'name' => get_the_author_meta( 'display_name', $post->post_author ),
				'url'  => get_author_posts_url( $post->post_author ),
			),
		);

		$feed['items'][] = $item;
	}

	header( 'Content-Type: application/json; charset=' . get_bloginfo( 'charset' ) );
	echo wp_json_encode( $feed, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
	exit;
}
add_action( 'template_redirect', 'sinople_generate_json_feed' );

/**
 * Add query var for JSON feed
 */
function sinople_json_feed_query_var( $vars ) {
	$vars[] = 'json_feed';
	return $vars;
}
add_filter( 'query_vars', 'sinople_json_feed_query_var' );

/**
 * Add rewrite rule for JSON feed
 */
function sinople_json_feed_rewrite() {
	add_rewrite_rule( '^feed/json/?$', 'index.php?json_feed=1', 'top' );
}
add_action( 'init', 'sinople_json_feed_rewrite' );
