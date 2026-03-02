<?php
/**
 * Sinople Theme Functions
 *
 * CSS-first WordPress journal theme for layered, narrative-rich content.
 * WCAG 2.3 AAA compliant with semantic web integration.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// Theme version
define( 'SINOPLE_VERSION', '0.1.0' );
define( 'SINOPLE_PATH', get_template_directory() );
define( 'SINOPLE_URI', get_template_directory_uri() );

/**
 * Load modular functionality
 */
require_once SINOPLE_PATH . '/inc/setup.php';
require_once SINOPLE_PATH . '/inc/enqueue.php';
require_once SINOPLE_PATH . '/inc/security.php';
require_once SINOPLE_PATH . '/inc/accessibility.php';
require_once SINOPLE_PATH . '/inc/semantic.php';
require_once SINOPLE_PATH . '/inc/indieweb.php';
require_once SINOPLE_PATH . '/inc/spans.php';
require_once SINOPLE_PATH . '/inc/taxonomies.php';
require_once SINOPLE_PATH . '/inc/privacy.php';
require_once SINOPLE_PATH . '/inc/performance.php';
require_once SINOPLE_PATH . '/inc/void-integration.php';
require_once SINOPLE_PATH . '/inc/modern-features.php';
require_once SINOPLE_PATH . '/inc/serialization.php';

// First-class serialization formats
require_once SINOPLE_PATH . '/inc/ndjson-feed.php';
require_once SINOPLE_PATH . '/inc/flatbuffers.php';
require_once SINOPLE_PATH . '/inc/capnproto.php';

// php-aegis security integration
require_once SINOPLE_PATH . '/inc/aegis-integration.php';
require_once SINOPLE_PATH . '/inc/turtle-output.php';

/**
 * Theme setup
 */
function sinople_setup() {
	// Text domain for translations
	load_theme_textdomain( 'sinople', SINOPLE_PATH . '/languages' );

	// Add default posts and comments RSS feed links to head
	add_theme_support( 'automatic-feed-links' );

	// Let WordPress manage the document title
	add_theme_support( 'title-tag' );

	// Enable support for Post Thumbnails
	add_theme_support( 'post-thumbnails' );

	// Custom image sizes for semantic contexts
	add_image_size( 'sinople-field-note', 800, 600, true );
	add_image_size( 'sinople-construct', 1200, 900, false );
	add_image_size( 'sinople-portal', 600, 600, true );

	// Register navigation menus
	register_nav_menus(
		array(
			'primary'   => esc_html__( 'Primary Navigation', 'sinople' ),
			'footer'    => esc_html__( 'Footer Navigation', 'sinople' ),
			'spans'     => esc_html__( 'Spans Navigation', 'sinople' ),
			'semantic'  => esc_html__( 'Semantic Navigation', 'sinople' ),
		)
	);

	// Switch default core markup to output valid HTML5
	add_theme_support(
		'html5',
		array(
			'search-form',
			'comment-form',
			'comment-list',
			'gallery',
			'caption',
			'style',
			'script',
			'navigation-widgets',
		)
	);

	// Add theme support for selective refresh for widgets
	add_theme_support( 'customize-selective-refresh-widgets' );

	// Add support for editor styles
	add_theme_support( 'editor-styles' );
	add_editor_style( 'assets/css/editor-style.css' );

	// Add support for responsive embeds
	add_theme_support( 'responsive-embeds' );

	// Add support for custom line height controls
	add_theme_support( 'custom-line-height' );

	// Add support for experimental link color control
	add_theme_support( 'experimental-link-color' );

	// Add support for custom units
	add_theme_support( 'custom-units', 'rem', 'em', 'vh', 'vw' );

	// Add support for custom spacing
	add_theme_support( 'custom-spacing' );

	// Add support for appearance tools
	add_theme_support( 'appearance-tools' );

	// Add support for border control
	add_theme_support( 'border' );

	// Post formats for narrative variety
	add_theme_support(
		'post-formats',
		array(
			'aside',
			'gallery',
			'link',
			'quote',
			'status',
			'video',
			'audio',
		)
	);

	// IndieWeb support
	add_theme_support( 'microformats2' );
	add_theme_support( 'webmentions' );
	add_theme_support( 'post-kinds' );

	// WCAG 2.3 AAA: Ensure no time limits on reading
	remove_action( 'wp_head', 'feed_links_extra', 3 );
}
add_action( 'after_setup_theme', 'sinople_setup' );

/**
 * Set content width for embedded media
 */
function sinople_content_width() {
	$GLOBALS['content_width'] = apply_filters( 'sinople_content_width', 800 );
}
add_action( 'after_setup_theme', 'sinople_content_width', 0 );

/**
 * Register widget areas
 */
function sinople_widgets_init() {
	register_sidebar(
		array(
			'name'          => esc_html__( 'Sidebar', 'sinople' ),
			'id'            => 'sidebar-1',
			'description'   => esc_html__( 'Add widgets here for narrative asides.', 'sinople' ),
			'before_widget' => '<section id="%1$s" class="widget %2$s" role="complementary">',
			'after_widget'  => '</section>',
			'before_title'  => '<h2 class="widget-title">',
			'after_title'   => '</h2>',
		)
	);

	register_sidebar(
		array(
			'name'          => esc_html__( 'Footer Widgets', 'sinople' ),
			'id'            => 'footer-widgets',
			'description'   => esc_html__( 'Footer widget area for metadata and links.', 'sinople' ),
			'before_widget' => '<section id="%1$s" class="footer-widget %2$s">',
			'after_widget'  => '</section>',
			'before_title'  => '<h3 class="footer-widget-title">',
			'after_title'   => '</h3>',
		)
	);

	register_sidebar(
		array(
			'name'          => esc_html__( 'Glosses', 'sinople' ),
			'id'            => 'glosses',
			'description'   => esc_html__( 'Footnotes and annotations.', 'sinople' ),
			'before_widget' => '<aside id="%1$s" class="gloss %2$s" role="note">',
			'after_widget'  => '</aside>',
			'before_title'  => '<h4 class="gloss-title">',
			'after_title'   => '</h4>',
		)
	);
}
add_action( 'widgets_init', 'sinople_widgets_init' );
