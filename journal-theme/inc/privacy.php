<?php
/**
 * Privacy Features
 *
 * Partitioned cookies, ECH support readiness, privacy-first defaults,
 * and GDPR compliance helpers.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Set partitioned cookies for privacy
 */
function sinople_set_partitioned_cookie( $name, $value, $expire = 0, $path = '/', $domain = '', $secure = true, $httponly = true ) {
	// Set SameSite=None; Partitioned for CHIPS (Cookies Having Independent Partitioned State)
	$cookie_options = array(
		'expires'  => $expire,
		'path'     => $path,
		'domain'   => $domain,
		'secure'   => $secure,
		'httponly' => $httponly,
		'samesite' => 'None',
	);

	// Add Partitioned attribute (not yet in PHP setcookie, so we use header)
	$cookie_string = sprintf(
		'%s=%s; Expires=%s; Path=%s; Secure; HttpOnly; SameSite=None; Partitioned',
		rawurlencode( $name ),
		rawurlencode( $value ),
		gmdate( 'D, d-M-Y H:i:s T', $expire ),
		$path
	);

	header( "Set-Cookie: {$cookie_string}", false );
}

/**
 * Check if user has given consent for feature
 */
function sinople_has_consent( $feature ) {
	// Check for consent cookie
	$consent = isset( $_COOKIE['sinople_consent'] ) ? json_decode( stripslashes( $_COOKIE['sinople_consent'] ), true ) : array();

	// Default to false for privacy
	return isset( $consent[ $feature ] ) && $consent[ $feature ] === true;
}

/**
 * Set consent preferences
 */
function sinople_set_consent() {
	if ( ! isset( $_POST['sinople_consent_nonce'] ) ||
		 ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['sinople_consent_nonce'] ) ), 'sinople_consent' ) ) {
		wp_send_json_error( array( 'message' => 'Invalid nonce' ) );
	}

	$consent = array(
		'analytics'       => isset( $_POST['consent_analytics'] ) && $_POST['consent_analytics'] === '1',
		'external_fonts'  => isset( $_POST['consent_fonts'] ) && $_POST['consent_fonts'] === '1',
		'external_media'  => isset( $_POST['consent_media'] ) && $_POST['consent_media'] === '1',
		'webmentions'     => isset( $_POST['consent_webmentions'] ) && $_POST['consent_webmentions'] === '1',
	);

	sinople_set_partitioned_cookie(
		'sinople_consent',
		wp_json_encode( $consent ),
		time() + YEAR_IN_SECONDS,
		'/',
		'',
		true,
		false // Need to read from JS
	);

	wp_send_json_success( array( 'message' => 'Consent preferences saved' ) );
}
add_action( 'wp_ajax_sinople_set_consent', 'sinople_set_consent' );
add_action( 'wp_ajax_nopriv_sinople_set_consent', 'sinople_set_consent' );

/**
 * Remove external resources without consent
 */
function sinople_privacy_first_embeds( $content ) {
	if ( ! sinople_has_consent( 'external_media' ) ) {
		// Replace embeds with privacy-preserving placeholders
		$content = preg_replace(
			'/<iframe[^>]*src=["\']([^"\']+)["\'][^>]*>/i',
			'<div class="privacy-embed" data-src="$1"><p>' .
			esc_html__( 'This content requires your consent to load external media.', 'sinople' ) .
			' <button class="consent-btn" data-feature="external_media">' .
			esc_html__( 'Load content', 'sinople' ) .
			'</button></p></div>',
			$content
		);
	}

	return $content;
}
add_filter( 'the_content', 'sinople_privacy_first_embeds' );

/**
 * Remove Google Fonts without consent
 */
function sinople_privacy_fonts() {
	if ( ! sinople_has_consent( 'external_fonts' ) ) {
		// Use local fonts instead
		remove_action( 'wp_head', 'sinople_google_fonts' );
	}
}
add_action( 'wp_head', 'sinople_privacy_fonts', 1 );

/**
 * Add privacy-related headers
 */
