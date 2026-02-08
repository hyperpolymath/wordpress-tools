<?php
/**
 * Theme Customizer for Sinople Theme
 *
 * @package Sinople
 * @since 1.0.0
 */

declare(strict_types=1);

// Prevent direct access
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function sinople_customize_register( $wp_customize ) {
    $wp_customize->add_setting( 'sinople_high_contrast_mode', array(
        'default' => false,
        'transport' => 'refresh',
    ));
}
add_action( 'customize_register', 'sinople_customize_register' );
