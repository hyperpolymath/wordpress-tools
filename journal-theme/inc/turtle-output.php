<?php
/**
 * RDF Turtle Output Support
 *
 * Generates W3C-compliant RDF Turtle output for semantic web integration.
 * Uses php-aegis TurtleEscaper for safe escaping.
 *
 * @package Sinople
 * @since 0.2.0
 * @see https://www.w3.org/TR/turtle/
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Check if TurtleEscaper is available
 *
 * @return bool True if TurtleEscaper class is loaded
 */
function sinople_turtle_available(): bool {
	return class_exists( '\\PhpAegis\\TurtleEscaper' );
}

/**
 * Escape a string for Turtle literal context.
 *
 * @param string $input The string to escape.
 * @return string Escaped string safe for Turtle literals.
 */
function sinople_turtle_escape_string( string $input ): string {
	if ( sinople_turtle_available() ) {
		return \PhpAegis\TurtleEscaper::string( $input );
	}
	// Manual fallback - basic escaping
	$replacements = array(
		'\\'  => '\\\\',
		'"'   => '\\"',
		"'"   => "\\'",
		"\t"  => '\\t',
		"\n"  => '\\n',
		"\r"  => '\\r',
	);
	return str_replace( array_keys( $replacements ), array_values( $replacements ), $input );
}

/**
 * Escape an IRI for Turtle <...> notation.
 *
 * @param string $uri The URI/IRI to escape.
 * @return string Escaped IRI safe for Turtle.
 * @throws InvalidArgumentException If the URI is malformed.
 */
function sinople_turtle_escape_iri( string $uri ): string {
	if ( sinople_turtle_available() ) {
		return \PhpAegis\TurtleEscaper::iri( $uri );
	}
	// Manual fallback - URL encode dangerous characters
	$dangerous = array(
		'<'  => '%3C',
		'>'  => '%3E',
		'"'  => '%22',
		'{'  => '%7B',
		'}'  => '%7D',
		'|'  => '%7C',
		'^'  => '%5E',
		'`'  => '%60',
		'\\' => '%5C',
		' '  => '%20',
	);
	return str_replace( array_keys( $dangerous ), array_values( $dangerous ), $uri );
}

/**
 * Build a Turtle literal with optional language tag.
 *
 * @param string      $value    The string value.
 * @param string|null $language Optional language tag (e.g., "en").
 * @return string Complete Turtle literal.
 */
function sinople_turtle_literal( string $value, ?string $language = null ): string {
	if ( sinople_turtle_available() ) {
		return \PhpAegis\TurtleEscaper::literal( $value, $language );
	}
	$escaped = sinople_turtle_escape_string( $value );
	$literal = '"' . $escaped . '"';
	if ( $language !== null ) {
		$literal .= '@' . strtolower( $language );
	}
	return $literal;
}

/**
 * Create a Turtle triple.
 *
 * @param string      $subject   Subject IRI.
 * @param string      $predicate Predicate IRI.
 * @param string      $object    Object string value.
 * @param string|null $language  Optional language tag.
 * @return string Complete Turtle triple.
 */
function sinople_turtle_triple( string $subject, string $predicate, string $object, ?string $language = null ): string {
	if ( sinople_turtle_available() ) {
		return \PhpAegis\TurtleEscaper::triple( $subject, $predicate, $object, $language );
	}
	return sprintf(
		'<%s> <%s> %s .',
		sinople_turtle_escape_iri( $subject ),
		sinople_turtle_escape_iri( $predicate ),
		sinople_turtle_literal( $object, $language )
	);
}

/**
 * Create a Turtle triple with IRI object.
 *
 * @param string $subject   Subject IRI.
 * @param string $predicate Predicate IRI.
 * @param string $objectIri Object IRI.
 * @return string Complete Turtle triple.
 */
function sinople_turtle_triple_iri( string $subject, string $predicate, string $objectIri ): string {
	if ( sinople_turtle_available() ) {
		return \PhpAegis\TurtleEscaper::tripleIri( $subject, $predicate, $objectIri );
	}
	return sprintf(
		'<%s> <%s> <%s> .',
		sinople_turtle_escape_iri( $subject ),
		sinople_turtle_escape_iri( $predicate ),
		sinople_turtle_escape_iri( $objectIri )
	);
}

/**
 * Generate Turtle output for a post.
 *
 * @param int|null $post_id Optional post ID. Defaults to current post.
 * @return string Turtle RDF representation of the post.
 */
