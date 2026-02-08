# WP Praxis Symbolic Injector

High-performance Rust-based symbolic logic injector for WordPress workflows. This injector reads declarative manifest files and performs semantic-preserving transformations on WordPress installations through database operations.

## Features

- **Declarative Manifests**: Define WordPress modifications in YAML or TOML
- **Symbolic Dispatch**: Route operations based on semantic tags and context
- **Transaction Safety**: Atomic operations with rollback support
- **State Tracking**: Full injection history with rollback capability
- **WordPress Integration**: Direct database access via wp-config.php parsing
- **Validation**: Pre-execution validation of manifests and dependencies
- **Diff Support**: Compare current state with desired manifest state

## Installation

### Build from Source

```bash
cd wp_injector
cargo build --release
```

The binary will be available at `target/release/wp_injector`.

### Add to PATH (Optional)

```bash
# Copy to local bin
sudo cp target/release/wp_injector /usr/local/bin/

# Or add to PATH
export PATH="$PATH:$(pwd)/target/release"
```

## Usage

### Basic Commands

#### Validate Manifest

Validate a manifest file without executing:

```bash
wp_injector validate --manifest examples/workflow.toml
```

With WordPress context validation:

```bash
wp_injector validate \
  --manifest examples/workflow.toml \
  --wp-root /var/www/html
```

#### Inject Symbols

Execute injection from manifest:

```bash
wp_injector inject \
  --manifest examples/workflow.toml \
  --wp-root /var/www/html
```

Dry run (validate without executing):

```bash
wp_injector inject \
  --manifest examples/workflow.toml \
  --wp-root /var/www/html \
  --dry-run
```

#### Check Status

View injection history:

```bash
wp_injector status --wp-root /var/www/html
```

Detailed history with symbol lists:

```bash
wp_injector status --wp-root /var/www/html --detailed
```

#### Compare State (Diff)

Compare current WordPress state with manifest:

```bash
wp_injector diff \
  --manifest examples/workflow.toml \
  --wp-root /var/www/html
```

#### Rollback

Rollback last injection:

```bash
wp_injector rollback \
  --last 1 \
  --wp-root /var/www/html
```

Rollback specific injection by ID:

```bash
wp_injector rollback \
  --id inj_1732234567 \
  --wp-root /var/www/html
```

### Global Options

- `--verbose` / `-v`: Enable debug logging
- `--log-file <PATH>`: Write logs to file

Example:

```bash
wp_injector inject \
  --manifest workflow.toml \
  --wp-root /var/www/html \
  --verbose \
  --log-file injection.log
```

## Manifest Format

Manifests can be written in YAML or TOML format.

### YAML Example

```yaml
metadata:
  name: "My WordPress Workflow"
  version: "1.0.0"
  description: "Custom post types and taxonomies"
  author: "Your Name"

symbols:
  - name: portfolio_post_type
    type: post_type
    context: wordpress
    dispatch: rust_injector
    parameters:
      post_type: portfolio
      label: Portfolio
      public: true
      supports:
        - title
        - editor
        - thumbnail
    validation:
      wordpress_version: ">=5.0"
    rollback: snapshot

  - name: portfolio_category
    type: taxonomy
    context: wordpress
    parameters:
      taxonomy: portfolio_category
      label: Portfolio Categories
      hierarchical: true
    depends_on:
      - portfolio_post_type
    rollback: snapshot

  - name: site_tagline
    type: option
    context: wordpress
    parameters:
      option_name: blogdescription
      option_value: "Custom tagline via symbolic injection"
    rollback: snapshot
```

### TOML Example

```toml
[metadata]
name = "My WordPress Workflow"
version = "1.0.0"
description = "Custom post types and taxonomies"
author = "Your Name"

[[symbols]]
name = "portfolio_post_type"
type = "post_type"
context = "wordpress"
dispatch = "rust_injector"
rollback = "snapshot"

[symbols.parameters]
post_type = "portfolio"
label = "Portfolio"
public = true

[symbols.validation]
wordpress_version = ">=5.0"

[[symbols]]
name = "portfolio_category"
type = "taxonomy"
context = "wordpress"
depends_on = ["portfolio_post_type"]
rollback = "snapshot"

[symbols.parameters]
taxonomy = "portfolio_category"
label = "Portfolio Categories"
hierarchical = true
```

## Symbol Types

### Supported Types

#### `post_type`

Register custom post type.

**Required Parameters:**
- `post_type`: Post type slug
- `label`: Display label

**Optional Parameters:**
- `public`: Boolean (default: true)
- `supports`: Array of features
- Additional WordPress post type arguments

#### `taxonomy`

Register custom taxonomy.

**Required Parameters:**
- `taxonomy`: Taxonomy slug
- `label`: Display label

