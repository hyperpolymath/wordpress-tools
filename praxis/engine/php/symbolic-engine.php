<?php
/**
 * Symbolic Engine - Core orchestration for WP Praxis
 *
 * Loads, validates, and executes symbolic workflows from declarative manifests.
 * Manages symbolic state, provides introspection API, and integrates with WordPress.
 *
 * @package WPPraxis\Engine
 * @license AGPL-3.0-or-later
 */

namespace WPPraxis\Engine;

use Symfony\Component\Yaml\Yaml;

/**
 * SymbolicEngine - Main orchestration engine
 */
class SymbolicEngine {
	/**
	 * Engine version
	 *
	 * @var string
	 */
	const VERSION = '0.1.0';

	/**
	 * Loaded symbols registry
	 *
	 * @var array<string, Symbol>
	 */
	private $symbols = array();

	/**
	 * Engine configuration
	 *
	 * @var array
	 */
	private $config;

	/**
	 * Logger callback
	 *
	 * @var callable|null
	 */
	private $logger;

	/**
	 * State storage backend (database, file, memory)
	 *
	 * @var string
	 */
	private $state_backend;

	/**
	 * WordPress database object (if available)
	 *
	 * @var \wpdb|null
	 */
	private $wpdb;

	/**
	 * Engine state
	 *
	 * @var array
	 */
	private $state;

	/**
	 * Constructor
	 *
	 * @param array $config Engine configuration.
	 */
	public function __construct( array $config = array() ) {
		$this->config = array_merge(
			array(
				'manifest_path'   => '',
				'state_backend'   => 'memory',
				'state_table'     => 'wp_praxis_state',
				'debug'           => false,
				'auto_register'   => true,
				'injector_path'   => '/home/user/wp-praxis/wp_injector/target/release/wp_injector',
				'ps_script_path'  => '/home/user/wp-praxis/SymbolicEngine/core/symbolic.ps1',
			),
			$config
		);

		$this->state_backend = $this->config['state_backend'];
		$this->logger        = null;
		$this->state         = array(
			'initialized' => false,
			'manifests'   => array(),
			'errors'      => array(),
		);

		// Get WordPress database if available
		if ( isset( $GLOBALS['wpdb'] ) ) {
			$this->wpdb = $GLOBALS['wpdb'];
		}
	}

	/**
	 * Set logger callback
	 *
	 * @param callable $logger Logger function.
	 */
	public function set_logger( callable $logger ) {
		$this->logger = $logger;
	}

	/**
	 * Log message
	 *
	 * @param string $level   Log level.
	 * @param string $message Message.
	 * @param array  $context Context.
	 */
	private function log( $level, $message, array $context = array() ) {
		if ( $this->logger ) {
			call_user_func( $this->logger, $level, $message, $context );
		}

		if ( $this->config['debug'] && function_exists( 'error_log' ) ) {
			$log_message = sprintf(
				'[WP-Praxis Engine] %s - %s',
				strtoupper( $level ),
				$message
			);
			if ( ! empty( $context ) ) {
				$log_message .= ' ' . wp_json_encode( $context );
			}
			error_log( $log_message );
		}
	}

	/**
	 * Initialize engine
	 *
	 * @return bool Success status.
	 */
	public function initialize() {
		$this->log( 'info', 'Initializing symbolic engine', array( 'version' => self::VERSION ) );

		try {
			// Initialize state storage
			$this->initialize_state_storage();

			// Load manifest if configured
			if ( ! empty( $this->config['manifest_path'] ) ) {
				$this->load_manifest( $this->config['manifest_path'] );
			}

			$this->state['initialized'] = true;
			$this->log( 'info', 'Engine initialized successfully' );

			return true;

		} catch ( \Exception $e ) {
			$this->state['errors'][] = $e->getMessage();
			$this->log( 'error', 'Initialization failed', array( 'exception' => $e->getMessage() ) );
			return false;
		}
	}

	/**
	 * Initialize state storage backend
	 *
	 * @throws \RuntimeException If initialization fails.
	 */
	private function initialize_state_storage() {
		switch ( $this->state_backend ) {
			case 'database':
				$this->initialize_database_storage();
				break;

			case 'file':
				$this->initialize_file_storage();
				break;

			case 'memory':
				// Memory storage requires no initialization
				break;

			default:
				throw new \RuntimeException( "Unknown state backend: {$this->state_backend}" );
		}
	}

