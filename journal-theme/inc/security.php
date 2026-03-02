<?php
/**
 * Security Headers and Configurations
 *
 * Implements strict security headers including CSP, CORP, COEP,
 * mixed content prevention, and OWASP best practices.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Send security headers
 */
function sinople_security_headers() {
	// Already sent in template_redirect
	if ( headers_sent() ) {
		return;
	}

	// Strict-Transport-Security (HSTS)
	header( 'Strict-Transport-Security: max-age=63072000; includeSubDomains; preload' );

	// Content-Security-Policy (Strict)
	$csp_directives = array(
		"default-src 'self'",
		"script-src 'self' 'wasm-unsafe-eval'", // WASM requires wasm-unsafe-eval
		"style-src 'self' 'unsafe-inline'", // WordPress requires inline styles
		"img-src 'self' data: https:",
		"font-src 'self' data:",
		"connect-src 'self'",
		"media-src 'self'",
		"object-src 'none'",
		"frame-src 'none'",
		"base-uri 'self'",
		"form-action 'self'",
		"frame-ancestors 'none'",
		"upgrade-insecure-requests",
		"block-all-mixed-content",
	);

	$csp = implode( '; ', apply_filters( 'sinople_csp_directives', $csp_directives ) );
	header( "Content-Security-Policy: {$csp}" );

	// X-Frame-Options (Defense in depth)
	header( 'X-Frame-Options: SAMEORIGIN' );

	// X-Content-Type-Options
	header( 'X-Content-Type-Options: nosniff' );

	// Referrer-Policy
	header( 'Referrer-Policy: strict-origin-when-cross-origin' );

	// Permissions-Policy (formerly Feature-Policy)
	$permissions = array(
		'accelerometer=()',
		'autoplay=()',
		'camera=()',
		'cross-origin-isolated=()',
		'display-capture=()',
		'encrypted-media=()',
		'fullscreen=(self)',
		'geolocation=()',
		'gyroscope=()',
		'magnetometer=()',
		'microphone=()',
		'midi=()',
		'payment=()',
		'picture-in-picture=()',
		'publickey-credentials-get=()',
		'screen-wake-lock=()',
		'sync-xhr=()',
		'usb=()',
		'web-share=()',
		'xr-spatial-tracking=()',
	);
	header( 'Permissions-Policy: ' . implode( ', ', $permissions ) );

	// Cross-Origin-Embedder-Policy (COEP)
	header( 'Cross-Origin-Embedder-Policy: require-corp' );

	// Cross-Origin-Opener-Policy (COOP)
	header( 'Cross-Origin-Opener-Policy: same-origin' );

	// Cross-Origin-Resource-Policy (CORP)
	header( 'Cross-Origin-Resource-Policy: same-origin' );

	// X-XSS-Protection (Legacy browsers)
	header( 'X-XSS-Protection: 1; mode=block' );

	// X-Permitted-Cross-Domain-Policies
	header( 'X-Permitted-Cross-Domain-Policies: none' );

	// Expect-CT
	header( 'Expect-CT: max-age=86400, enforce' );

	// NEL (Network Error Logging) - Optional
	if ( get_theme_mod( 'sinople_enable_nel', false ) ) {
		header( 'NEL: {"report_to":"default","max_age":31536000,"include_subdomains":true}' );
	}

	// Report-To header for CSP violation reporting
	if ( get_theme_mod( 'sinople_csp_reporting', false ) ) {
		$report_to = wp_json_encode(
			array(
				'group'     => 'default',
				'max_age'   => 31536000,
				'endpoints' => array(
					array( 'url' => home_url( '/csp-report/' ) ),
				),
			)
		);
		header( "Report-To: {$report_to}" );
	}
}
add_action( 'send_headers', 'sinople_security_headers' );
add_action( 'template_redirect', 'sinople_security_headers', 1 );

/**
 * Prevent mixed content by upgrading URLs
 */
