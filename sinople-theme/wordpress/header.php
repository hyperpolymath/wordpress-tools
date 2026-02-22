<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <?php
    /**
     * Sinople Theme Header — Semantic Document Metadata.
     *
     * This template defines the authoritative document structure for all 
     * pages in the Sinople ecosystem. It ensures that standard metadata 
     * (Charset, Viewport) and WordPress-specific head-matter are correctly 
     * emitted for SEO and accessibility.
     */
    ?>
    <meta charset="<?php bloginfo( 'charset' ); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<div id="page" class="site">
    <header id="masthead" class="site-header" role="banner">
        <?php /** PRIMARY NAVIGATION: Orchestrates the site-wide menu structure. */ ?>
        <nav id="nav" class="main-navigation" role="navigation" aria-label="<?php esc_attr_e( 'Primary Navigation', 'sinople' ); ?>">
            <?php wp_nav_menu( array( 'theme_location' => 'primary' ) ); ?>
        </nav>
    </header>
