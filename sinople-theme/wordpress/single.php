<?php get_header(); ?>
<main id="main" class="site-main" role="main">
    <?php while ( have_posts() ) : the_post(); ?>
        <article id="post-<?php the_ID(); ?>" <?php post_class( 'h-entry' ); ?>>
            <h1 class="p-name"><?php the_title(); ?></h1>
            <div class="e-content"><?php the_content(); ?></div>
        </article>
    <?php endwhile; ?>
</main>
<?php get_footer();