function sinople_generate_post_turtle( ?int $post_id = null ): string {
	if ( $post_id === null ) {
		$post_id = get_the_ID();
	}

	$post = get_post( $post_id );
	if ( ! $post ) {
		return '';
	}

	$subject = get_permalink( $post_id );
	$lines   = array();

	// Prefixes
	$lines[] = '@prefix schema: <https://schema.org/> .';
	$lines[] = '@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .';
	$lines[] = '@prefix dc: <http://purl.org/dc/elements/1.1/> .';
	$lines[] = '@prefix dcterms: <http://purl.org/dc/terms/> .';
	$lines[] = '';

	// Subject declaration
	$lines[] = '<' . sinople_turtle_escape_iri( $subject ) . '>';
	$lines[] = '    a schema:Article ;';
	$lines[] = '    schema:headline ' . sinople_turtle_literal( get_the_title( $post_id ), get_bloginfo( 'language' ) ) . ' ;';
	$lines[] = '    schema:description ' . sinople_turtle_literal( get_the_excerpt( $post_id ), get_bloginfo( 'language' ) ) . ' ;';
	$lines[] = '    schema:datePublished "' . get_the_date( 'c', $post_id ) . '"^^xsd:dateTime ;';
	$lines[] = '    schema:dateModified "' . get_the_modified_date( 'c', $post_id ) . '"^^xsd:dateTime ;';

	// Author
	$author_url  = get_author_posts_url( (int) $post->post_author );
	$author_name = get_the_author_meta( 'display_name', (int) $post->post_author );
	$lines[]     = '    schema:author [';
	$lines[]     = '        a schema:Person ;';
	$lines[]     = '        schema:name ' . sinople_turtle_literal( $author_name ) . ' ;';
	$lines[]     = '        schema:url <' . sinople_turtle_escape_iri( $author_url ) . '>';
	$lines[]     = '    ] ;';

	// Categories as keywords
	$categories = get_the_category( $post_id );
	if ( ! empty( $categories ) ) {
		$keywords = array_map(
			function ( $cat ) {
				return sinople_turtle_literal( $cat->name );
			},
			$categories
		);
		$lines[] = '    schema:keywords ' . implode( ', ', $keywords ) . ' ;';
	}

	// Word count
	$word_count = str_word_count( wp_strip_all_tags( $post->post_content ) );
	$lines[]    = '    schema:wordCount "' . $word_count . '"^^xsd:integer ;';

	// In language
	$lines[] = '    schema:inLanguage ' . sinople_turtle_literal( get_bloginfo( 'language' ) ) . ' .';

	return implode( "\n", $lines );
}

/**
 * Generate Turtle feed endpoint.
 */
function sinople_turtle_feed(): void {
	if ( ! get_query_var( 'turtle_feed' ) ) {
		return;
	}

	$posts = get_posts( array( 'posts_per_page' => 10 ) );

	header( 'Content-Type: text/turtle; charset=' . get_bloginfo( 'charset' ) );

	// Output prefixes once
	echo "@prefix schema: <https://schema.org/> .\n";
	echo "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .\n";
	echo "@prefix dc: <http://purl.org/dc/elements/1.1/> .\n";
	echo "@prefix dcterms: <http://purl.org/dc/terms/> .\n";
	echo "@prefix sinople: <" . esc_url( home_url( '/ontology/' ) ) . "> .\n";
	echo "\n";

	// Website metadata
	echo '# Website\n';
	echo '<' . sinople_turtle_escape_iri( home_url( '/' ) ) . ">\n";
	echo "    a schema:WebSite ;\n";
	echo '    schema:name ' . sinople_turtle_literal( get_bloginfo( 'name' ), get_bloginfo( 'language' ) ) . " ;\n";
	echo '    schema:description ' . sinople_turtle_literal( get_bloginfo( 'description' ), get_bloginfo( 'language' ) ) . " .\n";
	echo "\n";

	// Posts
	foreach ( $posts as $post ) {
		setup_postdata( $post );
		echo "# " . esc_html( get_the_title( $post->ID ) ) . "\n";
		echo sinople_generate_post_turtle( $post->ID ) . "\n\n";
	}

	wp_reset_postdata();
	exit;
}
add_action( 'template_redirect', 'sinople_turtle_feed' );

/**
 * Add query var for Turtle feed.
 *
 * @param array $vars Query variables.
 * @return array Modified query variables.
 */
function sinople_turtle_feed_query_var( array $vars ): array {
	$vars[] = 'turtle_feed';
	return $vars;
}
add_filter( 'query_vars', 'sinople_turtle_feed_query_var' );

/**
 * Add rewrite rule for Turtle feed.
 */
function sinople_turtle_feed_rewrite(): void {
	add_rewrite_rule( '^feed/turtle/?$', 'index.php?turtle_feed=1', 'top' );
}
add_action( 'init', 'sinople_turtle_feed_rewrite' );

/**
 * Add Turtle feed discovery link.
 */
function sinople_turtle_discovery(): void {
	echo '<link rel="alternate" type="text/turtle" href="' . esc_url( home_url( '/feed/turtle/' ) ) . '" title="' . esc_attr( get_bloginfo( 'name' ) ) . ' (Turtle/RDF)">' . "\n";
}
add_action( 'wp_head', 'sinople_turtle_discovery', 2 );
