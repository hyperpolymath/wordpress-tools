<?php
/**
 * WP Plugin Conflict Mapper — Main Entry Point.
 *
 * This plugin provides advanced diagnostics for identifying overlaps and 
 * conflicts between active WordPress plugins. It uses a multi-stage 
 * scanning process to evaluate performance impact and security risks.
 *
 * DESIGN PATTERNS:
 * 1. **Singleton**: The `WP_Plugin_Conflict_Mapper` class manages the 
 *    global plugin instance and its component services.
 * 2. **Dependency Injection**: Core logic is delegated to specialized 
 *    classes (`Scanner`, `Detector`, `Analyzer`).
 * 3. **Reflexive Audit**: The plugin includes a `Security_Scanner` to 
 *    monitor the safety of the plugins it analyzes.
 *
 * @package WP_Plugin_Conflict_Mapper
 */

declare(strict_types=1);

if (!defined('ABSPATH')) { exit; }

class WP_Plugin_Conflict_Mapper {
    private static $instance = null;
    public $scanner;
    public $detector;
    public $admin;

    public static function instance() {
        if (is_null(self::$instance)) { self::$instance = new self(); }
        return self::$instance;
    }

    /**
     * BOOTSTRAP: Loads the architectural layers of the plugin.
     * Note: `class-wpcm-security.php` is loaded FIRST to ensure all 
     * subsequent file operations and input handling are protected.
     */
    private function load_dependencies(): void {
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-security.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-plugin-scanner.php';
        require_once WPCM_PLUGIN_DIR . 'includes/class-wpcm-conflict-detector.php';
        // ... [Loading logic for Analyzers, Database, and API]
    }

    /**
     * INITIALIZATION: Hooks into the WordPress `plugins_loaded` event.
     * Spawns the logical engines and prepares the REST API namespace.
     */
    public function init() {
        $this->scanner = new WPCM_Plugin_Scanner();
        $this->detector = new WPCM_Conflict_Detector();
        // ... [Init logic for Admin and REST services]
    }
}

// INSTANTIATION: Start the plugin services.
function wpcm() { return WP_Plugin_Conflict_Mapper::instance(); }
wpcm();
