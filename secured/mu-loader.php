<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * Plugin Name: php-aegis Security Stack
 * Description: Automatic security enforcement via php-aegis
 * Version: 1.0.0
 * Author: Hyperpolymath
 */

// Autoload php-aegis classes
spl_autoload_register(function ($class) {
    $prefix = 'PhpAegis\\';
    $base_dir = __DIR__ . '/php-aegis/src/';

    $len = strlen($prefix);
    if (strncmp($prefix, $class, $len) !== 0) {
        return;
    }

    $relative_class = substr($class, $len);
    $file = $base_dir . str_replace('\\', '/', $relative_class) . '.php';

    if (file_exists($file)) {
        require $file;
    }
});

use PhpAegis\WordPress\Adapter;
use PhpAegis\Security\Headers;
use PhpAegis\RateLimit\RateLimiter;
use PhpAegis\RateLimit\Storage\FileStore;
use PhpAegis\IndieWeb\MicropubSecurity;
use PhpAegis\IndieWeb\WebmentionSecurity;

// Security Headers - Applied on every request
add_action('send_headers', function() {
    $headers = new Headers();

    // Content Security Policy
    $headers->setCSP([
        'default-src' => ["'self'"],
        'script-src' => ["'self'", "'unsafe-inline'", "'unsafe-eval'"], // WordPress admin needs inline scripts
        'style-src' => ["'self'", "'unsafe-inline'"],
        'img-src' => ["'self'", 'data:', 'https:'],
        'font-src' => ["'self'", 'data:'],
        'connect-src' => ["'self'"],
        'frame-ancestors' => ["'self'"]
    ]);

    // HSTS - Force HTTPS for 1 year
    $headers->setHSTS(31536000, true);

    // Prevent clickjacking
    $headers->setXFrameOptions('SAMEORIGIN');

    // Additional security headers
    $headers->setXContentTypeOptions('nosniff');
    $headers->setReferrerPolicy('strict-origin-when-cross-origin');

    $headers->send();
}, 1);

// Rate Limiting - 10 requests per minute per IP
$rateLimiter = RateLimiter::perMinute(10, new FileStore('/tmp/rate-limit'));

add_action('init', function() use ($rateLimiter) {
    $ip = $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';

    if (!$rateLimiter->attempt($ip)) {
        http_response_code(429);
        header('Retry-After: 60');
        die('Rate limit exceeded. Please try again later.');
    }
}, 1);

// Input Sanitization - WordPress Integration
add_filter('sanitize_text_field', [Adapter::class, 'sanitizeTextField'], 10, 1);
add_filter('sanitize_textarea_field', [Adapter::class, 'sanitizeTextarea'], 10, 1);
add_filter('sanitize_email', [Adapter::class, 'sanitizeEmail'], 10, 1);
add_filter('sanitize_url', [Adapter::class, 'sanitizeUrl'], 10, 1);

// Comment sanitization with XSS prevention
add_filter('pre_comment_content', function($content) {
    return Adapter::sanitizeComment($content);
}, 1);

// IndieWeb Security - Micropub endpoint protection
add_filter('micropub_post_content', function($content) {
    $security = new MicropubSecurity();
    return $security->sanitizeContent($content);
}, 1);

// IndieWeb Security - Webmention SSRF prevention
add_filter('webmention_target_url', function($url) {
    $security = new WebmentionSecurity();

    if (!$security->validateTargetUrl($url)) {
        return new WP_Error('invalid_url', 'Target URL failed security validation');
    }

    return $url;
}, 1);

// Block XMLRPC (common DDoS/brute force target)
add_filter('xmlrpc_enabled', '__return_false');

// Disable file editing from admin panel
define('DISALLOW_FILE_EDIT', true);

// Log security events
add_action('php_aegis_security_event', function($event_type, $details) {
    error_log(sprintf(
        '[php-aegis] Security Event: %s | Details: %s | IP: %s',
        $event_type,
        json_encode($details),
        $_SERVER['REMOTE_ADDR'] ?? 'unknown'
    ));
}, 10, 2);
