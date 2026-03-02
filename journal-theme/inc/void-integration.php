<?php
/**
 * VoID (Vocabulary of Interlinked Datasets) Integration
 *
 * Exposes WordPress content as linked data via VoID,
 * SPARQL endpoints (optional), and RDF serialization.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Get VoID endpoint URL
 */
function sinople_void_endpoint_url() {
	return home_url( '/void.rdf' );
}

/**
 * Generate VoID dataset description
 */
function sinople_generate_void_dataset() {
	if ( ! get_query_var( 'void' ) ) {
		return;
	}

	header( 'Content-Type: application/rdf+xml; charset=' . get_bloginfo( 'charset' ) );

	$post_count = wp_count_posts( 'post' )->publish;
	$page_count = wp_count_posts( 'page' )->publish;

	?>
	<?xml version="1.0" encoding="UTF-8"?>
	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:void="http://rdfs.org/ns/void#"
		xmlns:dcterms="http://purl.org/dc/terms/"
		xmlns:foaf="http://xmlns.com/foaf/0.1/">

		<void:Dataset rdf:about="<?php echo esc_url( home_url( '/' ) ); ?>#dataset">
			<dcterms:title><?php echo esc_attr( get_bloginfo( 'name' ) ); ?></dcterms:title>
			<dcterms:description><?php echo esc_attr( get_bloginfo( 'description' ) ); ?></dcterms:description>
			<dcterms:created><?php echo esc_attr( get_option( 'sinople_dataset_created', gmdate( 'c' ) ) ); ?></dcterms:created>
			<dcterms:modified><?php echo esc_attr( gmdate( 'c' ) ); ?></dcterms:modified>

			<void:feature rdf:resource="http://www.w3.org/ns/formats/RDF_XML"/>
			<void:feature rdf:resource="http://www.w3.org/ns/formats/Turtle"/>
			<void:feature rdf:resource="http://www.w3.org/ns/formats/JSON-LD"/>

			<void:dataDump rdf:resource="<?php echo esc_url( home_url( '/dump.rdf' ) ); ?>"/>
			<void:dataDump rdf:resource="<?php echo esc_url( home_url( '/dump.ttl' ) ); ?>"/>
			<void:dataDump rdf:resource="<?php echo esc_url( home_url( '/dump.jsonld' ) ); ?>"/>

			<void:exampleResource rdf:resource="<?php echo esc_url( get_permalink( get_option( 'page_on_front' ) ) ); ?>"/>

			<void:uriSpace><?php echo esc_url( home_url( '/' ) ); ?></void:uriSpace>

			<void:vocabulary rdf:resource="http://schema.org/"/>
			<void:vocabulary rdf:resource="http://xmlns.com/foaf/0.1/"/>
			<void:vocabulary rdf:resource="http://purl.org/dc/terms/"/>

			<void:entities><?php echo absint( $post_count + $page_count ); ?></void:entities>
			<void:triples><?php echo absint( ( $post_count + $page_count ) * 10 ); ?></void:triples>

			<dcterms:license rdf:resource="https://creativecommons.org/licenses/by/4.0/"/>
			<dcterms:rights>Content licensed under CC BY 4.0</dcterms:rights>

			<dcterms:publisher>
				<foaf:Organization>
					<foaf:name><?php echo esc_attr( get_bloginfo( 'name' ) ); ?></foaf:name>
					<foaf:homepage rdf:resource="<?php echo esc_url( home_url( '/' ) ); ?>"/>
				</foaf:Organization>
			</dcterms:publisher>

			<?php
			// Add custom span types as subsets
			if ( function_exists( 'sinople_get_span_types' ) ) {
				$span_types = sinople_get_span_types();
				foreach ( $span_types as $span_type ) {
					?>
					<void:classPartition>
						<void:Dataset>
							<dcterms:title><?php echo esc_attr( $span_type['label'] ); ?></dcterms:title>
							<void:class rdf:resource="<?php echo esc_url( $span_type['uri'] ); ?>"/>
						</void:Dataset>
					</void:classPartition>
					<?php
				}
			}
			?>

		</void:Dataset>

	</rdf:RDF>
	<?php

	exit;
}
add_action( 'template_redirect', 'sinople_generate_void_dataset' );

/**
 * Export post as RDF/XML
 */
