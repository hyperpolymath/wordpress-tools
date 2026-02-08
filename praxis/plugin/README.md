# WP Praxis WordPress Plugin

WordPress plugin for WP Praxis symbolic workflow orchestration.

## Installation

1. **Install Dependencies**

   ```bash
   cd plugin
   composer install

   cd ../engine/php
   composer install
   ```

2. **Activate Plugin**

   - Copy the `plugin` directory to your WordPress `wp-plugins` directory
   - Rename it to `wp-praxis` if needed
   - Activate via WordPress admin panel or WP-CLI:
     ```bash
     wp plugin activate wp-praxis
     ```

## Configuration

### Via WordPress Admin

1. Navigate to **WP Praxis > Settings**
2. Configure:
   - **Manifest Path**: Path to default manifest file
   - **State Backend**: Choose storage (database, file, memory)
   - **Debug Mode**: Enable detailed logging
   - **Auto-Register**: Automatically register symbols with WordPress hooks

### Via Code

```php
// Get plugin instance
$wp_praxis = wp_praxis();

// Get engine
$engine = $wp_praxis->get_engine();

// Load manifest programmatically
$engine->load_manifest('/path/to/manifest.yml');

// Execute symbol
$result = $engine->execute_symbol('symbol_name', $arg1, $arg2);

// Get all symbols
$symbols = $engine->get_symbols();

// Introspect engine state
$introspection = $engine->introspect();
```

## Usage

### Upload Manifest via Admin

1. Go to **WP Praxis > Dashboard**
2. Use the **Upload Manifest** form
3. Select YAML, TOML, or JSON manifest file
4. Click **Upload and Load**

### REST API

#### Execute Symbol

```bash
curl -X POST https://your-site.com/wp-json/wp-praxis/v1/execute/symbol_name \
  -H "Content-Type: application/json" \
  -u username:password
```

#### Get Symbols

```bash
curl https://your-site.com/wp-json/wp-praxis/v1/symbols \
  -u username:password
```

#### Introspection

```bash
curl https://your-site.com/wp-json/wp-praxis/v1/introspect \
  -u username:password
```

### WordPress Hooks

#### Before Symbol Execution

```php
add_action('wp_praxis_before_execute', function($symbol_name, $args) {
    // Your code here
}, 10, 2);
```

#### After Symbol Execution

```php
add_action('wp_praxis_after_execute', function($symbol_name, $args, $result) {
    // Your code here
}, 10, 3);
```

### Custom Symbols

Create custom symbol handlers:

```php
// Define in your theme or plugin
namespace MyPlugin;

class MySymbolHandler {
    public static function handle($context) {
        // Access symbol data
        $symbol = $context['symbol'];
        $args = $context['execution']['args'];

        // Your logic here

        return $result;
    }
}

// In manifest:
// symbols:
//   - name: my_custom_symbol
//     type: custom
//     dispatch: php
//     parameters:
//       callback: '\MyPlugin\MySymbolHandler::handle'
```

## Manifest Format

### YAML Example

```yaml
symbols:
  - name: example_action
    type: action
    context: wordpress
    dispatch: php
    priority: 10
    parameters:
      hook: init
      callback: 'my_callback_function'
    metadata:
      description: "Example action hook"
```

### JSON Example

```json
{
  "symbols": [
    {
      "name": "example_action",
      "type": "action",
      "context": "wordpress",
      "dispatch": "php",
      "priority": 10,
      "parameters": {
        "hook": "init",
        "callback": "my_callback_function"
      }
    }
  ]
}
```

## Symbol Types

- **action**: WordPress action hook
- **filter**: WordPress filter hook
- **state**: State management symbol (no hook)
- **hook**: Generic hook (auto-detect action/filter)
- **custom**: Custom operation with callback

## Dispatch Types

- **php**: Execute PHP callable
- **wordpress**: Use WordPress core functions
- **rust_injector**: Execute via Rust binary
- **powershell**: Execute PowerShell script

## Context Types

- **wordpress**: WordPress environment
- **cli**: Command-line interface
- **rest**: REST API request
- **ajax**: AJAX request
- **cron**: Scheduled task

## Database Schema

The plugin creates a `wp_praxis_state` table for persistent state storage:

```sql
CREATE TABLE wp_praxis_state (
  id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  symbol_name varchar(255) NOT NULL,
  state_data longtext NOT NULL,
  created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY symbol_name (symbol_name)
);
```

## Security

- All admin operations require `manage_options` capability
- AJAX requests use WordPress nonces
- REST API requires authentication
- Input sanitization on all user inputs
- Output escaping in all templates

## Troubleshooting

### Enable Debug Mode

In `wp-config.php`:

```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
```

Check `wp-content/debug.log` for WP Praxis messages.

### Common Issues

1. **Symbols not loading**
   - Check manifest file path and permissions
   - Verify YAML/JSON syntax
   - Check debug log for parsing errors

2. **State not persisting**
   - Verify database table exists
   - Check state_backend setting
   - Ensure database permissions

3. **Rust injector not found**
   - Build Rust injector: `cd wp_injector && cargo build --release`
   - Update injector_path in settings

## Development

### File Structure

```
plugin/
├── wp-praxis.php          # Main plugin file
├── admin/                 # Admin interface
│   ├── dashboard.php
│   ├── settings.php
│   ├── symbols.php
│   ├── introspection.php
│   ├── css/admin.css
│   └── js/admin.js
├── config/                # Example configurations
│   ├── example-manifest.yml
│   └── simple-manifest.json
└── composer.json          # Dependencies
```

### Running Tests

```bash
# PHP CodeSniffer
composer lint

# PHPUnit (when implemented)
composer test
```

## License

GNU AGPL v3 - See LICENSE file

## Support

- GitHub: https://github.com/wp-praxis/wp-praxis
- Documentation: https://github.com/wp-praxis/wp-praxis/blob/main/CLAUDE.md
