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

// ... [Remainder of functions implementation]
