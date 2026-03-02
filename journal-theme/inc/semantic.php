<?php
/**
 * Semantic Metadata Integration
 *
 * JSON-LD, Open Graph, Twitter Cards, RDFa, and structured data.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Output JSON-LD structured data
 */
function sinople_json_ld() {
	$schema = array();

	// Website/Organization
	$schema['website'] = array(
		'@context'        => 'https://schema.org',
		'@type'           => 'WebSite',
		'@id'             => home_url( '/#website' ),
		'url'             => home_url( '/' ),
		'name'            => get_bloginfo( 'name' ),
		'description'     => get_bloginfo( 'description' ),
		'publisher'       => array(
			'@type' => 'Organization',
			'@id'   => home_url( '/#organization' ),
			'name'  => get_bloginfo( 'name' ),
			'url'   => home_url( '/' ),
		),
		'inLanguage'      => get_bloginfo( 'language' ),
		'potentialAction' => array(
			'@type'       => 'SearchAction',
			'target'      => array(
				'@type'       => 'EntryPoint',
				'urlTemplate' => home_url( '/?s={search_term_string}' ),
			),
			'query-input' => 'required name=search_term_string',
		),
	);

	// Single post/page
	if ( is_singular() ) {
		global $post;

		$schema['article'] = array(
			'@context'        => 'https://schema.org',
			'@type'           => 'Article',
			'@id'             => get_permalink() . '#article',
			'headline'        => get_the_title(),
			'description'     => get_the_excerpt(),
			'datePublished'   => get_the_date( 'c' ),
			'dateModified'    => get_the_modified_date( 'c' ),
			'author'          => array(
				'@type' => 'Person',
				'name'  => get_the_author(),
				'url'   => get_author_posts_url( get_the_author_meta( 'ID' ) ),
			),
			'publisher'       => array(
				'@type' => 'Organization',
				'name'  => get_bloginfo( 'name' ),
				'logo'  => array(
					'@type' => 'ImageObject',
					'url'   => get_site_icon_url(),
				),
			),
			'mainEntityOfPage' => array(
				'@type' => 'WebPage',
				'@id'   => get_permalink(),
			),
			'wordCount'       => str_word_count( wp_strip_all_tags( get_the_content() ) ),
			'timeRequired'    => 'PT' . ceil( sinople_get_reading_time() ) . 'M',
			'inLanguage'      => get_bloginfo( 'language' ),
		);

		// Add image if available
		if ( has_post_thumbnail() ) {
			$image_id  = get_post_thumbnail_id();
			$image_url = wp_get_attachment_image_url( $image_id, 'full' );
			$image_meta = wp_get_attachment_metadata( $image_id );

			$schema['article']['image'] = array(
				'@type'  => 'ImageObject',
				'url'    => $image_url,
				'width'  => isset( $image_meta['width'] ) ? $image_meta['width'] : '',
				'height' => isset( $image_meta['height'] ) ? $image_meta['height'] : '',
			);
		}

		// Add span-specific schema
		if ( function_exists( 'sinople_get_span_schema' ) ) {
			$span_schema = sinople_get_span_schema( get_the_ID() );
			if ( $span_schema ) {
				$schema['span'] = $span_schema;
			}
		}
	}

	// Breadcrumb schema
	if ( ! is_front_page() && function_exists( 'sinople_get_breadcrumb_schema' ) ) {
		$schema['breadcrumb'] = sinople_get_breadcrumb_schema();
	}

	// Output JSON-LD
	if ( ! empty( $schema ) ) {
		echo '<script type="application/ld+json">';
		echo wp_json_encode( array( '@graph' => array_values( $schema ) ), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
		echo '</script>' . "\n";
	}
}
add_action( 'wp_head', 'sinople_json_ld', 5 );

/**
 * Output Open Graph metadata
 */
function sinople_open_graph() {
	// Basic OG tags
	echo '<meta property="og:site_name" content="' . esc_attr( get_bloginfo( 'name' ) ) . '">' . "\n";
	echo '<meta property="og:locale" content="' . esc_attr( get_bloginfo( 'language' ) ) . '">' . "\n";

	if ( is_singular() ) {
		// Single post/page
		echo '<meta property="og:type" content="article">' . "\n";
		echo '<meta property="og:title" content="' . esc_attr( get_the_title() ) . '">' . "\n";
		echo '<meta property="og:description" content="' . esc_attr( get_the_excerpt() ) . '">' . "\n";
		echo '<meta property="og:url" content="' . esc_url( get_permalink() ) . '">' . "\n";

		// Image
		if ( has_post_thumbnail() ) {
			$image_url = wp_get_attachment_image_url( get_post_thumbnail_id(), 'full' );
			echo '<meta property="og:image" content="' . esc_url( $image_url ) . '">' . "\n";

			$image_meta = wp_get_attachment_metadata( get_post_thumbnail_id() );
			if ( isset( $image_meta['width'], $image_meta['height'] ) ) {
				echo '<meta property="og:image:width" content="' . esc_attr( $image_meta['width'] ) . '">' . "\n";
				echo '<meta property="og:image:height" content="' . esc_attr( $image_meta['height'] ) . '">' . "\n";
			}
		}

		// Article metadata
		echo '<meta property="article:published_time" content="' . esc_attr( get_the_date( 'c' ) ) . '">' . "\n";
		echo '<meta property="article:modified_time" content="' . esc_attr( get_the_modified_date( 'c' ) ) . '">' . "\n";
		echo '<meta property="article:author" content="' . esc_attr( get_the_author() ) . '">' . "\n";
	} else {
		// Homepage or archive
		echo '<meta property="og:type" content="website">' . "\n";
		echo '<meta property="og:title" content="' . esc_attr( get_bloginfo( 'name' ) ) . '">' . "\n";
		echo '<meta property="og:description" content="' . esc_attr( get_bloginfo( 'description' ) ) . '">' . "\n";
		echo '<meta property="og:url" content="' . esc_url( home_url( '/' ) ) . '">' . "\n";

		// Site icon
		if ( has_site_icon() ) {
			echo '<meta property="og:image" content="' . esc_url( get_site_icon_url( 512 ) ) . '">' . "\n";
		}
	}
}
add_action( 'wp_head', 'sinople_open_graph', 6 );

/**
 * Output Twitter Card metadata
 */
function sinople_twitter_cards() {
	echo '<meta name="twitter:card" content="summary_large_image">' . "\n";

	if ( is_singular() ) {
		echo '<meta name="twitter:title" content="' . esc_attr( get_the_title() ) . '">' . "\n";
		echo '<meta name="twitter:description" content="' . esc_attr( get_the_excerpt() ) . '">' . "\n";

		if ( has_post_thumbnail() ) {
			$image_url = wp_get_attachment_image_url( get_post_thumbnail_id(), 'full' );
			echo '<meta name="twitter:image" content="' . esc_url( $image_url ) . '">' . "\n";
		}
	} else {
		echo '<meta name="twitter:title" content="' . esc_attr( get_bloginfo( 'name' ) ) . '">' . "\n";
		echo '<meta name="twitter:description" content="' . esc_attr( get_bloginfo( 'description' ) ) . '">' . "\n";
	}
}
add_action( 'wp_head', 'sinople_twitter_cards', 7 );

/**
 * Generate breadcrumb schema
 */
function sinople_get_breadcrumb_schema() {
	$items = array();
	$position = 1;

	// Home
	$items[] = array(
		'@type'    => 'ListItem',
		'position' => $position++,
		'name'     => esc_html__( 'Home', 'sinople' ),
		'item'     => home_url( '/' ),
	);

	if ( is_category() || is_single() ) {
		$category = get_the_category();
		if ( $category ) {
			$items[] = array(
				'@type'    => 'ListItem',
				'position' => $position++,
				'name'     => $category[0]->name,
				'item'     => get_category_link( $category[0]->term_id ),
			);
		}
	}

	if ( is_single() ) {
		$items[] = array(
			'@type'    => 'ListItem',
			'position' => $position,
			'name'     => get_the_title(),
			'item'     => get_permalink(),
		);
	}

	if ( empty( $items ) ) {
		return null;
	}

	return array(
		'@context'        => 'https://schema.org',
		'@type'           => 'BreadcrumbList',
		'itemListElement' => $items,
	);
}

/**
 * Add RDFa attributes to HTML element
 */
function sinople_html_rdfa( $output ) {
	$output .= ' prefix="og: http://ogp.me/ns# article: http://ogp.me/ns/article# schema: https://schema.org/"';
	return $output;
}
add_filter( 'language_attributes', 'sinople_html_rdfa' );

/**
 * Add canonical link
 */
function sinople_canonical_link() {
	if ( is_singular() ) {
		echo '<link rel="canonical" href="' . esc_url( get_permalink() ) . '">' . "\n";
	} elseif ( is_front_page() ) {
		echo '<link rel="canonical" href="' . esc_url( home_url( '/' ) ) . '">' . "\n";
	}
}
add_action( 'wp_head', 'sinople_canonical_link', 1 );