	/**
	 * Initialize database storage (WordPress)
	 *
	 * @throws \RuntimeException If database is not available.
	 */
	private function initialize_database_storage() {
		if ( ! $this->wpdb ) {
			throw new \RuntimeException( 'Database backend requires WordPress $wpdb' );
		}

		$table_name = $this->wpdb->prefix . $this->config['state_table'];

		// Check if table exists
		$table_exists = $this->wpdb->get_var(
			$this->wpdb->prepare(
				'SHOW TABLES LIKE %s',
				$table_name
			)
		);

		if ( ! $table_exists ) {
			$this->log( 'warning', 'State table does not exist, will be created on activation' );
		}

		$this->log( 'info', 'Database storage initialized', array( 'table' => $table_name ) );
	}

	/**
	 * Initialize file storage
	 */
	private function initialize_file_storage() {
		$state_dir = $this->config['state_dir'] ?? sys_get_temp_dir() . '/wp-praxis-state';

		if ( ! is_dir( $state_dir ) ) {
			mkdir( $state_dir, 0755, true );
		}

		$this->log( 'info', 'File storage initialized', array( 'dir' => $state_dir ) );
	}

	/**
	 * Load manifest from file
	 *
	 * @param string $manifest_path Path to manifest file.
	 * @return bool Success status.
	 * @throws \RuntimeException If manifest loading fails.
	 */
	public function load_manifest( $manifest_path ) {
		$this->log( 'info', 'Loading manifest', array( 'path' => $manifest_path ) );

		if ( ! file_exists( $manifest_path ) ) {
			throw new \RuntimeException( "Manifest file not found: {$manifest_path}" );
		}

		$extension = strtolower( pathinfo( $manifest_path, PATHINFO_EXTENSION ) );

		$manifest_data = null;

		switch ( $extension ) {
			case 'yml':
			case 'yaml':
				$manifest_data = $this->load_yaml_manifest( $manifest_path );
				break;

			case 'toml':
				$manifest_data = $this->load_toml_manifest( $manifest_path );
				break;

			case 'json':
				$manifest_data = $this->load_json_manifest( $manifest_path );
				break;

			default:
				throw new \RuntimeException( "Unsupported manifest format: {$extension}" );
		}

		if ( ! $manifest_data ) {
			throw new \RuntimeException( 'Failed to parse manifest' );
		}

		// Validate manifest structure
		$this->validate_manifest( $manifest_data );

		// Load symbols from manifest
		$this->load_symbols_from_manifest( $manifest_data );

		// Track loaded manifest
		$this->state['manifests'][] = array(
			'path'      => $manifest_path,
			'loaded_at' => time(),
			'symbols'   => count( $manifest_data['symbols'] ?? array() ),
		);

		$this->log( 'info', 'Manifest loaded successfully', array( 'symbols' => count( $this->symbols ) ) );

		return true;
	}

	/**
	 * Load YAML manifest
	 *
	 * @param string $path Manifest path.
	 * @return array Parsed manifest data.
	 * @throws \RuntimeException If parsing fails.
	 */
	private function load_yaml_manifest( $path ) {
		try {
			// Try Symfony YAML parser first
			if ( class_exists( 'Symfony\Component\Yaml\Yaml' ) ) {
				return Yaml::parseFile( $path );
			}

			// Fallback to Spyc if available
			if ( function_exists( 'spyc_load_file' ) ) {
				return spyc_load_file( $path );
			}

			throw new \RuntimeException( 'No YAML parser available (install symfony/yaml or spyc)' );

		} catch ( \Exception $e ) {
			throw new \RuntimeException( 'YAML parsing failed: ' . $e->getMessage() );
		}
	}

