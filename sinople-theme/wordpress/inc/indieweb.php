<?php
/**
 * IndieWeb Integration for Sinople Theme
 *
 * Implements Webmention and Micropub endpoints for IndieWeb Level 4 compliance.
 *
 * SECURITY: Uses PhpAegis\Validator for proper URL validation.
 * Uses WordPress sanitization functions for all input.
 *
 * @package Sinople
 * @since 1.0.0
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

use PhpAegis\Validator;
use PhpAegis\Sanitizer;

/**
 * Add IndieWeb discovery links to head
 */
function sinople_indieweb_discovery(): void {
    $webmention_endpoint = rest_url( 'sinople/v1/webmention' );
    $micropub_endpoint   = rest_url( 'sinople/v1/micropub' );

    echo '<link rel="webmention" href="' . esc_url( $webmention_endpoint ) . '">' . "\n";
    echo '<link rel="micropub" href="' . esc_url( $micropub_endpoint ) . '">' . "\n";
    echo '<link rel="authorization_endpoint" href="https://indieauth.com/auth">' . "\n";
    echo '<link rel="token_endpoint" href="https://tokens.indieauth.com/token">' . "\n";
}
add_action( 'wp_head', 'sinople_indieweb_discovery' );

/**
 * Register IndieWeb REST API endpoints
 */
function sinople_register_indieweb_api(): void {
    // Webmention endpoint
    register_rest_route( 'sinople/v1', '/webmention', array(
        'methods'             => 'POST',
        'callback'            => 'sinople_webmention_endpoint',
        'permission_callback' => '__return_true',
        'args'                => array(
            'source' => array(
                'required'          => true,
                'validate_callback' => 'sinople_validate_url_param',
                'sanitize_callback' => 'esc_url_raw',
            ),
            'target' => array(
                'required'          => true,
                'validate_callback' => 'sinople_validate_url_param',
                'sanitize_callback' => 'esc_url_raw',
            ),
        ),
    ) );

    // Micropub endpoint
    register_rest_route( 'sinople/v1', '/micropub', array(
        'methods'             => array( 'GET', 'POST' ),
        'callback'            => 'sinople_micropub_endpoint',
        'permission_callback' => 'sinople_micropub_permission',
    ) );
}
add_action( 'rest_api_init', 'sinople_register_indieweb_api' );

/**
 * Validate URL parameter for REST API.
 *
 * @param mixed $param The parameter value.
 * @param WP_REST_Request $request The request object.
 * @param string $key The parameter key.
 * @return bool Whether the parameter is valid.
 */
function sinople_validate_url_param( $param, WP_REST_Request $request, string $key ): bool {
    if ( ! is_string( $param ) ) {
        return false;
    }

    // Use PhpAegis Validator for proper URL validation
    return Validator::url( $param );
}

/**
 * Check if a URL belongs to this site using proper host comparison.
 *
 * SECURITY: Uses parse_url() for proper host extraction instead of strpos().
 * This prevents bypass attacks like "http://evil.com?http://your-site.com".
 *
 * @param string $url The URL to check.
 * @return bool Whether the URL is on this site.
 */
function sinople_is_local_url( string $url ): bool {
    $home_url = home_url();

    // Parse both URLs
    $url_parts = parse_url( $url );
    $home_parts = parse_url( $home_url );

    // Must have valid host
    if ( empty( $url_parts['host'] ) || empty( $home_parts['host'] ) ) {
        return false;
    }

    // Compare hosts (case-insensitive)
    if ( strtolower( $url_parts['host'] ) !== strtolower( $home_parts['host'] ) ) {
        return false;
    }

    // Compare schemes if both present
    if ( isset( $url_parts['scheme'] ) && isset( $home_parts['scheme'] ) ) {
        if ( strtolower( $url_parts['scheme'] ) !== strtolower( $home_parts['scheme'] ) ) {
            // Allow upgrade from http to https
            if ( $home_parts['scheme'] === 'https' && $url_parts['scheme'] === 'http' ) {
                return false; // Don't accept http targets on https sites
            }
        }
    }

    // Compare ports if specified
    $url_port = $url_parts['port'] ?? ( $url_parts['scheme'] === 'https' ? 443 : 80 );
    $home_port = $home_parts['port'] ?? ( $home_parts['scheme'] === 'https' ? 443 : 80 );

    return $url_port === $home_port;
}

