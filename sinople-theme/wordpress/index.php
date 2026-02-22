<?php
/**
 * Sinople Theme Index — Primary Fallback Template.
 *
 * This template acts as the base layout for the WordPress site. it is 
 * used to render the main post loop when a more specific template 
 * (like archive.php or search.php) is not present.
 *
 * @package Sinople
 */

get_header(); ?>

<main id="main" class="site-main" role="main">
    <?php if ( have_posts() ) : ?>
        <?php while ( have_posts() ) : the_post(); ?>
            <?php 
            /** DISPATCH: Renders the appropriate content fragment based on post type. */
            get_template_part( 'template-parts/content', get_post_type() ); 
            ?>
        <?php endwhile; ?>

        <?php the_posts_navigation(); ?>
    <?php else : ?>
        <?php get_template_part( 'template-parts/content', 'none' ); ?>
    <?php endif; ?>
</main>

<?php get_sidebar(); get_footer();