	/**
	 * Load TOML manifest
	 *
	 * Basic TOML parser supporting key=value, [sections], and basic types.
	 *
	 * @param string $path Manifest path.
	 * @return array Parsed manifest data.
	 * @throws \RuntimeException If parsing fails.
	 */
	private function load_toml_manifest( $path ) {
		$content = file_get_contents( $path );
		if ( false === $content ) {
			throw new \RuntimeException( "Could not read TOML file: {$path}" );
		}

		$result          = array();
		$current_section = &$result;
		$lines           = explode( "\n", $content );

		foreach ( $lines as $line_num => $line ) {
			$line = trim( $line );

			// Skip empty lines and comments.
			if ( empty( $line ) || '#' === $line[0] ) {
				continue;
			}

			// Section header [section.name].
			if ( preg_match( '/^\[([^\]]+)\]$/', $line, $matches ) ) {
				$section_path    = explode( '.', $matches[1] );
				$current_section = &$result;
				foreach ( $section_path as $part ) {
					if ( ! isset( $current_section[ $part ] ) ) {
						$current_section[ $part ] = array();
					}
					$current_section = &$current_section[ $part ];
				}
				continue;
			}

			// Key = value.
			if ( preg_match( '/^([a-zA-Z_][a-zA-Z0-9_-]*)\s*=\s*(.+)$/', $line, $matches ) ) {
				$key   = $matches[1];
				$value = trim( $matches[2] );

				// Parse value type.
				$current_section[ $key ] = $this->parse_toml_value( $value );
			}
		}

		return $result;
	}

	/**
	 * Parse TOML value to PHP type
	 *
	 * @param string $value Raw TOML value.
	 * @return mixed Parsed PHP value.
	 */
	private function parse_toml_value( $value ) {
		// Boolean.
		if ( 'true' === $value ) {
			return true;
		}
		if ( 'false' === $value ) {
			return false;
		}

		// String (quoted).
		if ( preg_match( '/^"(.*)"|\'(.*)\'$/', $value, $matches ) ) {
			return $matches[1] ?: $matches[2];
		}

		// Integer.
		if ( preg_match( '/^-?\d+$/', $value ) ) {
			return (int) $value;
		}

		// Float.
		if ( preg_match( '/^-?\d+\.\d+$/', $value ) ) {
			return (float) $value;
		}

		// Array.
		if ( preg_match( '/^\[(.+)\]$/', $value, $matches ) ) {
			$items = preg_split( '/,\s*/', $matches[1] );
			return array_map( array( $this, 'parse_toml_value' ), $items );
		}

		// Default: return as string.
		return $value;
	}

	/**
	 * Load JSON manifest
	 *
	 * @param string $path Manifest path.
	 * @return array Parsed manifest data.
	 * @throws \RuntimeException If parsing fails.
	 */
	private function load_json_manifest( $path ) {
		$content = file_get_contents( $path );
		$data    = json_decode( $content, true );

		if ( JSON_ERROR_NONE !== json_last_error() ) {
			throw new \RuntimeException( 'JSON parsing failed: ' . json_last_error_msg() );
		}

		return $data;
	}

	/**
	 * Validate manifest structure
	 *
	 * @param array $manifest Manifest data.
	 * @throws \InvalidArgumentException If validation fails.
	 */
	private function validate_manifest( array $manifest ) {
		// Check for symbols array
		if ( ! isset( $manifest['symbols'] ) || ! is_array( $manifest['symbols'] ) ) {
			throw new \InvalidArgumentException( 'Manifest must contain symbols array' );
		}

		// Validate each symbol
		foreach ( $manifest['symbols'] as $index => $symbol ) {
			if ( ! is_array( $symbol ) ) {
				throw new \InvalidArgumentException( "Symbol at index {$index} must be an array" );
			}

			if ( ! isset( $symbol['name'] ) ) {
				throw new \InvalidArgumentException( "Symbol at index {$index} must have a name" );
			}
		}

		$this->log( 'debug', 'Manifest validation passed', array( 'symbols' => count( $manifest['symbols'] ) ) );
	}

	/**
	 * Load symbols from manifest data
	 *
	 * @param array $manifest Manifest data.
	 */
	private function load_symbols_from_manifest( array $manifest ) {
		$symbols = $manifest['symbols'] ?? array();

		foreach ( $symbols as $symbol_config ) {
			try {
				// Merge global config into symbol config
				if ( isset( $manifest['config'] ) ) {
					$symbol_config = array_merge(
						array( 'global_config' => $manifest['config'] ),
						$symbol_config
					);
				}

				// Create symbol instance
				$symbol = new Symbol( $symbol_config );

				// Set logger
				if ( $this->logger ) {
					$symbol->set_logger( $this->logger );
				}

				// Register symbol
				$this->register_symbol( $symbol );

			} catch ( \Exception $e ) {
				$this->log(
					'error',
					'Failed to load symbol',
					array(
						'name'      => $symbol_config['name'] ?? 'unknown',
						'exception' => $e->getMessage(),
					)
				);
				$this->state['errors'][] = $e->getMessage();
			}
		}
	}

