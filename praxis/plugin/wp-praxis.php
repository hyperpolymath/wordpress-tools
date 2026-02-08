<?php
/**
 * Plugin Name: WP Praxis
 * Plugin URI: https://github.com/wp-praxis/wp-praxis
 * Description: Modular symbolic system for WordPress workflows - Declarative orchestration through recursive logic and metadata-driven configuration
 * Version: 0.1.0
 * Requires at least: 5.8
 * Requires PHP: 7.4
 * Author: WP Praxis Project
 * Author URI: https://github.com/wp-praxis
 * License: AGPL-3.0-or-later
 * License URI: https://www.gnu.org/licenses/agpl-3.0.html
 * Text Domain: wp-praxis
 * Domain Path: /languages
 *
 * @package WPPraxis
 */

// Exit if accessed directly
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

// Define plugin constants
define( 'WP_PRAXIS_VERSION', '0.1.0' );
define( 'WP_PRAXIS_PLUGIN_FILE', __FILE__ );
define( 'WP_PRAXIS_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( 'WP_PRAXIS_PLUGIN_URL', plugin_dir_url( __FILE__ ) );
define( 'WP_PRAXIS_ENGINE_PATH', dirname( __DIR__ ) . '/engine/php/' );

/**
 * Main WP Praxis Plugin Class
 */
class WP_Praxis {
	/**
	 * Plugin instance
	 *
	 * @var WP_Praxis|null
	 */
	private static $instance = null;

	/**
	 * Symbolic engine instance
	 *
	 * @var \WPPraxis\Engine\SymbolicEngine|null
	 */
	private $engine = null;

	/**
	 * Plugin settings
	 *
	 * @var array
	 */
	private $settings = array();

	/**
	 * Get plugin instance (singleton)
	 *
	 * @return WP_Praxis
	 */
	public static function get_instance() {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}
		return self::$instance;
	}

	/**
	 * Constructor
	 */
	private function __construct() {
		// Load composer autoloader if available
		$this->load_autoloader();

		// Load symbolic engine
		$this->load_engine();

		// Initialize hooks
		$this->init_hooks();
	}

	/**
	 * Load composer autoloader
	 */
	private function load_autoloader() {
		$engine_autoload = WP_PRAXIS_ENGINE_PATH . 'vendor/autoload.php';

		if ( file_exists( $engine_autoload ) ) {
			require_once $engine_autoload;
		}

		// Load engine files manually if autoloader not available
		if ( ! class_exists( '\WPPraxis\Engine\Symbol' ) ) {
			require_once WP_PRAXIS_ENGINE_PATH . 'Symbol.php';
		}

		if ( ! class_exists( '\WPPraxis\Engine\SymbolicEngine' ) ) {
			require_once WP_PRAXIS_ENGINE_PATH . 'symbolic-engine.php';
		}
	}

	/**
	 * Load symbolic engine
	 */
	private function load_engine() {
		// Get settings
		$this->settings = $this->get_settings();

		// Configure engine
		$engine_config = array(
			'manifest_path'  => $this->settings['manifest_path'] ?? '',
			'state_backend'  => $this->settings['state_backend'] ?? 'database',
			'state_table'    => 'praxis_state',
			'debug'          => $this->settings['debug'] ?? WP_DEBUG,
			'auto_register'  => $this->settings['auto_register'] ?? true,
			'injector_path'  => $this->settings['injector_path'] ?? '/home/user/wp-praxis/wp_injector/target/release/wp_injector',
			'ps_script_path' => $this->settings['ps_script_path'] ?? '/home/user/wp-praxis/SymbolicEngine/core/symbolic.ps1',
		);

		// Create engine instance
		$this->engine = new \WPPraxis\Engine\SymbolicEngine( $engine_config );

		// Set logger
		$this->engine->set_logger( array( $this, 'log_message' ) );

		// Initialize engine
		$this->engine->initialize();
	}

	/**
	 * Initialize WordPress hooks
	 */
	private function init_hooks() {
		// Activation/deactivation hooks
		register_activation_hook( WP_PRAXIS_PLUGIN_FILE, array( $this, 'activate' ) );
		register_deactivation_hook( WP_PRAXIS_PLUGIN_FILE, array( $this, 'deactivate' ) );

		// Admin hooks
		add_action( 'admin_menu', array( $this, 'add_admin_menu' ) );
		add_action( 'admin_init', array( $this, 'register_settings' ) );
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_admin_assets' ) );

		// AJAX hooks
		add_action( 'wp_ajax_wp_praxis_execute_symbol', array( $this, 'ajax_execute_symbol' ) );
		add_action( 'wp_ajax_wp_praxis_upload_manifest', array( $this, 'ajax_upload_manifest' ) );
		add_action( 'wp_ajax_wp_praxis_introspect', array( $this, 'ajax_introspect' ) );

		// REST API hooks
		add_action( 'rest_api_init', array( $this, 'register_rest_routes' ) );

		// Symbolic lifecycle hooks
		add_action( 'wp_praxis_before_execute', array( $this, 'before_symbol_execute' ), 10, 2 );
		add_action( 'wp_praxis_after_execute', array( $this, 'after_symbol_execute' ), 10, 3 );

		// Load text domain
		add_action( 'plugins_loaded', array( $this, 'load_textdomain' ) );
	}

	/**
	 * Plugin activation
	 */
	public function activate() {
		// Create database table if using database backend
		if ( 'database' === ( $this->settings['state_backend'] ?? 'database' ) ) {
			$this->engine->create_state_table();
		}

		// Create upload directory for manifests
		$upload_dir = wp_upload_dir();
		$praxis_dir = $upload_dir['basedir'] . '/wp-praxis';

		if ( ! file_exists( $praxis_dir ) ) {
			wp_mkdir_p( $praxis_dir );

			// Add .htaccess to protect manifest files
			$htaccess = $praxis_dir . '/.htaccess';
			if ( ! file_exists( $htaccess ) ) {
				file_put_contents( $htaccess, 'Deny from all' );
			}
		}

		// Set default options
		if ( false === get_option( 'wp_praxis_settings' ) ) {
			update_option(
				'wp_praxis_settings',
				array(
					'state_backend' => 'database',
					'debug'         => false,
					'auto_register' => true,
				)
			);
		}

		// Flush rewrite rules
		flush_rewrite_rules();

		// Log activation
		$this->log_message( 'info', 'WP Praxis activated', array( 'version' => WP_PRAXIS_VERSION ) );
	}

	/**
	 * Plugin deactivation
	 */
	public function deactivate() {
		// Clear scheduled events
		wp_clear_scheduled_hook( 'wp_praxis_cleanup' );

		// Flush rewrite rules
		flush_rewrite_rules();

		// Log deactivation
		$this->log_message( 'info', 'WP Praxis deactivated' );

		// Note: We don't drop the database table on deactivation
		// Users can manually remove it if needed
	}

	/**
	 * Add admin menu
	 */
	public function add_admin_menu() {
		add_menu_page(
			__( 'WP Praxis', 'wp-praxis' ),
			__( 'WP Praxis', 'wp-praxis' ),
			'manage_options',
			'wp-praxis',
			array( $this, 'render_admin_page' ),
			'dashicons-networking',
			80
		);

		add_submenu_page(
			'wp-praxis',
			__( 'Settings', 'wp-praxis' ),
			__( 'Settings', 'wp-praxis' ),
			'manage_options',
			'wp-praxis-settings',
			array( $this, 'render_settings_page' )
		);

		add_submenu_page(
			'wp-praxis',
			__( 'Symbols', 'wp-praxis' ),
			__( 'Symbols', 'wp-praxis' ),
			'manage_options',
			'wp-praxis-symbols',
			array( $this, 'render_symbols_page' )
		);

		add_submenu_page(
			'wp-praxis',
			__( 'Introspection', 'wp-praxis' ),
			__( 'Introspection', 'wp-praxis' ),
			'manage_options',
			'wp-praxis-introspection',
			array( $this, 'render_introspection_page' )
		);
	}

	/**
	 * Register settings
	 */
	public function register_settings() {
		register_setting(
			'wp_praxis_settings',
			'wp_praxis_settings',
			array(
				'sanitize_callback' => array( $this, 'sanitize_settings' ),
			)
		);

		// General settings section
		add_settings_section(
			'wp_praxis_general',
			__( 'General Settings', 'wp-praxis' ),
			array( $this, 'render_general_section' ),
			'wp-praxis-settings'
		);

		// Manifest path setting
		add_settings_field(
			'manifest_path',
			__( 'Manifest Path', 'wp-praxis' ),
			array( $this, 'render_manifest_path_field' ),
			'wp-praxis-settings',
			'wp_praxis_general'
		);

		// State backend setting
		add_settings_field(
			'state_backend',
			__( 'State Backend', 'wp-praxis' ),
			array( $this, 'render_state_backend_field' ),
			'wp-praxis-settings',
			'wp_praxis_general'
		);

		// Debug mode setting
		add_settings_field(
			'debug',
			__( 'Debug Mode', 'wp-praxis' ),
			array( $this, 'render_debug_field' ),
			'wp-praxis-settings',
			'wp_praxis_general'
		);

		// Auto-register setting
		add_settings_field(
			'auto_register',
			__( 'Auto-Register Symbols', 'wp-praxis' ),
			array( $this, 'render_auto_register_field' ),
			'wp-praxis-settings',
			'wp_praxis_general'
		);
	}

	/**
	 * Sanitize settings
	 *
	 * @param array $input Settings input.
	 * @return array Sanitized settings.
	 */
	public function sanitize_settings( $input ) {
		$sanitized = array();

		if ( isset( $input['manifest_path'] ) ) {
			$sanitized['manifest_path'] = sanitize_text_field( $input['manifest_path'] );
		}

		if ( isset( $input['state_backend'] ) ) {
			$allowed_backends           = array( 'database', 'file', 'memory' );
			$sanitized['state_backend'] = in_array( $input['state_backend'], $allowed_backends, true )
				? $input['state_backend']
				: 'database';
		}

		$sanitized['debug']         = ! empty( $input['debug'] );
		$sanitized['auto_register'] = ! empty( $input['auto_register'] );

		if ( isset( $input['injector_path'] ) ) {
			$sanitized['injector_path'] = sanitize_text_field( $input['injector_path'] );
		}

		if ( isset( $input['ps_script_path'] ) ) {
			$sanitized['ps_script_path'] = sanitize_text_field( $input['ps_script_path'] );
		}

		return $sanitized;
	}

	/**
	 * Enqueue admin assets
	 *
	 * @param string $hook Current admin page hook.
	 */
	public function enqueue_admin_assets( $hook ) {
		// Only load on WP Praxis pages
		if ( strpos( $hook, 'wp-praxis' ) === false ) {
			return;
		}

		// Enqueue CSS
		wp_enqueue_style(
			'wp-praxis-admin',
			WP_PRAXIS_PLUGIN_URL . 'admin/css/admin.css',
			array(),
			WP_PRAXIS_VERSION
		);

		// Enqueue JavaScript
		wp_enqueue_script(
			'wp-praxis-admin',
			WP_PRAXIS_PLUGIN_URL . 'admin/js/admin.js',
			array( 'jquery' ),
			WP_PRAXIS_VERSION,
			true
		);

		// Localize script
		wp_localize_script(
			'wp-praxis-admin',
			'wpPraxis',
			array(
				'ajaxUrl' => admin_url( 'admin-ajax.php' ),
				'nonce'   => wp_create_nonce( 'wp_praxis_nonce' ),
				'strings' => array(
					'confirm'        => __( 'Are you sure?', 'wp-praxis' ),
					'error'          => __( 'An error occurred', 'wp-praxis' ),
					'success'        => __( 'Operation completed successfully', 'wp-praxis' ),
					'executing'      => __( 'Executing...', 'wp-praxis' ),
					'uploadSuccess'  => __( 'Manifest uploaded successfully', 'wp-praxis' ),
					'uploadError'    => __( 'Failed to upload manifest', 'wp-praxis' ),
				),
			)
		);
	}

	/**
	 * Render admin page
	 */
	public function render_admin_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have sufficient permissions to access this page.', 'wp-praxis' ) );
		}

		include WP_PRAXIS_PLUGIN_DIR . 'admin/dashboard.php';
	}

	/**
	 * Render settings page
	 */
	public function render_settings_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have sufficient permissions to access this page.', 'wp-praxis' ) );
		}

		include WP_PRAXIS_PLUGIN_DIR . 'admin/settings.php';
	}

	/**
	 * Render symbols page
	 */
	public function render_symbols_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have sufficient permissions to access this page.', 'wp-praxis' ) );
		}

		include WP_PRAXIS_PLUGIN_DIR . 'admin/symbols.php';
	}

	/**
	 * Render introspection page
	 */
	public function render_introspection_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'You do not have sufficient permissions to access this page.', 'wp-praxis' ) );
		}

		include WP_PRAXIS_PLUGIN_DIR . 'admin/introspection.php';
	}

	/**
	 * Render general settings section
	 */
	public function render_general_section() {
		echo '<p>' . esc_html__( 'Configure the symbolic engine behavior and storage options.', 'wp-praxis' ) . '</p>';
	}

	/**
	 * Render manifest path field
	 */
	public function render_manifest_path_field() {
		$value = $this->settings['manifest_path'] ?? '';
		?>
		<input
			type="text"
			name="wp_praxis_settings[manifest_path]"
			value="<?php echo esc_attr( $value ); ?>"
			class="regular-text"
			placeholder="/path/to/manifest.yml"
		/>
		<p class="description">
			<?php esc_html_e( 'Path to the default manifest file (YAML, TOML, or JSON)', 'wp-praxis' ); ?>
		</p>
		<?php
	}

	/**
	 * Render state backend field
	 */
	public function render_state_backend_field() {
		$value = $this->settings['state_backend'] ?? 'database';
		?>
		<select name="wp_praxis_settings[state_backend]">
			<option value="database" <?php selected( $value, 'database' ); ?>>
				<?php esc_html_e( 'Database', 'wp-praxis' ); ?>
			</option>
			<option value="file" <?php selected( $value, 'file' ); ?>>
				<?php esc_html_e( 'File', 'wp-praxis' ); ?>
			</option>
			<option value="memory" <?php selected( $value, 'memory' ); ?>>
				<?php esc_html_e( 'Memory (temporary)', 'wp-praxis' ); ?>
			</option>
		</select>
		<p class="description">
			<?php esc_html_e( 'Storage backend for symbolic state', 'wp-praxis' ); ?>
		</p>
		<?php
	}

	/**
	 * Render debug field
	 */
	public function render_debug_field() {
		$value = $this->settings['debug'] ?? false;
		?>
		<label>
			<input
				type="checkbox"
				name="wp_praxis_settings[debug]"
				value="1"
				<?php checked( $value, true ); ?>
			/>
			<?php esc_html_e( 'Enable debug logging', 'wp-praxis' ); ?>
		</label>
		<?php
	}

	/**
	 * Render auto-register field
	 */
	public function render_auto_register_field() {
		$value = $this->settings['auto_register'] ?? true;
		?>
		<label>
			<input
				type="checkbox"
				name="wp_praxis_settings[auto_register]"
				value="1"
				<?php checked( $value, true ); ?>
			/>
			<?php esc_html_e( 'Automatically register symbols with WordPress hooks', 'wp-praxis' ); ?>
		</label>
		<?php
	}

	/**
	 * AJAX: Execute symbol
	 */
	public function ajax_execute_symbol() {
		check_ajax_referer( 'wp_praxis_nonce', 'nonce' );

		if ( ! current_user_can( 'manage_options' ) ) {
			wp_send_json_error( array( 'message' => __( 'Permission denied', 'wp-praxis' ) ) );
		}

		$symbol_name = sanitize_text_field( $_POST['symbol'] ?? '' );

		if ( empty( $symbol_name ) ) {
			wp_send_json_error( array( 'message' => __( 'Symbol name is required', 'wp-praxis' ) ) );
		}

		try {
			$result = $this->engine->execute_symbol( $symbol_name );

			wp_send_json_success(
				array(
					'result' => $result,
					'symbol' => $symbol_name,
				)
			);
		} catch ( Exception $e ) {
			wp_send_json_error(
				array(
					'message' => $e->getMessage(),
					'symbol'  => $symbol_name,
				)
			);
		}
	}

	/**
	 * AJAX: Upload manifest
	 */
	public function ajax_upload_manifest() {
		check_ajax_referer( 'wp_praxis_nonce', 'nonce' );

		if ( ! current_user_can( 'manage_options' ) ) {
			wp_send_json_error( array( 'message' => __( 'Permission denied', 'wp-praxis' ) ) );
		}

		if ( empty( $_FILES['manifest'] ) ) {
			wp_send_json_error( array( 'message' => __( 'No file uploaded', 'wp-praxis' ) ) );
		}

		$file = $_FILES['manifest'];

		// Validate file type
		$allowed_types = array( 'yml', 'yaml', 'toml', 'json' );
		$file_ext      = strtolower( pathinfo( $file['name'], PATHINFO_EXTENSION ) );

		if ( ! in_array( $file_ext, $allowed_types, true ) ) {
			wp_send_json_error( array( 'message' => __( 'Invalid file type', 'wp-praxis' ) ) );
		}

		// Move uploaded file
		$upload_dir  = wp_upload_dir();
		$praxis_dir  = $upload_dir['basedir'] . '/wp-praxis';
		$target_file = $praxis_dir . '/' . sanitize_file_name( $file['name'] );

		if ( move_uploaded_file( $file['tmp_name'], $target_file ) ) {
			try {
				// Load manifest
				$this->engine->load_manifest( $target_file );

				wp_send_json_success(
					array(
						'message' => __( 'Manifest uploaded and loaded successfully', 'wp-praxis' ),
						'path'    => $target_file,
					)
				);
			} catch ( Exception $e ) {
				wp_send_json_error( array( 'message' => $e->getMessage() ) );
			}
		} else {
			wp_send_json_error( array( 'message' => __( 'Failed to save file', 'wp-praxis' ) ) );
		}
	}

	/**
	 * AJAX: Get introspection data
	 */
	public function ajax_introspect() {
		check_ajax_referer( 'wp_praxis_nonce', 'nonce' );

		if ( ! current_user_can( 'manage_options' ) ) {
			wp_send_json_error( array( 'message' => __( 'Permission denied', 'wp-praxis' ) ) );
		}

		try {
			$data = $this->engine->introspect();
			wp_send_json_success( $data );
		} catch ( Exception $e ) {
			wp_send_json_error( array( 'message' => $e->getMessage() ) );
		}
	}

	/**
	 * Register REST API routes
	 */
	public function register_rest_routes() {
		// Execute symbol endpoint
		register_rest_route(
			'wp-praxis/v1',
			'/execute/(?P<symbol>[a-zA-Z0-9_-]+)',
			array(
				'methods'             => 'POST',
				'callback'            => array( $this, 'rest_execute_symbol' ),
				'permission_callback' => array( $this, 'rest_permission_check' ),
				'args'                => array(
					'symbol' => array(
						'required'          => true,
						'sanitize_callback' => 'sanitize_text_field',
					),
				),
			)
		);

		// Get symbols endpoint
		register_rest_route(
			'wp-praxis/v1',
			'/symbols',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'rest_get_symbols' ),
				'permission_callback' => array( $this, 'rest_permission_check' ),
			)
		);

		// Introspection endpoint
		register_rest_route(
			'wp-praxis/v1',
			'/introspect',
			array(
				'methods'             => 'GET',
				'callback'            => array( $this, 'rest_introspect' ),
				'permission_callback' => array( $this, 'rest_permission_check' ),
			)
		);
	}

	/**
	 * REST API permission check
	 *
	 * @return bool
	 */
	public function rest_permission_check() {
		return current_user_can( 'manage_options' );
	}

	/**
	 * REST API: Execute symbol
	 *
	 * @param WP_REST_Request $request Request object.
	 * @return WP_REST_Response
	 */
	public function rest_execute_symbol( $request ) {
		$symbol_name = $request->get_param( 'symbol' );

		try {
			$result = $this->engine->execute_symbol( $symbol_name );

			return new WP_REST_Response(
				array(
					'success' => true,
					'symbol'  => $symbol_name,
					'result'  => $result,
				),
				200
			);
		} catch ( Exception $e ) {
			return new WP_REST_Response(
				array(
					'success' => false,
					'error'   => $e->getMessage(),
				),
				500
			);
		}
	}

	/**
	 * REST API: Get symbols
	 *
	 * @return WP_REST_Response
	 */
	public function rest_get_symbols() {
		$symbols = $this->engine->get_symbols();
		$data    = array();

		foreach ( $symbols as $name => $symbol ) {
			$data[ $name ] = $symbol->get_config();
		}

		return new WP_REST_Response(
			array(
				'success' => true,
				'symbols' => $data,
			),
			200
		);
	}

	/**
	 * REST API: Introspect
	 *
	 * @return WP_REST_Response
	 */
	public function rest_introspect() {
		$data = $this->engine->introspect();

		return new WP_REST_Response(
			array(
				'success' => true,
				'data'    => $data,
			),
			200
		);
	}

	/**
	 * Before symbol execution hook
	 *
	 * @param string $symbol_name Symbol name.
	 * @param array  $args        Execution arguments.
	 */
	public function before_symbol_execute( $symbol_name, $args ) {
		$this->log_message(
			'debug',
			'Before symbol execution',
			array(
				'symbol' => $symbol_name,
				'args'   => $args,
			)
		);
	}

	/**
	 * After symbol execution hook
	 *
	 * @param string $symbol_name Symbol name.
	 * @param array  $args        Execution arguments.
	 * @param mixed  $result      Execution result.
	 */
	public function after_symbol_execute( $symbol_name, $args, $result ) {
		$this->log_message(
			'debug',
			'After symbol execution',
			array(
				'symbol' => $symbol_name,
				'result' => $result,
			)
		);
	}

	/**
	 * Load text domain for translations
	 */
	public function load_textdomain() {
		load_plugin_textdomain(
			'wp-praxis',
			false,
			dirname( plugin_basename( WP_PRAXIS_PLUGIN_FILE ) ) . '/languages'
		);
	}

	/**
	 * Get plugin settings
	 *
	 * @return array Settings.
	 */
	private function get_settings() {
		return get_option( 'wp_praxis_settings', array() );
	}

	/**
	 * Log message
	 *
	 * @param string $level   Log level.
	 * @param string $message Message.
	 * @param array  $context Context.
	 */
	public function log_message( $level, $message, $context = array() ) {
		if ( ! $this->settings['debug'] ?? false ) {
			return;
		}

		$log_message = sprintf(
			'[WP-Praxis] %s: %s',
			strtoupper( $level ),
			$message
		);

		if ( ! empty( $context ) ) {
			$log_message .= ' ' . wp_json_encode( $context );
		}

		error_log( $log_message );
	}

	/**
	 * Get engine instance
	 *
	 * @return \WPPraxis\Engine\SymbolicEngine|null
	 */
	public function get_engine() {
		return $this->engine;
	}
}

/**
 * Initialize plugin
 */
function wp_praxis_init() {
	return WP_Praxis::get_instance();
}

// Initialize on plugins_loaded
add_action( 'plugins_loaded', 'wp_praxis_init' );

/**
 * Helper function to get plugin instance
 *
 * @return WP_Praxis
 */
function wp_praxis() {
	return WP_Praxis::get_instance();
}
