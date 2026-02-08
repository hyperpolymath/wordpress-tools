<?php
/**
 * Main template file
 * @package Sinople
 */
get_header(); ?>

<main id="main" class="site-main" role="main">
    <?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
        <article id="post-<?php the_ID(); ?>" <?php post_class( 'h-entry' ); ?>>
            <header class="entry-header">
                <h2 class="entry-title p-name"><a href="<?php the_permalink(); ?>" class="u-url"><?php the_title(); ?></a></h2>
            </header>
            <div class="entry-content e-content">
                <?php the_excerpt(); ?>
            </div>
        </article>
    <?php endwhile; endif; ?>
</main>

<?php get_sidebar(); get_footer();
