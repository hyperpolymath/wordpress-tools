<?php
/**
 * Tests for serialization modules
 *
 * @package Sinople
 */

declare(strict_types=1);

/**
 * Class Test_Sinople_Serialization
 */
class Test_Sinople_Serialization extends SinopleTestCase {
	/**
	 * Test NDJSON feed generation
	 */
	public function test_ndjson_feed(): void {
		$this->create_test_post( array( 'post_title' => 'Post 1' ) );
		$this->create_test_post( array( 'post_title' => 'Post 2' ) );

		ob_start();
		Sinople_NDJSON_Feed::handle_ndjson_feed();
		$output = ob_get_clean();

		$lines = explode( "\n", trim( $output ) );

		$this->assertCount( 2, $lines );

		foreach ( $lines as $line ) {
			$json = json_decode( $line, true );
			$this->assertIsArray( $json );
			$this->assertArrayHasKey( 'id', $json );
			$this->assertArrayHasKey( 'title', $json );
		}
	}

	/**
	 * Test FlatBuffers JSON serialization
	 */
	public function test_flatbuffers_json(): void {
		$post_id = $this->create_test_post(
			array(
				'post_title'   => 'FlatBuffers Test',
				'post_content' => 'Test content',
			)
		);

		$post = get_post( $post_id );
		$json = Sinople_FlatBuffers::serialize_post_to_json( $post );

		$this->assertIsString( $json );
		$data = json_decode( $json, true );

		$this->assertArrayHasKey( 'metadata', $data );
		$this->assertArrayHasKey( 'title', $data );
		$this->assertEquals( 'FlatBuffers Test', $data['title'] );
	}

	/**
	 * Test Cap'n Proto RPC handler
	 */
	public function test_capnproto_rpc(): void {
		$post_id = $this->create_test_post();

		// Simulate RPC call
		$_GET['cp_format'] = 'json';
		$_GET['method']    = 'getPost';
		$_GET['id']        = $post_id;

		ob_start();
		Sinople_CapnProto::handle_rpc();
		$output = ob_get_clean();

		$json = json_decode( $output, true );

		$this->assertIsArray( $json );
		$this->assertArrayHasKey( 'metadata', $json );
		$this->assertEquals( $post_id, $json['metadata']['id'] );
	}

	/**
	 * Test BEAM interop - Erlang Term Format
	 */
	public function test_beam_erlang_term_format(): void {
		$data = array(
			'title'   => 'Test Post',
			'content' => 'Test content',
			'tags'    => array( 'tag1', 'tag2' ),
		);

		$etf = sinople_to_erlang_term( $data );

		$this->assertIsString( $etf );
		$this->assertNotEmpty( $etf );
	}

	/**
	 * Test Ecto schema compatibility
	 */
	public function test_ecto_schema_compatibility(): void {
		$post_id = $this->create_test_post(
			array(
				'post_title'   => 'Ecto Test',
				'post_content' => 'Ecto content',
			)
		);

		$post         = get_post( $post_id );
		$ecto_compat  = sinople_post_to_ecto_compatible( $post );

		$this->assertIsArray( $ecto_compat );
		$this->assertArrayHasKey( 'id', $ecto_compat );
		$this->assertArrayHasKey( 'title', $ecto_compat );
		$this->assertArrayHasKey( 'inserted_at', $ecto_compat );
		$this->assertArrayHasKey( 'updated_at', $ecto_compat );
	}
}