/**
 * Webmention endpoint handler.
 *
 * SECURITY: Uses proper URL validation and host comparison.
 *
 * @param WP_REST_Request $request The REST request object.
 * @return WP_REST_Response|WP_Error Response or error.
 */
function sinople_webmention_endpoint( WP_REST_Request $request ) {
    $source = $request->get_param( 'source' );
    $target = $request->get_param( 'target' );

    // Parameters are already validated by REST API args
    // But double-check for defense in depth
    if ( ! Validator::url( $source ) || ! Validator::url( $target ) ) {
        return new WP_Error( 'invalid_request', 'Invalid source or target URL', array( 'status' => 400 ) );
    }

    // Verify target is on this site using proper host comparison
    if ( ! sinople_is_local_url( $target ) ) {
        return new WP_Error( 'invalid_target', 'Target not on this site', array( 'status' => 400 ) );
    }

    // Rate limiting: Check for recent webmentions from same source
    $recent = get_posts( array(
        'post_type'      => 'sinople_webmention',
        'post_status'    => 'any',
        'posts_per_page' => 1,
        'meta_query'     => array(
            array(
                'key'   => '_sinople_wm_source',
                'value' => esc_url_raw( $source ),
            ),
        ),
        'date_query'     => array(
            array(
                'after' => '1 minute ago',
            ),
        ),
    ) );

    if ( ! empty( $recent ) ) {
        return new WP_Error( 'rate_limited', 'Please wait before sending another webmention', array( 'status' => 429 ) );
    }

    // Queue webmention for async processing
    $webmention_id = wp_insert_post( array(
        'post_type'   => 'sinople_webmention',
        'post_status' => 'pending',
        'post_title'  => sanitize_text_field( wp_parse_url( $source, PHP_URL_HOST ) ?: 'Unknown' ),
        'meta_input'  => array(
            '_sinople_wm_source' => esc_url_raw( $source ),
            '_sinople_wm_target' => esc_url_raw( $target ),
            '_sinople_wm_received' => current_time( 'mysql' ),
        ),
    ) );

    if ( is_wp_error( $webmention_id ) ) {
        return new WP_Error( 'storage_error', 'Failed to store webmention', array( 'status' => 500 ) );
    }

    return new WP_REST_Response( array(
        'status'  => 'accepted',
        'message' => 'Webmention accepted for processing',
    ), 202 );
}

/**
 * Micropub permission callback.
 *
 * @param WP_REST_Request $request The REST request object.
 * @return bool|WP_Error Whether the request is authorized.
 */
function sinople_micropub_permission( WP_REST_Request $request ) {
    // GET requests for config don't require auth
    if ( $request->get_method() === 'GET' ) {
        return true;
    }

    $auth_header = $request->get_header( 'Authorization' );

    if ( empty( $auth_header ) ) {
        return new WP_Error( 'unauthorized', 'Authorization required', array( 'status' => 401 ) );
    }

    // Extract Bearer token
    if ( ! preg_match( '/^Bearer\s+(.+)$/i', $auth_header, $matches ) ) {
        return new WP_Error( 'invalid_token', 'Invalid authorization header format', array( 'status' => 401 ) );
    }

    $token = $matches[1];

    // Verify token with IndieAuth token endpoint
    // https://indieweb.org/IndieAuth
    $token_endpoint = apply_filters( 'sinople_indieauth_token_endpoint', 'https://tokens.indieauth.com/token' );

    $response = wp_remote_get( $token_endpoint, array(
        'headers' => array(
            'Authorization' => 'Bearer ' . $token,
            'Accept'        => 'application/json',
        ),
        'timeout' => 10,
    ) );

    if ( is_wp_error( $response ) ) {
        return new WP_Error(
            'token_verification_failed',
            'Could not verify token: ' . $response->get_error_message(),
            array( 'status' => 502 )
        );
    }

    $status_code = wp_remote_retrieve_response_code( $response );
    if ( 200 !== $status_code ) {
        return new WP_Error(
            'invalid_token',
            'Token verification failed',
            array( 'status' => 401 )
        );
    }

    $body = wp_remote_retrieve_body( $response );
    $token_data = json_decode( $body, true );

    if ( ! $token_data || ! isset( $token_data['me'] ) ) {
        return new WP_Error(
            'invalid_token_response',
            'Invalid token endpoint response',
            array( 'status' => 401 )
        );
    }

    // Verify the token is for this site
    $site_url  = trailingslashit( home_url() );
    $token_url = trailingslashit( $token_data['me'] );

    if ( strcasecmp( $site_url, $token_url ) !== 0 ) {
        return new WP_Error(
            'token_site_mismatch',
            'Token is not valid for this site',
            array( 'status' => 403 )
        );
    }

    // Check required scopes for Micropub
    $scopes = isset( $token_data['scope'] ) ? explode( ' ', $token_data['scope'] ) : array();
    $required_scopes = array( 'create' );

    // Allow write to substitute for create
    if ( in_array( 'write', $scopes, true ) ) {
        $scopes[] = 'create';
        $scopes[] = 'update';
        $scopes[] = 'delete';
    }

    foreach ( $required_scopes as $required ) {
        if ( ! in_array( $required, $scopes, true ) ) {
            return new WP_Error(
                'insufficient_scope',
                'Token lacks required scope: ' . $required,
                array( 'status' => 403 )
            );
        }
    }

    // Store token data for use in the request
    $request = func_num_args() > 0 ? func_get_arg( 0 ) : null;
    if ( $request instanceof WP_REST_Request ) {
        $request->set_param( '_indieauth_me', $token_data['me'] );
        $request->set_param( '_indieauth_scope', $scopes );
    }

    return true;
}

