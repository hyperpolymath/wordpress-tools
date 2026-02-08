<?php
/**
 * PHPUnit bootstrap file
 *
 * @package WP_Plugin_Conflict_Mapper
 */

// Define test environment
define('WPCM_PLUGIN_DIR', dirname(dirname(__FILE__)));

// Load WordPress test environment
$_tests_dir = getenv('WP_TESTS_DIR');

if (!$_tests_dir) {
    $_tests_dir = rtrim(sys_get_temp_dir(), '/\\') . '/wordpress-tests-lib';
}

// Forward custom PHPUnit Polyfills configuration to PHPUnit bootstrap file
if (!defined('WP_TESTS_PHPUNIT_POLYFILLS_PATH')) {
    define('WP_TESTS_PHPUNIT_POLYFILLS_PATH', dirname(dirname(__FILE__)) . '/vendor/yoast/phpunit-polyfills');
}

if (!file_exists("{$_tests_dir}/includes/functions.php")) {
    echo "Could not find {$_tests_dir}/includes/functions.php\n";
    echo "Please run: bash bin/install-wp-tests.sh wordpress_test root '' localhost latest\n";
    exit(1);
}

// Give access to tests_add_filter() function
require_once "{$_tests_dir}/includes/functions.php";

/**
 * Manually load the plugin being tested
 */
function _manually_load_plugin() {
    require WPCM_PLUGIN_DIR . '/wp-plugin-conflict-mapper.php';
}

tests_add_filter('muplugins_loaded', '_manually_load_plugin');

// Start up the WP testing environment
require "{$_tests_dir}/includes/bootstrap.php";
