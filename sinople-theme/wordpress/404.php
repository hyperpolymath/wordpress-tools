<?php
/**
 * Sinople 404 Error Template — User Recovery Page.
 *
 * This template is rendered when a requested semantic resource or page 
 * cannot be found. it is designed to facilitate user recovery through 
 * search and discovery of related constructs.
 *
 * @package Sinople
 */

get_header(); ?>

<main id="main" class="site-main" role="main">
    <header class="page-header">
        <h1 class="page-title"><?php esc_html_e( '404: Page Not Found', 'sinople' ); ?></h1>
    </header>

    <div class="page-content">
        <p><?php esc_html_e( 'The semantic resource you requested is unavailable.', 'sinople' ); ?></p>

        <?php /** RECOVERY: Search interface for knowledge discovery. */ ?>
        <h2><?php esc_html_e( 'Try searching:', 'sinople' ); ?></h2>
        <?php get_search_form(); ?>

        <?php /** DISCOVERY: Recommends recent knowledge constructs. */ ?>
        <h2><?php esc_html_e( 'Recent Constructs:', 'sinople' ); ?></h2>
        <ul>
        <?php
        $recent = get_posts( array( 'post_type' => 'sinople_construct', 'numberposts' => 5 ) );
        foreach ( $recent as $post ) :
            setup_postdata( $post );
            ?>
            <li><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></li>
        <?php endforeach; wp_reset_postdata(); ?>
        </ul>
    </div>
</main>

<?php get_footer();
