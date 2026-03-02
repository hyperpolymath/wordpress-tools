<?php
/**
 * Template part for displaying posts
 *
 * @package Sinople
 * @since 0.1.0
 */
?>

<article id="post-<?php the_ID(); ?>" <?php post_class(); ?> itemscope itemtype="https://schema.org/Article">

	<header class="entry-header">
		<?php
		if ( is_singular() ) :
			the_title( '<h1 class="entry-title p-name" itemprop="headline">', '</h1>' );
		else :
			the_title( '<h2 class="entry-title p-name" itemprop="headline"><a href="' . esc_url( get_permalink() ) . '" class="u-url" rel="bookmark" itemprop="url">', '</a></h2>' );
		endif;
		?>

		<div class="entry-meta">
			<time class="entry-date published dt-published" datetime="<?php echo esc_attr( get_the_date( 'c' ) ); ?>" itemprop="datePublished">
				<?php echo esc_html( get_the_date() ); ?>
			</time>

			<?php if ( get_the_date() !== get_the_modified_date() ) : ?>
				<time class="updated dt-updated" datetime="<?php echo esc_attr( get_the_modified_date( 'c' ) ); ?>" itemprop="dateModified">
					<?php
					printf(
						/* translators: %s: modified date */
						esc_html__( 'Updated: %s', 'sinople' ),
						esc_html( get_the_modified_date() )
					);
					?>
				</time>
			<?php endif; ?>

			<span class="author vcard p-author h-card" itemscope itemtype="https://schema.org/Person">
				<?php esc_html_e( 'by', 'sinople' ); ?>
				<a class="url fn n p-name u-url" href="<?php echo esc_url( get_author_posts_url( get_the_author_meta( 'ID' ) ) ); ?>" itemprop="url">
					<span itemprop="name"><?php echo esc_html( get_the_author() ); ?></span>
				</a>
			</span>

			<?php if ( function_exists( 'sinople_display_reading_time' ) ) : ?>
				<?php sinople_display_reading_time(); ?>
			<?php endif; ?>
		</div><!-- .entry-meta -->
	</header><!-- .entry-header -->

	<?php if ( has_post_thumbnail() && ! is_singular() ) : ?>
		<div class="entry-thumbnail">
			<a href="<?php the_permalink(); ?>" aria-hidden="true" tabindex="-1">
				<?php
				the_post_thumbnail(
					'sinople-field-note',
					array(
						'alt'   => the_title_attribute( array( 'echo' => false ) ),
						'class' => 'u-photo',
					)
				);
				?>
			</a>
		</div>
	<?php endif; ?>

	<div class="entry-content e-content" itemprop="articleBody">
		<?php
		if ( is_singular() ) {
			the_content(
				sprintf(
					wp_kses(
						/* translators: %s: Post title */
						__( 'Continue reading<span class="screen-reader-text"> "%s"</span>', 'sinople' ),
						array(
							'span' => array(
								'class' => array(),
							),
						)
					),
					esc_html( get_the_title() )
				)
			);

			wp_link_pages(
				array(
					'before' => '<nav class="page-links" aria-label="' . esc_attr__( 'Page navigation', 'sinople' ) . '"><span class="page-links-title">' . esc_html__( 'Pages:', 'sinople' ) . '</span>',
					'after'  => '</nav>',
				)
			);
		} else {
			the_excerpt();
		}
		?>
	</div><!-- .entry-content -->

	<?php if ( is_singular() ) : ?>
		<footer class="entry-footer">
			<?php
			$categories_list = get_the_category_list( esc_html__( ', ', 'sinople' ) );
			if ( $categories_list ) {
				printf(
					'<span class="cat-links">' .
					'<span class="screen-reader-text">%1$s </span>%2$s</span>',
					esc_html__( 'Categories:', 'sinople' ),
					$categories_list // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
				);
			}

			$tags_list = get_the_tag_list( '', esc_html_x( ', ', 'list item separator', 'sinople' ) );
			if ( $tags_list ) {
				printf(
					'<span class="tags-links">' .
					'<span class="screen-reader-text">%1$s </span>%2$s</span>',
					esc_html__( 'Tags:', 'sinople' ),
					$tags_list // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
				);
			}

			// Syndication links (POSSE)
			if ( function_exists( 'sinople_syndication_links' ) ) {
				sinople_syndication_links();
			}
			?>
		</footer><!-- .entry-footer -->
	<?php endif; ?>

</article><!-- #post-<?php the_ID(); ?> -->
