<?php
/**
 * Serialization Formats
 *
 * Cap'n Proto, NDJSON, FlatBuffers support for efficient data exchange
 * with BEAM (Erlang/Elixir) and other systems.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Get NDJSON feed URL
 */
function sinople_ndjson_feed_url() {
	return home_url( '/feed/ndjson/' );
}

/**
 * Generate NDJSON feed
 */
function sinople_generate_ndjson_feed() {
	if ( ! get_query_var( 'ndjson' ) ) {
		return;
	}

	header( 'Content-Type: application/x-ndjson; charset=' . get_bloginfo( 'charset' ) );
	header( 'Cache-Control: public, max-age=600' );

	$posts = get_posts(
		array(
			'posts_per_page' => get_theme_mod( 'sinople_ndjson_limit', 100 ),
			'post_status'    => 'publish',
			'orderby'        => 'date',
			'order'          => 'DESC',
		)
	);

	foreach ( $posts as $post ) {
		$entry = array(
			'id'             => get_permalink( $post->ID ),
			'type'           => 'post',
			'title'          => get_the_title( $post->ID ),
			'content'        => apply_filters( 'the_content', $post->post_content ),
			'excerpt'        => get_the_excerpt( $post->ID ),
			'author'         => array(
				'name' => get_the_author_meta( 'display_name', $post->post_author ),
				'url'  => get_author_posts_url( $post->post_author ),
			),
			'published'      => get_the_date( 'c', $post->ID ),
			'modified'       => get_the_modified_date( 'c', $post->ID ),
			'url'            => get_permalink( $post->ID ),
			'categories'     => wp_get_post_categories( $post->ID, array( 'fields' => 'names' ) ),
			'tags'           => wp_get_post_tags( $post->ID, array( 'fields' => 'names' ) ),
		);

		// Add thumbnail if available
		if ( has_post_thumbnail( $post->ID ) ) {
			$entry['image'] = array(
				'url'    => get_the_post_thumbnail_url( $post->ID, 'full' ),
				'width'  => get_post_thumbnail_id( $post->ID ) ? wp_get_attachment_metadata( get_post_thumbnail_id( $post->ID ) )['width'] : null,
				'height' => get_post_thumbnail_id( $post->ID ) ? wp_get_attachment_metadata( get_post_thumbnail_id( $post->ID ) )['height'] : null,
			);
		}

		// Output as single-line JSON
		echo wp_json_encode( $entry, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ) . "\n";
	}

	exit;
}
add_action( 'template_redirect', 'sinople_generate_ndjson_feed' );

/**
 * Get Cap'n Proto endpoint URL
 */
function sinople_capnproto_endpoint_url() {
	return home_url( '/feed/capnproto/' );
}

/**
 * BEAM (Erlang/Elixir) interoperability helpers
 */
class Sinople_BEAM_Interop {

	/**
	 * Convert PHP array to Erlang term format (ETF)
	 */
	public static function to_etf( $data ) {
		// This would require erlang extension or external library
		// Placeholder for implementation
		return base64_encode( serialize( $data ) );
	}

	/**
	 * Parse Erlang term format (ETF) to PHP array
	 */
	public static function from_etf( $etf ) {
		// Placeholder for implementation
		return unserialize( base64_decode( $etf ) );
	}

	/**
	 * Create Erlang port message
	 */
	public static function port_message( $command, $data = array() ) {
		return array(
			'command' => $command,
			'data'    => $data,
			'pid'     => getmypid(),
			'timestamp' => gmdate( 'c' ),
		);
	}

	/**
	 * Format for Ecto schema compatibility
	 */
	public static function to_ecto_schema( $post ) {
		return array(
			'__struct__' => 'Elixir.Sinople.Post',
			'id'         => $post->ID,
			'title'      => $post->post_title,
			'content'    => $post->post_content,
			'author_id'  => $post->post_author,
			'published_at' => get_the_date( 'c', $post->ID ),
			'updated_at'   => get_the_modified_date( 'c', $post->ID ),
			'inserted_at'  => get_the_date( 'c', $post->ID ),
		);
	}
}

/**
 * NDJSON streaming endpoint for real-time updates
 */
