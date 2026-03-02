<?php
/**
 * Custom Taxonomies
 *
 * Registers taxonomies for emotional, chromatic, and symbolic organization.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Register Emotion taxonomy
 */
function sinople_register_emotion_taxonomy() {
	$labels = array(
		'name'              => _x( 'Emotions', 'taxonomy general name', 'sinople' ),
		'singular_name'     => _x( 'Emotion', 'taxonomy singular name', 'sinople' ),
		'search_items'      => __( 'Search Emotions', 'sinople' ),
		'all_items'         => __( 'All Emotions', 'sinople' ),
		'parent_item'       => __( 'Parent Emotion', 'sinople' ),
		'parent_item_colon' => __( 'Parent Emotion:', 'sinople' ),
		'edit_item'         => __( 'Edit Emotion', 'sinople' ),
		'update_item'       => __( 'Update Emotion', 'sinople' ),
		'add_new_item'      => __( 'Add New Emotion', 'sinople' ),
		'new_item_name'     => __( 'New Emotion Name', 'sinople' ),
		'menu_name'         => __( 'Emotions', 'sinople' ),
	);

	$args = array(
		'hierarchical'      => true,
		'labels'            => $labels,
		'show_ui'           => true,
		'show_admin_column' => true,
		'query_var'         => true,
		'rewrite'           => array( 'slug' => 'emotion' ),
		'show_in_rest'      => true,
	);

	register_taxonomy( 'emotion', array( 'post', 'field_note' ), $args );
}
add_action( 'init', 'sinople_register_emotion_taxonomy' );

/**
 * Register Color taxonomy
 */
function sinople_register_color_taxonomy() {
	$labels = array(
		'name'              => _x( 'Colors', 'taxonomy general name', 'sinople' ),
		'singular_name'     => _x( 'Color', 'taxonomy singular name', 'sinople' ),
		'search_items'      => __( 'Search Colors', 'sinople' ),
		'all_items'         => __( 'All Colors', 'sinople' ),
		'edit_item'         => __( 'Edit Color', 'sinople' ),
		'update_item'       => __( 'Update Color', 'sinople' ),
		'add_new_item'      => __( 'Add New Color', 'sinople' ),
		'new_item_name'     => __( 'New Color Name', 'sinople' ),
		'menu_name'         => __( 'Colors', 'sinople' ),
	);

	$args = array(
		'hierarchical'      => false,
		'labels'            => $labels,
		'show_ui'           => true,
		'show_admin_column' => true,
		'query_var'         => true,
		'rewrite'           => array( 'slug' => 'color' ),
		'show_in_rest'      => true,
	);

	register_taxonomy( 'color', array( 'post', 'field_note' ), $args );
}
add_action( 'init', 'sinople_register_color_taxonomy' );

/**
 * Register Motif taxonomy
 */
function sinople_register_motif_taxonomy() {
	$labels = array(
		'name'              => _x( 'Motifs', 'taxonomy general name', 'sinople' ),
		'singular_name'     => _x( 'Motif', 'taxonomy singular name', 'sinople' ),
		'search_items'      => __( 'Search Motifs', 'sinople' ),
		'all_items'         => __( 'All Motifs', 'sinople' ),
		'parent_item'       => __( 'Parent Motif', 'sinople' ),
		'parent_item_colon' => __( 'Parent Motif:', 'sinople' ),
		'edit_item'         => __( 'Edit Motif', 'sinople' ),
		'update_item'       => __( 'Update Motif', 'sinople' ),
		'add_new_item'      => __( 'Add New Motif', 'sinople' ),
		'new_item_name'     => __( 'New Motif Name', 'sinople' ),
		'menu_name'         => __( 'Motifs', 'sinople' ),
	);

	$args = array(
		'hierarchical'      => true,
		'labels'            => $labels,
		'show_ui'           => true,
		'show_admin_column' => true,
		'query_var'         => true,
		'rewrite'           => array( 'slug' => 'motif' ),
		'show_in_rest'      => true,
	);

	register_taxonomy( 'motif', array( 'post', 'field_note' ), $args );
}
add_action( 'init', 'sinople_register_motif_taxonomy' );

/**
 * Register Archetype taxonomy (for constructs)
 */
