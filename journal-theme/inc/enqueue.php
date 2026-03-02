<?php
/**
 * Asset Enqueueing
 *
 * Loads stylesheets and scripts with modern features,
 * resource hints, and performance optimizations.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Enqueue styles
 */
function sinople_enqueue_styles() {
	// Main stylesheet (compiled from SCSS)
	wp_enqueue_style(
		'sinople-main',
		SINOPLE_URI . '/assets/css/main.css',
		array(),
		SINOPLE_VERSION,
		'all'
	);

	// Print styles (optimized for printing)
	wp_enqueue_style(
		'sinople-print',
		SINOPLE_URI . '/assets/css/print.css',
		array( 'sinople-main' ),
		SINOPLE_VERSION,
		'print'
	);

	// Accessibility enhancements stylesheet
	wp_enqueue_style(
		'sinople-accessibility',
		SINOPLE_URI . '/assets/css/accessibility.css',
		array( 'sinople-main' ),
		SINOPLE_VERSION,
		'all'
	);

	// Add preload for critical fonts
	if ( sinople_has_consent( 'fonts' ) ) {
		add_action( 'wp_head', 'sinople_preload_fonts', 1 );
	}
}
add_action( 'wp_enqueue_scripts', 'sinople_enqueue_styles' );

/**
 * Enqueue scripts
 */
function sinople_enqueue_scripts() {
	// Main JavaScript bundle (ESM module)
	wp_enqueue_script(
		'sinople-main',
		SINOPLE_URI . '/assets/js/dist/main.js',
		array(),
		SINOPLE_VERSION,
		array(
			'in_footer' => true,
			'strategy'  => 'defer',
		)
	);

	// Add type="module" attribute
	add_filter(
		'script_loader_tag',
		function ( $tag, $handle ) {
			if ( 'sinople-main' === $handle ) {
				$tag = str_replace( ' src', ' type="module" src', $tag );
			}
			return $tag;
		},
		10,
		2
	);

	// Accessibility controls
	wp_enqueue_script(
		'sinople-accessibility',
		SINOPLE_URI . '/assets/js/dist/accessibility.js',
		array(),
		SINOPLE_VERSION,
		array(
			'in_footer' => true,
			'strategy'  => 'defer',
		)
	);

	// WebAssembly support (progressive enhancement)
	if ( sinople_supports_wasm() ) {
		wp_enqueue_script(
			'sinople-wasm',
			SINOPLE_URI . '/assets/js/dist/wasm-loader.js',
			array( 'sinople-main' ),
			SINOPLE_VERSION,
			array(
				'in_footer' => true,
				'strategy'  => 'defer',
			)
		);
	}

	// Localize script with theme data
	wp_localize_script(
		'sinople-main',
		'sinople',
		array(
			'ajaxUrl'           => admin_url( 'admin-ajax.php' ),
			'nonce'             => wp_create_nonce( 'sinople_nonce' ),
			'themeUri'          => SINOPLE_URI,
			'homeUrl'           => home_url( '/' ),
			'isRTL'             => is_rtl(),
			'i18n'              => array(
				'loading'       => esc_html__( 'Loading...', 'sinople' ),
				'error'         => esc_html__( 'An error occurred', 'sinople' ),
				'close'         => esc_html__( 'Close', 'sinople' ),
				'menuOpen'      => esc_html__( 'Open menu', 'sinople' ),
				'menuClose'     => esc_html__( 'Close menu', 'sinople' ),
			),
			'features'          => array(
				'wasm'              => sinople_supports_wasm(),
				'serviceWorker'     => get_theme_mod( 'sinople_enable_offline', true ),
				'viewTransitions'   => get_theme_mod( 'sinople_view_transitions', true ),
				'prefersReducedMotion' => false, // Detected client-side
			),
			'endpoints'         => array(
				'void'      => sinople_void_endpoint_url(),
				'ndjson'    => sinople_ndjson_feed_url(),
				'capnproto' => sinople_capnproto_endpoint_url(),
			),
		)
	);

	// Comment reply script
	if ( is_singular() && comments_open() && get_option( 'thread_comments' ) ) {
		wp_enqueue_script( 'comment-reply' );
	}
}
add_action( 'wp_enqueue_scripts', 'sinople_enqueue_scripts' );

/**
 * Preload critical fonts
 */
function sinople_preload_fonts() {
	?>
	<link rel="preload" href="<?php echo esc_url( SINOPLE_URI . '/assets/fonts/inter-var.woff2' ); ?>" as="font" type="font/woff2" crossorigin>
	<?php
}

/**
 * Add resource hints for performance
 */
function sinople_resource_hints( $urls, $relation_type ) {
	if ( 'dns-prefetch' === $relation_type ) {
		$urls[] = home_url();
	}

	if ( 'preconnect' === $relation_type ) {
		if ( sinople_has_consent( 'external_fonts' ) ) {
			$urls[] = array(
				'href'        => 'https://fonts.googleapis.com',
				'crossorigin' => 'anonymous',
			);
		}
	}

	return $urls;
}
add_filter( 'wp_resource_hints', 'sinople_resource_hints', 10, 2 );

/**
 * Check if browser supports WebAssembly
 */
function sinople_supports_wasm() {
	// Server-side: Assume modern browsers support WASM
	// Client-side detection happens in JavaScript
	return apply_filters( 'sinople_supports_wasm', true );
}

/**
 * Add integrity attributes to scripts and styles
 */
function sinople_add_sri( $html, $handle ) {
	// SRI hashes would be generated during build
	// This is a placeholder for the implementation
	return apply_filters( 'sinople_sri_html', $html, $handle );
}
add_filter( 'style_loader_tag', 'sinople_add_sri', 10, 2 );
add_filter( 'script_loader_tag', 'sinople_add_sri', 10, 2 );

/**
 * Add crossorigin attribute to external resources
 */
function sinople_crossorigin_attribute( $tag, $handle, $src ) {
	// Add crossorigin to external resources
	if ( strpos( $src, home_url() ) === false ) {
		$tag = str_replace( ' href=', ' crossorigin="anonymous" href=', $tag );
		$tag = str_replace( ' src=', ' crossorigin="anonymous" src=', $tag );
	}
	return $tag;
}
add_filter( 'style_loader_tag', 'sinople_crossorigin_attribute', 10, 3 );
add_filter( 'script_loader_tag', 'sinople_crossorigin_attribute', 10, 3 );
