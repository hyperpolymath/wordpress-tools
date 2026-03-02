<?php
/**
 * Tests for inc/semantic.php
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Sinople_Semantic
 */
class Test_Sinople_Semantic extends SinopleTestCase {
	/**
	 * Test JSON-LD generation for post
	 */
	public function test_sinople_get_jsonld_post(): void {
		$author_id = $this->create_test_user( 'author' );
		$post_id   = $this->create_test_post(
			array(
				'post_title'   => 'Test Article',
				'post_content' => 'Test content for JSON-LD',
				'post_author'  => $author_id,
			)
		);

		// Go to the post
		$this->go_to( get_permalink( $post_id ) );

		ob_start();
		sinople_output_jsonld();
		$output = ob_get_clean();

		$this->assertValidJsonLd( $output );
		$this->assertStringContainsString( '"@type":"Article"', $output );
		$this->assertStringContainsString( 'Test Article', $output );
	}

	/**
	 * Test JSON-LD for home page
	 */
	public function test_sinople_get_jsonld_home(): void {
		$this->go_to( home_url() );

		ob_start();
		sinople_output_jsonld();
		$output = ob_get_clean();

		$this->assertValidJsonLd( $output );
		$this->assertStringContainsString( '"@type":"WebSite"', $output );
	}

	/**
	 * Test Open Graph metadata
	 */
	public function test_sinople_output_opengraph(): void {
		$post_id = $this->create_test_post(
			array(
				'post_title'   => 'OG Test Post',
				'post_content' => 'Open Graph test content',
			)
		);

		$this->go_to( get_permalink( $post_id ) );

		ob_start();
		sinople_output_opengraph();
		$output = ob_get_clean();

		$this->assertStringContainsString( 'og:title', $output );
		$this->assertStringContainsString( 'og:type', $output );
		$this->assertStringContainsString( 'og:url', $output );
		$this->assertStringContainsString( 'OG Test Post', $output );
	}

	/**
	 * Test Twitter Card metadata
	 */
	public function test_sinople_output_twitter_cards(): void {
		$post_id = $this->create_test_post(
			array(
				'post_title'   => 'Twitter Test Post',
				'post_content' => 'Twitter card test content',
			)
		);

		$this->go_to( get_permalink( $post_id ) );

		ob_start();
		sinople_output_twitter_cards();
		$output = ob_get_clean();

		$this->assertStringContainsString( 'twitter:card', $output );
		$this->assertStringContainsString( 'twitter:title', $output );
		$this->assertStringContainsString( 'Twitter Test Post', $output );
	}

	/**
	 * Test breadcrumb JSON-LD
	 */
	public function test_sinople_get_breadcrumb_jsonld(): void {
		$post_id = $this->create_test_post();
		$this->go_to( get_permalink( $post_id ) );

		$breadcrumb = sinople_get_breadcrumb_jsonld();

		$this->assertIsArray( $breadcrumb );
		$this->assertEquals( 'BreadcrumbList', $breadcrumb['@type'] );
		$this->assertArrayHasKey( 'itemListElement', $breadcrumb );
	}

	/**
	 * Test RDFa attributes
	 */
	public function test_sinople_get_rdfa_attributes(): void {
		$post_id = $this->create_test_post();
		$this->go_to( get_permalink( $post_id ) );

		$rdfa = sinople_get_rdfa_attributes();

		$this->assertStringContainsString( 'vocab=', $rdfa );
		$this->assertStringContainsString( 'typeof=', $rdfa );
	}
}
