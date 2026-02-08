# WP Praxis PHP Symbolic Engine

Core PHP implementation of the WP Praxis symbolic orchestration engine.

## Overview

The PHP Symbolic Engine provides:

- **Symbol Class**: Represents symbolic operations with recursive dispatch capabilities
- **SymbolicEngine Class**: Orchestrates manifest loading, validation, and execution
- **Manifest Parsing**: YAML, TOML, and JSON support
- **State Management**: Database, file, or memory storage
- **WordPress Integration**: Native hook integration
- **External Dispatchers**: Rust injector and PowerShell support

## Installation

```bash
cd engine/php
composer install
```

## Dependencies

- PHP 7.4+
- Symfony YAML parser
- Spyc YAML parser (fallback)
- WordPress (optional, for integration)

## Usage

### Basic Usage

```php
<?php
require_once 'vendor/autoload.php';

use WPPraxis\Engine\SymbolicEngine;
use WPPraxis\Engine\Symbol;

// Create engine instance
$engine = new SymbolicEngine([
    'manifest_path' => '/path/to/manifest.yml',
    'state_backend' => 'database',
    'debug' => true,
]);

// Initialize
$engine->initialize();

// Load manifest
$engine->load_manifest('/path/to/manifest.yml');

// Execute symbol
$result = $engine->execute_symbol('symbol_name', $arg1, $arg2);

// Get all symbols
$symbols = $engine->get_symbols();

// Introspect
$data = $engine->introspect();
```

### Creating Symbols Programmatically

```php
use WPPraxis\Engine\Symbol;

$symbol = new Symbol([
    'name' => 'my_symbol',
    'type' => 'action',
    'context' => 'wordpress',
    'dispatch' => 'php',
    'priority' => 10,
    'accepted_args' => 1,
    'parameters' => [
        'hook' => 'init',
        'callback' => function($context) {
            // Your logic here
            return $result;
        }
    ],
    'metadata' => [
        'description' => 'My custom symbol'
    ]
]);

// Register with engine
$engine->register_symbol($symbol);

// Or register with WordPress directly
$symbol->register();
```

## Symbol Class

### Configuration

```php
[
    'name' => 'symbol_name',           // Required: Unique identifier
    'type' => 'action',                // action, filter, state, hook, custom
    'context' => 'wordpress',          // wordpress, cli, rest, ajax, cron
    'dispatch' => 'php',               // php, wordpress, rust_injector, powershell
    'priority' => 10,                  // WordPress hook priority
    'accepted_args' => 1,              // Number of arguments
    'parameters' => [],                // Symbol-specific parameters
    'metadata' => [],                  // Additional metadata
]
```

### Methods

- `register()`: Register symbol with WordPress hooks
- `execute(...$args)`: Execute symbol with arguments
- `get_state()`: Get current symbol state
- `get_config()`: Get symbol configuration
- `reset_state()`: Reset symbol state
- `introspect()`: Get introspection data
- `set_logger(callable)`: Set logger callback

### Dispatch Types

#### PHP Dispatch

```php
'dispatch' => 'php',
'parameters' => [
    'callback' => function($context) {
        // Access symbol data
        $symbol = $context['symbol'];
        $args = $context['execution']['args'];

        return $result;
    }
]
```

#### WordPress Dispatch

```php
'dispatch' => 'wordpress',
'parameters' => [
    'action' => 'function_name'  // WordPress function to call
]
```

#### Rust Injector Dispatch

```php
'dispatch' => 'rust_injector',
'parameters' => [
    'injector_path' => '/path/to/wp_injector',
    'use_socket' => false  // Use exec (false) or socket (true)
]
```

#### PowerShell Dispatch

```php
'dispatch' => 'powershell',
'parameters' => [
    'script' => '/path/to/script.ps1'
]
```

## SymbolicEngine Class

### Configuration Options

```php
[
    'manifest_path' => '',           // Default manifest to load
    'state_backend' => 'memory',     // database, file, memory
    'state_table' => 'wp_praxis_state',  // Database table name
    'state_dir' => '/tmp/wp-praxis-state',  // File storage directory
    'debug' => false,                // Enable debug logging
    'auto_register' => true,         // Auto-register symbols with WordPress
    'injector_path' => '/path/to/wp_injector',  // Rust injector path
    'ps_script_path' => '/path/to/symbolic.ps1',  // PowerShell script path
]
```