**Optional Parameters:**
- `hierarchical`: Boolean
- `object_type`: Post types to attach to
- Additional WordPress taxonomy arguments

#### `option`

Set WordPress option.

**Required Parameters:**
- `option_name`: Option key
- `option_value`: Option value

#### `query`

Execute custom SQL query.

**Required Parameters:**
- `sql`: SQL query to execute

**⚠️ Warning:** Use with caution. Ensure queries are safe and tested.

## Rollback Strategies

### `snapshot`

Store previous state before injection. On rollback, restore the original state.

Best for: Options, settings that can be restored.

### `inverse`

Execute inverse operations on rollback.

Best for: Complex operations with clear reverse actions.

### `none`

Cannot be rolled back.

Use only for idempotent or irreversible operations.

## State Management

Injection state is stored in:

```
{wp-root}/wp-content/.wp-praxis/injections/
```

Each injection creates a JSON state file containing:
- Injection ID and timestamp
- List of injected symbols
- Rollback data for each symbol
- Injection status

**State File Example:**

```json
{
  "id": "inj_1732234567",
  "manifest_name": "My WordPress Workflow",
  "timestamp": "2025-11-22T12:34:56Z",
  "symbols_injected": [
    "portfolio_post_type",
    "portfolio_category",
    "site_tagline"
  ],
  "rollback_data": {
    "site_tagline": {
      "type": "option",
      "option_name": "blogdescription",
      "old_value": "Just another WordPress site"
    }
  },
  "status": "completed"
}
```

## WordPress Integration

### Database Connection

The injector automatically parses `wp-config.php` to extract database credentials:

- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST`
- `$table_prefix`

**Requirements:**
- WordPress installation at specified `--wp-root`
- Valid `wp-config.php` with database credentials
- Network access to MySQL/MariaDB server
- Appropriate database permissions

### Security Considerations

1. **Database Credentials**: Injector reads credentials from wp-config.php (never commits credentials to version control)
2. **SQL Injection**: Parameterized queries prevent SQL injection
3. **Validation**: Pre-execution validation prevents invalid operations
4. **Rollback**: State tracking enables safe rollback of changes
5. **Permissions**: Run with appropriate user permissions (avoid root)

## Architecture

### Execution Flow

```
Manifest (YAML/TOML)
    ↓
Parse & Validate
    ↓
WordPress Config (wp-config.php)
    ↓
Database Connection (MySQL)
    ↓
Dependency Resolution (Topological Sort)
    ↓
Symbol Injection (with Snapshots)
    ↓
State Persistence
```

### Error Handling

The injector uses Rust's `Result` type for comprehensive error handling:

- **Manifest errors**: Parse errors, validation failures
- **Database errors**: Connection failures, query errors
- **Injection errors**: Failed operations, constraint violations
- **State errors**: File I/O errors, serialization failures

All errors include detailed messages for debugging.

## Development

### Running Tests

```bash
cargo test
```

### Building with Debug Symbols

```bash
cargo build
```

### Linting

```bash
cargo clippy
```

### Formatting

```bash
cargo fmt
```

## Examples

See the `examples/` directory for sample manifests:

- `examples/simple-option.toml` - Simple option injection
- `examples/custom-post-type.yaml` - Custom post type registration
- `examples/complete-workflow.toml` - Full workflow with dependencies

## Troubleshooting

### "wp-config.php not found"

Ensure `--wp-root` points to the WordPress installation root (where wp-config.php is located).

### "Database connection error"

Check:
- MySQL/MariaDB is running
- Database credentials in wp-config.php are correct
- Network connectivity to database host
- User has appropriate permissions

### "Validation failed"

Run with `--verbose` to see detailed validation errors:

```bash
wp_injector validate --manifest workflow.toml --verbose
```

### "Circular dependency detected"

Check symbol `depends_on` relationships. Dependencies must form a directed acyclic graph (DAG).

## Performance

- **Async I/O**: Uses Tokio for asynchronous database operations
- **Connection Pooling**: SQLx connection pool for efficient database access
- **Optimized Binary**: Release builds use LTO and optimization level 3
- **Minimal Dependencies**: Carefully selected crates for small binary size

**Typical Performance:**
- Manifest parsing: < 10ms
- Database connection: 50-200ms
- Symbol injection: 10-50ms per symbol
- State persistence: < 5ms

## License

GNU Affero General Public License v3.0 (AGPL-3.0)

See LICENSE file for full text.

## Contributing

Follow the Rust conventions outlined in `CLAUDE.md`:

1. Use `cargo fmt` for formatting
2. Run `cargo clippy` for linting
3. Add tests for new functionality
4. Document public APIs
5. Follow error handling patterns

## Support

For issues or questions:

1. Check existing documentation
2. Review example manifests
3. Enable verbose logging for debugging
4. Consult `Docs/` directory for architecture details
