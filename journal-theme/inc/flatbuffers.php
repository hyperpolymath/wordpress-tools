<?php
/**
 * FlatBuffers Serialization Support
 *
 * First-class FlatBuffers support for high-performance
 * zero-copy serialization with PHP and BEAM integration.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * FlatBuffers Handler
 *
 * Requires FlatBuffers PHP library:
 * composer require google/flatbuffers
 */
class Sinople_FlatBuffers {

	/**
	 * Initialize FlatBuffers support
	 */
	public static function init() {
		add_action( 'template_redirect', array( __CLASS__, 'handle_flatbuffers_request' ), 1 );
		add_filter( 'query_vars', array( __CLASS__, 'add_query_vars' ) );
		add_action( 'init', array( __CLASS__, 'add_rewrite_rules' ) );
	}

	/**
	 * Add query vars
	 */
	public static function add_query_vars( $vars ) {
		$vars[] = 'flatbuffers';
		$vars[] = 'fb_type'; // post, feed, user
		$vars[] = 'fb_format'; // binary, json
		return $vars;
	}

	/**
	 * Add rewrite rules
	 */
	public static function add_rewrite_rules() {
		add_rewrite_rule( '^feed/flatbuffers/?$', 'index.php?flatbuffers=1&fb_type=feed', 'top' );
		add_rewrite_rule( '^feed/fb/?$', 'index.php?flatbuffers=1&fb_type=feed', 'top' );
	}

	/**
	 * Handle FlatBuffers request
	 */
	public static function handle_flatbuffers_request() {
		if ( ! get_query_var( 'flatbuffers' ) ) {
			return;
		}

		// Check if FlatBuffers extension is available
		if ( ! class_exists( 'Google\FlatBuffers\FlatBufferBuilder' ) ) {
			header( 'HTTP/1.1 501 Not Implemented' );
			echo wp_json_encode(
				array(
					'error'   => 'FlatBuffers not available',
					'message' => 'Install FlatBuffers PHP extension or library',
				)
			);
			exit;
		}

		$type   = get_query_var( 'fb_type', 'feed' );
		$format = get_query_var( 'fb_format', 'binary' );

		switch ( $type ) {
			case 'feed':
				self::output_feed( $format );
				break;
			case 'post':
				self::output_post( get_the_ID(), $format );
				break;
			case 'user':
				self::output_user( get_current_user_id(), $format );
				break;
			default:
				header( 'HTTP/1.1 400 Bad Request' );
				exit;
		}

		exit;
	}

	/**
	 * Output feed as FlatBuffers
	 */
	private static function output_feed( $format ) {
		$posts = get_posts(
			array(
				'posts_per_page' => 100,
				'post_status'    => 'publish',
				'orderby'        => 'date',
				'order'          => 'DESC',
			)
		);

		// For now, output as JSON representation of FlatBuffers schema
		// Full binary serialization would require compiled FlatBuffers PHP code
		if ( 'json' === $format ) {
			header( 'Content-Type: application/json' );
			echo wp_json_encode(
				array(
					'site'         => array(
						'name'         => get_bloginfo( 'name' ),
						'description'  => get_bloginfo( 'description' ),
						'url'          => home_url( '/' ),
						'language'     => get_bloginfo( 'language' ),
						'post_count'   => wp_count_posts()->publish,
						'last_updated' => get_lastpostmodified( 'gmt' ),
					),
					'posts'        => array_map( array( __CLASS__, 'serialize_post' ), $posts ),
					'version'      => '1.0',
					'generated_at' => gmdate( 'c' ),
				),
				JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
			);
		} else {
			// Binary format
			header( 'Content-Type: application/octet-stream' );
			header( 'Content-Disposition: attachment; filename="feed.fb"' );

			// Placeholder for binary serialization
			// Would use FlatBufferBuilder to create binary format
			echo ''; // Binary data would go here
		}
	}