	/**
	 * Register symbol with engine
	 *
	 * @param Symbol $symbol Symbol instance.
	 * @return bool Success status.
	 */
	public function register_symbol( Symbol $symbol ) {
		$config = $symbol->get_config();
		$name   = $config['name'];

		if ( isset( $this->symbols[ $name ] ) ) {
			$this->log( 'warning', 'Symbol already registered, replacing', array( 'name' => $name ) );
		}

		$this->symbols[ $name ] = $symbol;

		// Auto-register with WordPress if enabled
		if ( $this->config['auto_register'] ) {
			$symbol->register();
		}

		$this->log( 'info', 'Symbol registered', array( 'name' => $name ) );

		return true;
	}

	/**
	 * Get symbol by name
	 *
	 * @param string $name Symbol name.
	 * @return Symbol|null Symbol instance or null if not found.
	 */
	public function get_symbol( $name ) {
		return $this->symbols[ $name ] ?? null;
	}

	/**
	 * Get all symbols
	 *
	 * @return array<string, Symbol> All symbols.
	 */
	public function get_symbols() {
		return $this->symbols;
	}

	/**
	 * Execute symbol by name
	 *
	 * @param string $name Symbol name.
	 * @param mixed  ...$args Execution arguments.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If symbol not found.
	 */
	public function execute_symbol( $name, ...$args ) {
		$symbol = $this->get_symbol( $name );

		if ( ! $symbol ) {
			throw new \RuntimeException( "Symbol not found: {$name}" );
		}

		return $symbol->execute( ...$args );
	}

	/**
	 * Save symbolic state to storage backend
	 *
	 * @param string $symbol_name Symbol name.
	 * @param array  $state       State data.
	 * @return bool Success status.
	 */
	public function save_state( $symbol_name, array $state ) {
		switch ( $this->state_backend ) {
			case 'database':
				return $this->save_state_to_database( $symbol_name, $state );

			case 'file':
				return $this->save_state_to_file( $symbol_name, $state );

			case 'memory':
				// Memory storage - state is lost on shutdown
				return true;

			default:
				$this->log( 'warning', 'Unknown state backend, state not saved' );
				return false;
		}
	}

	/**
	 * Save state to database
	 *
	 * @param string $symbol_name Symbol name.
	 * @param array  $state       State data.
	 * @return bool Success status.
	 */
	private function save_state_to_database( $symbol_name, array $state ) {
		if ( ! $this->wpdb ) {
			return false;
		}

		$table_name = $this->wpdb->prefix . $this->config['state_table'];

		$result = $this->wpdb->replace(
			$table_name,
			array(
				'symbol_name' => $symbol_name,
				'state_data'  => wp_json_encode( $state ),
				'updated_at'  => current_time( 'mysql' ),
			),
			array( '%s', '%s', '%s' )
		);

		return false !== $result;
	}

	/**
	 * Save state to file
	 *
	 * @param string $symbol_name Symbol name.
	 * @param array  $state       State data.
	 * @return bool Success status.
	 */
	private function save_state_to_file( $symbol_name, array $state ) {
		$state_dir  = $this->config['state_dir'] ?? sys_get_temp_dir() . '/wp-praxis-state';
		$state_file = $state_dir . '/' . sanitize_file_name( $symbol_name ) . '.json';

		$result = file_put_contents( $state_file, wp_json_encode( $state, JSON_PRETTY_PRINT ) );

		return false !== $result;
	}

	/**
	 * Load symbolic state from storage backend
	 *
	 * @param string $symbol_name Symbol name.
	 * @return array|null State data or null if not found.
	 */
	public function load_state( $symbol_name ) {
		switch ( $this->state_backend ) {
			case 'database':
				return $this->load_state_from_database( $symbol_name );

			case 'file':
				return $this->load_state_from_file( $symbol_name );

			case 'memory':
				// Memory storage - no persistent state
				return null;

			default:
				return null;
		}
	}

