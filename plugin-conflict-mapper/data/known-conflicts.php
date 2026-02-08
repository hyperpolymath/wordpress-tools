<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Known Plugin Conflicts Database
 *
 * Curated database of known conflicts between popular WordPress plugins.
 * Data sourced from community reports, documentation, and testing.
 *
 * @package WP_Plugin_Conflict_Mapper
 * @since 1.3.0
 */

declare(strict_types=1);

if (!defined('ABSPATH')) {
    exit;
}

/**
 * Known conflicts database
 *
 * Structure:
 * - plugin_a: Plugin slug or text domain
 * - plugin_b: Plugin slug or text domain
 * - type: conflict|overlap|incompatible|performance
 * - severity: critical|high|medium|low
 * - description: Human-readable description
 * - affected_versions: Version constraints (optional)
 * - resolution: Suggested fix or workaround
 * - verified: Whether this conflict has been verified
 * - reported_date: When this conflict was first reported
 */
return array(
    // Cache Plugin Conflicts
    array(
        'plugin_a'          => 'w3-total-cache',
        'plugin_b'          => 'wp-super-cache',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Multiple caching plugins cause double caching and cache invalidation issues',
        'resolution'        => 'Use only one caching plugin. Disable or uninstall the other.',
        'verified'          => true,
        'reported_date'     => '2020-01-15',
    ),
    array(
        'plugin_a'          => 'w3-total-cache',
        'plugin_b'          => 'litespeed-cache',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Running multiple cache plugins causes cache conflicts and performance degradation',
        'resolution'        => 'Choose one caching solution. LiteSpeed Cache requires LiteSpeed server.',
        'verified'          => true,
        'reported_date'     => '2021-03-10',
    ),
    array(
        'plugin_a'          => 'wp-super-cache',
        'plugin_b'          => 'wp-fastest-cache',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Duplicate caching functionality leads to serving stale content',
        'resolution'        => 'Use only one caching plugin at a time.',
        'verified'          => true,
        'reported_date'     => '2019-08-22',
    ),
    array(
        'plugin_a'          => 'autoptimize',
        'plugin_b'          => 'wp-rocket',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Both plugins minify CSS/JS causing double minification and broken assets',
        'resolution'        => 'Disable file optimization in Autoptimize when using WP Rocket.',
        'verified'          => true,
        'reported_date'     => '2020-06-14',
    ),

    // SEO Plugin Conflicts
    array(
        'plugin_a'          => 'wordpress-seo',
        'plugin_b'          => 'all-in-one-seo-pack',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Duplicate meta tags, sitemaps, and SEO functionality',
        'resolution'        => 'Use only one SEO plugin. Migrate settings before switching.',
        'verified'          => true,
        'reported_date'     => '2018-01-01',
    ),
    array(
        'plugin_a'          => 'wordpress-seo',
        'plugin_b'          => 'the-seo-framework',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Conflicting meta tags and schema markup output',
        'resolution'        => 'Choose one SEO plugin and fully uninstall the other.',
        'verified'          => true,
        'reported_date'     => '2019-05-20',
    ),
    array(
        'plugin_a'          => 'all-in-one-seo-pack',
        'plugin_b'          => 'rank-math',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Multiple SEO plugins output duplicate meta tags harming SEO',
        'resolution'        => 'Use a single SEO plugin. Rank Math offers import from AIOSEO.',
        'verified'          => true,
        'reported_date'     => '2020-02-28',
    ),

    // Security Plugin Conflicts
    array(
        'plugin_a'          => 'wordfence',
        'plugin_b'          => 'sucuri-scanner',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Multiple firewall plugins can conflict and cause performance issues',
        'resolution'        => 'Use one security plugin or disable firewall in one of them.',
        'verified'          => true,
        'reported_date'     => '2019-11-05',
    ),
    array(
        'plugin_a'          => 'wordfence',
        'plugin_b'          => 'ithemes-security',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Conflicting brute force protection and login security rules',
        'resolution'        => 'Choose one comprehensive security plugin.',
        'verified'          => true,
        'reported_date'     => '2020-04-12',
    ),
    array(
        'plugin_a'          => 'all-in-one-wp-security-and-firewall',
        'plugin_b'          => 'wordfence',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Multiple security plugins increase server load and may block legitimate traffic',
        'resolution'        => 'Select one security solution based on your needs.',
        'verified'          => true,
        'reported_date'     => '2021-01-18',
    ),

    // WooCommerce Conflicts
    array(
        'plugin_a'          => 'woocommerce',
        'plugin_b'          => 'jetpack',
        'type'              => 'conflict',
        'severity'          => 'medium',
        'description'       => 'Jetpack image CDN can break WooCommerce product images',
        'affected_versions' => array('jetpack' => '<10.0'),
        'resolution'        => 'Disable Jetpack Site Accelerator for images or update Jetpack.',
        'verified'          => true,
        'reported_date'     => '2020-08-30',
    ),
    array(
        'plugin_a'          => 'woocommerce',
        'plugin_b'          => 'wp-mail-smtp',
        'type'              => 'conflict',
        'severity'          => 'medium',
        'description'       => 'WooCommerce emails may not send if SMTP not configured correctly',
        'resolution'        => 'Ensure WP Mail SMTP is configured before activating WooCommerce.',
        'verified'          => true,
        'reported_date'     => '2019-07-14',
    ),
    array(
        'plugin_a'          => 'woocommerce',
        'plugin_b'          => 'wp-super-cache',
        'type'              => 'conflict',
        'severity'          => 'high',
        'description'       => 'Cart and checkout pages may show cached content causing checkout issues',
        'resolution'        => 'Exclude cart, checkout, and my-account pages from caching.',
        'verified'          => true,
        'reported_date'     => '2018-12-01',
    ),

    // Page Builder Conflicts
    array(
        'plugin_a'          => 'elementor',
        'plugin_b'          => 'js_composer',
        'type'              => 'conflict',
        'severity'          => 'high',
        'description'       => 'Multiple page builders cause editor conflicts and content corruption',
        'resolution'        => 'Use one page builder per site. Migrate content before switching.',
        'verified'          => true,
        'reported_date'     => '2019-09-22',
    ),
    array(
        'plugin_a'          => 'elementor',
        'plugin_b'          => 'beaver-builder',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Page builders conflict when editing the same content',
        'resolution'        => 'Choose one page builder for your site.',
        'verified'          => true,
        'reported_date'     => '2020-03-17',
    ),
    array(
        'plugin_a'          => 'elementor',
        'plugin_b'          => 'divi-builder',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Multiple visual editors cause JavaScript conflicts and broken layouts',
        'resolution'        => 'Use only one page builder.',
        'verified'          => true,
        'reported_date'     => '2020-05-08',
    ),

    // Backup Plugin Overlaps
    array(
        'plugin_a'          => 'updraftplus',
        'plugin_b'          => 'duplicator',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Running multiple backup plugins wastes server resources',
        'resolution'        => 'Choose one backup solution. UpdraftPlus for backups, Duplicator for migrations.',
        'verified'          => true,
        'reported_date'     => '2020-07-25',
    ),
    array(
        'plugin_a'          => 'updraftplus',
        'plugin_b'          => 'backwpup',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Multiple backup schedules can overload server during execution',
        'resolution'        => 'Use one backup plugin or stagger backup schedules significantly.',
        'verified'          => true,
        'reported_date'     => '2019-04-30',
    ),

    // Form Plugin Conflicts
    array(
        'plugin_a'          => 'contact-form-7',
        'plugin_b'          => 'wpforms-lite',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Loading multiple form plugin assets affects page performance',
        'resolution'        => 'Use one form plugin or load scripts only on pages with forms.',
        'verified'          => true,
        'reported_date'     => '2021-02-14',
    ),
    array(
        'plugin_a'          => 'contact-form-7',
        'plugin_b'          => 'wp-mail-smtp',
        'type'              => 'conflict',
        'severity'          => 'medium',
        'description'       => 'CF7 emails may fail without proper SMTP configuration',
        'resolution'        => 'Configure WP Mail SMTP before using Contact Form 7.',
        'verified'          => true,
        'reported_date'     => '2018-06-10',
    ),

    // Image Optimization Overlaps
    array(
        'plugin_a'          => 'smush',
        'plugin_b'          => 'shortpixel-image-optimiser',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Multiple image optimizers cause over-compression and quality loss',
        'resolution'        => 'Use only one image optimization plugin.',
        'verified'          => true,
        'reported_date'     => '2020-09-05',
    ),
    array(
        'plugin_a'          => 'imagify',
        'plugin_b'          => 'ewww-image-optimizer',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Double optimization degrades image quality unnecessarily',
        'resolution'        => 'Choose one image optimizer based on your needs.',
        'verified'          => true,
        'reported_date'     => '2019-12-20',
    ),
    array(
        'plugin_a'          => 'smush',
        'plugin_b'          => 'imagify',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Running multiple image optimizers wastes resources',
        'resolution'        => 'Select one image optimization solution.',
        'verified'          => true,
        'reported_date'     => '2020-11-12',
    ),

    // Lazy Load Conflicts
    array(
        'plugin_a'          => 'a3-lazy-load',
        'plugin_b'          => 'wp-rocket',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Duplicate lazy loading causes images not to load properly',
        'resolution'        => 'Disable lazy load in a3 Lazy Load when using WP Rocket.',
        'verified'          => true,
        'reported_date'     => '2020-01-28',
    ),
    array(
        'plugin_a'          => 'jetpack',
        'plugin_b'          => 'autoptimize',
        'type'              => 'conflict',
        'severity'          => 'medium',
        'description'       => 'Jetpack lazy load and Autoptimize may conflict on image loading',
        'resolution'        => 'Disable lazy load in one of the plugins.',
        'verified'          => true,
        'reported_date'     => '2021-04-03',
    ),

    // Multilingual Plugin Conflicts
    array(
        'plugin_a'          => 'polylang',
        'plugin_b'          => 'wpml',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Multiple translation plugins cause content duplication and URL conflicts',
        'resolution'        => 'Use only one translation plugin. Migration tools available.',
        'verified'          => true,
        'reported_date'     => '2019-02-15',
    ),
    array(
        'plugin_a'          => 'translatepress-multilingual',
        'plugin_b'          => 'polylang',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Different translation approaches conflict with each other',
        'resolution'        => 'Choose one translation method and plugin.',
        'verified'          => true,
        'reported_date'     => '2020-10-08',
    ),

    // Slider Plugin Overlaps
    array(
        'plugin_a'          => 'revslider',
        'plugin_b'          => 'smartslider3',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Multiple slider plugins load unnecessary assets',
        'resolution'        => 'Use one slider plugin and remove unused ones.',
        'verified'          => true,
        'reported_date'     => '2021-05-20',
    ),

    // Analytics Conflicts
    array(
        'plugin_a'          => 'google-analytics-for-wordpress',
        'plugin_b'          => 'google-site-kit',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Double tracking code causes inflated analytics data',
        'resolution'        => 'Use Site Kit for Google services or MonsterInsights, not both.',
        'verified'          => true,
        'reported_date'     => '2020-12-01',
    ),
    array(
        'plugin_a'          => 'wordpress-seo',
        'plugin_b'          => 'google-site-kit',
        'type'              => 'conflict',
        'severity'          => 'medium',
        'description'       => 'Both plugins may add duplicate verification meta tags',
        'resolution'        => 'Remove site verification from one plugin.',
        'verified'          => true,
        'reported_date'     => '2021-03-25',
    ),

    // Database Optimization Overlaps
    array(
        'plugin_a'          => 'wp-optimize',
        'plugin_b'          => 'wp-sweep',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Multiple database optimizers provide redundant functionality',
        'resolution'        => 'Use one database optimization tool.',
        'verified'          => true,
        'reported_date'     => '2020-04-18',
    ),

    // Comment Plugin Conflicts
    array(
        'plugin_a'          => 'akismet',
        'plugin_b'          => 'antispam-bee',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Running multiple spam filters may cause false positives',
        'resolution'        => 'Choose one anti-spam solution based on privacy needs.',
        'verified'          => true,
        'reported_date'     => '2019-08-10',
    ),
    array(
        'plugin_a'          => 'disqus-comment-system',
        'plugin_b'          => 'akismet',
        'type'              => 'conflict',
        'severity'          => 'low',
        'description'       => 'Akismet does not filter Disqus comments',
        'resolution'        => 'Use Disqus built-in moderation when using Disqus.',
        'verified'          => true,
        'reported_date'     => '2018-11-22',
    ),

    // Redirection Plugin Overlaps
    array(
        'plugin_a'          => 'redirection',
        'plugin_b'          => 'wordpress-seo',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Both plugins offer redirect management causing confusion',
        'resolution'        => 'Use Yoast redirects or Redirection plugin, not both.',
        'verified'          => true,
        'reported_date'     => '2020-06-30',
    ),
    array(
        'plugin_a'          => 'redirection',
        'plugin_b'          => 'rank-math',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Duplicate redirect functionality',
        'resolution'        => 'Choose one plugin for redirect management.',
        'verified'          => true,
        'reported_date'     => '2021-01-05',
    ),

    // CDN and Performance
    array(
        'plugin_a'          => 'jetpack',
        'plugin_b'          => 'cloudflare',
        'type'              => 'conflict',
        'severity'          => 'medium',
        'description'       => 'Jetpack CDN and Cloudflare may conflict on asset delivery',
        'resolution'        => 'Disable Jetpack Site Accelerator when using Cloudflare.',
        'verified'          => true,
        'reported_date'     => '2020-02-14',
    ),

    // GDPR/Cookie Overlaps
    array(
        'plugin_a'          => 'cookie-notice',
        'plugin_b'          => 'gdpr-cookie-compliance',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Multiple cookie consent banners confuse users',
        'resolution'        => 'Use one GDPR/cookie consent plugin.',
        'verified'          => true,
        'reported_date'     => '2020-08-12',
    ),
    array(
        'plugin_a'          => 'complianz-gdpr',
        'plugin_b'          => 'cookie-law-info',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Conflicting cookie consent implementations',
        'resolution'        => 'Select one comprehensive GDPR solution.',
        'verified'          => true,
        'reported_date'     => '2021-02-28',
    ),

    // Social Sharing Overlaps
    array(
        'plugin_a'          => 'social-warfare',
        'plugin_b'          => 'shareaholic',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Multiple social sharing buttons clutter the interface',
        'resolution'        => 'Use one social sharing solution.',
        'verified'          => true,
        'reported_date'     => '2019-10-15',
    ),
    array(
        'plugin_a'          => 'jetpack',
        'plugin_b'          => 'social-warfare',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Jetpack sharing and Social Warfare provide duplicate features',
        'resolution'        => 'Disable Jetpack Sharing or use only Jetpack for social.',
        'verified'          => true,
        'reported_date'     => '2020-05-22',
    ),

    // Login/Registration Conflicts
    array(
        'plugin_a'          => 'theme-my-login',
        'plugin_b'          => 'wps-hide-login',
        'type'              => 'conflict',
        'severity'          => 'high',
        'description'       => 'Custom login plugins may conflict on URL handling',
        'resolution'        => 'Test thoroughly or use one login customization plugin.',
        'verified'          => true,
        'reported_date'     => '2020-09-18',
    ),

    // Membership Plugin Conflicts
    array(
        'plugin_a'          => 'memberpress',
        'plugin_b'          => 'paid-memberships-pro',
        'type'              => 'overlap',
        'severity'          => 'critical',
        'description'       => 'Multiple membership plugins cause access control conflicts',
        'resolution'        => 'Use only one membership plugin.',
        'verified'          => true,
        'reported_date'     => '2019-06-28',
    ),

    // Performance Conflicts
    array(
        'plugin_a'          => 'heartbeat-control',
        'plugin_b'          => 'perfmatters',
        'type'              => 'overlap',
        'severity'          => 'low',
        'description'       => 'Both plugins control WordPress Heartbeat API',
        'resolution'        => 'Configure Heartbeat in one plugin only.',
        'verified'          => true,
        'reported_date'     => '2021-04-10',
    ),
    array(
        'plugin_a'          => 'wp-rocket',
        'plugin_b'          => 'perfmatters',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'Overlapping optimization features may conflict',
        'resolution'        => 'Disable overlapping features in Perfmatters when using WP Rocket.',
        'verified'          => true,
        'reported_date'     => '2020-11-30',
    ),

    // Specific Version Conflicts
    array(
        'plugin_a'          => 'classic-editor',
        'plugin_b'          => 'gutenberg',
        'type'              => 'conflict',
        'severity'          => 'high',
        'description'       => 'Classic Editor disables Gutenberg, both active causes confusion',
        'resolution'        => 'Choose one editor. Classic Editor for old editor, remove Gutenberg.',
        'verified'          => true,
        'reported_date'     => '2018-12-15',
    ),

    // Minification Conflicts
    array(
        'plugin_a'          => 'fast-velocity-minify',
        'plugin_b'          => 'autoptimize',
        'type'              => 'overlap',
        'severity'          => 'high',
        'description'       => 'Multiple minification plugins cause broken scripts and styles',
        'resolution'        => 'Use one minification solution.',
        'verified'          => true,
        'reported_date'     => '2020-03-05',
    ),
    array(
        'plugin_a'          => 'w3-total-cache',
        'plugin_b'          => 'autoptimize',
        'type'              => 'overlap',
        'severity'          => 'medium',
        'description'       => 'W3TC minification conflicts with Autoptimize',
        'resolution'        => 'Disable minification in W3TC when using Autoptimize.',
        'verified'          => true,
        'reported_date'     => '2019-07-20',
    ),

    // Query Monitor Compatibility
    array(
        'plugin_a'          => 'query-monitor',
        'plugin_b'          => 'w3-total-cache',
        'type'              => 'conflict',
        'severity'          => 'low',
        'description'       => 'Query Monitor may not show accurate data with page caching enabled',
        'resolution'        => 'Disable page cache when debugging with Query Monitor.',
        'verified'          => true,
        'reported_date'     => '2020-07-08',
    ),
);
