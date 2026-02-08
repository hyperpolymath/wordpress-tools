<?php
/**
 * Template part for displaying posts
 * @package Sinople
 */
?>

<article id="post-<?php the_ID(); ?>" <?php post_class( 'h-entry' ); ?>>
    <header class="entry-header">
        <?php
        if ( is_singular() ) :
            the_title( '<h1 class="entry-title p-name">', '</h1>' );
        else :
            the_title( '<h2 class="entry-title p-name"><a href="' . esc_url( get_permalink() ) . '" class="u-url" rel="bookmark">', '</a></h2>' );
        endif;
        ?>

        <div class="entry-meta">
            <time class="dt-published" datetime="<?php echo esc_attr( get_the_date( 'c' ) ); ?>">
                <?php echo esc_html( get_the_date() ); ?>
            </time>
            <span class="byline">
                <?php esc_html_e( 'by', 'sinople' ); ?>
                <span class="p-author h-card">
                    <a href="<?php echo esc_url( get_author_posts_url( get_the_author_meta( 'ID' ) ) ); ?>" class="u-url">
                        <span class="p-name"><?php echo esc_html( get_the_author() ); ?></span>
                    </a>
                </span>
            </span>
        </div>
    </header>

    <div class="entry-content e-content">
        <?php
        if ( is_singular() ) :
            the_content();
        else :
            the_excerpt();
        endif;
        ?>
    </div>

    <footer class="entry-footer">
        <?php
        $categories = get_the_category_list( ', ' );
        $tags = get_the_tag_list( '', ', ' );

        if ( $categories ) :
            echo '<span class="cat-links">' . $categories . '</span>';
        endif;

        if ( $tags ) :
            echo '<span class="tags-links">' . $tags . '</span>';
        endif;
        ?>
    </footer>
</article>
