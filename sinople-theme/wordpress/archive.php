<?php
/**
 * Archive template
 * @package Sinople
 */
get_header(); ?>

<main id="main" class="site-main" role="main">
    <header class="page-header">
        <h1 class="page-title"><?php the_archive_title(); ?></h1>
        <?php the_archive_description( '<div class="archive-description">', '</div>' ); ?>
    </header>

    <?php if ( have_posts() ) : ?>
        <?php while ( have_posts() ) : the_post(); ?>
            <?php get_template_part( 'template-parts/content', get_post_type() ); ?>
        <?php endwhile; ?>

        <?php the_posts_navigation(); ?>

    <?php else : ?>
        <p><?php esc_html_e( 'No content found.', 'sinople' ); ?></p>
    <?php endif; ?>
</main>

<?php get_sidebar(); get_footer();
