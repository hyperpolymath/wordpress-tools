<?php
/**
 * Sinople Archive Template — Semantic Index View.
 *
 * This template renders lists of posts based on shared taxonomies 
 * (Categories, Tags, or Construct Types). It acts as a high-level 
 * index for the knowledge graph.
 *
 * @package Sinople
 */

get_header(); ?>

<main id="main" class="site-main" role="main">
    <header class="page-header">
        <?php 
        /** METADATA: Displays the authoritative archive title and description. */
        the_archive_title( '<h1 class="page-title">', '</h1>' );
        the_archive_description( '<div class="archive-description">', '</div>' ); 
        ?>
    </header>

    <?php if ( have_posts() ) : ?>
        <?php while ( have_posts() ) : the_post(); ?>
            <?php 
            /** DISPATCH: Routes to specific template parts based on post type. */
            get_template_part( 'template-parts/content', get_post_type() ); 
            ?>
        <?php endwhile; ?>

        <?php the_posts_navigation(); ?>
    <?php endif; ?>
</main>

<?php get_sidebar(); get_footer();
