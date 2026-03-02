<?php
/**
 * Cap'n Proto Serialization Support
 *
 * First-class Cap'n Proto support for ultra-fast
 * zero-copy serialization with RPC capabilities.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Cap'n Proto Handler
 *
 * Requires Cap'n Proto PHP extension or capnpc compiler:
 * https://capnproto.org/
 */
class Sinople_CapnProto {

	/**
	 * Initialize Cap'n Proto support
	 */
	public static function init() {
		add_action( 'template_redirect', array( __CLASS__, 'handle_capnproto_request' ), 1 );
		add_filter( 'query_vars', array( __CLASS__, 'add_query_vars' ) );
		add_action( 'init', array( __CLASS__, 'add_rewrite_rules' ) );

		// Add CORS headers for Cap'n Proto RPC
		add_action( 'send_headers', array( __CLASS__, 'add_capnproto_headers' ) );
	}

	/**
	 * Add query vars
	 */
	public static function add_query_vars( $vars ) {
		$vars[] = 'capnproto';
		$vars[] = 'cp_type'; // post, feed, user, rpc
		$vars[] = 'cp_format'; // binary, json, packed
		return $vars;
	}

	/**
	 * Add rewrite rules
	 */
	public static function add_rewrite_rules() {
		add_rewrite_rule( '^feed/capnproto/?$', 'index.php?capnproto=1&cp_type=feed', 'top' );
		add_rewrite_rule( '^feed/capnp/?$', 'index.php?capnproto=1&cp_type=feed', 'top' );
		add_rewrite_rule( '^rpc/capnp/?$', 'index.php?capnproto=1&cp_type=rpc', 'top' );
	}

	/**
	 * Add Cap'n Proto headers
	 */
	public static function add_capnproto_headers() {
		if ( get_query_var( 'capnproto' ) ) {
			header( 'Access-Control-Allow-Origin: *' );
			header( 'Access-Control-Allow-Methods: GET, POST, OPTIONS' );
			header( 'Access-Control-Allow-Headers: Content-Type' );
		}
	}

	/**
	 * Handle Cap'n Proto request
	 */
	public static function handle_capnproto_request() {
		if ( ! get_query_var( 'capnproto' ) ) {
			return;
		}

		$type   = get_query_var( 'cp_type', 'feed' );
		$format = get_query_var( 'cp_format', 'binary' );

		// Handle OPTIONS for CORS
		if ( $_SERVER['REQUEST_METHOD'] === 'OPTIONS' ) {
			http_response_code( 204 );
			exit;
		}

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
			case 'rpc':
				self::handle_rpc();
				break;
			default:
				header( 'HTTP/1.1 400 Bad Request' );
				echo wp_json_encode( array( 'error' => 'Invalid type' ) );
				exit;
		}

