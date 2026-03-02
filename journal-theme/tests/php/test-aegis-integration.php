<?php
/**
 * Tests for inc/aegis-integration.php
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Aegis_Integration
 */
class Test_Aegis_Integration extends SinopleTestCase {
	/**
	 * Test aegis availability check
	 */
	public function test_sinople_aegis_available(): void {
		// Function should exist and return bool
		$this->assertIsBool( sinople_aegis_available() );
	}

	/**
	 * Test HTML sanitization
	 */
	public function test_sinople_aegis_html(): void {
		$input    = '<script>alert("xss")</script>Hello';
		$output   = sinople_aegis_html( $input );

		$this->assertStringNotContainsString( '<script>', $output );
		$this->assertStringContainsString( 'Hello', $output );
	}

	/**
	 * Test attribute sanitization
	 */
	public function test_sinople_aegis_attr(): void {
		$input  = 'value" onclick="evil()';
		$output = sinople_aegis_attr( $input );

		$this->assertStringNotContainsString( '"', $output );
	}

	/**
	 * Test JSON encoding with security flags
	 */
	public function test_sinople_aegis_json(): void {
		$data   = array( 'test' => '<script>' );
		$output = sinople_aegis_json( $data );

		// Should escape HTML tags in JSON
		$this->assertStringNotContainsString( '<script>', $output );
		$this->assertJson( $output );
	}

	/**
	 * Test email validation
	 */
	public function test_sinople_aegis_validate_email(): void {
		$this->assertTrue( sinople_aegis_validate_email( 'test@example.com' ) );
		$this->assertFalse( sinople_aegis_validate_email( 'invalid-email' ) );
		$this->assertFalse( sinople_aegis_validate_email( '' ) );
	}

	/**
	 * Test URL validation
	 */
	public function test_sinople_aegis_validate_url(): void {
		$this->assertTrue( sinople_aegis_validate_url( 'https://example.com' ) );
		$this->assertTrue( sinople_aegis_validate_url( 'http://example.com/path' ) );
		$this->assertFalse( sinople_aegis_validate_url( 'not-a-url' ) );
		$this->assertFalse( sinople_aegis_validate_url( 'javascript:alert(1)' ) );
	}

	/**
	 * Test HTTPS URL validation
	 */
	public function test_sinople_aegis_validate_https_url(): void {
		$this->assertTrue( sinople_aegis_validate_https_url( 'https://example.com' ) );
		$this->assertFalse( sinople_aegis_validate_https_url( 'http://example.com' ) );
		$this->assertFalse( sinople_aegis_validate_https_url( 'ftp://example.com' ) );
	}

	/**
	 * Test UUID validation
	 */
	public function test_sinople_aegis_validate_uuid(): void {
		$this->assertTrue( sinople_aegis_validate_uuid( '550e8400-e29b-41d4-a716-446655440000' ) );
		$this->assertFalse( sinople_aegis_validate_uuid( 'not-a-uuid' ) );
		$this->assertFalse( sinople_aegis_validate_uuid( '550e8400-e29b-41d4-a716' ) );
	}

	/**
	 * Test ISO 8601 datetime validation
	 */
	public function test_sinople_aegis_validate_iso8601(): void {
		$this->assertTrue( sinople_aegis_validate_iso8601( '2024-01-15' ) );
		$this->assertTrue( sinople_aegis_validate_iso8601( '2024-01-15T10:30:00Z' ) );
		$this->assertFalse( sinople_aegis_validate_iso8601( '15-01-2024' ) );
		$this->assertFalse( sinople_aegis_validate_iso8601( 'not-a-date' ) );
	}

	/**
	 * Test domain validation
	 */
	public function test_sinople_aegis_validate_domain(): void {
		$this->assertTrue( sinople_aegis_validate_domain( 'example.com' ) );
		$this->assertTrue( sinople_aegis_validate_domain( 'sub.example.com' ) );
		$this->assertFalse( sinople_aegis_validate_domain( 'invalid..domain' ) );
		$this->assertFalse( sinople_aegis_validate_domain( '' ) );
	}

	/**
	 * Test filename sanitization
	 */
	public function test_sinople_aegis_filename(): void {
		$this->assertSame( 'safe_file.txt', sinople_aegis_filename( '../../../safe_file.txt' ) );
		$this->assertSame( 'file.txt', sinople_aegis_filename( '.file.txt' ) );
	}
}

/**
 * Class Test_Turtle_Output
 */
class Test_Turtle_Output extends SinopleTestCase {
	/**
	 * Test turtle availability check
	 */
	public function test_sinople_turtle_available(): void {
		$this->assertIsBool( sinople_turtle_available() );
	}

	/**
	 * Test turtle string escaping
	 */
	public function test_sinople_turtle_escape_string(): void {
		$input  = "Hello\nWorld";
		$output = sinople_turtle_escape_string( $input );

		$this->assertStringContainsString( '\\n', $output );
		$this->assertStringNotContainsString( "\n", $output );
	}

	/**
	 * Test turtle IRI escaping
	 */
	public function test_sinople_turtle_escape_iri(): void {
		$input  = 'https://example.com/path with spaces';
		$output = sinople_turtle_escape_iri( $input );

		$this->assertStringNotContainsString( ' ', $output );
		$this->assertStringContainsString( '%20', $output );
	}

	/**
	 * Test turtle literal generation
	 */
	public function test_sinople_turtle_literal(): void {
		$value  = 'Hello World';
		$output = sinople_turtle_literal( $value, 'en' );

		$this->assertStringStartsWith( '"', $output );
		$this->assertStringContainsString( '@en', $output );
	}

	/**
	 * Test turtle triple generation
	 */
	public function test_sinople_turtle_triple(): void {
		$subject   = 'https://example.com/post/1';
		$predicate = 'https://schema.org/name';
		$object    = 'Test Post';

		$output = sinople_turtle_triple( $subject, $predicate, $object );

		$this->assertStringContainsString( '<https://example.com/post/1>', $output );
		$this->assertStringContainsString( '<https://schema.org/name>', $output );
		$this->assertStringContainsString( '"Test Post"', $output );
		$this->assertStringEndsWith( ' .', $output );
	}

	/**
	 * Test turtle triple with IRI object
	 */
	public function test_sinople_turtle_triple_iri(): void {
		$subject   = 'https://example.com/post/1';
		$predicate = 'https://schema.org/author';
		$objectIri = 'https://example.com/author/1';

		$output = sinople_turtle_triple_iri( $subject, $predicate, $objectIri );

		$this->assertStringContainsString( '<https://example.com/author/1>', $output );
		$this->assertStringNotContainsString( '"', $output );
	}
}
