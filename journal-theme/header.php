<?php
/**
 * Header Template
 *
 * Displays the site header with ARIA landmarks, skip links,
 * microformats v2 h-card, and semantic metadata.
 *
 * @package Sinople
 * @since 0.1.0
 */
?>
<!DOCTYPE html>
<html <?php language_attributes(); ?> class="no-js">
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">

	<?php
	// Security headers are set in inc/security.php
	// Privacy-first: No external resources without consent
	?>

	<!-- Preconnect hints for performance -->
	<?php if ( sinople_has_consent( 'external_fonts' ) ) : ?>
		<link rel="preconnect" href="https://fonts.googleapis.com" crossorigin>
	<?php endif; ?>

	<!-- Resource hints -->
	<link rel="dns-prefetch" href="<?php echo esc_url( home_url() ); ?>">

	<!-- Theme color for browser UI -->
	<meta name="theme-color" content="#2d3436" media="(prefers-color-scheme: dark)">
	<meta name="theme-color" content="#dfe6e9" media="(prefers-color-scheme: light)">

	<!-- Accessibility: Reduce motion if user prefers -->
	<meta name="color-scheme" content="light dark">

	<?php wp_head(); ?>

	<!-- Inline critical CSS loaded via inc/performance.php -->
	<!-- JSON-LD structured data loaded via inc/semantic.php -->
	<!-- Open Graph metadata loaded via inc/semantic.php -->

	<!-- Feature detection: Remove no-js class -->
	<script>
		document.documentElement.classList.remove('no-js');
		document.documentElement.classList.add('js');

		// Detect modern features
		if ('IntersectionObserver' in window) {
			document.documentElement.classList.add('has-intersection-observer');
		}
		if ('ResizeObserver' in window) {
			document.documentElement.classList.add('has-resize-observer');
		}
		if (CSS.supports('container-type: inline-size')) {
			document.documentElement.classList.add('has-container-queries');
		}
		if ('ViewTransition' in document) {
			document.documentElement.classList.add('has-view-transitions');
		}
		if (typeof window.crypto?.subtle?.generateKey === 'function') {
			document.documentElement.classList.add('has-webcrypto');
		}
	</script>
</head>

<body <?php body_class(); ?> itemscope itemtype="https://schema.org/WebPage">

	<?php wp_body_open(); ?>

	<!-- Skip links for keyboard navigation (WCAG 2.3 AAA) -->
	<a class="skip-link screen-reader-text" href="#main">
		<?php esc_html_e( 'Skip to main content', 'sinople' ); ?>
	</a>
	<a class="skip-link screen-reader-text" href="#site-navigation">
		<?php esc_html_e( 'Skip to navigation', 'sinople' ); ?>
	</a>
	<a class="skip-link screen-reader-text" href="#footer">
		<?php esc_html_e( 'Skip to footer', 'sinople' ); ?>
	</a>

	<div id="page" class="site h-feed" itemscope itemtype="https://schema.org/Blog">

		<!-- Site header with role="banner" -->
		<header id="masthead" class="site-header" role="banner" itemscope itemtype="https://schema.org/WPHeader">

			<div class="site-branding h-card" itemscope itemtype="https://schema.org/Organization">

				<?php if ( has_custom_logo() ) : ?>
					<div class="site-logo">
						<?php the_custom_logo(); ?>
					</div>
				<?php endif; ?>

				<div class="site-identity">
					<?php if ( is_front_page() && is_home() ) : ?>
						<h1 class="site-title p-name" itemprop="name">
							<a href="<?php echo esc_url( home_url( '/' ) ); ?>" class="u-url" rel="home" itemprop="url">
								<?php bloginfo( 'name' ); ?>
							</a>
						</h1>
					<?php else : ?>
						<p class="site-title p-name" itemprop="name">
							<a href="<?php echo esc_url( home_url( '/' ) ); ?>" class="u-url" rel="home" itemprop="url">
								<?php bloginfo( 'name' ); ?>
							</a>
						</p>
					<?php endif; ?>

					<?php
					$sinople_description = get_bloginfo( 'description', 'display' );
					if ( $sinople_description || is_customize_preview() ) :
						?>
						<p class="site-description p-note" itemprop="description">
							<?php echo $sinople_description; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped ?>
						</p>
					<?php endif; ?>
				</div><!-- .site-identity -->

				<!-- Accessibility controls -->
				<div class="accessibility-controls" role="toolbar" aria-label="<?php esc_attr_e( 'Accessibility controls', 'sinople' ); ?>">
					<button id="font-size-decrease" class="a11y-btn" aria-label="<?php esc_attr_e( 'Decrease font size', 'sinople' ); ?>" title="<?php esc_attr_e( 'Decrease font size', 'sinople' ); ?>">
						<span aria-hidden="true">A−</span>
					</button>
					<button id="font-size-increase" class="a11y-btn" aria-label="<?php esc_attr_e( 'Increase font size', 'sinople' ); ?>" title="<?php esc_attr_e( 'Increase font size', 'sinople' ); ?>">
						<span aria-hidden="true">A+</span>
					</button>
					<button id="theme-toggle" class="a11y-btn" aria-label="<?php esc_attr_e( 'Toggle dark mode', 'sinople' ); ?>" aria-pressed="false" title="<?php esc_attr_e( 'Toggle dark mode', 'sinople' ); ?>">
						<span class="theme-toggle-icon" aria-hidden="true">◐</span>
					</button>
					<button id="contrast-toggle" class="a11y-btn" aria-label="<?php esc_attr_e( 'Toggle high contrast', 'sinople' ); ?>" aria-pressed="false" title="<?php esc_attr_e( 'Toggle high contrast', 'sinople' ); ?>">
						<span aria-hidden="true">◑</span>
					</button>
				</div><!-- .accessibility-controls -->

			</div><!-- .site-branding -->

			<!-- Primary navigation with ARIA -->
			<nav id="site-navigation" class="main-navigation" role="navigation" aria-label="<?php esc_attr_e( 'Primary navigation', 'sinople' ); ?>" itemscope itemtype="https://schema.org/SiteNavigationElement">
				<button class="menu-toggle" aria-controls="primary-menu" aria-expanded="false" aria-label="<?php esc_attr_e( 'Toggle navigation menu', 'sinople' ); ?>">
					<span class="menu-toggle-icon" aria-hidden="true">☰</span>
					<span class="menu-toggle-text"><?php esc_html_e( 'Menu', 'sinople' ); ?></span>
				</button>
				<?php
				wp_nav_menu(
					array(
						'theme_location' => 'primary',
						'menu_id'        => 'primary-menu',
						'menu_class'     => 'primary-menu',
						'container'      => false,
						'fallback_cb'    => false,
						'items_wrap'     => '<ul id="%1$s" class="%2$s" role="menubar">%3$s</ul>',
					)
				);
				?>
			</nav><!-- #site-navigation -->

		</header><!-- #masthead -->

		<?php
		// Breadcrumbs for non-front page views
		if ( ! is_front_page() && function_exists( 'sinople_breadcrumbs' ) ) :
			sinople_breadcrumbs();
		endif;
		?>
