<?php
/**
 * Tests for inc/security.php
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Sinople_Security
 */
class Test_Sinople_Security extends SinopleTestCase {
	/**
	 * Test security headers are set
	 */
	public function test_sinople_security_headers(): void {
		// Capture headers
		if ( ! function_exists( 'xdebug_get_headers' ) ) {
			$this->markTestSkipped( 'xdebug required for header testing' );
		}

		sinople_security_headers();
		$headers = xdebug_get_headers();

		$header_names = array_map(
			function( $header ) {
				return explode( ':', $header )[0];
			},
			$headers
		);

		$this->assertContains( 'Strict-Transport-Security', $header_names );
		$this->assertContains( 'Content-Security-Policy', $header_names );
		$this->assertContains( 'X-Frame-Options', $header_names );
		$this->assertContains( 'X-Content-Type-Options', $header_names );
	}

	/**
	 * Test CSP header includes required directives
	 */
	public function test_csp_header_content(): void {
		if ( ! function_exists( 'xdebug_get_headers' ) ) {
			$this->markTestSkipped( 'xdebug required for header testing' );
		}

		sinople_security_headers();
		$headers = xdebug_get_headers();

		$csp_header = '';
		foreach ( $headers as $header ) {
			if ( strpos( $header, 'Content-Security-Policy:' ) === 0 ) {
				$csp_header = $header;
				break;
			}
		}

		$this->assertStringContainsString( "default-src 'self'", $csp_header );
		$this->assertStringContainsString( 'wasm-unsafe-eval', $csp_header );
		$this->assertNotContainsString( 'unsafe-inline', $csp_header );
		$this->assertNotContainsString( 'unsafe-eval', $csp_header );
	}

	/**
	 * Test input sanitization
	 */
	public function test_sinople_sanitize_input(): void {
		$dirty_input = '<script>alert("xss")</script>Hello';
		$clean_input = sinople_sanitize_input( $dirty_input );

		$this->assertStringNotContainsString( '<script>', $clean_input );
		$this->assertStringContainsString( 'Hello', $clean_input );
	}

	/**
	 * Test URL validation
	 */
	public function test_sinople_is_safe_url(): void {
		$safe_url   = home_url( '/test' );
		$unsafe_url = 'javascript:alert(1)';

		$this->assertTrue( sinople_is_safe_url( $safe_url ) );
		$this->assertFalse( sinople_is_safe_url( $unsafe_url ) );
	}

	/**
	 * Test nonce verification helper
	 */
	public function test_sinople_verify_nonce(): void {
		$nonce = wp_create_nonce( 'test_action' );

		$_POST['_wpnonce'] = $nonce;
		$this->assertTrue( sinople_verify_nonce( 'test_action' ) );

		$_POST['_wpnonce'] = 'invalid_nonce';
		$this->assertFalse( sinople_verify_nonce( 'test_action' ) );
	}
}
