<?php
/**
 * Search results template
 * @package Sinople
 */
get_header(); ?>

<main id="main" class="site-main" role="main">
    <header class="page-header">
        <h1 class="page-title">
            <?php printf( esc_html__( 'Search Results for: %s', 'sinople' ), '<span>' . get_search_query() . '</span>' ); ?>
        </h1>
    </header>

    <?php if ( have_posts() ) : ?>
        <?php while ( have_posts() ) : the_post(); ?>
            <article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>
                <h2><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
                <?php the_excerpt(); ?>
            </article>
        <?php endwhile; ?>
        <?php the_posts_navigation(); ?>
    <?php else : ?>
        <p><?php esc_html_e( 'No results found. Try different keywords.', 'sinople' ); ?></p>
        <?php get_search_form(); ?>
    <?php endif; ?>
</main>

<?php get_sidebar(); get_footer();
