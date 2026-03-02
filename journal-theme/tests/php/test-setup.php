<?php
/**
 * Tests for inc/setup.php
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Sinople_Setup
 */
class Test_Sinople_Setup extends SinopleTestCase {
	/**
	 * Test reading time calculation
	 */
	public function test_sinople_reading_time(): void {
		$post_id = $this->create_test_post(
			array(
				'post_content' => str_repeat( 'word ', 200 ), // 200 words
			)
		);

		$reading_time = sinople_reading_time( $post_id );

		$this->assertIsInt( $reading_time );
		$this->assertGreaterThan( 0, $reading_time );
		$this->assertEquals( 1, $reading_time ); // 200 words / 200 wpm = 1 minute
	}

	/**
	 * Test reading time with empty content
	 */
	public function test_sinople_reading_time_empty(): void {
		$post_id = $this->create_test_post(
			array(
				'post_content' => '',
			)
		);

		$reading_time = sinople_reading_time( $post_id );

		$this->assertEquals( 1, $reading_time ); // Minimum 1 minute
	}

	/**
	 * Test reading time with very long content
	 */
	public function test_sinople_reading_time_long_content(): void {
		$post_id = $this->create_test_post(
			array(
				'post_content' => str_repeat( 'word ', 1000 ), // 1000 words
			)
		);

		$reading_time = sinople_reading_time( $post_id );

		$this->assertEquals( 5, $reading_time ); // 1000 words / 200 wpm = 5 minutes
	}

	/**
	 * Test post classes include semantic information
	 */
	public function test_sinople_post_classes(): void {
		$post_id = $this->create_test_post(
			array(
				'post_type' => 'field_note',
			)
		);

		$classes = get_post_class( '', $post_id );

		$this->assertContains( 'h-entry', $classes );
		$this->assertContains( 'field-note', $classes );
	}

	/**
	 * Test body classes include feature detection
	 */
	public function test_sinople_body_classes(): void {
		$classes = get_body_class();

		$this->assertIsArray( $classes );
		$this->assertNotEmpty( $classes );
	}

	/**
	 * Test custom query vars registration
	 */
	public function test_sinople_query_vars(): void {
		global $wp;

		$query_vars = $wp->public_query_vars;

		$this->assertContains( 'void_format', $query_vars );
		$this->assertContains( 'ndjson_stream', $query_vars );
		$this->assertContains( 'cp_format', $query_vars );
	}

	/**
	 * Test rewrite rules for semantic endpoints
	 */
	public function test_sinople_rewrite_rules(): void {
		global $wp_rewrite;

		$rules = $wp_rewrite->wp_rewrite_rules();

		$this->assertArrayHasKey( 'void\\.rdf/?$', $rules );
		$this->assertArrayHasKey( 'feed/ndjson/?$', $rules );
		$this->assertArrayHasKey( 'feed/capnproto/?$', $rules );
	}

	/**
	 * Test theme supports
	 */
	public function test_theme_supports(): void {
		$this->assertTrue( current_theme_supports( 'html5' ) );
		$this->assertTrue( current_theme_supports( 'title-tag' ) );
		$this->assertTrue( current_theme_supports( 'post-thumbnails' ) );
		$this->assertTrue( current_theme_supports( 'customize-selective-refresh-widgets' ) );
		$this->assertTrue( current_theme_supports( 'microformats2' ) );
	}
}
