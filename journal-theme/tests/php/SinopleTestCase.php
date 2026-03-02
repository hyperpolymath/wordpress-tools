<?php
/**
 * Base test case for Sinople theme tests
 *
 * @package Sinople
 */

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

/**
 * Class SinopleTestCase
 *
 * Base class for all Sinople theme tests with common utilities
 */
class SinopleTestCase extends WP_UnitTestCase {
	/**
	 * Set up before each test
	 */
	public function setUp(): void {
		parent::setUp();

		// Ensure clean state
		$this->clean_up_global_scope();
	}

	/**
	 * Tear down after each test
	 */
	public function tearDown(): void {
		parent::tearDown();

		// Clean up
		$this->clean_up_global_scope();
	}

	/**
	 * Clean up global scope
	 */
	protected function clean_up_global_scope(): void {
		$_GET  = array();
		$_POST = array();
	}

	/**
	 * Create a test post with metadata
	 *
	 * @param array $args Post arguments
	 * @return int Post ID
	 */
	protected function create_test_post( array $args = array() ): int {
		$defaults = array(
			'post_title'   => 'Test Post',
			'post_content' => 'Test content with multiple words for reading time calculation.',
			'post_status'  => 'publish',
			'post_type'    => 'post',
		);

		$args = wp_parse_args( $args, $defaults );

		return $this->factory()->post->create( $args );
	}

	/**
	 * Create a test user
	 *
	 * @param string $role User role
	 * @return int User ID
	 */
	protected function create_test_user( string $role = 'subscriber' ): int {
		return $this->factory()->user->create( array( 'role' => $role ) );
	}

	/**
	 * Assert that a string contains valid JSON-LD
	 *
	 * @param string $json_ld JSON-LD string
	 */
	protected function assertValidJsonLd( string $json_ld ): void {
		$decoded = json_decode( $json_ld, true );

		$this->assertIsArray( $decoded, 'JSON-LD must be valid JSON' );
		$this->assertArrayHasKey( '@context', $decoded, 'JSON-LD must have @context' );
		$this->assertArrayHasKey( '@type', $decoded, 'JSON-LD must have @type' );
	}

	/**
	 * Assert that HTML contains valid microformats
	 *
	 * @param string $html HTML string
	 * @param string $microformat Microformat class (e.g., 'h-entry')
	 */
	protected function assertHasMicroformat( string $html, string $microformat ): void {
		$this->assertStringContainsString(
			$microformat,
			$html,
			"HTML must contain microformat class: {$microformat}"
		);
	}

	/**
	 * Assert that element has proper ARIA attributes
	 *
	 * @param string $html HTML string
	 * @param string $aria_attribute ARIA attribute name
	 */
	protected function assertHasAriaAttribute( string $html, string $aria_attribute ): void {
		$this->assertStringContainsString(
			$aria_attribute,
			$html,
			"HTML must contain ARIA attribute: {$aria_attribute}"
		);
	}
}
