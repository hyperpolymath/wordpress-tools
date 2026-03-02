<?php
/**
 * Main Template File
 *
 * Displays posts with full semantic markup, microformats v2,
 * and ARIA-rich accessibility features.
 *
 * @package Sinople
 * @since 0.1.0
 */

get_header();
?>

<main id="main" class="site-main" role="main" aria-label="<?php esc_attr_e( 'Main content', 'sinople' ); ?>">

	<?php if ( have_posts() ) : ?>

		<?php
		// Archive header for non-singular views
		if ( ! is_singular() ) :
			?>
			<header class="archive-header" role="banner">
				<h1 class="archive-title p-name">
					<?php
					if ( is_home() && ! is_front_page() ) :
						single_post_title();
					elseif ( is_archive() ) :
						the_archive_title();
					elseif ( is_search() ) :
						printf(
							/* translators: %s: search query */
							esc_html__( 'Search Results for: %s', 'sinople' ),
							'<span class="search-query">' . get_search_query() . '</span>'
						);
					else :
						esc_html_e( 'Recent Entries', 'sinople' );
					endif;
					?>
				</h1>
				<?php
				if ( is_archive() && get_the_archive_description() ) :
					?>
					<div class="archive-description e-content">
						<?php the_archive_description(); ?>
					</div>
				<?php endif; ?>
			</header>
			<?php
		endif;

		// Start the Loop
		while ( have_posts() ) :
			the_post();

			/*
			 * Include the Post-Type-specific template for the content.
			 * If you want to override this in a child theme, include a file
			 * called content-___.php (where ___ is the Post Type name) and that will be used instead.
			 */
			get_template_part( 'templates/content', get_post_type() );

		endwhile;

		// Pagination with ARIA labels
		the_posts_pagination(
			array(
				'mid_size'           => 2,
				'prev_text'          => '<span class="screen-reader-text">' . __( 'Previous page', 'sinople' ) . '</span><span aria-hidden="true">' . __( '← Previous', 'sinople' ) . '</span>',
				'next_text'          => '<span class="screen-reader-text">' . __( 'Next page', 'sinople' ) . '</span><span aria-hidden="true">' . __( 'Next →', 'sinople' ) . '</span>',
				'before_page_number' => '<span class="screen-reader-text">' . __( 'Page ', 'sinople' ) . '</span>',
				'aria_label'         => __( 'Posts navigation', 'sinople' ),
			)
		);

	else :

		// No posts found
		get_template_part( 'templates/content', 'none' );

	endif;
	?>

</main><!-- #main -->

<?php
get_sidebar();
get_footer();
