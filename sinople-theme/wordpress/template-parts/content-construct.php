<?php
/**
 * Template part for displaying constructs
 * @package Sinople
 */

$gloss = get_post_meta( get_the_ID(), '_sinople_gloss', true );
$complexity = get_post_meta( get_the_ID(), '_sinople_complexity', true );
$construct_type = get_post_meta( get_the_ID(), '_sinople_construct_type', true );
?>

<article id="construct-<?php the_ID(); ?>" <?php post_class( 'h-entry construct' ); ?>>
    <header class="entry-header">
        <h1 class="entry-title p-name"><?php the_title(); ?></h1>

        <?php if ( $gloss ) : ?>
            <div class="construct-gloss" aria-label="<?php esc_attr_e( 'Brief explanation', 'sinople' ); ?>">
                <strong><?php esc_html_e( 'Gloss:', 'sinople' ); ?></strong>
                <?php echo esc_html( $gloss ); ?>
            </div>
        <?php endif; ?>

        <div class="construct-meta">
            <?php if ( $construct_type ) : ?>
                <span class="construct-type">
                    <strong><?php esc_html_e( 'Type:', 'sinople' ); ?></strong>
                    <?php echo esc_html( ucfirst( $construct_type ) ); ?>
                </span>
            <?php endif; ?>

            <?php if ( $complexity !== '' ) : ?>
                <span class="construct-complexity">
                    <strong><?php esc_html_e( 'Complexity:', 'sinople' ); ?></strong>
                    <?php echo esc_html( $complexity ); ?>/10
                </span>
            <?php endif; ?>
        </div>
    </header>

    <div class="entry-content e-content">
        <?php the_content(); ?>
    </div>

    <div class="semantic-graph" role="region" aria-label="<?php esc_attr_e( 'Related constructs visualization', 'sinople' ); ?>">
        <!-- Graph will be rendered here by graph-viewer.js -->
    </div>
</article>
