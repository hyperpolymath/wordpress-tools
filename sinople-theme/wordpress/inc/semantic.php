<?php
/**
 * Semantic Web Integration for Sinople Theme
 *
 * Handles RDF/OWL processing, semantic graph generation,
 * and REST API endpoints for semantic data.
 *
 * SECURITY: Uses PhpAegis\TurtleEscaper for W3C-compliant RDF Turtle escaping.
 * This prevents RDF injection attacks in semantic web output.
 *
 * @package Sinople
 * @since 1.0.0
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

use PhpAegis\TurtleEscaper;
use PhpAegis\Validator;

/**
 * Register REST API endpoints for semantic data
 */
function sinople_register_semantic_api(): void {
    // Semantic graph endpoint
    register_rest_route( 'sinople/v1', '/semantic-graph', array(
        'methods'             => 'GET',
        'callback'            => 'sinople_get_semantic_graph',
        'permission_callback' => '__return_true',
    ) );

    // Construct RDF endpoint
    register_rest_route( 'sinople/v1', '/constructs/(?P<id>\d+)/rdf', array(
        'methods'             => 'GET',
        'callback'            => 'sinople_get_construct_rdf',
        'permission_callback' => '__return_true',
        'args'                => array(
            'id' => array(
                'validate_callback' => function( $param ): bool {
                    return is_numeric( $param ) && intval( $param ) > 0;
                },
                'sanitize_callback' => 'absint',
            ),
        ),
    ) );

    // Full ontology export
    register_rest_route( 'sinople/v1', '/ontology', array(
        'methods'             => 'GET',
        'callback'            => 'sinople_export_ontology',
        'permission_callback' => '__return_true',
    ) );
}
add_action( 'rest_api_init', 'sinople_register_semantic_api' );

/**
 * Get semantic graph data for visualization
 *
 * @param WP_REST_Request $request The REST request object.
 * @return WP_REST_Response Graph data with nodes and edges.
 */
function sinople_get_semantic_graph( WP_REST_Request $request ): WP_REST_Response {
    $constructs = get_posts( array(
        'post_type'      => 'sinople_construct',
        'posts_per_page' => -1,
        'post_status'    => 'publish',
    ) );

    $entanglements = get_posts( array(
        'post_type'      => 'sinople_entanglement',
        'posts_per_page' => -1,
        'post_status'    => 'publish',
    ) );

    $nodes = array();
    $edges = array();

    // Build nodes
    foreach ( $constructs as $construct ) {
        $nodes[] = array(
            'id'    => $construct->ID,
            'label' => $construct->post_title,
            'type'  => 'construct',
            'iri'   => get_post_meta( $construct->ID, '_sinople_rdf_iri', true ),
        );
    }

    // Build edges
    foreach ( $entanglements as $entanglement ) {
        $source = get_post_meta( $entanglement->ID, '_sinople_source', true );
        $target = get_post_meta( $entanglement->ID, '_sinople_target', true );
        $type   = get_post_meta( $entanglement->ID, '_sinople_relationship_type', true );

        if ( $source && $target ) {
            $edges[] = array(
                'source' => intval( $source ),
                'target' => intval( $target ),
                'label'  => $type ?: 'related',
                'id'     => $entanglement->ID,
            );
        }
    }

    return new WP_REST_Response( array(
        'nodes' => $nodes,
        'edges' => $edges,
    ), 200 );
}

/**
 * Validate and escape an IRI for Turtle output.
 *
 * @param string $iri The IRI to validate.
 * @return string|null The escaped IRI or null if invalid.
 */
function sinople_escape_iri( string $iri ): ?string {
    // Validate URL structure
    if ( ! Validator::url( $iri ) ) {
        return null;
    }

    try {
        return TurtleEscaper::iri( $iri );
    } catch ( \InvalidArgumentException $e ) {
        return null;
    }
}

/**
 * Get RDF representation of a construct
 *
 * SECURITY: All string values are escaped using TurtleEscaper::string()
 * and all IRIs are validated and escaped using TurtleEscaper::iri().
 * This prevents RDF injection attacks.
 *
 * @param WP_REST_Request $request The REST request object.
 * @return WP_REST_Response|WP_Error Turtle RDF or error.
 */
