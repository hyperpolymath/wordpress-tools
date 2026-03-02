<?php
/**
 * php-aegis Integration for WordPress
 *
 * Provides WordPress-style function wrappers for php-aegis security utilities.
 * Falls back to WordPress built-in functions if php-aegis is not available.
 *
 * @package Sinople
 * @since 0.2.0
 * @see https://github.com/hyperpolymath/php-aegis
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Check if php-aegis is available
 *
 * @return bool True if php-aegis classes are loaded
 */
function sinople_aegis_available(): bool {
	return class_exists( '\\PhpAegis\\Sanitizer' );
}

/**
 * Sanitize string for HTML content context.
 *
 * Uses php-aegis if available, falls back to WordPress esc_html().
 *
 * @param string $input The string to sanitize.
 * @return string Sanitized string safe for HTML content.
 */
function sinople_aegis_html( string $input ): string {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Sanitizer::html( $input );
	}
	return esc_html( $input );
}

/**
 * Sanitize string for HTML attribute context.
 *
 * Uses php-aegis if available, falls back to WordPress esc_attr().
 *
 * @param string $input The string to sanitize.
 * @return string Sanitized string safe for HTML attributes.
 */
function sinople_aegis_attr( string $input ): string {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Sanitizer::attr( $input );
	}
	return esc_attr( $input );
}

/**
 * Sanitize string for JavaScript context.
 *
 * Uses php-aegis if available, falls back to WordPress esc_js().
 *
 * @param string $input The string to sanitize.
 * @return string Sanitized string safe for JavaScript.
 */
function sinople_aegis_js( string $input ): string {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Sanitizer::js( $input );
	}
	return esc_js( $input );
}

/**
 * Encode data as safe JSON with security flags.
 *
 * Uses php-aegis if available, falls back to wp_json_encode().
 * php-aegis adds JSON_HEX_TAG, JSON_HEX_APOS, JSON_HEX_QUOT, JSON_HEX_AMP flags.
 *
 * @param mixed $data The data to encode.
 * @return string JSON-encoded string.
 */
function sinople_aegis_json( mixed $data ): string {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Sanitizer::json( $data );
	}
	// WordPress fallback with similar security flags
	$result = wp_json_encode( $data, JSON_HEX_TAG | JSON_HEX_APOS | JSON_HEX_QUOT | JSON_HEX_AMP );
	return $result !== false ? $result : 'null';
}

/**
 * Sanitize URL for output.
 *
 * Uses php-aegis if available, falls back to WordPress esc_url().
 *
 * @param string $input The URL to sanitize.
 * @return string Sanitized URL.
 */
function sinople_aegis_url( string $input ): string {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Sanitizer::url( $input );
	}
	return rawurlencode( $input );
}

/**
 * Sanitize filename for uploads.
 *
 * Uses php-aegis if available, falls back to WordPress sanitize_file_name().
 *
 * @param string $input The filename to sanitize.
 * @return string Sanitized filename.
 */
function sinople_aegis_filename( string $input ): string {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Sanitizer::filename( $input );
	}
	return sanitize_file_name( $input );
}

/**
 * Validate email address.
 *
 * Uses php-aegis if available, falls back to is_email().
 *
 * @param string $email The email to validate.
 * @return bool True if valid email.
 */
function sinople_aegis_validate_email( string $email ): bool {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Validator::email( $email );
	}
	return (bool) is_email( $email );
}

/**
 * Validate URL.
 *
 * Uses php-aegis if available, falls back to filter_var.
 *
 * @param string $url The URL to validate.
 * @return bool True if valid URL.
 */
function sinople_aegis_validate_url( string $url ): bool {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Validator::url( $url );
	}
	return filter_var( $url, FILTER_VALIDATE_URL ) !== false;
}

/**
 * Validate URL is HTTPS (security requirement per RSR).
 *
 * Uses php-aegis if available, falls back to manual check.
 *
 * @param string $url The URL to validate.
 * @return bool True if valid HTTPS URL.
 */
function sinople_aegis_validate_https_url( string $url ): bool {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Validator::httpsUrl( $url );
	}
	if ( ! filter_var( $url, FILTER_VALIDATE_URL ) ) {
		return false;
	}
	$scheme = wp_parse_url( $url, PHP_URL_SCHEME );
	return $scheme === 'https';
}

/**
 * Validate UUID (RFC 4122).
 *
 * Uses php-aegis if available, falls back to regex.
 *
 * @param string $uuid The UUID to validate.
 * @return bool True if valid UUID.
 */
function sinople_aegis_validate_uuid( string $uuid ): bool {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Validator::uuid( $uuid );
	}
	$pattern = '/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i';
	return preg_match( $pattern, $uuid ) === 1;
}

/**
 * Validate ISO 8601 datetime string.
 *
 * Uses php-aegis if available, falls back to DateTimeImmutable parsing.
 *
 * @param string $datetime The datetime to validate.
 * @return bool True if valid ISO 8601 datetime.
 */
function sinople_aegis_validate_iso8601( string $datetime ): bool {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Validator::iso8601( $datetime );
	}
	$formats = array( 'Y-m-d', 'Y-m-d\TH:i:s', 'Y-m-d\TH:i:sP', 'Y-m-d\TH:i:s\Z' );
	foreach ( $formats as $format ) {
		$parsed = DateTimeImmutable::createFromFormat( $format, $datetime );
		if ( $parsed !== false && $parsed->format( $format ) === $datetime ) {
			return true;
		}
	}
	return false;
}

/**
 * Validate domain name.
 *
 * Uses php-aegis if available, falls back to regex.
 *
 * @param string $domain The domain to validate.
 * @return bool True if valid domain.
 */
function sinople_aegis_validate_domain( string $domain ): bool {
	if ( sinople_aegis_available() ) {
		return \PhpAegis\Validator::domain( $domain );
	}
	if ( $domain === '' || strlen( $domain ) > 253 ) {
		return false;
	}
	$pattern = '/^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$/';
	return preg_match( $pattern, $domain ) === 1;
}

/**
 * Remove potentially dangerous headers.
 *
 * Uses php-aegis if available, falls back to header_remove.
 */
function sinople_aegis_remove_insecure_headers(): void {
	if ( sinople_aegis_available() ) {
		\PhpAegis\Headers::removeInsecureHeaders();
		return;
	}
	header_remove( 'X-Powered-By' );
	header_remove( 'Server' );
}
add_action( 'send_headers', 'sinople_aegis_remove_insecure_headers', 0 );

/**
 * Log php-aegis availability status (for debugging).
 */
function sinople_aegis_log_status(): void {
	if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
		$status = sinople_aegis_available() ? 'loaded' : 'not available (using fallbacks)';
		// phpcs:ignore WordPress.PHP.DevelopmentFunctions.error_log_error_log
		error_log( sprintf( '[Sinople] php-aegis status: %s', $status ) );
	}
}
add_action( 'init', 'sinople_aegis_log_status' );
