<?php
/**
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Jonathan
 *
 * Plugin Name: WP Plugin Conflict Mapper
 * Plugin URI: https://github.com/Hyperpolymath/wp-plugin-conflict-mapper
 * Description: Advanced plugin overlap and conflict diagnostics with ranked plugin recommendations for WordPress. Detects conflicts, analyzes performance impact, and provides actionable insights.
 * Version: 1.3.0
 * Author: Jonathan
 * Author URI: https://github.com/Hyperpolymath
 * License: AGPL-3.0
 * License URI: https://www.gnu.org/licenses/agpl-3.0.html
 * Text Domain: wp-plugin-conflict-mapper
 * Domain Path: /languages
 * Requires at least: 6.4
 * Requires PHP: 8.2
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// Define plugin constants
define('WPCM_VERSION', '1.3.0');
define('WPCM_PLUGIN_FILE', __FILE__);
define('WPCM_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('WPCM_PLUGIN_URL', plugin_dir_url(__FILE__));
define('WPCM_PLUGIN_BASENAME', plugin_basename(__FILE__));

/**
 * Main Plugin Class
 *
 * @since 1.0.0
 */
class WP_Plugin_Conflict_Mapper {

    /**
     * Single instance of the class
     *
     * @var WP_Plugin_Conflict_Mapper
     */
    private static $instance = null;

    /**
     * Plugin scanner instance
     *
     * @var WPCM_Plugin_Scanner
     */
    public $scanner;

    /**
     * Conflict detector instance
     *
     * @var WPCM_Conflict_Detector
     */
    public $detector;

    /**
     * Admin interface instance
     *
     * @var WPCM_Admin
     */
    public $admin;

    /**
     * Minimal scanner instance
     *
     * @var WPCM_Minimal_Scanner
     */
    public $minimal_scanner;

    /**
     * Get singleton instance
     *
     * @return WP_Plugin_Conflict_Mapper
     */
    public static function instance() {
        if (is_null(self::$instance)) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    /**
     * Constructor
     */
    private function __construct() {
        $this->load_dependencies();
        $this->init_hooks();
    }

    /**
     * Load required files
     *
     * @return void
     */
    private function load_dependencies(): void {
        // Security class (load first)
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-security.php';

        // Core classes
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-plugin-scanner.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-conflict-detector.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-overlap-analyzer.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-ranking-engine.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-database.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-cache.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-security-scanner.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-performance-analyzer.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-minimal-scanner.php';

        // Admin classes
        if (is_admin()) {
            require_once WPCM_PLUGIN_DIR . 'admin/class-wpcm-admin.php';
            require_once WPCM_PLUGIN_DIR . 'admin/class-wpcm-ajax.php';
            require_once WPCM_PLUGIN_DIR . 'admin/class-wpcm-settings.php';
        }

        // REST API
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-rest-api.php';

        // WP-CLI
        if (defined('WP_CLI') && WP_CLI) {
            require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-cli.php';
        }
    }

    /**
     * Initialize WordPress hooks
     *
     * @return void
     */
    private function init_hooks() {
        register_activation_hook(WPCM_PLUGIN_FILE, array($this, 'activate'));
        register_deactivation_hook(WPCM_PLUGIN_FILE, array($this, 'deactivate'));

        add_action('plugins_loaded', array($this, 'init'));
        add_action('init', array($this, 'load_textdomain'));
    }

    /**
     * Initialize plugin
     *
     * @return void
     */
    public function init() {
        $this->scanner = new WPCM_Plugin_Scanner();
        $this->detector = new WPCM_Conflict_Detector();
        $this->minimal_scanner = new WPCM_Minimal_Scanner();

        if (is_admin()) {
            $this->admin = new WPCM_Admin();
        }

        // Initialize REST API
        $rest_api = new WPCM_REST_API();
        $rest_api->init();

        do_action('wpcm_loaded');
    }

    /**
     * Load plugin textdomain for translations
     *
     * @return void
     */
    public function load_textdomain() {
        load_plugin_textdomain(
            'wp-plugin-conflict-mapper',
            false,
            dirname(WPCM_PLUGIN_BASENAME) . '/languages'
        );
    }

    /**
     * Plugin activation
     *
     * @return void
     */
    public function activate() {
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-installer.php';
        WPCM_Installer::activate();
    }

    /**
     * Plugin deactivation
     *
     * @return void
     */
    public function deactivate() {
        // Clear scheduled events
        wp_clear_scheduled_hook('wpcm_scheduled_scan');

        // Clear transients
        delete_transient('wpcm_plugin_scan_cache');
        delete_transient('wpcm_conflict_scan_cache');
    }
}

/**
 * Get main plugin instance
 *
 * @return WP_Plugin_Conflict_Mapper
 */
function wpcm() {
    return WP_Plugin_Conflict_Mapper::instance();
}

// Initialize plugin
wpcm();
