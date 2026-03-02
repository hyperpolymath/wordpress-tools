<?php
/**
 * Enhanced NDJSON Feed Implementation
 *
 * First-class NDJSON support with streaming, filtering,
 * and real-time updates via Server-Sent Events.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * NDJSON Feed Handler
 */
class Sinople_NDJSON_Feed {

	/**
	 * Initialize NDJSON feed
	 */
	public static function init() {
		add_action( 'template_redirect', array( __CLASS__, 'handle_ndjson_request' ), 1 );
		add_action( 'template_redirect', array( __CLASS__, 'handle_ndjson_stream' ), 1 );
		add_filter( 'query_vars', array( __CLASS__, 'add_query_vars' ) );
		add_action( 'init', array( __CLASS__, 'add_rewrite_rules' ) );
	}

	/**
	 * Add query vars
	 */
	public static function add_query_vars( $vars ) {
		$vars[] = 'ndjson';
		$vars[] = 'ndjson_stream';
		$vars[] = 'ndjson_filter';
		$vars[] = 'ndjson_limit';
		$vars[] = 'ndjson_offset';
		return $vars;
	}

	/**
	 * Add rewrite rules
	 */
	public static function add_rewrite_rules() {
		add_rewrite_rule( '^feed/ndjson/?$', 'index.php?ndjson=1', 'top' );
		add_rewrite_rule( '^feed/ndjson/stream/?$', 'index.php?ndjson_stream=1', 'top' );
	}

	/**
	 * Handle NDJSON feed request
	 */
	public static function handle_ndjson_request() {
		if ( ! get_query_var( 'ndjson' ) ) {
			return;
		}

		// Set headers
		header( 'Content-Type: application/x-ndjson; charset=' . get_bloginfo( 'charset' ) );
		header( 'Cache-Control: public, max-age=600' );
		header( 'Access-Control-Allow-Origin: *' );
		header( 'Access-Control-Allow-Methods: GET, OPTIONS' );
		header( 'X-Content-Type-Options: nosniff' );

		// Get filter parameters
		$filter     = get_query_var( 'ndjson_filter', '' );
		$limit      = absint( get_query_var( 'ndjson_limit', 100 ) );
		$offset     = absint( get_query_var( 'ndjson_offset', 0 ) );
		$post_type  = sanitize_text_field( get_query_var( 'post_type', 'post' ) );

		// Build query args
		$args = array(
			'posts_per_page' => min( $limit, 1000 ), // Max 1000
			'offset'         => $offset,
			'post_status'    => 'publish',
			'post_type'      => explode( ',', $post_type ),
			'orderby'        => 'date',
			'order'          => 'DESC',
		);

		// Apply filters
		if ( $filter ) {
			$args = apply_filters( 'sinople_ndjson_query_args', $args, $filter );
		}

		// Get posts
		$posts = get_posts( $args );

		// Output feed metadata as first line
		$metadata = array(
			'feed_version' => '1.0',
			'feed_url'     => home_url( '/feed/ndjson/' ),
			'site_name'    => get_bloginfo( 'name' ),
			'site_url'     => home_url( '/' ),
			'generated_at' => gmdate( 'c' ),
			'count'        => count( $posts ),
			'total'        => wp_count_posts( $post_type )->publish,
		);
		echo wp_json_encode( $metadata, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ) . "\n";

		// Output each post as NDJSON line
		foreach ( $posts as $post ) {
			echo self::encode_post( $post ) . "\n";
			flush();
		}

		exit;
	}

	/**
	 * Handle NDJSON streaming (Server-Sent Events)
	 */
	public static function handle_ndjson_stream() {
		if ( ! get_query_var( 'ndjson_stream' ) ) {
			return;
		}

		// Verify capabilities for streaming
		if ( ! current_user_can( 'read' ) ) {
			wp_die( 'Unauthorized', 401 );
		}

		// Set headers for SSE
		header( 'Content-Type: text/event-stream' );
		header( 'Cache-Control: no-cache' );
		header( 'X-Accel-Buffering: no' ); // Disable nginx buffering
		header( 'Connection: keep-alive' );

		// Disable output buffering
		while ( ob_get_level() ) {
			ob_end_flush();
		}

		set_time_limit( 0 );
		ignore_user_abort( true );

		// Send initial connection event
		self::send_sse_event( 'connected', array( 'message' => 'Stream started' ) );

		// Get last post ID from request
		$since = absint( $_GET['since'] ?? 0 );

		// Stream loop
		while ( true ) {
			// Check if client disconnected
			if ( connection_aborted() ) {
				break;
			}

			// Query for new posts
			$new_posts = get_posts(
				array(
					'posts_per_page' => 10,
					'post_status'    => 'publish',
					'orderby'        => 'ID',
					'order'          => 'ASC',
					'post__in'       => range( $since + 1, $since + 1000 ), // Efficient range query
				)
			);

			// Send new posts
			foreach ( $new_posts as $post ) {
				self::send_sse_event( 'post', self::get_post_data( $post ) );
				$since = max( $since, $post->ID );
			}

			// Heartbeat
			self::send_sse_event( 'heartbeat', array( 'timestamp' => gmdate( 'c' ) ) );

			// Sleep before next check
			sleep( 5 );
		}

		exit;
	}