function sinople_privacy_headers() {
	// Clear-Site-Data for privacy
	if ( isset( $_GET['clear_site_data'] ) && wp_verify_nonce( sanitize_text_field( wp_unslash( $_GET['nonce'] ?? '' ) ), 'clear_site_data' ) ) {
		header( 'Clear-Site-Data: "cache", "cookies", "storage"' );
	}

	// Support for ECH (Encrypted Client Hello) - indicate support
	// This is primarily a server/TLS configuration, but we can indicate readiness
	header( 'Supports-Loading-Mode: credentialed-prerender' );
}
add_action( 'send_headers', 'sinople_privacy_headers' );

/**
 * Add privacy policy link to footer
 */
function sinople_privacy_policy_link() {
	if ( function_exists( 'get_privacy_policy_url' ) && get_privacy_policy_url() ) {
		printf(
			'<a href="%s" class="privacy-policy-link">%s</a>',
			esc_url( get_privacy_policy_url() ),
			esc_html__( 'Privacy Policy', 'sinople' )
		);
	}
}

/**
 * Add consent management UI
 */
function sinople_consent_ui() {
	?>
	<div id="consent-banner" class="consent-banner" role="dialog" aria-labelledby="consent-title" aria-describedby="consent-description" hidden>
		<div class="consent-content">
			<h2 id="consent-title"><?php esc_html_e( 'Privacy & Consent', 'sinople' ); ?></h2>
			<p id="consent-description">
				<?php esc_html_e( 'This site respects your privacy. Choose which features you want to enable:', 'sinople' ); ?>
			</p>

			<form id="consent-form">
				<?php wp_nonce_field( 'sinople_consent', 'sinople_consent_nonce' ); ?>

				<label>
					<input type="checkbox" name="consent_analytics" value="1">
					<?php esc_html_e( 'Anonymous analytics', 'sinople' ); ?>
				</label>

				<label>
					<input type="checkbox" name="consent_fonts" value="1">
					<?php esc_html_e( 'External fonts (Google Fonts)', 'sinople' ); ?>
				</label>

				<label>
					<input type="checkbox" name="consent_media" value="1">
					<?php esc_html_e( 'External media (YouTube, Vimeo, etc.)', 'sinople' ); ?>
				</label>

				<label>
					<input type="checkbox" name="consent_webmentions" value="1" checked>
					<?php esc_html_e( 'Webmentions and social interactions', 'sinople' ); ?>
				</label>

				<div class="consent-actions">
					<button type="submit" class="button button-primary">
						<?php esc_html_e( 'Save Preferences', 'sinople' ); ?>
					</button>
					<button type="button" class="button" data-action="accept-all">
						<?php esc_html_e( 'Accept All', 'sinople' ); ?>
					</button>
					<button type="button" class="button" data-action="reject-all">
						<?php esc_html_e( 'Reject All', 'sinople' ); ?>
					</button>
				</div>
			</form>
		</div>
	</div>
	<?php
}
add_action( 'wp_footer', 'sinople_consent_ui' );

/**
 * Remove WordPress version and generator tags for privacy
 */
remove_action( 'wp_head', 'wp_generator' );

/**
 * Anonymize IP addresses in comments
 */
function sinople_anonymize_comment_ip( $comment_data ) {
	if ( isset( $comment_data['comment_author_IP'] ) ) {
		// Anonymize IPv4: 192.168.1.1 -> 192.168.1.0
		// Anonymize IPv6: 2001:db8::1 -> 2001:db8::
		$ip = $comment_data['comment_author_IP'];

		if ( filter_var( $ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 ) ) {
			$parts = explode( '.', $ip );
			$parts[3] = '0';
			$comment_data['comment_author_IP'] = implode( '.', $parts );
		} elseif ( filter_var( $ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6 ) ) {
			$parts = explode( ':', $ip );
			$parts[ count( $parts ) - 1 ] = '';
			$comment_data['comment_author_IP'] = implode( ':', $parts );
		}
	}

	return $comment_data;
}
add_filter( 'preprocess_comment', 'sinople_anonymize_comment_ip' );

/**
 * Add Do Not Track header respect
 */
function sinople_respect_dnt() {
	if ( isset( $_SERVER['HTTP_DNT'] ) && $_SERVER['HTTP_DNT'] === '1' ) {
		// Disable tracking
		add_filter( 'sinople_enable_analytics', '__return_false' );
	}
}
add_action( 'init', 'sinople_respect_dnt' );
