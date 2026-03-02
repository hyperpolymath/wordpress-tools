<?php
/**
 * Footer Template
 *
 * Displays the site footer with semantic markup,
 * microformats, and ARIA landmarks.
 *
 * @package Sinople
 * @since 0.1.0
 */
?>

	<footer id="footer" class="site-footer" role="contentinfo" itemscope itemtype="https://schema.org/WPFooter">

		<?php if ( is_active_sidebar( 'footer-widgets' ) ) : ?>
			<div class="footer-widgets">
				<div class="footer-widgets-container">
					<?php dynamic_sidebar( 'footer-widgets' ); ?>
				</div>
			</div>
		<?php endif; ?>

		<div class="site-info">

			<!-- IndieWeb h-card for site identity -->
			<div class="h-card" itemscope itemtype="https://schema.org/Organization">
				<a class="p-name u-url" href="<?php echo esc_url( home_url( '/' ) ); ?>" rel="home" itemprop="url">
					<span itemprop="name"><?php bloginfo( 'name' ); ?></span>
				</a>
				<?php if ( get_bloginfo( 'description' ) ) : ?>
					<span class="p-note" itemprop="description">
						— <?php bloginfo( 'description' ); ?>
					</span>
				<?php endif; ?>
			</div>

			<!-- Copyright and licensing -->
			<div class="copyright" role="contentinfo">
				<p>
					<?php
					printf(
						/* translators: 1: Copyright symbol, 2: Year, 3: Site name */
						esc_html__( '%1$s %2$s %3$s', 'sinople' ),
						'&copy;',
						esc_html( gmdate( 'Y' ) ),
						'<span itemprop="name">' . esc_html( get_bloginfo( 'name' ) ) . '</span>'
					);
					?>
				</p>
				<p class="license-info">
					<?php
					printf(
						/* translators: 1: License name, 2: License URL */
						wp_kses_post( __( 'Content licensed under <a href="%2$s" rel="license">%1$s</a>', 'sinople' ) ),
						'CC BY 4.0',
						'https://creativecommons.org/licenses/by/4.0/'
					);
					?>
				</p>
			</div>

			<!-- Theme credit with semantic markup -->
			<div class="theme-credit">
				<p>
					<?php
					printf(
						/* translators: 1: Theme name, 2: Theme URI */
						wp_kses_post( __( 'Powered by <a href="%2$s" rel="nofollow">%1$s</a>', 'sinople' ) ),
						'Sinople',
						esc_url( 'https://github.com/hyperpolymath/sinople-theme' )
					);
					?>
					<span aria-hidden="true">— stitched with care, contradiction, and quiet resistance.</span>
				</p>
			</div>

			<!-- Privacy and semantic links -->
			<nav class="footer-navigation" role="navigation" aria-label="<?php esc_attr_e( 'Footer navigation', 'sinople' ); ?>">
				<?php
				wp_nav_menu(
					array(
						'theme_location' => 'footer',
						'menu_id'        => 'footer-menu',
						'menu_class'     => 'footer-menu',
						'container'      => false,
						'depth'          => 1,
						'fallback_cb'    => false,
					)
				);
				?>

				<!-- Semantic web endpoints -->
				<ul class="semantic-links">
					<?php if ( function_exists( 'sinople_void_endpoint_url' ) ) : ?>
						<li>
							<a href="<?php echo esc_url( sinople_void_endpoint_url() ); ?>" rel="meta" type="application/rdf+xml">
								<?php esc_html_e( 'VoID Dataset', 'sinople' ); ?>
							</a>
						</li>
					<?php endif; ?>
					<li>
						<a href="<?php echo esc_url( home_url( '/feed/' ) ); ?>" rel="alternate" type="application/rss+xml">
							<?php esc_html_e( 'RSS Feed', 'sinople' ); ?>
						</a>
					</li>
					<li>
						<a href="<?php echo esc_url( home_url( '/feed/json/' ) ); ?>" rel="alternate" type="application/json">
							<?php esc_html_e( 'JSON Feed', 'sinople' ); ?>
						</a>
					</li>
					<?php if ( function_exists( 'sinople_ndjson_feed_url' ) ) : ?>
						<li>
							<a href="<?php echo esc_url( sinople_ndjson_feed_url() ); ?>" rel="alternate" type="application/x-ndjson">
								<?php esc_html_e( 'NDJSON Feed', 'sinople' ); ?>
							</a>
						</li>
					<?php endif; ?>
				</ul>
			</nav>

			<!-- IndieWeb rel-me links -->
			<?php if ( function_exists( 'sinople_get_rel_me_links' ) ) : ?>
				<div class="rel-me-links">
					<?php sinople_get_rel_me_links(); ?>
				</div>
			<?php endif; ?>

		</div><!-- .site-info -->

		<!-- Back to top button (WCAG 2.3 AAA) -->
		<a href="#page" class="back-to-top" aria-label="<?php esc_attr_e( 'Back to top', 'sinople' ); ?>" title="<?php esc_attr_e( 'Back to top', 'sinople' ); ?>">
			<span aria-hidden="true">↑</span>
			<span class="back-to-top-text"><?php esc_html_e( 'Top', 'sinople' ); ?></span>
		</a>

	</footer><!-- #footer -->

</div><!-- #page -->

<?php wp_footer(); ?>

<!-- Service Worker registration (progressive enhancement) -->
<script>
if ('serviceWorker' in navigator && <?php echo wp_json_encode( get_theme_mod( 'sinople_enable_offline', true ) ); ?>) {
	window.addEventListener('load', () => {
		navigator.serviceWorker.register('<?php echo esc_url( SINOPLE_URI . "/sw.js" ); ?>', {
			scope: '<?php echo esc_url( home_url( "/" ) ); ?>'
		}).catch(() => {
			// Silent fail - progressive enhancement
		});
	});
}
</script>

</body>
</html>
