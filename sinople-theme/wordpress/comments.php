<?php
/**
 * Comments template
 * @package Sinople
 */
if ( post_password_required() ) return;
?>

<div id="comments" class="comments-area">
    <?php if ( have_comments() ) : ?>
        <h2 class="comments-title">
            <?php
            $comment_count = get_comments_number();
            printf(
                esc_html( _n( 'One comment', '%s comments', $comment_count, 'sinople' ) ),
                number_format_i18n( $comment_count )
            );
            ?>
        </h2>

        <ol class="comment-list">
            <?php
            wp_list_comments( array(
                'style'      => 'ol',
                'short_ping' => true,
            ) );
            ?>
        </ol>

        <?php the_comments_navigation(); ?>

    <?php endif; ?>

    <?php if ( ! comments_open() && get_comments_number() && post_type_supports( get_post_type(), 'comments' ) ) : ?>
        <p class="no-comments"><?php esc_html_e( 'Comments are closed.', 'sinople' ); ?></p>
    <?php endif; ?>

    <?php comment_form(); ?>
</div>
