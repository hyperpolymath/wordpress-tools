<?php
/**
 * Modern Browser Features
 *
 * View Transitions API, Scroll-driven Animations, Container Queries,
 * :has() selector support, and other experimental features.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Add View Transitions API support
 */
function sinople_view_transitions_meta() {
	if ( ! get_theme_mod( 'sinople_view_transitions', true ) ) {
		return;
	}

	// Enable View Transitions API
	?>
	<meta name="view-transition" content="same-origin">
	<style>
		@view-transition {
			navigation: auto;
		}

		/* Customize transitions */
		::view-transition-old(root),
		::view-transition-new(root) {
			animation-duration: 0.3s;
		}

		::view-transition-old(main) {
			animation: fade-out 0.3s ease-out;
		}

		::view-transition-new(main) {
			animation: fade-in 0.3s ease-in;
		}

		@keyframes fade-out {
			to { opacity: 0; }
		}

		@keyframes fade-in {
			from { opacity: 0; }
		}

		/* Respect prefers-reduced-motion */
		@media (prefers-reduced-motion: reduce) {
			::view-transition-old(root),
			::view-transition-new(root) {
				animation: none !important;
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_view_transitions_meta' );

/**
 * Add scroll-driven animations CSS
 */
function sinople_scroll_driven_animations() {
	if ( ! get_theme_mod( 'sinople_scroll_animations', true ) ) {
		return;
	}

	?>
	<style>
		/* Scroll-driven animations for progressive disclosure */
		@supports (animation-timeline: scroll()) {
			.reveal-on-scroll {
				animation: reveal linear;
				animation-timeline: view();
				animation-range: entry 0% cover 30%;
			}

			@keyframes reveal {
				from {
					opacity: 0;
					transform: translateY(2rem);
				}
				to {
					opacity: 1;
					transform: translateY(0);
				}
			}

			/* Respect reduced motion */
			@media (prefers-reduced-motion: reduce) {
				.reveal-on-scroll {
					animation: none;
				}
			}
		}

		/* Scroll-linked progress indicator */
		@supports (animation-timeline: scroll()) {
			.reading-progress {
				position: fixed;
				top: 0;
				left: 0;
				height: 4px;
				background: var(--accent-color, #0066cc);
				transform-origin: left;
				animation: progress-bar linear;
				animation-timeline: scroll(root);
				z-index: 9999;
			}

			@keyframes progress-bar {
				from { transform: scaleX(0); }
				to { transform: scaleX(1); }
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_scroll_driven_animations', 99 );

/**
 * Add container query support CSS
 */
function sinople_container_queries() {
	?>
	<style>
		/* Container queries for responsive components */
		@supports (container-type: inline-size) {
			.post-card-container {
				container-type: inline-size;
				container-name: card;
			}

			@container card (min-width: 400px) {
				.post-card {
					display: grid;
					grid-template-columns: 200px 1fr;
					gap: 1rem;
				}
			}

			@container card (min-width: 600px) {
				.post-card {
					grid-template-columns: 300px 1fr;
				}
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_container_queries', 99 );

/**
 * Add :has() selector support CSS
 */
function sinople_has_selector() {
	?>
	<style>
		/* :has() selector for parent styling */
		@supports selector(:has(*)) {
			/* Style card differently if it has an image */
			.post-card:has(img) {
				background: var(--card-with-image-bg, #f9f9f9);
			}

			/* Adjust layout if sidebar has content */
			.site-container:has(.sidebar:not(:empty)) {
				grid-template-columns: 1fr 300px;
			}

			/* Highlight nav item for current section */
			.main-navigation:has(.current-menu-item) {
				border-bottom: 2px solid var(--accent-color);
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_has_selector', 99 );

/**
 * Add popover API support
 */
function sinople_popover_api() {
	?>
	<style>
		/* Popover API styling */
		@supports (top-layer: auto) {
			[popover] {
				padding: 1rem;
				border: 1px solid var(--border-color, #ddd);
				border-radius: 4px;
				background: var(--popover-bg, white);
				box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
			}

			[popover]::backdrop {
				background: rgba(0, 0, 0, 0.3);
			}

			/* Popover animations */
			[popover]:popover-open {
				animation: popover-in 0.2s ease-out;
			}

			@keyframes popover-in {
				from {
					opacity: 0;
					transform: scale(0.9);
				}
				to {
					opacity: 1;
					transform: scale(1);
				}
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_popover_api', 99 );

/**
 * Add anchor positioning CSS
 */
function sinople_anchor_positioning() {
	?>
	<style>
		/* CSS Anchor Positioning */
		@supports (anchor-name: --target) {
			.tooltip-anchor {
				anchor-name: --tooltip-target;
			}

			.tooltip {
				position: absolute;
				position-anchor: --tooltip-target;
				bottom: anchor(top);
				left: anchor(center);
				translate: -50% 0;
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_anchor_positioning', 99 );

/**
 * Add color-mix() support
 */
function sinople_color_mix() {
	?>
	<style>
		/* color-mix() for dynamic theming */
		@supports (color: color-mix(in oklch, red, blue)) {
			:root {
				--primary-lighter: color-mix(in oklch, var(--primary-color), white 20%);
				--primary-darker: color-mix(in oklch, var(--primary-color), black 20%);
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_color_mix', 99 );

/**
 * Add relative color syntax support
 */
function sinople_relative_colors() {
	?>
	<style>
		/* Relative color syntax */
		@supports (color: oklch(from white l c h)) {
			:root {
				--text-muted: oklch(from var(--text-color) calc(l * 0.7) c h);
				--bg-subtle: oklch(from var(--bg-color) calc(l * 1.05) c h);
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_relative_colors', 99 );

/**
 * Add subgrid support
 */
function sinople_subgrid() {
	?>
	<style>
		/* Subgrid for nested layouts */
		@supports (grid-template-columns: subgrid) {
			.nested-grid {
				display: grid;
				grid-template-columns: subgrid;
				grid-column: 1 / -1;
			}
		}
	</style>
	<?php
}
add_action( 'wp_head', 'sinople_subgrid', 99 );

/**
 * Add WebRTC support detection
 */
function sinople_webrtc_support() {
	?>
	<script>
		if ('RTCPeerConnection' in window) {
			document.documentElement.classList.add('has-webrtc');
		}
	</script>
	<?php
}
add_action( 'wp_footer', 'sinople_webrtc_support' );

/**
 * Add WebCodecs API support detection
 */
function sinople_webcodecs_support() {
	?>
	<script>
		if ('VideoEncoder' in window && 'VideoDecoder' in window) {
			document.documentElement.classList.add('has-webcodecs');
		}
	</script>
	<?php
}
add_action( 'wp_footer', 'sinople_webcodecs_support' );

/**
 * Add WebGPU support detection
 */
function sinople_webgpu_support() {
	?>
	<script>
		if ('gpu' in navigator) {
			document.documentElement.classList.add('has-webgpu');
		}
	</script>
	<?php
}
add_action( 'wp_footer', 'sinople_webgpu_support' );

/**
 * Add File System Access API support
 */
function sinople_file_system_access() {
	?>
	<script>
		if ('showOpenFilePicker' in window) {
			document.documentElement.classList.add('has-file-system-access');
		}
	</script>
	<?php
}
add_action( 'wp_footer', 'sinople_file_system_access' );

/**
 * Add Web Share API support
 */
function sinople_web_share_api() {
	?>
	<script>
		if ('share' in navigator) {
			document.documentElement.classList.add('has-web-share');

			// Add share buttons where appropriate
			document.querySelectorAll('[data-share]').forEach(btn => {
				btn.addEventListener('click', async () => {
					try {
						await navigator.share({
							title: document.title,
							text: btn.dataset.shareText || '',
							url: btn.dataset.shareUrl || window.location.href
						});
					} catch (err) {
						console.warn('Share failed:', err);
					}
				});
			});
		}
	</script>
	<?php
}
add_action( 'wp_footer', 'sinople_web_share_api' );