	/**
	 * Load state from database
	 *
	 * @param string $symbol_name Symbol name.
	 * @return array|null State data.
	 */
	private function load_state_from_database( $symbol_name ) {
		if ( ! $this->wpdb ) {
			return null;
		}

		$table_name = $this->wpdb->prefix . $this->config['state_table'];

		$state_json = $this->wpdb->get_var(
			$this->wpdb->prepare(
				"SELECT state_data FROM {$table_name} WHERE symbol_name = %s",
				$symbol_name
			)
		);

		if ( ! $state_json ) {
			return null;
		}

		return json_decode( $state_json, true );
	}

	/**
	 * Load state from file
	 *
	 * @param string $symbol_name Symbol name.
	 * @return array|null State data.
	 */
	private function load_state_from_file( $symbol_name ) {
		$state_dir  = $this->config['state_dir'] ?? sys_get_temp_dir() . '/wp-praxis-state';
		$state_file = $state_dir . '/' . sanitize_file_name( $symbol_name ) . '.json';

		if ( ! file_exists( $state_file ) ) {
			return null;
		}

		$state_json = file_get_contents( $state_file );
		return json_decode( $state_json, true );
	}

	/**
	 * Get engine introspection data
	 *
	 * @return array Introspection data.
	 */
	public function introspect() {
		$symbols_data = array();

		foreach ( $this->symbols as $name => $symbol ) {
			$symbols_data[ $name ] = $symbol->introspect();
		}

		return array(
			'engine'  => array(
				'version'       => self::VERSION,
				'initialized'   => $this->state['initialized'],
				'config'        => $this->config,
				'state_backend' => $this->state_backend,
			),
			'symbols' => $symbols_data,
			'state'   => $this->state,
		);
	}

	/**
	 * Get engine state
	 *
	 * @return array Engine state.
	 */
	public function get_state() {
		return $this->state;
	}

	/**
	 * Clear all symbols
	 */
	public function clear_symbols() {
		$this->symbols = array();
		$this->log( 'info', 'All symbols cleared' );
	}

	/**
	 * Create database table for state storage
	 *
	 * @return bool Success status.
	 */
	public function create_state_table() {
		if ( ! $this->wpdb ) {
			return false;
		}

		$table_name      = $this->wpdb->prefix . $this->config['state_table'];
		$charset_collate = $this->wpdb->get_charset_collate();

		$sql = "CREATE TABLE IF NOT EXISTS {$table_name} (
			id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
			symbol_name varchar(255) NOT NULL,
			state_data longtext NOT NULL,
			created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
			updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY  (id),
			UNIQUE KEY symbol_name (symbol_name),
			KEY updated_at (updated_at)
		) {$charset_collate};";

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';
		dbDelta( $sql );

		$this->log( 'info', 'State table created', array( 'table' => $table_name ) );

		return true;
	}

	/**
	 * Drop database table for state storage
	 *
	 * @return bool Success status.
	 */
	public function drop_state_table() {
		if ( ! $this->wpdb ) {
			return false;
		}

		$table_name = $this->wpdb->prefix . $this->config['state_table'];

		$result = $this->wpdb->query( "DROP TABLE IF EXISTS {$table_name}" );

		$this->log( 'info', 'State table dropped', array( 'table' => $table_name ) );

		return false !== $result;
	}
}

/**
 * Helper function to sanitize file name
 *
 * @param string $filename File name.
 * @return string Sanitized file name.
 */
function sanitize_file_name( $filename ) {
	if ( function_exists( 'sanitize_file_name' ) ) {
		return \sanitize_file_name( $filename );
	}

	// Fallback sanitization
	$filename = preg_replace( '/[^a-zA-Z0-9_\-.]/', '_', $filename );
	return $filename;
}

/**
 * Helper function to encode JSON (WordPress compatibility)
 *
 * @param mixed $data Data to encode.
 * @param int   $options JSON options.
 * @return string JSON string.
 */
function wp_json_encode( $data, $options = 0 ) {
	if ( function_exists( 'wp_json_encode' ) ) {
		return \wp_json_encode( $data, $options );
	}

	return json_encode( $data, $options );
}
