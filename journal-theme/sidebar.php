<?php
/**
 * Sidebar Template
 *
 * Displays the sidebar with ARIA landmarks and semantic markup.
 *
 * @package Sinople
 * @since 0.1.0
 */

if ( ! is_active_sidebar( 'sidebar-1' ) ) {
	return;
}
?>

<aside id="secondary" class="widget-area sidebar" role="complementary" aria-label="<?php esc_attr_e( 'Sidebar', 'sinople' ); ?>">
	<?php dynamic_sidebar( 'sidebar-1' ); ?>
</aside><!-- #secondary -->