function sinople_upgrade_insecure_urls( $content ) {
	if ( is_ssl() ) {
		$content = str_replace( 'http://', 'https://', $content );
	}
	return $content;
}
add_filter( 'the_content', 'sinople_upgrade_insecure_urls' );
add_filter( 'widget_text', 'sinople_upgrade_insecure_urls' );

/**
 * Remove WordPress version from head
 */
remove_action( 'wp_head', 'wp_generator' );

/**
 * Disable XML-RPC for security
 */
add_filter( 'xmlrpc_enabled', '__return_false' );

/**
 * Remove RSD link
 */
remove_action( 'wp_head', 'rsd_link' );

/**
 * Remove wlwmanifest link
 */
remove_action( 'wp_head', 'wlwmanifest_link' );

/**
 * Remove shortlink
 */
remove_action( 'wp_head', 'wp_shortlink_wp_head' );

/**
 * Disable embeds for security
 */
function sinople_disable_embeds() {
	remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
	remove_action( 'wp_head', 'wp_oembed_add_host_js' );
	remove_filter( 'pre_oembed_result', 'wp_filter_pre_oembed_result', 10 );
}
add_action( 'init', 'sinople_disable_embeds' );

/**
 * Add nonce to inline scripts (CSP compatibility)
 */
function sinople_add_csp_nonce( $tag, $handle ) {
	// Generate nonce for inline scripts
	static $nonce;
	if ( ! $nonce ) {
		$nonce = base64_encode( random_bytes( 16 ) );
	}

	// Add nonce to inline scripts
	if ( strpos( $tag, '<script' ) === 0 && strpos( $tag, 'src=' ) === false ) {
		$tag = str_replace( '<script', '<script nonce="' . esc_attr( $nonce ) . '"', $tag );
	}

	return $tag;
}
// Uncomment when strict CSP nonce is needed:
// add_filter( 'script_loader_tag', 'sinople_add_csp_nonce', 10, 2 );

/**
 * Sanitize file uploads
 */
function sinople_sanitize_file_name( $filename ) {
	// Remove special characters
	$filename = sanitize_file_name( $filename );

	// Convert to lowercase
	$filename = strtolower( $filename );

	// Remove multiple hyphens
	$filename = preg_replace( '/-+/', '-', $filename );

	return $filename;
}
add_filter( 'sanitize_file_name', 'sinople_sanitize_file_name' );

/**
 * Restrict file upload types
 */
function sinople_upload_mimes( $mimes ) {
	// Remove potentially dangerous file types
	unset( $mimes['exe'] );
	unset( $mimes['dll'] );
	unset( $mimes['php'] );
	unset( $mimes['js'] );
	unset( $mimes['swf'] );

	// Add safe file types
	$mimes['svg']   = 'image/svg+xml';
	$mimes['wasm']  = 'application/wasm';
	$mimes['woff2'] = 'font/woff2';
	$mimes['capnp'] = 'application/x-capnproto';

	return apply_filters( 'sinople_allowed_mimes', $mimes );
}
add_filter( 'upload_mimes', 'sinople_upload_mimes' );

/**
 * Validate uploaded SVG files
 */
function sinople_validate_svg( $file ) {
	if ( 'image/svg+xml' === $file['type'] ) {
		$svg_content = file_get_contents( $file['tmp_name'] );

		// Check for malicious patterns
		$dangerous_patterns = array(
			'/<script/i',
			'/on\w+\s*=/i', // Event handlers
			'/javascript:/i',
			'/data:text\/html/i',
		);

		foreach ( $dangerous_patterns as $pattern ) {
			if ( preg_match( $pattern, $svg_content ) ) {
				$file['error'] = esc_html__( 'SVG file contains potentially malicious code.', 'sinople' );
				return $file;
			}
		}
	}

	return $file;
}
add_filter( 'wp_handle_upload_prefilter', 'sinople_validate_svg' );
