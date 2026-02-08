<?php
/**
 * Symbol Class - Core symbolic dispatch and execution
 *
 * Handles symbolic operation dispatch, context preservation, and integration
 * with WordPress hooks and external injectors (Rust, PowerShell).
 *
 * @package WPPraxis\Engine
 * @license AGPL-3.0-or-later
 */

namespace WPPraxis\Engine;

/**
 * Symbol - Represents a symbolic operation with recursive dispatch capabilities
 */
class Symbol {
	/**
	 * Symbol name/identifier
	 *
	 * @var string
	 */
	private $name;

	/**
	 * Symbol type (action, filter, state, hook, custom)
	 *
	 * @var string
	 */
	private $type;

	/**
	 * Execution context (wordpress, cli, rest, ajax)
	 *
	 * @var string
	 */
	private $context;

	/**
	 * Dispatch target (rust_injector, powershell, php, wordpress)
	 *
	 * @var string
	 */
	private $dispatch;

	/**
	 * Symbol parameters
	 *
	 * @var array
	 */
	private $parameters;

	/**
	 * Symbol metadata
	 *
	 * @var array
	 */
	private $metadata;

	/**
	 * Execution state
	 *
	 * @var array
	 */
	private $state;

	/**
	 * WordPress hook priority
	 *
	 * @var int
	 */
	private $priority;

	/**
	 * Number of accepted arguments for WordPress hooks
	 *
	 * @var int
	 */
	private $accepted_args;

	/**
	 * Logger instance
	 *
	 * @var callable|null
	 */
	private $logger;

	/**
	 * Constructor
	 *
	 * @param array $config Symbol configuration from manifest.
	 */
	public function __construct( array $config ) {
		$this->name          = $config['name'] ?? '';
		$this->type          = $config['type'] ?? 'action';
		$this->context       = $config['context'] ?? 'wordpress';
		$this->dispatch      = $config['dispatch'] ?? 'php';
		$this->parameters    = $config['parameters'] ?? array();
		$this->metadata      = $config['metadata'] ?? array();
		$this->priority      = $config['priority'] ?? 10;
		$this->accepted_args = $config['accepted_args'] ?? 1;
		$this->state         = array(
			'status'      => 'initialized',
			'executions'  => 0,
			'last_result' => null,
			'errors'      => array(),
		);
		$this->logger        = null;

		$this->validate();
	}