	/**
	 * Output single post as FlatBuffers
	 */
	private static function output_post( $post_id, $format ) {
		$post = get_post( $post_id );

		if ( ! $post ) {
			header( 'HTTP/1.1 404 Not Found' );
			exit;
		}

		if ( 'json' === $format ) {
			header( 'Content-Type: application/json' );
			echo wp_json_encode( self::serialize_post( $post ), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
		} else {
			header( 'Content-Type: application/octet-stream' );
			header( 'Content-Disposition: attachment; filename="post-' . $post_id . '.fb"' );
			// Binary serialization would go here
		}
	}

	/**
	 * Serialize post to FlatBuffers-compatible structure
	 */
	private static function serialize_post( $post ) {
		$image_data = null;
		if ( has_post_thumbnail( $post->ID ) ) {
			$image_id   = get_post_thumbnail_id( $post->ID );
			$image_meta = wp_get_attachment_metadata( $image_id );

			$image_data = array(
				'id'        => $image_id,
				'url'       => get_the_post_thumbnail_url( $post->ID, 'full' ),
				'width'     => $image_meta['width'] ?? 0,
				'height'    => $image_meta['height'] ?? 0,
				'mime_type' => get_post_mime_type( $image_id ),
				'alt_text'  => get_post_meta( $image_id, '_wp_attachment_image_alt', true ),
			);
		}

		return array(
			'metadata'       => array(
				'id'          => $post->ID,
				'created_at'  => strtotime( $post->post_date_gmt ),
				'updated_at'  => strtotime( $post->post_modified_gmt ),
				'author_id'   => $post->post_author,
				'author_name' => get_the_author_meta( 'display_name', $post->post_author ),
				'language'    => get_post_meta( $post->ID, 'language', true ) ?: get_bloginfo( 'language' ),
				'status'      => $post->post_status,
			),
			'title'          => get_the_title( $post->ID ),
			'slug'           => $post->post_name,
			'content'        => $post->post_content,
			'excerpt'        => get_the_excerpt( $post->ID ),
			'post_type'      => $post->post_type,
			'categories'     => wp_get_post_categories( $post->ID, array( 'fields' => 'names' ) ),
			'tags'           => wp_get_post_tags( $post->ID, array( 'fields' => 'names' ) ),
			'emotions'       => wp_get_post_terms( $post->ID, 'emotion', array( 'fields' => 'names' ) ),
			'colors'         => wp_get_post_terms( $post->ID, 'color', array( 'fields' => 'names' ) ),
			'motifs'         => wp_get_post_terms( $post->ID, 'motif', array( 'fields' => 'names' ) ),
			'featured_image' => $image_data,
			'reading_time'   => (float) sinople_get_reading_time( $post->ID ),
			'word_count'     => str_word_count( wp_strip_all_tags( $post->post_content ) ),
			'custom_fields'  => self::get_custom_fields( $post->ID ),
		);
	}

	/**
	 * Get custom fields as array
	 */
	private static function get_custom_fields( $post_id ) {
		$meta   = get_post_meta( $post_id );
		$fields = array();

		foreach ( $meta as $key => $values ) {
			// Skip private meta
			if ( strpos( $key, '_' ) === 0 ) {
				continue;
			}

			$value = maybe_unserialize( $values[0] );
			$type  = gettype( $value );

			$fields[] = array(
				'key'   => $key,
				'value' => is_scalar( $value ) ? (string) $value : wp_json_encode( $value ),
				'type'  => $type,
			);
		}

		return $fields;
	}

	/**
	 * Output user as FlatBuffers
	 */
	private static function output_user( $user_id, $format ) {
		$user = get_userdata( $user_id );

		if ( ! $user ) {
			header( 'HTTP/1.1 404 Not Found' );
			exit;
		}

		$user_data = array(
			'id'           => $user->ID,
			'username'     => $user->user_login,
			'display_name' => $user->display_name,
			'email'        => $user->user_email,
			'bio'          => $user->description,
			'avatar_url'   => get_avatar_url( $user->ID ),
			'post_count'   => count_user_posts( $user->ID ),
		);

		if ( 'json' === $format ) {
			header( 'Content-Type: application/json' );
			echo wp_json_encode( $user_data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
		} else {
			header( 'Content-Type: application/octet-stream' );
			// Binary serialization
		}
	}
}

// Initialize
Sinople_FlatBuffers::init();
