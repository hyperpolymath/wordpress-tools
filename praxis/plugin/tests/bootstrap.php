<?php
/**
 * PHPUnit Bootstrap File
 *
 * Sets up the testing environment for WP Praxis tests
 *
 * @package WPPraxis\Tests
 */

// Composer autoloader
if (file_exists(__DIR__ . '/../../vendor/autoload.php')) {
    require_once __DIR__ . '/../../vendor/autoload.php';
}

// WP Mock setup
if (class_exists('\WP_Mock')) {
    \WP_Mock::bootstrap();
}

// Define test constants
define('WP_PRAXIS_TEST_MODE', true);
define('WP_PRAXIS_TEST_DIR', __DIR__);
define('WP_PRAXIS_FIXTURES_DIR', __DIR__ . '/../../tests/fixtures');

// Mock WordPress functions if WP is not loaded
if (!function_exists('add_action')) {
    function add_action($hook, $callback, $priority = 10, $accepted_args = 1) {
        return true;
    }
}

if (!function_exists('add_filter')) {
    function add_filter($hook, $callback, $priority = 10, $accepted_args = 1) {
        return true;
    }
}

if (!function_exists('wp_verify_nonce')) {
    function wp_verify_nonce($nonce, $action = -1) {
        return true;
    }
}

if (!function_exists('current_user_can')) {
    function current_user_can($capability) {
        return true;
    }
}

if (!function_exists('sanitize_text_field')) {
    function sanitize_text_field($str) {
        return strip_tags($str);
    }
}

// Set up error reporting
error_reporting(E_ALL);
ini_set('display_errors', '1');

// Set timezone
date_default_timezone_set('UTC');

echo "WP Praxis Test Bootstrap Complete\n";
