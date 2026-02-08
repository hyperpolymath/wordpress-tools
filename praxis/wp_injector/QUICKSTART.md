# WP Injector Quick Start Guide

Get started with the WP Praxis Symbolic Injector in 5 minutes.

## Prerequisites

- Rust toolchain (for building)
- WordPress installation
- MySQL/MariaDB access
- Valid wp-config.php

## Build

```bash
cd wp_injector
cargo build --release
```

Binary location: `target/release/wp_injector`

## Your First Injection

### 1. Create a Simple Manifest

Create `my-workflow.toml`:

```toml
[metadata]
name = "My First Workflow"
version = "1.0.0"

[[symbols]]
name = "update_site_title"
type = "option"
rollback = "snapshot"

[symbols.parameters]
option_name = "blogname"
option_value = "My WP Praxis Site"
```

### 2. Validate the Manifest

```bash
./target/release/wp_injector validate --manifest my-workflow.toml
```

Expected output:
```
✓ Manifest validation successful!
```

### 3. Dry Run (Test Without Changes)

```bash
./target/release/wp_injector inject \
  --manifest my-workflow.toml \
  --wp-root /var/www/html \
  --dry-run
```

### 4. Execute the Injection

```bash
./target/release/wp_injector inject \
  --manifest my-workflow.toml \
  --wp-root /var/www/html
```

Expected output:
```
✓ Injection completed successfully!
  ID: inj_1732234567
  Symbols injected: 1
  Timestamp: 2025-11-22T12:34:56Z
```

### 5. Check Status

```bash
./target/release/wp_injector status --wp-root /var/www/html
```

### 6. Rollback (If Needed)

```bash
./target/release/wp_injector rollback \
  --last 1 \
  --wp-root /var/www/html
```

## Next Steps

### Try More Complex Manifests

**Custom Post Type:**

```bash
./target/release/wp_injector inject \
  --manifest examples/custom-post-type.yaml \
  --wp-root /var/www/html
```

**Complete Workflow:**

```bash
./target/release/wp_injector inject \
  --manifest examples/complete-workflow.toml \
  --wp-root /var/www/html
```

### Compare State vs Manifest

```bash
./target/release/wp_injector diff \
  --manifest my-workflow.toml \
  --wp-root /var/www/html
```

### Enable Verbose Logging

```bash
./target/release/wp_injector inject \
  --manifest my-workflow.toml \
  --wp-root /var/www/html \
  --verbose
```

### Save Logs to File

```bash
./target/release/wp_injector inject \
  --manifest my-workflow.toml \
  --wp-root /var/www/html \
  --log-file injection.log
```

## Common Patterns

### Multiple Options

```toml
[[symbols]]
name = "site_settings"
type = "option"
rollback = "snapshot"

[symbols.parameters]
option_name = "blogname"
option_value = "My Site"

[[symbols]]
name = "tagline"
type = "option"
rollback = "snapshot"

[symbols.parameters]
option_name = "blogdescription"
option_value = "My tagline"
```

### Custom Post Type with Taxonomy

```yaml
symbols:
  - name: my_cpt
    type: post_type
    rollback: snapshot
    parameters:
      post_type: portfolio
      label: Portfolio

  - name: my_tax
    type: taxonomy
    depends_on: [my_cpt]
    rollback: snapshot
    parameters:
      taxonomy: portfolio_cat
      label: Categories
```

### Dependency Chain

```toml
[[symbols]]
name = "first"
type = "option"
[symbols.parameters]
option_name = "step_1"
option_value = "done"

[[symbols]]
name = "second"
type = "option"
depends_on = ["first"]
[symbols.parameters]
option_name = "step_2"
option_value = "done"

[[symbols]]
name = "third"
type = "option"
depends_on = ["second"]
[symbols.parameters]
option_name = "step_3"
option_value = "done"
```

## Troubleshooting

### Can't Connect to Database

1. Check wp-config.php exists at `{wp-root}/wp-config.php`
2. Verify database credentials
3. Ensure MySQL is running: `systemctl status mysql`
4. Test connection: `mysql -u username -p database_name`

### Validation Fails

Run with verbose mode to see details:

```bash
./target/release/wp_injector validate \
  --manifest my-workflow.toml \
  --verbose
```

### Permission Denied

Ensure you have:
- Read access to wp-config.php
- Write access to `wp-content/.wp-praxis/`
- Database permissions for INSERT/UPDATE

## Best Practices

1. **Always validate first**: Run `validate` before `inject`
2. **Use dry run**: Test with `--dry-run` flag
3. **Version your manifests**: Use git to track manifest changes
4. **Descriptive names**: Use clear symbol names
5. **Enable rollback**: Use `rollback = "snapshot"` for safety
6. **Check dependencies**: Ensure dependency chains are correct
7. **Test rollback**: Verify rollback works in development

## Examples in This Repository

- `examples/simple-option.toml` - Single option update
- `examples/custom-post-type.yaml` - CPT with taxonomies
- `examples/complete-workflow.toml` - Full featured workflow
- `examples/rollback-demo.yaml` - Rollback strategies

## Additional Resources

- Full documentation: `README.md`
- Project guide: `../CLAUDE.md`
- Architecture docs: `../Docs/`
- Rust API docs: `cargo doc --open`

## Getting Help

1. Check error messages (usually self-explanatory)
2. Run with `--verbose` for detailed logging
3. Review example manifests
4. Check state files: `wp-content/.wp-praxis/injections/`
5. Consult README.md for detailed documentation