		exit;
	}

	/**
	 * Output feed as Cap'n Proto
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

		$feed_data = array(
			'site'        => array(
				'name'        => get_bloginfo( 'name' ),
				'description' => get_bloginfo( 'description' ),
				'url'         => home_url( '/' ),
				'language'    => get_bloginfo( 'language' ),
				'timezone'    => wp_timezone_string(),
				'postCount'   => wp_count_posts()->publish,
				'pageCount'   => wp_count_posts( 'page' )->publish,
				'lastUpdated' => strtotime( get_lastpostmodified( 'gmt' ) ),
			),
			'posts'       => array_map( array( __CLASS__, 'serialize_post' ), $posts ),
			'version'     => '1.0',
			'generatedAt' => time(),
		);

		if ( 'json' === $format ) {
			// JSON representation of Cap'n Proto schema
			header( 'Content-Type: application/json' );
			echo wp_json_encode( $feed_data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
		} elseif ( 'packed' === $format ) {
			// Packed binary format (more compact)
			header( 'Content-Type: application/x-capnproto-packed' );
			header( 'Content-Disposition: attachment; filename="feed.capnp"' );
			// Would use Cap'n Proto packer
			echo self::encode_capnproto_packed( $feed_data );
		} else {
			// Standard binary format
			header( 'Content-Type: application/x-capnproto' );
			header( 'Content-Disposition: attachment; filename="feed.capnp"' );
			echo self::encode_capnproto( $feed_data );
		}
	}

	/**
	 * Output single post
	 */
	private static function output_post( $post_id, $format ) {
		$post = get_post( $post_id );

		if ( ! $post ) {
			header( 'HTTP/1.1 404 Not Found' );
			echo wp_json_encode( array( 'error' => 'Post not found' ) );
			return;
		}

		$post_data = self::serialize_post( $post );

		if ( 'json' === $format ) {
			header( 'Content-Type: application/json' );
			echo wp_json_encode( $post_data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
		} else {
			header( 'Content-Type: application/x-capnproto' );
			header( 'Content-Disposition: attachment; filename="post-' . $post_id . '.capnp"' );
			echo self::encode_capnproto( $post_data );
		}
	}

	/**
	 * Serialize post to Cap'n Proto structure
	 */
	private static function serialize_post( $post ) {
		$image = null;
		if ( has_post_thumbnail( $post->ID ) ) {
			$image_id   = get_post_thumbnail_id( $post->ID );
			$image_meta = wp_get_attachment_metadata( $image_id );

			$image = array(
				'id'       => $image_id,
				'url'      => get_the_post_thumbnail_url( $post->ID, 'full' ),
				'width'    => $image_meta['width'] ?? 0,
				'height'   => $image_meta['height'] ?? 0,
				'mimeType' => get_post_mime_type( $image_id ),
				'altText'  => get_post_meta( $image_id, '_wp_attachment_image_alt', true ),
				'sizes'    => array(),
			);
		}

		$syndication_links = get_post_meta( $post->ID, 'syndication_links', true );
		if ( ! is_array( $syndication_links ) ) {
			$syndication_links = array();
		}

		return array(
			'metadata'        => array(
				'id'         => $post->ID,
				'createdAt'  => strtotime( $post->post_date_gmt ),
				'updatedAt'  => strtotime( $post->post_modified_gmt ),
				'authorId'   => $post->post_author,
				'authorName' => get_the_author_meta( 'display_name', $post->post_author ),
				'language'   => get_post_meta( $post->ID, 'language', true ) ?: get_bloginfo( 'language' ),
				'status'     => $post->post_status,
			),
			'title'           => get_the_title( $post->ID ),
			'slug'            => $post->post_name,
			'content'         => $post->post_content,
			'excerpt'         => get_the_excerpt( $post->ID ),
			'postType'        => $post->post_type,
			'categories'      => wp_get_post_categories( $post->ID, array( 'fields' => 'names' ) ),
			'tags'            => wp_get_post_tags( $post->ID, array( 'fields' => 'names' ) ),
			'emotions'        => wp_get_post_terms( $post->ID, 'emotion', array( 'fields' => 'names' ) ),
			'colors'          => wp_get_post_terms( $post->ID, 'color', array( 'fields' => 'names' ) ),
			'motifs'          => wp_get_post_terms( $post->ID, 'motif', array( 'fields' => 'names' ) ),
			'featuredImage'   => $image,
			'readingTime'     => (float) sinople_get_reading_time( $post->ID ),
			'wordCount'       => str_word_count( wp_strip_all_tags( $post->post_content ) ),
			'customFields'    => self::get_custom_fields( $post->ID ),
			'inReplyTo'       => get_post_meta( $post->ID, 'in_reply_to', true ) ?: '',
			'likeOf'          => get_post_meta( $post->ID, 'like_of', true ) ?: '',
			'repostOf'        => get_post_meta( $post->ID, 'repost_of', true ) ?: '',
			'bookmarkOf'      => get_post_meta( $post->ID, 'bookmark_of', true ) ?: '',
			'syndicationLinks' => $syndication_links,
		);
	}

	/**
	 * Get custom fields
	 */
	private static function get_custom_fields( $post_id ) {
		$meta   = get_post_meta( $post_id );
		$fields = array();

		foreach ( $meta as $key => $values ) {
			if ( strpos( $key, '_' ) === 0 ) {
				continue;
			}

			$value = maybe_unserialize( $values[0] );
			$type  = is_int( $value ) ? 'int' : ( is_float( $value ) ? 'float' : ( is_bool( $value ) ? 'bool' : 'string' ) );

			$fields[] = array(
				'key'   => $key,
				'value' => is_scalar( $value ) ? (string) $value : wp_json_encode( $value ),
				'type'  => $type,
			);
		}

		return $fields;
	}

	/**
	 * Handle RPC requests
	 */
	private static function handle_rpc() {
		// Read RPC request from POST body
		$request_body = file_get_contents( 'php://input' );

		if ( empty( $request_body ) ) {
			header( 'HTTP/1.1 400 Bad Request' );
			echo wp_json_encode( array( 'error' => 'Empty request' ) );
			return;
		}

		// Decode RPC call (simplified - would use Cap'n Proto RPC protocol)
		$request = json_decode( $request_body, true );

		if ( ! $request || ! isset( $request['method'] ) ) {
			header( 'HTTP/1.1 400 Bad Request' );
			echo wp_json_encode( array( 'error' => 'Invalid RPC request' ) );
			return;
		}

		// Handle RPC methods
		switch ( $request['method'] ) {
			case 'getPost':
				$post_id = $request['params']['id'] ?? 0;
				$post    = get_post( $post_id );

				if ( $post ) {
					$response = array(
						'result' => self::serialize_post( $post ),
					);
				} else {
					$response = array(
						'error' => array(
							'code'    => 404,
							'message' => 'Post not found',
						),
					);
				}
				break;

			case 'streamPosts':
				// Would implement streaming response
				$response = array(
					'error' => array(
						'code'    => 501,
						'message' => 'Streaming not yet implemented',
					),
				);
				break;

			default:
				$response = array(
					'error' => array(
						'code'    => 400,
						'message' => 'Unknown method',
					),
				);
		}

		header( 'Content-Type: application/json' );
		echo wp_json_encode( $response, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
	}

	/**
	 * Encode data as Cap'n Proto binary
	 *
	 * Placeholder - would use actual Cap'n Proto compiler/library
	 */
	private static function encode_capnproto( $data ) {
		// In production, would use capnpc-generated PHP code
		// For now, return JSON as placeholder
		return wp_json_encode( $data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
	}

	/**
	 * Encode as packed Cap'n Proto binary (more compact)
	 */
	private static function encode_capnproto_packed( $data ) {
		// Would use Cap'n Proto packing algorithm
		return self::encode_capnproto( $data );
	}

	/**
	 * Output user data
	 */
	private static function output_user( $user_id, $format ) {
		$user = get_userdata( $user_id );

		if ( ! $user ) {
			header( 'HTTP/1.1 404 Not Found' );
			echo wp_json_encode( array( 'error' => 'User not found' ) );
			return;
		}

		$user_data = array(
			'id'          => $user->ID,
			'username'    => $user->user_login,
			'displayName' => $user->display_name,
			'email'       => $user->user_email,
			'bio'         => $user->description,
			'avatarUrl'   => get_avatar_url( $user->ID ),
			'socialLinks' => array(), // Would get from user meta
			'postCount'   => count_user_posts( $user->ID ),
		);

		if ( 'json' === $format ) {
			header( 'Content-Type: application/json' );
			echo wp_json_encode( $user_data, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE );
		} else {
			header( 'Content-Type: application/x-capnproto' );
			echo self::encode_capnproto( $user_data );
		}
	}
}

// Initialize
Sinople_CapnProto::init();