/**
 * Micropub endpoint handler.
 *
 * SECURITY: All input is properly sanitized before use.
 *
 * @param WP_REST_Request $request The REST request object.
 * @return WP_REST_Response|WP_Error Response or error.
 */
function sinople_micropub_endpoint( WP_REST_Request $request ) {
    $method = $request->get_method();

    if ( $method === 'GET' ) {
        // Configuration query
        $q = sanitize_text_field( $request->get_param( 'q' ) ?? '' );

        if ( $q === 'config' ) {
            return new WP_REST_Response( array(
                'media-endpoint' => rest_url( 'sinople/v1/media' ),
            ) );
        }

        if ( $q === 'syndicate-to' ) {
            return new WP_REST_Response( array(
                'syndicate-to' => array(),
            ) );
        }

        return new WP_REST_Response( array(), 200 );
    }

    if ( $method === 'POST' ) {
        // Create post from Micropub request
        $content_type = $request->get_content_type();
        $security = sinople_security();

        if ( isset( $content_type['value'] ) && $content_type['value'] === 'application/json' ) {
            $data = $request->get_json_params();
        } else {
            $data = $request->get_body_params();
        }

        // Validate required data
        if ( empty( $data ) || ! is_array( $data ) ) {
            return new WP_Error( 'invalid_request', 'No valid data provided', array( 'status' => 400 ) );
        }

        // Sanitize input data
        $name = isset( $data['name'] ) ? sanitize_text_field( $data['name'] ) : '';
        $content = isset( $data['content'] ) ? wp_kses_post( $data['content'] ) : '';

        // Validate content exists
        if ( empty( $name ) && empty( $content ) ) {
            return new WP_Error( 'invalid_request', 'Name or content required', array( 'status' => 400 ) );
        }

        // Parse h-entry microformat
        $post_data = array(
            'post_type'    => 'post',
            'post_status'  => 'publish',
            'post_title'   => $name,
            'post_content' => $content,
        );

        // Handle category/tags if provided
        if ( isset( $data['category'] ) && is_array( $data['category'] ) ) {
            $post_data['tags_input'] = array_map( 'sanitize_text_field', $data['category'] );
        }

        $post_id = wp_insert_post( $post_data, true );

        if ( is_wp_error( $post_id ) ) {
            return new WP_Error( 'create_failed', 'Failed to create post: ' . $post_id->get_error_message(), array( 'status' => 500 ) );
        }

        $location = get_permalink( $post_id );

        return new WP_REST_Response( array( 'url' => $location ), 201, array(
            'Location' => $location,
        ) );
    }

    return new WP_Error( 'method_not_allowed', 'Method not allowed', array( 'status' => 405 ) );
}

/**
 * Register webmention custom post type.
 */
function sinople_register_webmention_cpt(): void {
    register_post_type( 'sinople_webmention', array(
        'labels'       => array(
            'name'          => __( 'Webmentions', 'sinople' ),
            'singular_name' => __( 'Webmention', 'sinople' ),
        ),
        'public'       => false,
        'show_ui'      => true,
        'show_in_menu' => 'edit.php',
        'supports'     => array( 'title' ),
        'capabilities' => array(
            'create_posts' => 'do_not_allow',
        ),
        'map_meta_cap' => true,
    ) );
}
add_action( 'init', 'sinople_register_webmention_cpt' );