function sinople_register_archetype_taxonomy() {
	$labels = array(
		'name'              => _x( 'Archetypes', 'taxonomy general name', 'sinople' ),
		'singular_name'     => _x( 'Archetype', 'taxonomy singular name', 'sinople' ),
		'search_items'      => __( 'Search Archetypes', 'sinople' ),
		'all_items'         => __( 'All Archetypes', 'sinople' ),
		'edit_item'         => __( 'Edit Archetype', 'sinople' ),
		'update_item'       => __( 'Update Archetype', 'sinople' ),
		'add_new_item'      => __( 'Add New Archetype', 'sinople' ),
		'new_item_name'     => __( 'New Archetype Name', 'sinople' ),
		'menu_name'         => __( 'Archetypes', 'sinople' ),
	);

	$args = array(
		'hierarchical'      => false,
		'labels'            => $labels,
		'show_ui'           => true,
		'show_admin_column' => true,
		'query_var'         => true,
		'rewrite'           => array( 'slug' => 'archetype' ),
		'show_in_rest'      => true,
	);

	register_taxonomy( 'archetype', array( 'construct' ), $args );
}
add_action( 'init', 'sinople_register_archetype_taxonomy' );

/**
 * Register Symbol taxonomy (for constructs)
 */
function sinople_register_symbol_taxonomy() {
	$labels = array(
		'name'              => _x( 'Symbols', 'taxonomy general name', 'sinople' ),
		'singular_name'     => _x( 'Symbol', 'taxonomy singular name', 'sinople' ),
		'search_items'      => __( 'Search Symbols', 'sinople' ),
		'all_items'         => __( 'All Symbols', 'sinople' ),
		'parent_item'       => __( 'Parent Symbol', 'sinople' ),
		'parent_item_colon' => __( 'Parent Symbol:', 'sinople' ),
		'edit_item'         => __( 'Edit Symbol', 'sinople' ),
		'update_item'       => __( 'Update Symbol', 'sinople' ),
		'add_new_item'      => __( 'Add New Symbol', 'sinople' ),
		'new_item_name'     => __( 'New Symbol Name', 'sinople' ),
		'menu_name'         => __( 'Symbols', 'sinople' ),
	);

	$args = array(
		'hierarchical'      => true,
		'labels'            => $labels,
		'show_ui'           => true,
		'show_admin_column' => true,
		'query_var'         => true,
		'rewrite'           => array( 'slug' => 'symbol' ),
		'show_in_rest'      => true,
	);

	register_taxonomy( 'symbol', array( 'construct' ), $args );
}
add_action( 'init', 'sinople_register_symbol_taxonomy' );

/**
 * Register Inspiration Type taxonomy (for portals)
 */
function sinople_register_inspiration_type_taxonomy() {
	$labels = array(
		'name'              => _x( 'Inspiration Types', 'taxonomy general name', 'sinople' ),
		'singular_name'     => _x( 'Inspiration Type', 'taxonomy singular name', 'sinople' ),
		'search_items'      => __( 'Search Inspiration Types', 'sinople' ),
		'all_items'         => __( 'All Inspiration Types', 'sinople' ),
		'edit_item'         => __( 'Edit Inspiration Type', 'sinople' ),
		'update_item'       => __( 'Update Inspiration Type', 'sinople' ),
		'add_new_item'      => __( 'Add New Inspiration Type', 'sinople' ),
		'new_item_name'     => __( 'New Inspiration Type Name', 'sinople' ),
		'menu_name'         => __( 'Inspiration Types', 'sinople' ),
	);

	$args = array(
		'hierarchical'      => false,
		'labels'            => $labels,
		'show_ui'           => true,
		'show_admin_column' => true,
		'query_var'         => true,
		'rewrite'           => array( 'slug' => 'inspiration' ),
		'show_in_rest'      => true,
	);

	register_taxonomy( 'inspiration_type', array( 'portal' ), $args );
}
add_action( 'init', 'sinople_register_inspiration_type_taxonomy' );

/**
 * Add custom taxonomy fields
 */
function sinople_add_taxonomy_fields( $term ) {
	$color_hex = get_term_meta( $term->term_id, 'color_hex', true );
	?>
	<tr class="form-field">
		<th scope="row"><label for="color_hex"><?php esc_html_e( 'Hex Color', 'sinople' ); ?></label></th>
		<td>
			<input type="color" name="color_hex" id="color_hex" value="<?php echo esc_attr( $color_hex ); ?>">
			<p class="description"><?php esc_html_e( 'Choose a color to represent this term.', 'sinople' ); ?></p>
		</td>
	</tr>
	<?php
}
add_action( 'color_edit_form_fields', 'sinople_add_taxonomy_fields' );
add_action( 'emotion_edit_form_fields', 'sinople_add_taxonomy_fields' );

/**
 * Save custom taxonomy fields
 */
function sinople_save_taxonomy_fields( $term_id ) {
	if ( isset( $_POST['color_hex'] ) ) {
		update_term_meta( $term_id, 'color_hex', sanitize_hex_color( wp_unslash( $_POST['color_hex'] ) ) );
	}
}
add_action( 'edited_color', 'sinople_save_taxonomy_fields' );
add_action( 'edited_emotion', 'sinople_save_taxonomy_fields' );