	/**
	 * Send Server-Sent Event
	 */
	private static function send_sse_event( $event, $data ) {
		echo "event: {$event}\n";
		echo 'data: ' . wp_json_encode( $data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE ) . "\n\n";
		flush();
	}

	/**
	 * Encode post as NDJSON line
	 */
	public static function encode_post( $post ) {
		$data = self::get_post_data( $post );
		return wp_json_encode( $data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
	}

	/**
	 * Get post data in standardized format
	 */
	public static function get_post_data( $post ) {
		$data = array(
			'id'             => $post->ID,
			'type'           => 'post',
			'post_type'      => $post->post_type,
			'title'          => get_the_title( $post->ID ),
			'slug'           => $post->post_name,
			'content'        => apply_filters( 'the_content', $post->post_content ),
			'excerpt'        => get_the_excerpt( $post->ID ),
			'status'         => $post->post_status,
			'author'         => array(
				'id'   => $post->post_author,
				'name' => get_the_author_meta( 'display_name', $post->post_author ),
				'url'  => get_author_posts_url( $post->post_author ),
			),
			'published'      => get_the_date( 'c', $post->ID ),
			'modified'       => get_the_modified_date( 'c', $post->ID ),
			'url'            => get_permalink( $post->ID ),
			'categories'     => wp_get_post_categories( $post->ID, array( 'fields' => 'names' ) ),
			'tags'           => wp_get_post_tags( $post->ID, array( 'fields' => 'names' ) ),
		);

		// Add span-specific taxonomies
		if ( in_array( $post->post_type, array( 'post', 'field_note' ), true ) ) {
			$data['emotions'] = wp_get_post_terms( $post->ID, 'emotion', array( 'fields' => 'names' ) );
			$data['colors']   = wp_get_post_terms( $post->ID, 'color', array( 'fields' => 'names' ) );
			$data['motifs']   = wp_get_post_terms( $post->ID, 'motif', array( 'fields' => 'names' ) );
		}

		// Add featured image
		if ( has_post_thumbnail( $post->ID ) ) {
			$image_id = get_post_thumbnail_id( $post->ID );
			$image_meta = wp_get_attachment_metadata( $image_id );

			$data['featured_image'] = array(
				'id'     => $image_id,
				'url'    => get_the_post_thumbnail_url( $post->ID, 'full' ),
				'width'  => $image_meta['width'] ?? null,
				'height' => $image_meta['height'] ?? null,
				'alt'    => get_post_meta( $image_id, '_wp_attachment_image_alt', true ),
			);
		}

		// Add reading time and word count
		$data['word_count']   = str_word_count( wp_strip_all_tags( $post->post_content ) );
		$data['reading_time'] = sinople_get_reading_time( $post->ID );

		// Add custom fields
		$custom_fields = get_post_meta( $post->ID );
		if ( ! empty( $custom_fields ) ) {
			$data['custom_fields'] = array();
			foreach ( $custom_fields as $key => $values ) {
				// Skip private meta
				if ( strpos( $key, '_' ) !== 0 ) {
					$data['custom_fields'][ $key ] = maybe_unserialize( $values[0] );
				}
			}
		}

		// Add IndieWeb fields
		$data['in_reply_to']  = get_post_meta( $post->ID, 'in_reply_to', true );
		$data['like_of']      = get_post_meta( $post->ID, 'like_of', true );
		$data['repost_of']    = get_post_meta( $post->ID, 'repost_of', true );
		$data['bookmark_of']  = get_post_meta( $post->ID, 'bookmark_of', true );

		// Add syndication links
		$syndication = get_post_meta( $post->ID, 'syndication_links', true );
		if ( $syndication ) {
			$data['syndication_links'] = $syndication;
		}

		return apply_filters( 'sinople_ndjson_post_data', $data, $post );
	}
}

// Initialize
Sinople_NDJSON_Feed::init();