### Methods

- `initialize()`: Initialize engine and storage
- `load_manifest(string $path)`: Load manifest from file
- `register_symbol(Symbol $symbol)`: Register symbol
- `get_symbol(string $name)`: Get symbol by name
- `get_symbols()`: Get all symbols
- `execute_symbol(string $name, ...$args)`: Execute symbol
- `save_state(string $name, array $state)`: Save symbol state
- `load_state(string $name)`: Load symbol state
- `introspect()`: Get engine introspection data
- `clear_symbols()`: Clear all symbols
- `create_state_table()`: Create database table
- `drop_state_table()`: Drop database table
- `set_logger(callable)`: Set logger callback

### State Backends

#### Database Backend

Uses WordPress `$wpdb` to store state in database table.

```php
'state_backend' => 'database',
'state_table' => 'wp_praxis_state',
```

Requires WordPress environment with `$wpdb` available.

#### File Backend

Stores state as JSON files in directory.

```php
'state_backend' => 'file',
'state_dir' => '/path/to/state/directory',
```

#### Memory Backend

No persistent storage - state lost on shutdown.

```php
'state_backend' => 'memory',
```

## Manifest Format

### YAML

```yaml
config:
  version: "0.1.0"
  description: "Example manifest"

symbols:
  - name: example_symbol
    type: action
    context: wordpress
    dispatch: php
    priority: 10
    parameters:
      hook: init
    metadata:
      description: "Example symbol"
```

### JSON

```json
{
  "config": {
    "version": "0.1.0",
    "description": "Example manifest"
  },
  "symbols": [
    {
      "name": "example_symbol",
      "type": "action",
      "context": "wordpress",
      "dispatch": "php",
      "priority": 10,
      "parameters": {
        "hook": "init"
      }
    }
  ]
}
```

### TOML

TOML support planned but not yet implemented.

## Execution Context

When a symbol is executed, it receives a context array:

```php
[
    'symbol' => [
        'name' => 'symbol_name',
        'type' => 'action',
        'context' => 'wordpress',
        'dispatch' => 'php',
        'parameters' => [...],
        'metadata' => [...]
    ],
    'execution' => [
        'args' => [...],             // Execution arguments
        'timestamp' => 1234567890,   // Unix timestamp
        'count' => 1,                // Execution count
        'environment' => [...]       // Environment info
    ],
    'state' => [...],                // Current symbol state
    'trace' => [...]                 // Execution trace
]
```

## Logging

Set custom logger:

```php
$engine->set_logger(function($level, $message, $context) {
    error_log("[$level] $message " . json_encode($context));
});
```

Levels: `debug`, `info`, `warning`, `error`

## Error Handling

Exceptions are caught and logged. In debug mode, exceptions are re-thrown.

```php
try {
    $result = $engine->execute_symbol('symbol_name');
} catch (\Exception $e) {
    // Handle error
}
```

## WordPress Integration

When used with WordPress:

- Symbols can register as actions/filters
- State can be stored in WordPress database
- WordPress functions are available
- Hooks are automatically registered

## Testing

```bash
# Run tests (when implemented)
composer test

# Lint code
composer lint
```

## Architecture

### Symbol Lifecycle

1. **Creation**: Symbol created from manifest config
2. **Validation**: Configuration validated
3. **Registration**: Registered with engine and/or WordPress
4. **Execution**: Dispatched to appropriate executor
5. **State Update**: State saved to storage backend

### Dispatch Flow

```
Symbol.execute()
  → build_execution_context()
  → dispatch_execution()
    → dispatch_php() / dispatch_wordpress() / dispatch_rust_injector() / dispatch_powershell()
      → executor runs
    → return result
  → update state
  → save state (if persistent)
```

## Performance Considerations

- Use memory backend for non-critical state
- Use Rust injector for performance-critical operations
- Limit recursive depth in complex workflows
- Consider caching for frequently accessed symbols

## Security

- Validate all manifest inputs
- Sanitize file paths
- Use prepared statements for database queries
- Limit execution permissions
- Validate callback callability

## License

GNU AGPL v3

## Contributing

See main project repository for contribution guidelines.