function sinople_export_post_rdf( $post_id = null ) {
	if ( ! $post_id ) {
		$post_id = get_the_ID();
	}

	$post = get_post( $post_id );

	if ( ! $post ) {
		return '';
	}

	$rdf = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
	$rdf .= '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"' . "\n";
	$rdf .= '  xmlns:schema="https://schema.org/"' . "\n";
	$rdf .= '  xmlns:dcterms="http://purl.org/dc/terms/"' . "\n";
	$rdf .= '  xmlns:foaf="http://xmlns.com/foaf/0.1/">' . "\n\n";

	$rdf .= '  <schema:Article rdf:about="' . esc_url( get_permalink( $post_id ) ) . '">' . "\n";
	$rdf .= '    <schema:headline>' . esc_xml( get_the_title( $post_id ) ) . '</schema:headline>' . "\n";
	$rdf .= '    <schema:datePublished>' . esc_xml( get_the_date( 'c', $post_id ) ) . '</schema:datePublished>' . "\n";
	$rdf .= '    <schema:dateModified>' . esc_xml( get_the_modified_date( 'c', $post_id ) ) . '</schema:dateModified>' . "\n";
	$rdf .= '    <schema:author>' . "\n";
	$rdf .= '      <schema:Person>' . "\n";
	$rdf .= '        <schema:name>' . esc_xml( get_the_author_meta( 'display_name', $post->post_author ) ) . '</schema:name>' . "\n";
	$rdf .= '      </schema:Person>' . "\n";
	$rdf .= '    </schema:author>' . "\n";
	$rdf .= '  </schema:Article>' . "\n\n";

	$rdf .= '</rdf:RDF>';

	return $rdf;
}

/**
 * Export post as Turtle
 */
function sinople_export_post_turtle( $post_id = null ) {
	if ( ! $post_id ) {
		$post_id = get_the_ID();
	}

	$post = get_post( $post_id );

	if ( ! $post ) {
		return '';
	}

	$ttl = '@prefix schema: <https://schema.org/> .' . "\n";
	$ttl .= '@prefix dcterms: <http://purl.org/dc/terms/> .' . "\n";
	$ttl .= '@prefix foaf: <http://xmlns.com/foaf/0.1/> .' . "\n\n";

	$ttl .= '<' . get_permalink( $post_id ) . '>' . "\n";
	$ttl .= '  a schema:Article ;' . "\n";
	$ttl .= '  schema:headline "' . esc_attr( get_the_title( $post_id ) ) . '" ;' . "\n";
	$ttl .= '  schema:datePublished "' . get_the_date( 'c', $post_id ) . '" ;' . "\n";
	$ttl .= '  schema:dateModified "' . get_the_modified_date( 'c', $post_id ) . '" ;' . "\n";
	$ttl .= '  schema:author [' . "\n";
	$ttl .= '    a schema:Person ;' . "\n";
	$ttl .= '    schema:name "' . esc_attr( get_the_author_meta( 'display_name', $post->post_author ) ) . '"' . "\n";
	$ttl .= '  ] .' . "\n";

	return $ttl;
}

/**
 * Add RDF alternate links
 */
function sinople_rdf_alternate_links() {
	if ( is_singular() ) {
		printf(
			'<link rel="alternate" type="application/rdf+xml" href="%s" title="RDF/XML" />' . "\n",
			esc_url( add_query_arg( 'format', 'rdf', get_permalink() ) )
		);

		printf(
			'<link rel="alternate" type="text/turtle" href="%s" title="Turtle" />' . "\n",
			esc_url( add_query_arg( 'format', 'ttl', get_permalink() ) )
		);
	}

	// VoID dataset link
	printf(
		'<link rel="meta" type="application/rdf+xml" href="%s" title="VoID Dataset Description" />' . "\n",
		esc_url( sinople_void_endpoint_url() )
	);
}
add_action( 'wp_head', 'sinople_rdf_alternate_links', 5 );

/**
 * Handle RDF format requests
 */
function sinople_handle_rdf_request() {
	if ( ! is_singular() ) {
		return;
	}

	$format = get_query_var( 'format' );

	if ( ! $format ) {
		return;
	}

	switch ( $format ) {
		case 'rdf':
			header( 'Content-Type: application/rdf+xml; charset=' . get_bloginfo( 'charset' ) );
			echo sinople_export_post_rdf(); // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
			exit;

		case 'ttl':
			header( 'Content-Type: text/turtle; charset=' . get_bloginfo( 'charset' ) );
			echo sinople_export_post_turtle(); // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
			exit;

		case 'jsonld':
			header( 'Content-Type: application/ld+json; charset=' . get_bloginfo( 'charset' ) );
			// JSON-LD export would go here
			exit;
	}
}
add_action( 'template_redirect', 'sinople_handle_rdf_request', 5 );

/**
 * Add format query var
 */
function sinople_format_query_var( $vars ) {
	$vars[] = 'format';
	return $vars;
}
add_filter( 'query_vars', 'sinople_format_query_var' );