function sinople_ndjson_stream() {
	if ( ! isset( $_GET['stream'] ) || $_GET['stream'] !== 'ndjson' ) {
		return;
	}

	// Verify nonce
	if ( ! isset( $_GET['nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_GET['nonce'] ) ), 'ndjson_stream' ) ) {
		wp_die( 'Invalid nonce' );
	}

	header( 'Content-Type: application/x-ndjson' );
	header( 'Cache-Control: no-cache' );
	header( 'X-Accel-Buffering: no' ); // Disable nginx buffering

	// Disable output buffering for streaming
	while ( ob_get_level() ) {
		ob_end_flush();
	}

	set_time_limit( 0 );

	// Stream updates
	$last_post_id = isset( $_GET['since'] ) ? absint( $_GET['since'] ) : 0;

	while ( true ) {
		$new_posts = get_posts(
			array(
				'posts_per_page' => 10,
				'post_status'    => 'publish',
				'orderby'        => 'ID',
				'order'          => 'ASC',
				'post__gt'       => $last_post_id,
			)
		);

		foreach ( $new_posts as $post ) {
			$entry = array(
				'id'        => $post->ID,
				'title'     => get_the_title( $post->ID ),
				'url'       => get_permalink( $post->ID ),
				'published' => get_the_date( 'c', $post->ID ),
			);

			echo wp_json_encode( $entry, JSON_UNESCAPED_SLASHES ) . "\n";
			flush();

			$last_post_id = $post->ID;
		}

		// Sleep for a bit before checking for new posts
		sleep( 5 );

		// Check if connection is still alive
		if ( connection_aborted() ) {
			break;
		}
	}

	exit;
}
add_action( 'init', 'sinople_ndjson_stream' );

/**
 * Message queue integration (for BEAM communication)
 */
class Sinople_Message_Queue {

	/**
	 * Send message to RabbitMQ (AMQP)
	 */
	public static function publish( $queue, $message, $properties = array() ) {
		// Placeholder - would use php-amqplib
		// Connection to RabbitMQ running in Podman container
		$connection_params = array(
			'host'     => getenv( 'RABBITMQ_HOST' ) ?: 'localhost',
			'port'     => getenv( 'RABBITMQ_PORT' ) ?: 5672,
			'user'     => getenv( 'RABBITMQ_USER' ) ?: 'guest',
			'password' => getenv( 'RABBITMQ_PASS' ) ?: 'guest',
			'vhost'    => '/',
		);

		return apply_filters( 'sinople_mq_publish', false, $queue, $message, $properties, $connection_params );
	}

	/**
	 * Publish post update to queue
	 */
	public static function publish_post_update( $post_id, $post, $update ) {
		$message = array(
			'event'   => $update ? 'post_updated' : 'post_created',
			'post_id' => $post_id,
			'data'    => Sinople_BEAM_Interop::to_ecto_schema( $post ),
		);

		self::publish( 'sinople.posts', $message );
	}
}

// Hook into post save to notify queue
add_action( 'save_post', array( 'Sinople_Message_Queue', 'publish_post_update' ), 10, 3 );

/**
 * Binary serialization via MessagePack (alternative to Cap'n Proto)
 */
function sinople_msgpack_encode( $data ) {
	if ( ! function_exists( 'msgpack_pack' ) ) {
		return false;
	}

	return msgpack_pack( $data );
}

function sinople_msgpack_decode( $data ) {
	if ( ! function_exists( 'msgpack_unpack' ) ) {
		return false;
	}

	return msgpack_unpack( $data );
}

/**
 * Add serialization format query var
 */
function sinople_serialization_query_vars( $vars ) {
	$vars[] = 'format';
	$vars[] = 'ndjson';
	$vars[] = 'capnproto';
	$vars[] = 'msgpack';
	return $vars;
}
add_filter( 'query_vars', 'sinople_serialization_query_vars' );

/**
 * Content negotiation for format selection
 */
function sinople_content_negotiation() {
	if ( ! isset( $_SERVER['HTTP_ACCEPT'] ) ) {
		return;
	}

	$accept = sanitize_text_field( wp_unslash( $_SERVER['HTTP_ACCEPT'] ) );

	if ( strpos( $accept, 'application/x-ndjson' ) !== false ) {
		set_query_var( 'ndjson', '1' );
	} elseif ( strpos( $accept, 'application/x-capnproto' ) !== false ) {
		set_query_var( 'capnproto', '1' );
	} elseif ( strpos( $accept, 'application/x-msgpack' ) !== false ) {
		set_query_var( 'msgpack', '1' );
	}
}
add_action( 'parse_request', 'sinople_content_negotiation' );