	/**
	 * Validate symbol configuration
	 *
	 * @throws \InvalidArgumentException If configuration is invalid.
	 */
	private function validate() {
		if ( empty( $this->name ) ) {
			throw new \InvalidArgumentException( 'Symbol name is required' );
		}

		$valid_types = array( 'action', 'filter', 'state', 'hook', 'custom' );
		if ( ! in_array( $this->type, $valid_types, true ) ) {
			throw new \InvalidArgumentException( "Invalid symbol type: {$this->type}" );
		}

		$valid_contexts = array( 'wordpress', 'cli', 'rest', 'ajax', 'cron' );
		if ( ! in_array( $this->context, $valid_contexts, true ) ) {
			throw new \InvalidArgumentException( "Invalid context: {$this->context}" );
		}

		$valid_dispatchers = array( 'rust_injector', 'powershell', 'php', 'wordpress' );
		if ( ! in_array( $this->dispatch, $valid_dispatchers, true ) ) {
			throw new \InvalidArgumentException( "Invalid dispatcher: {$this->dispatch}" );
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
	 * @param string $level   Log level (debug, info, warning, error).
	 * @param string $message Log message.
	 * @param array  $context Additional context.
	 */
	private function log( $level, $message, array $context = array() ) {
		if ( $this->logger ) {
			call_user_func( $this->logger, $level, $message, $context );
		}

		// Also use WordPress debug log if available
		if ( function_exists( 'error_log' ) && defined( 'WP_DEBUG' ) && WP_DEBUG ) {
			$log_message = sprintf(
				'[WP-Praxis Symbol:%s] %s - %s',
				$this->name,
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
	 * Register symbol with WordPress hooks
	 *
	 * @return bool Success status.
	 */
	public function register() {
		$this->log( 'info', 'Registering symbol', array( 'type' => $this->type ) );

		try {
			switch ( $this->type ) {
				case 'action':
					return $this->register_action();

				case 'filter':
					return $this->register_filter();

				case 'hook':
					// Generic hook - determine if action or filter based on metadata
					$hook_type = $this->metadata['hook_type'] ?? 'action';
					return 'filter' === $hook_type ? $this->register_filter() : $this->register_action();

				case 'state':
					// State symbols don't register with WordPress hooks
					$this->state['status'] = 'registered';
					return true;

				case 'custom':
					// Custom symbols use callback if provided
					if ( isset( $this->parameters['register_callback'] ) && is_callable( $this->parameters['register_callback'] ) ) {
						return call_user_func( $this->parameters['register_callback'], $this );
					}
					return true;

				default:
					throw new \RuntimeException( "Unsupported symbol type for registration: {$this->type}" );
			}
		} catch ( \Exception $e ) {
			$this->log( 'error', 'Registration failed', array( 'exception' => $e->getMessage() ) );
			$this->state['errors'][] = $e->getMessage();
			return false;
		}
	}

	/**
	 * Register as WordPress action
	 *
	 * @return bool Success status.
	 */
	private function register_action() {
		$hook_name = $this->parameters['hook'] ?? $this->name;

		if ( ! function_exists( 'add_action' ) ) {
			$this->log( 'warning', 'WordPress functions not available, skipping action registration' );
			return false;
		}

		add_action(
			$hook_name,
			array( $this, 'execute' ),
			$this->priority,
			$this->accepted_args
		);

		$this->state['status'] = 'registered';
		$this->log( 'info', 'Action registered', array( 'hook' => $hook_name ) );
		return true;
	}

	/**
	 * Register as WordPress filter
	 *
	 * @return bool Success status.
	 */
	private function register_filter() {
		$hook_name = $this->parameters['hook'] ?? $this->name;

		if ( ! function_exists( 'add_filter' ) ) {
			$this->log( 'warning', 'WordPress functions not available, skipping filter registration' );
			return false;
		}

		add_filter(
			$hook_name,
			array( $this, 'execute' ),
			$this->priority,
			$this->accepted_args
		);

		$this->state['status'] = 'registered';
		$this->log( 'info', 'Filter registered', array( 'hook' => $hook_name ) );
		return true;
	}

	/**
	 * Execute symbol - Main entry point for symbolic dispatch
	 *
	 * @param mixed ...$args Arguments passed from WordPress hook or manual invocation.
	 * @return mixed Execution result.
	 */
	public function execute( ...$args ) {
		$this->log( 'info', 'Executing symbol', array( 'args_count' => count( $args ) ) );

		$this->state['status'] = 'executing';
		++$this->state['executions'];

		try {
			// Preserve context through dispatch chain
			$execution_context = $this->build_execution_context( $args );

			// Dispatch based on configured dispatcher
			$result = $this->dispatch_execution( $execution_context );

			// Update state with result
			$this->state['status']      = 'completed';
			$this->state['last_result'] = $result;

			$this->log( 'info', 'Execution completed successfully' );

			return $result;

		} catch ( \Exception $e ) {
			$this->state['status']   = 'failed';
			$this->state['errors'][] = $e->getMessage();

			$this->log( 'error', 'Execution failed', array( 'exception' => $e->getMessage() ) );

			// Re-throw in debug mode, return null otherwise
			if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
				throw $e;
			}

			return null;
		}
	}

	/**
	 * Build execution context preserving semantic meaning
	 *
	 * @param array $args Execution arguments.
	 * @return array Execution context.
	 */
	private function build_execution_context( array $args ) {
		return array(
			'symbol'     => array(
				'name'       => $this->name,
				'type'       => $this->type,
				'context'    => $this->context,
				'dispatch'   => $this->dispatch,
				'parameters' => $this->parameters,
				'metadata'   => $this->metadata,
			),
			'execution'  => array(
				'args'        => $args,
				'timestamp'   => time(),
				'count'       => $this->state['executions'],
				'environment' => $this->get_environment_info(),
			),
			'state'      => $this->state,
			'trace'      => $this->build_trace(),
		);
	}

	/**
	 * Get environment information
	 *
	 * @return array Environment info.
	 */
	private function get_environment_info() {
		$env = array(
			'php_version' => PHP_VERSION,
			'sapi'        => php_sapi_name(),
		);

		// Add WordPress info if available
		if ( function_exists( 'get_bloginfo' ) ) {
			$env['wp_version'] = get_bloginfo( 'version' );
			$env['is_admin']   = is_admin();
			$env['is_ajax']    = wp_doing_ajax();
		}

		if ( defined( 'WP_DEBUG' ) ) {
			$env['wp_debug'] = WP_DEBUG;
		}

		return $env;
	}

	/**
	 * Build execution trace for introspection
	 *
	 * @return array Execution trace.
	 */
	private function build_trace() {
		$trace = array(
			'symbol'    => $this->name,
			'depth'     => 0,
			'parent'    => null,
			'timestamp' => microtime( true ),
		);

		// Include backtrace in debug mode
		if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {
			$trace['backtrace'] = debug_backtrace( DEBUG_BACKTRACE_IGNORE_ARGS, 5 );
		}

		return $trace;
	}

	/**
	 * Dispatch execution to appropriate executor
	 *
	 * @param array $context Execution context.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If dispatch fails.
	 */
	private function dispatch_execution( array $context ) {
		$this->log( 'debug', 'Dispatching to executor', array( 'dispatcher' => $this->dispatch ) );

		switch ( $this->dispatch ) {
			case 'php':
				return $this->dispatch_php( $context );

			case 'wordpress':
				return $this->dispatch_wordpress( $context );

			case 'rust_injector':
				return $this->dispatch_rust_injector( $context );

			case 'powershell':
				return $this->dispatch_powershell( $context );

			default:
				throw new \RuntimeException( "Unknown dispatcher: {$this->dispatch}" );
		}
	}

	/**
	 * Dispatch to PHP callable
	 *
	 * @param array $context Execution context.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If callback is not configured or not callable.
	 */
	private function dispatch_php( array $context ) {
		if ( ! isset( $this->parameters['callback'] ) ) {
			throw new \RuntimeException( 'PHP dispatcher requires callback parameter' );
		}

		$callback = $this->parameters['callback'];

		if ( ! is_callable( $callback ) ) {
			throw new \RuntimeException( 'Configured callback is not callable' );
		}

		return call_user_func( $callback, $context );
	}

	/**
	 * Dispatch to WordPress function or action
	 *
	 * @param array $context Execution context.
	 * @return mixed Execution result.
	 */
	private function dispatch_wordpress( array $context ) {
		$action = $this->parameters['action'] ?? null;

		if ( ! $action ) {
			// Default WordPress behavior - apply filters or do action
			if ( 'filter' === $this->type ) {
				$value = $context['execution']['args'][0] ?? null;
				return apply_filters( 'wp_praxis_filter_' . $this->name, $value, $context );
			} else {
				do_action( 'wp_praxis_action_' . $this->name, $context );
				return null;
			}
		}

		// Execute specific WordPress function
		if ( function_exists( $action ) ) {
			return call_user_func( $action, $context );
		}

		throw new \RuntimeException( "WordPress function not found: {$action}" );
	}

	/**
	 * Dispatch to Rust injector via subprocess or socket
	 *
	 * @param array $context Execution context.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If execution fails.
	 */
	private function dispatch_rust_injector( array $context ) {
		$injector_path = $this->parameters['injector_path'] ?? '/home/user/wp-praxis/wp_injector/target/release/wp_injector';
		$use_socket    = $this->parameters['use_socket'] ?? false;

		if ( $use_socket ) {
			return $this->dispatch_via_socket( $injector_path, $context );
		} else {
			return $this->dispatch_via_exec( $injector_path, $context );
		}
	}

	/**
	 * Dispatch to Rust injector via exec
	 *
	 * @param string $injector_path Path to Rust injector binary.
	 * @param array  $context       Execution context.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If execution fails.
	 */
	private function dispatch_via_exec( $injector_path, array $context ) {
		if ( ! file_exists( $injector_path ) ) {
			throw new \RuntimeException( "Rust injector not found: {$injector_path}" );
		}

		// Create temporary file with context JSON
		$temp_file = tempnam( sys_get_temp_dir(), 'wp_praxis_' );
		file_put_contents( $temp_file, wp_json_encode( $context ) );

		// Execute injector
		$command = sprintf(
			'%s execute --context %s 2>&1',
			escapeshellarg( $injector_path ),
			escapeshellarg( $temp_file )
		);

		$output      = array();
		$return_code = 0;
		exec( $command, $output, $return_code );

		// Cleanup temp file
		unlink( $temp_file );

		if ( 0 !== $return_code ) {
			throw new \RuntimeException( 'Rust injector execution failed: ' . implode( "\n", $output ) );
		}

		// Parse JSON output
		$result = json_decode( implode( "\n", $output ), true );

		if ( JSON_ERROR_NONE !== json_last_error() ) {
			throw new \RuntimeException( 'Failed to parse Rust injector output: ' . json_last_error_msg() );
		}

		return $result;
	}

	/**
	 * Dispatch to Rust injector via Unix domain socket
	 *
	 * Uses Unix domain sockets for low-latency IPC with the Rust injector.
	 * Falls back to process execution if socket not available.
	 *
	 * @param string $injector_path Path to Rust injector binary.
	 * @param array  $context       Execution context.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If socket communication fails.
	 */
	private function dispatch_via_socket( $injector_path, array $context ) {
		$socket_path = $this->parameters['socket_path'] ?? '/var/run/wp-praxis/injector.sock';

		// Check if socket exists.
		if ( ! file_exists( $socket_path ) ) {
			// Fall back to process execution if socket not available.
			return $this->dispatch_rust_injector( array( 'binary' => $injector_path ), $context );
		}

		// Create Unix domain socket.
		$socket = socket_create( AF_UNIX, SOCK_STREAM, 0 );
		if ( false === $socket ) {
			throw new \RuntimeException( 'Failed to create socket: ' . socket_strerror( socket_last_error() ) );
		}

		// Set socket timeout (5 seconds).
		socket_set_option( $socket, SOL_SOCKET, SO_RCVTIMEO, array( 'sec' => 5, 'usec' => 0 ) );
		socket_set_option( $socket, SOL_SOCKET, SO_SNDTIMEO, array( 'sec' => 5, 'usec' => 0 ) );

		// Connect to injector socket.
		if ( ! @socket_connect( $socket, $socket_path ) ) {
			socket_close( $socket );
			// Fall back to process execution.
			return $this->dispatch_rust_injector( array( 'binary' => $injector_path ), $context );
		}

		try {
			// Send request as JSON with length prefix.
			$request = wp_json_encode( $context );
			$length  = pack( 'N', strlen( $request ) );
			socket_write( $socket, $length . $request );

			// Read response length.
			$length_data = socket_read( $socket, 4 );
			if ( false === $length_data || strlen( $length_data ) < 4 ) {
				throw new \RuntimeException( 'Failed to read response length from socket' );
			}
			$response_length = unpack( 'N', $length_data )[1];

			// Read response.
			$response = '';
			$remaining = $response_length;
			while ( $remaining > 0 ) {
				$chunk = socket_read( $socket, min( $remaining, 8192 ) );
				if ( false === $chunk ) {
					throw new \RuntimeException( 'Failed to read response from socket' );
				}
				$response  .= $chunk;
				$remaining -= strlen( $chunk );
			}

			$result = json_decode( $response, true );
			if ( null === $result && JSON_ERROR_NONE !== json_last_error() ) {
				throw new \RuntimeException( 'Invalid JSON response from injector: ' . json_last_error_msg() );
			}

			return $result;

		} finally {
			socket_close( $socket );
		}
	}

	/**
	 * Dispatch to PowerShell symbolic engine
	 *
	 * @param array $context Execution context.
	 * @return mixed Execution result.
	 * @throws \RuntimeException If execution fails.
	 */
	private function dispatch_powershell( array $context ) {
		$ps_script = $this->parameters['script'] ?? '/home/user/wp-praxis/SymbolicEngine/core/symbolic.ps1';

		if ( ! file_exists( $ps_script ) ) {
			throw new \RuntimeException( "PowerShell script not found: {$ps_script}" );
		}

		// Create temporary file with context JSON
		$temp_file = tempnam( sys_get_temp_dir(), 'wp_praxis_ps_' );
		file_put_contents( $temp_file, wp_json_encode( $context ) );

		// Execute PowerShell script
		$command = sprintf(
			'pwsh -File %s -ContextFile %s 2>&1',
			escapeshellarg( $ps_script ),
			escapeshellarg( $temp_file )
		);

		$output      = array();
		$return_code = 0;
		exec( $command, $output, $return_code );

		// Cleanup temp file
		unlink( $temp_file );

		if ( 0 !== $return_code ) {
			throw new \RuntimeException( 'PowerShell execution failed: ' . implode( "\n", $output ) );
		}

		// Parse JSON output
		$result = json_decode( implode( "\n", $output ), true );

		if ( JSON_ERROR_NONE !== json_last_error() ) {
			// PowerShell might return non-JSON output
			return implode( "\n", $output );
		}

		return $result;
	}

	/**
	 * Get symbol state
	 *
	 * @return array Current state.
	 */
	public function get_state() {
		return $this->state;
	}

	/**
	 * Get symbol configuration
	 *
	 * @return array Symbol configuration.
	 */
	public function get_config() {
		return array(
			'name'          => $this->name,
			'type'          => $this->type,
			'context'       => $this->context,
			'dispatch'      => $this->dispatch,
			'parameters'    => $this->parameters,
			'metadata'      => $this->metadata,
			'priority'      => $this->priority,
			'accepted_args' => $this->accepted_args,
		);
	}

	/**
	 * Reset symbol state
	 */
	public function reset_state() {
		$this->state = array(
			'status'      => 'initialized',
			'executions'  => 0,
			'last_result' => null,
			'errors'      => array(),
		);
		$this->log( 'info', 'State reset' );
	}

	/**
	 * Get symbol introspection data
	 *
	 * @return array Introspection data.
	 */
	public function introspect() {
		return array(
			'config'      => $this->get_config(),
			'state'       => $this->state,
			'environment' => $this->get_environment_info(),
			'trace'       => $this->build_trace(),
		);
	}
}
