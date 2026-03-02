<?php
/**
 * Performance Optimizations
 *
 * Critical CSS inlining, lazy loading, resource hints,
 * and WASM acceleration where applicable.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Inline critical CSS
 */
function sinople_inline_critical_css() {
	$critical_css_file = SINOPLE_PATH . '/assets/css/critical.css';

	if ( file_exists( $critical_css_file ) ) {
		$critical_css = file_get_contents( $critical_css_file );
		echo '<style id="critical-css">' . $critical_css . '</style>' . "\n"; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
	}
}
add_action( 'wp_head', 'sinople_inline_critical_css', 1 );

/**
 * Lazy load images
 */
function sinople_lazy_load_images( $attr, $attachment ) {
	// Native lazy loading
	$attr['loading'] = 'lazy';

	// Add decoding attribute
	$attr['decoding'] = 'async';

	return $attr;
}
add_filter( 'wp_get_attachment_image_attributes', 'sinople_lazy_load_images', 10, 2 );

/**
 * Add fetchpriority to hero images
 */
function sinople_hero_image_priority( $attr, $attachment, $size ) {
	if ( 'full' === $size && is_singular() && get_post_thumbnail_id() === $attachment->ID ) {
		$attr['fetchpriority'] = 'high';
		unset( $attr['loading'] ); // Don't lazy load hero images
	}

	return $attr;
}
add_filter( 'wp_get_attachment_image_attributes', 'sinople_hero_image_priority', 10, 3 );

/**
 * Defer non-critical scripts
 */
function sinople_defer_scripts( $tag, $handle, $src ) {
	$defer_scripts = array( 'comment-reply', 'wp-embed' );

	if ( in_array( $handle, $defer_scripts, true ) ) {
		$tag = str_replace( ' src', ' defer src', $tag );
	}

	return $tag;
}
add_filter( 'script_loader_tag', 'sinople_defer_scripts', 10, 3 );

/**
 * Remove query strings from static resources
 */
function sinople_remove_query_strings( $src ) {
	if ( strpos( $src, '?ver=' ) ) {
		$src = remove_query_arg( 'ver', $src );
	}
	return $src;
}
add_filter( 'script_loader_src', 'sinople_remove_query_strings' );
add_filter( 'style_loader_src', 'sinople_remove_query_strings' );

/**
 * Disable emojis for performance
 */
function sinople_disable_emojis() {
	remove_action( 'wp_head', 'print_emoji_detection_script', 7 );
	remove_action( 'admin_print_scripts', 'print_emoji_detection_script' );
	remove_action( 'wp_print_styles', 'print_emoji_styles' );
	remove_action( 'admin_print_styles', 'print_emoji_styles' );
	remove_filter( 'the_content_feed', 'wp_staticize_emoji' );
	remove_filter( 'comment_text_rss', 'wp_staticize_emoji' );
	remove_filter( 'wp_mail', 'wp_staticize_emoji_for_email' );
}
add_action( 'init', 'sinople_disable_emojis' );

/**
 * Remove emoji DNS prefetch
 */
function sinople_remove_emoji_dns_prefetch( $urls, $relation_type ) {
	if ( 'dns-prefetch' === $relation_type ) {
		$emoji_svg_url = apply_filters( 'emoji_svg_url', 'https://s.w.org/images/core/emoji/2/svg/' );
		$urls = array_diff( $urls, array( $emoji_svg_url ) );
	}
	return $urls;
}
add_filter( 'wp_resource_hints', 'sinople_remove_emoji_dns_prefetch', 10, 2 );

/**
 * Optimize Gravatar loading
 */
function sinople_optimize_gravatar( $avatar ) {
	$avatar = str_replace( ' src=', ' loading="lazy" decoding="async" src=', $avatar );
	return $avatar;
}
add_filter( 'get_avatar', 'sinople_optimize_gravatar' );

/**
 * Add preload for web fonts
 */
