<?php
/**
 * PHPUnit bootstrap file for Sinople theme tests
 *
 * @package Sinople
 */

declare(strict_types=1);

// Composer autoloader
require_once dirname( __DIR__ ) . '/vendor/autoload.php';

// Define test constants
define( 'SINOPLE_TESTS_DIR', __DIR__ );
define( 'SINOPLE_THEME_DIR', dirname( __DIR__ ) );

// WordPress test library location (customize for your environment)
$_tests_dir = getenv( 'WP_TESTS_DIR' );
if ( ! $_tests_dir ) {
	$_tests_dir = '/tmp/wordpress-tests-lib';
}

// Check if WordPress test suite is available
if ( ! file_exists( $_tests_dir . '/includes/functions.php' ) ) {
	echo "WordPress test suite not found at: {$_tests_dir}\n";
	echo "Please install WordPress test suite:\n";
	echo "  bash bin/install-wp-tests.sh wordpress_test root '' localhost latest\n";
	exit( 1 );
}

// Load WordPress test functions
require_once $_tests_dir . '/includes/functions.php';

/**
 * Manually load the theme being tested
 */
function _manually_load_theme() {
	// Switch to the Sinople theme
	switch_theme( 'sinople' );

	// Load theme functions
	require SINOPLE_THEME_DIR . '/functions.php';
}
tests_add_filter( 'muplugins_loaded', '_manually_load_theme' );

// Start up the WP testing environment
require $_tests_dir . '/includes/bootstrap.php';

// Load test case base class
require_once SINOPLE_TESTS_DIR . '/php/SinopleTestCase.php';