function sinople_get_construct_rdf( WP_REST_Request $request ) {
    $post_id = absint( $request['id'] );
    $post    = get_post( $post_id );

    if ( ! $post || $post->post_type !== 'sinople_construct' ) {
        return new WP_Error( 'not_found', 'Construct not found', array( 'status' => 404 ) );
    }

    // Get and validate IRI
    $stored_iri = get_post_meta( $post_id, '_sinople_rdf_iri', true );
    $iri = $stored_iri ?: home_url( "/constructs/{$post->post_name}" );

    $escaped_iri = sinople_escape_iri( $iri );
    if ( ! $escaped_iri ) {
        return new WP_Error( 'invalid_iri', 'Invalid IRI for construct', array( 'status' => 500 ) );
    }

    $gloss = get_post_meta( $post_id, '_sinople_gloss', true );
    $type  = get_post_meta( $post_id, '_sinople_construct_type', true );

    // Build Turtle format RDF with proper escaping
    $ttl = "@prefix sn: <http://sinople.org/ontology#> .\n";
    $ttl .= "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n";
    $ttl .= "@prefix dc: <http://purl.org/dc/elements/1.1/> .\n\n";

    // Subject with escaped IRI
    $ttl .= "<{$escaped_iri}> a sn:Construct ;\n";

    // Label with proper Turtle string escaping
    $ttl .= "    rdfs:label " . TurtleEscaper::literal( $post->post_title, 'en' ) . " ;\n";

    // Optional comment (excerpt)
    if ( $post->post_excerpt ) {
        $ttl .= "    rdfs:comment " . TurtleEscaper::literal( $post->post_excerpt, 'en' ) . " ;\n";
    }

    // Optional gloss
    if ( $gloss ) {
        $ttl .= "    sn:hasGloss " . TurtleEscaper::literal( $gloss, 'en' ) . " ;\n";
    }

    // Optional construct type (validated against allowed values)
    $allowed_types = array( 'philosophical', 'scientific', 'mathematical', 'linguistic', 'social', 'other' );
    if ( $type && in_array( $type, $allowed_types, true ) ) {
        $ttl .= "    sn:constructType " . TurtleEscaper::literal( $type ) . " ;\n";
    }

    // Identifier with escaped IRI
    $ttl .= "    dc:identifier <{$escaped_iri}> .\n";

    return new WP_REST_Response( $ttl, 200, array(
        'Content-Type' => 'text/turtle; charset=UTF-8',
    ) );
}

/**
 * Export full ontology in Turtle format
 *
 * SECURITY: All values are properly escaped for Turtle format.
 *
 * @param WP_REST_Request $request The REST request object.
 * @return WP_REST_Response Turtle RDF ontology export.
 */
function sinople_export_ontology( WP_REST_Request $request ): WP_REST_Response {
    $ttl = "@prefix sn: <http://sinople.org/ontology#> .\n";
    $ttl .= "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .\n";
    $ttl .= "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .\n";
    $ttl .= "@prefix dc: <http://purl.org/dc/elements/1.1/> .\n";
    $ttl .= "@prefix owl: <http://www.w3.org/2002/07/owl#> .\n\n";

    // Export constructs
    $constructs = get_posts( array(
        'post_type'      => 'sinople_construct',
        'posts_per_page' => -1,
        'post_status'    => 'publish',
    ) );

    // Get security helper for proper Turtle escaping
    $security = sinople_security();

    foreach ( $constructs as $construct ) {
        $stored_iri = get_post_meta( $construct->ID, '_sinople_rdf_iri', true );
        $iri = $stored_iri ?: home_url( "/constructs/{$construct->post_name}" );

        $escaped_iri = sinople_escape_iri( $iri );
        if ( ! $escaped_iri ) {
            // Skip constructs with invalid IRIs, log for debugging
            if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
                error_log( "Sinople: Skipping construct {$construct->ID} due to invalid IRI: {$iri}" );
            }
            continue;
        }

        $ttl .= "<{$escaped_iri}> a sn:Construct ;\n";
        $ttl .= "    rdfs:label " . TurtleEscaper::literal( $construct->post_title, 'en' ) . " .\n\n";
    }

    return new WP_REST_Response( $ttl, 200, array(
        'Content-Type' => 'text/turtle; charset=UTF-8',
    ) );
}

/**
 * Add RDF link to construct head
 */
function sinople_add_rdf_link(): void {
    if ( is_singular( 'sinople_construct' ) ) {
        $post_id = get_the_ID();
        if ( $post_id ) {
            $api_url = rest_url( "sinople/v1/constructs/{$post_id}/rdf" );
            echo '<link rel="alternate" type="text/turtle" href="' . esc_url( $api_url ) . '" title="RDF Representation">' . "\n";
        }
    }
}
add_action( 'wp_head', 'sinople_add_rdf_link' );