function sinople_preload_webfonts() {
	?>
	<link rel="preload" href="<?php echo esc_url( SINOPLE_URI . '/assets/fonts/inter-var.woff2' ); ?>" as="font" type="font/woff2" crossorigin>
	<?php
}
add_action( 'wp_head', 'sinople_preload_webfonts', 1 );

/**
 * Add resource hints
 */
function sinople_add_resource_hints( $urls, $relation_type ) {
	if ( 'preconnect' === $relation_type ) {
		$urls[] = array(
			'href'        => home_url(),
			'crossorigin' => '',
		);
	}

	if ( 'dns-prefetch' === $relation_type ) {
		$urls[] = home_url();
	}

	return $urls;
}
add_filter( 'wp_resource_hints', 'sinople_add_resource_hints', 10, 2 );

/**
 * Optimize database queries
 */
function sinople_optimize_queries() {
	if ( is_admin() ) {
		return;
	}

	// Remove unnecessary queries
	remove_action( 'wp_head', 'adjacent_posts_rel_link_wp_head' );
}
add_action( 'init', 'sinople_optimize_queries' );

/**
 * Add cache-control headers
 */
function sinople_cache_headers() {
	if ( is_admin() || is_user_logged_in() ) {
		return;
	}

	// Cache static pages for 1 hour
	if ( is_singular() && ! is_front_page() ) {
		header( 'Cache-Control: public, max-age=3600' );
	}

	// Cache archives for 30 minutes
	if ( is_archive() ) {
		header( 'Cache-Control: public, max-age=1800' );
	}
}
add_action( 'send_headers', 'sinople_cache_headers' );

/**
 * Enable Gzip compression
 */
function sinople_enable_gzip() {
	if ( ! headers_sent() && ! ob_get_contents() ) {
		if ( extension_loaded( 'zlib' ) && ! ini_get( 'zlib.output_compression' ) ) {
			ob_start( 'ob_gzhandler' );
		}
	}
}
add_action( 'init', 'sinople_enable_gzip', 0 );

/**
 * Minify HTML output (optional)
 */
function sinople_minify_html( $html ) {
	if ( ! get_theme_mod( 'sinople_minify_html', false ) ) {
		return $html;
	}

	// Remove HTML comments (except conditional comments)
	$html = preg_replace( '/<!--(?!\[if)(?!\<!\[endif).*?-->/s', '', $html );

	// Remove whitespace
	$html = preg_replace( '/\s+/', ' ', $html );

	// Remove whitespace between tags
	$html = preg_replace( '/>\s+</', '><', $html );

	return $html;
}
add_filter( 'final_output', 'sinople_minify_html' );

/**
 * Capture output for minification
 */
function sinople_start_output_buffer() {
	if ( get_theme_mod( 'sinople_minify_html', false ) ) {
		ob_start(
			function ( $html ) {
				return apply_filters( 'final_output', $html );
			}
		);
	}
}
add_action( 'template_redirect', 'sinople_start_output_buffer', -1 );

/**
 * WebP image support
 */
function sinople_webp_support( $sources, $size_array, $image_src, $image_meta, $attachment_id ) {
	if ( ! function_exists( 'imagewebp' ) ) {
		return $sources;
	}

	foreach ( $sources as &$source ) {
		$webp_path = preg_replace( '/\.(jpg|jpeg|png)$/i', '.webp', $source['url'] );

		if ( file_exists( str_replace( home_url( '/' ), ABSPATH, $webp_path ) ) ) {
			$source['type'] = 'image/webp';
			$source['url']  = $webp_path;
		}
	}

	return $sources;
}
add_filter( 'wp_calculate_image_srcset', 'sinople_webp_support', 10, 5 );

/**
 * WASM-accelerated operations detection
 */
function sinople_wasm_available() {
	static $wasm_available = null;

	if ( null === $wasm_available ) {
		$wasm_file = SINOPLE_PATH . '/assets/js/dist/sinople.wasm';
		$wasm_available = file_exists( $wasm_file );
	}

	return $wasm_available;
}
