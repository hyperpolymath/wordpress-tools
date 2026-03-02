<?php
/**
 * Tests for inc/indieweb.php
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Sinople_IndieWeb
 */
class Test_Sinople_IndieWeb extends SinopleTestCase {
	/**
	 * Test microformats classes are added
	 */
	public function test_sinople_add_microformats_classes(): void {
		$post_id = $this->create_test_post();
		$classes = get_post_class( '', $post_id );

		$this->assertContains( 'h-entry', $classes );
	}

	/**
	 * Test h-card generation for author
	 */
	public function test_sinople_author_hcard(): void {
		$author_id = $this->create_test_user( 'author' );

		ob_start();
		sinople_author_hcard( $author_id );
		$output = ob_get_clean();

		$this->assertHasMicroformat( $output, 'h-card' );
		$this->assertHasMicroformat( $output, 'p-name' );
		$this->assertHasMicroformat( $output, 'u-url' );
	}

	/**
	 * Test entry properties
	 */
	public function test_sinople_entry_properties(): void {
		$post_id = $this->create_test_post(
			array(
				'post_title'   => 'Test Entry',
				'post_content' => 'Test content',
			)
		);

		$this->go_to( get_permalink( $post_id ) );

		ob_start();
		the_title( '<h1 class="p-name entry-title">', '</h1>' );
		$output = ob_get_clean();

		$this->assertHasMicroformat( $output, 'p-name' );
		$this->assertHasMicroformat( $output, 'entry-title' );
	}

	/**
	 * Test webmention endpoint
	 */
	public function test_sinople_webmention_endpoint(): void {
		ob_start();
		wp_head();
		$output = ob_get_clean();

		$this->assertStringContainsString( 'rel="webmention"', $output );
	}

	/**
	 * Test JSON Feed generation
	 */
	public function test_sinople_json_feed(): void {
		$this->create_test_post();
		$this->create_test_post();

		ob_start();
		sinople_json_feed();
		$output = ob_get_clean();

		$json = json_decode( $output, true );

		$this->assertIsArray( $json );
		$this->assertEquals( 'https://jsonfeed.org/version/1.1', $json['version'] );
		$this->assertArrayHasKey( 'items', $json );
		$this->assertCount( 2, $json['items'] );
	}

	/**
	 * Test POSSE syndication links
	 */
	public function test_sinople_syndication_links(): void {
		$post_id = $this->create_test_post();

		add_post_meta( $post_id, 'syndication_urls', array(
			'https://twitter.com/example/status/123',
			'https://mastodon.social/@example/456',
		) );

		ob_start();
		sinople_syndication_links( $post_id );
		$output = ob_get_clean();

		$this->assertHasMicroformat( $output, 'u-syndication' );
		$this->assertStringContainsString( 'twitter.com', $output );
		$this->assertStringContainsString( 'mastodon.social', $output );
	}
}
