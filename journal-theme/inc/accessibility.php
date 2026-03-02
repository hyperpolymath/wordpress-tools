<?php
/**
 * Accessibility Features
 *
 * WCAG 2.3 AAA compliance features including keyboard navigation,
 * skip links, ARIA enhancements, and user preference respect.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Add skip links to beginning of page
 */
function sinople_skip_links() {
	?>
	<nav class="skip-links" aria-label="<?php esc_attr_e( 'Skip links', 'sinople' ); ?>">
		<ul>
			<li><a href="#main" class="skip-link"><?php esc_html_e( 'Skip to main content', 'sinople' ); ?></a></li>
			<li><a href="#site-navigation" class="skip-link"><?php esc_html_e( 'Skip to navigation', 'sinople' ); ?></a></li>
			<li><a href="#footer" class="skip-link"><?php esc_html_e( 'Skip to footer', 'sinople' ); ?></a></li>
		</ul>
	</nav>
	<?php
}

/**
 * Enhanced screen reader text
 */
function sinople_screen_reader_text( $text, $context = '' ) {
	return '<span class="screen-reader-text">' . esc_html( $text ) . '</span>';
}

/**
 * Add ARIA labels to navigation
 */
function sinople_nav_menu_aria( $items, $args ) {
	if ( 'primary' === $args->theme_location ) {
		$items = str_replace( '<a', '<a role="menuitem"', $items );
	}
	return $items;
}
add_filter( 'wp_nav_menu_items', 'sinople_nav_menu_aria', 10, 2 );

/**
 * Add describedby attributes to form fields
 */
function sinople_comment_form_defaults( $defaults ) {
	$commenter = wp_get_current_commenter();

	$defaults['fields']['author'] = '<p class="comment-form-author">' .
		'<label for="author">' . esc_html__( 'Name', 'sinople' ) . ( $defaults['fields']['author']['required'] ? ' <span class="required" aria-label="required">*</span>' : '' ) . '</label>' .
		'<input id="author" name="author" type="text" value="' . esc_attr( $commenter['comment_author'] ) . '" ' .
		'aria-required="true" aria-describedby="author-description" ' .
		'size="30" maxlength="245" required />' .
		'<span id="author-description" class="field-description screen-reader-text">' . esc_html__( 'Enter your full name', 'sinople' ) . '</span>' .
		'</p>';

	return $defaults;
}
add_filter( 'comment_form_defaults', 'sinople_comment_form_defaults' );

/**
 * Add reading time to posts
 */
function sinople_display_reading_time( $post_id = null ) {
	$reading_time = sinople_get_reading_time( $post_id );

	if ( ! $reading_time ) {
		return;
	}

	$minutes = ceil( $reading_time );

	printf(
		'<div class="reading-time" role="status" aria-live="polite"><span class="screen-reader-text">%s</span><span aria-hidden="true">%s</span></div>',
		sprintf(
			/* translators: %d: reading time in minutes */
			esc_html( _n( 'Estimated reading time: %d minute', 'Estimated reading time: %d minutes', $minutes, 'sinople' ) ),
			$minutes
		),
		sprintf(
			/* translators: %d: reading time in minutes */
			esc_html( _n( '%d min read', '%d min read', $minutes, 'sinople' ) ),
			$minutes
		)
	);
}

/**
 * Add focus indicators via CSS custom properties
 */
function sinople_focus_styles() {
	?>
	<style id="sinople-focus-styles">
		:root {
			--focus-color: #0066cc;
			--focus-width: 3px;
			--focus-offset: 2px;
			--focus-style: solid;
		}

		*:focus-visible {
			outline: var(--focus-width) var(--focus-style) var(--focus-color);
			outline-offset: var(--focus-offset);
		}

		a:focus-visible,
		button:focus-visible,
		input:focus-visible,
		textarea:focus-visible,
		select:focus-visible {
			outline: var(--focus-width) var(--focus-style) var(--focus-color);
			outline-offset: var(--focus-offset);
		}

		.skip-link:focus {
			position: fixed;
			top: 10px;
			left: 10px;
			z-index: 100000;
			background: var(--focus-color);
			color: white;
			padding: 1rem;
			text-decoration: none;
			border-radius: 4px;
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_focus_styles', 100 );

/**
 * Ensure images have alt text
 */
function sinople_enforce_image_alt( $attr, $attachment ) {
	if ( empty( $attr['alt'] ) ) {
		$attr['alt'] = get_the_title( $attachment->ID );

		// If still empty, use a descriptive fallback
		if ( empty( $attr['alt'] ) ) {
			$attr['alt'] = esc_html__( 'Image', 'sinople' );
		}
	}

	return $attr;
}
add_filter( 'wp_get_attachment_image_attributes', 'sinople_enforce_image_alt', 10, 2 );

/**
 * Add lang attribute to blockquotes if needed
 */
function sinople_blockquote_lang( $content ) {
	// This is a simplified example - would need language detection
	return $content;
}
add_filter( 'the_content', 'sinople_blockquote_lang' );

/**
 * Create accessible breadcrumbs
 */
function sinople_breadcrumbs() {
	if ( is_front_page() ) {
		return;
	}

	$breadcrumbs = array();
	$breadcrumbs[] = '<a href="' . esc_url( home_url( '/' ) ) . '" rel="home">' . esc_html__( 'Home', 'sinople' ) . '</a>';

	if ( is_category() || is_single() ) {
		$category = get_the_category();
		if ( $category ) {
			$breadcrumbs[] = '<a href="' . esc_url( get_category_link( $category[0]->term_id ) ) . '">' . esc_html( $category[0]->name ) . '</a>';
		}
	}

	if ( is_single() ) {
		$breadcrumbs[] = '<span aria-current="page">' . get_the_title() . '</span>';
	} elseif ( is_page() ) {
		$breadcrumbs[] = '<span aria-current="page">' . get_the_title() . '</span>';
	} elseif ( is_archive() ) {
		$breadcrumbs[] = '<span aria-current="page">' . get_the_archive_title() . '</span>';
	}

	if ( ! empty( $breadcrumbs ) ) {
		?>
		<nav class="breadcrumbs" aria-label="<?php esc_attr_e( 'Breadcrumb navigation', 'sinople' ); ?>" role="navigation">
			<ol class="breadcrumb-list" vocab="https://schema.org/" typeof="BreadcrumbList">
				<?php
				foreach ( $breadcrumbs as $index => $crumb ) {
					$position = $index + 1;
					echo '<li property="itemListElement" typeof="ListItem">';
					echo '<span property="item">' . $crumb . '</span>'; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
					echo '<meta property="position" content="' . absint( $position ) . '">';
					echo '</li>';
				}
				?>
			</ol>
		</nav>
		<?php
	}
}

/**
 * Add live regions for dynamic content
 */
function sinople_add_live_regions() {
	?>
	<div id="live-region-polite" class="screen-reader-text" aria-live="polite" aria-atomic="true"></div>
	<div id="live-region-assertive" class="screen-reader-text" aria-live="assertive" aria-atomic="true"></div>
	<?php
}
add_action( 'wp_footer', 'sinople_add_live_regions' );

/**
 * Respect prefers-reduced-motion
 */
function sinople_reduced_motion_css() {
	?>
	<style id="sinople-reduced-motion">
		@media (prefers-reduced-motion: reduce) {
			*,
			*::before,
			*::after {
				animation-duration: 0.01ms !important;
				animation-iteration-count: 1 !important;
				transition-duration: 0.01ms !important;
				scroll-behavior: auto !important;
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_reduced_motion_css', 99 );
