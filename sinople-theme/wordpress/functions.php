<?php
/**
 * Sinople Theme — High-Assurance WordPress Core Logic.
 *
 * This module orchestrates the foundational services for the Sinople theme, 
 * integrating security, semantic web processing, and accessibility.
 *
 * KEY INTEGRATIONS:
 * 1. **PhpAegis**: Provides robust input validation and response header security.
 * 2. **Libravatar**: Uses free/open-source avatars instead of proprietary Gravatar.
 * 3. **Secure SMTP**: Forces encrypted email transport via PHPMailer hooks.
 * 4. **Semantic Web**: Prepares the environment for Turtle/RDFa embedding.
 *
 * @package Sinople
 * @since 1.0.0
 */

declare(strict_types=1);

// BOOTSTRAP: Load the security library. 
// PhpAegis handles XSS prevention and CSP header management.
require_once get_template_directory() . '/vendor/php-aegis/autoload.php';

/**
 * THEME SETUP: Registers capabilities with the WordPress core.
 * Enables modern features like responsive embeds and HTML5 markup.
 */
function sinople_theme_setup() {
    // ACCESSIBILITY: Switches default core markup to semantic HTML5.
    add_theme_support( 'html5', array(
        'search-form', 'comment-form', 'comment-list', 'gallery', 'caption',
    ) );

    // VISUALS: Enables thumbnails and standard responsive image sizes.
    add_theme_support( 'post-thumbnails' );
    set_post_thumbnail_size( 1200, 630, true );
}
add_action( 'after_setup_theme', 'sinople_theme_setup' );

/**
 * SECURITY: Enforces encrypted SMTP for all outgoing mail.
 * Blocks insecure connections on Port 25.
 */
function sinople_configure_secure_smtp( $phpmailer ) {
    if ( $phpmailer->Mailer === 'smtp' || ! empty( $phpmailer->Host ) ) {
        $phpmailer->SMTPSecure = get_option( 'sinople_smtp_secure', 'tls' );
        // Ensure we don't fall back to unencrypted port 25.
        if ( $phpmailer->Port == 25 ) {
            $phpmailer->Port = 587; 
        }
    }
}
add_action( 'phpmailer_init', 'sinople_configure_secure_smtp', 10 );

/**
 * SECURITY HARDENING: Defaults applied on theme activation.
 * These reduce the attack surface of a default WordPress install.
 * All can be overridden via the theme customizer or wp-config.php.
 *
 * Dogfooding lesson C1: Never redefine constants already set in wp-config.php.
 * Dogfooding lesson P3: Bake security defaults into the theme.
 *
 * @since 2.0.3
 */
function sinople_security_hardening() {
    // Disable the built-in theme/plugin file editor (defence in depth).
    if ( ! defined( 'DISALLOW_FILE_EDIT' ) ) {
        define( 'DISALLOW_FILE_EDIT', true );
    }

    // Remove WordPress version from HTML head and RSS feeds.
    remove_action( 'wp_head', 'wp_generator' );

    // Disable XML-RPC unless explicitly enabled via filter.
    if ( ! has_filter( 'sinople_enable_xmlrpc' ) ) {
        add_filter( 'xmlrpc_enabled', '__return_false' );
    }

    // Disable pingbacks and trackbacks by default.
    add_filter( 'pings_open', '__return_false', 20, 2 );

    // Remove Windows Live Writer manifest link.
    remove_action( 'wp_head', 'wlwmanifest_link' );

    // Remove RSD (Really Simple Discovery) link.
    remove_action( 'wp_head', 'rsd_link' );

    // Remove shortlink from head.
    remove_action( 'wp_head', 'wp_shortlink_wp_head' );

    // Remove REST API discovery link from head (API still works).
    remove_action( 'wp_head', 'rest_output_link_wp_head' );

    // Remove oEmbed discovery links.
    remove_action( 'wp_head', 'wp_oembed_add_discovery_links' );
}
add_action( 'after_setup_theme', 'sinople_security_hardening' );

/**
 * PERFORMANCE: Register theme support for modern navigation and menus.
 *
 * @since 2.0.3
 */
function sinople_register_menus() {
    register_nav_menus( array(
        'primary' => __( 'Primary Menu', 'sinople' ),
        'footer'  => __( 'Footer Menu', 'sinople' ),
    ) );
}
add_action( 'after_setup_theme', 'sinople_register_menus' );

/**
 * PERFORMANCE: Enqueue theme stylesheet with cache-busting version.
 *
 * @since 2.0.3
 */
function sinople_enqueue_styles() {
    wp_enqueue_style(
        'sinople-style',
        get_stylesheet_uri(),
        array(),
        '2.0.3'
    );
}
add_action( 'wp_enqueue_scripts', 'sinople_enqueue_styles' );

/**
 * SECURITY: Add security headers via PHP when not handled by the web server.
 * LiteSpeed and Cloudflare handle most of these, but this provides defence
 * in depth for environments without those layers.
 *
 * @since 2.0.3
 */
function sinople_security_headers() {
    if ( ! is_admin() && ! headers_sent() ) {
        header( 'X-Content-Type-Options: nosniff' );
        header( 'X-Frame-Options: SAMEORIGIN' );
        header( 'Referrer-Policy: strict-origin-when-cross-origin' );
        header( 'Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=()' );
    }
}
add_action( 'send_headers', 'sinople_security_headers' );
