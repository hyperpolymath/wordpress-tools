# WP Praxis Manifest Format Specification

**Version:** 1.0
**Last Updated:** 2025-11-22

## Overview

WP Praxis manifests are declarative configuration files that define symbolic operations, workflows, and dispatch rules. Manifests can be written in YAML, TOML, or Dhall formats.

## Supported Formats

- **YAML 1.2** (`.yaml`, `.yml`)
- **TOML 1.0** (`.toml`, `.tml`)
- **Dhall** (`.dhall`) - Future support

## Manifest Structure

All manifests share a common structure:

```
manifest
├── version (required)
├── format (optional, auto-detected)
├── metadata (required)
│   ├── name
│   ├── description
│   ├── version
│   ├── author
│   ├── license
│   └── tags
├── symbols (required)
│   └── [ symbol definitions ]
├── workflows (optional)
│   └── [ workflow definitions ]
├── contexts (optional)
│   └── [ context definitions ]
└── dispatches (optional)
    └── [ dispatch rules ]
```

## Required Fields

### Manifest Root

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | string | Yes | Manifest format version (e.g., "1.0") |
| `format` | string | No | Format type: "yaml", "toml" (auto-detected) |
| `metadata` | object | Yes | Manifest metadata |
| `symbols` | array | Yes | Symbol definitions |
| `workflows` | array | No | Workflow definitions |
| `contexts` | array | No | Context definitions |
| `dispatches` | array | No | Dispatch rules |

### Metadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Manifest name |
| `description` | string | No | Manifest description |
| `version` | string | Yes | Manifest version (semantic versioning) |
| `author` | string | No | Manifest author |
| `license` | string | No | License (default: "AGPL-3.0") |
| `tags` | array[string] | No | Categorization tags |

### Symbol Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Symbol name (unique identifier) |
| `type` | string | Yes | Symbol type: "action", "query", "event" |
| `context` | string | Yes | Execution context (e.g., "wordpress") |
| `dispatch` | string | No | Executor hint: "rust_injector", "php_engine", "auto" |
| `parameters` | object | No | Symbol parameters |
| `dependencies` | array[string] | No | Symbol dependencies (other symbol names) |
| `metadata` | object | No | Additional metadata |
| `enabled` | boolean | No | Enable/disable symbol (default: true) |

### Workflow Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Workflow name |
| `description` | string | No | Workflow description |
| `steps` | array[step] | Yes | Workflow steps |
| `triggers` | array[object] | No | Trigger conditions |
| `conditions` | array[object] | No | Execution conditions |
| `error-handling` | string | No | Error handling: "stop", "continue" (default: "stop") |
| `parallel` | boolean | No | Parallel execution (default: false) |
| `metadata` | object | No | Additional metadata |

### Workflow Step

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `symbol` | string | Yes | Symbol to execute |
| `name` | string | No | Step name (defaults to symbol name) |
| `parameters` | object | No | Step-specific parameters |
| `continue-on-error` | boolean | No | Continue if step fails (default: false) |
| `timeout` | integer | No | Step timeout in seconds |
| `retry` | integer | No | Retry count on failure (default: 0) |

### Context Definition

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Context name |
| `type` | string | Yes | Context type: "runtime", "test", "build" |
| `configuration` | object | No | Context configuration |
| `variables` | object | No | Context variables |
| `inherits` | array[string] | No | Inherited contexts |

### Dispatch Rule

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `pattern` | object | Yes | Matching pattern |
| `executor` | string | Yes | Executor to use |
| `priority` | integer | No | Priority (higher = first, default: 0) |
| `conditions` | object | No | Additional conditions |
| `metadata` | object | No | Rule metadata |

## Symbol Types

### Action Symbols
Perform operations (mutations):
```yaml
- name: backup-database
  type: action
  context: wordpress
```

### Query Symbols
Read-only operations:
```yaml
- name: get-post-count
  type: query
  context: wordpress
```

### Event Symbols
Event handlers:
```yaml
- name: on-post-publish
  type: event
  context: wordpress
```

## Parameter Types

Parameters support various data types:

- **String**: `"value"` or `value`
- **Integer**: `42`
- **Float**: `3.14`
- **Boolean**: `true`, `false`
- **Array**: `[item1, item2]`
- **Object**: `{key: value}`
- **Null**: `null` or `~`

### Variable Interpolation

Reference environment variables:
```yaml
parameters:
  db_host: "${DB_HOST}"
  debug: "$DEBUG_MODE"
```

Reference other symbols:
```yaml
parameters:
  previous_result: "@backup-database.result"
```

## Dependency Resolution

Symbols can declare dependencies:

```yaml
symbols:
  - name: normalize-db
    dependencies: []

  - name: backup-db
    dependencies: [normalize-db]

  - name: deploy
    dependencies: [normalize-db, backup-db]
```

The parser performs topological sort to ensure correct execution order.

### Circular Dependencies

Circular dependencies are **not allowed** and will fail validation:

```yaml
# ❌ INVALID - circular dependency
symbols:
  - name: a
    dependencies: [b]
  - name: b
    dependencies: [a]
```

## Workflow Execution

### Sequential Workflows
```yaml
workflows:
  - name: deploy
    parallel: false
    steps:
      - symbol: backup-db
      - symbol: update-code
      - symbol: clear-cache
```

### Parallel Workflows
```yaml
workflows:
  - name: health-check
    parallel: true
    steps:
      - symbol: check-database
      - symbol: check-cache
      - symbol: check-filesystem
```

### Conditional Steps
```yaml
workflows:
  - name: deploy
    steps:
      - symbol: backup-db
      - symbol: deploy-code
        continue-on-error: true
      - symbol: rollback
        conditions:
          previous-failed: true
```

## Context Management

Contexts provide environment configuration:

```yaml
contexts:
  - name: production
    type: runtime
    configuration:
      environment: production
      debug: false
    variables:
      wp_path: /var/www/html
      db_host: db.example.com

  - name: staging
    type: runtime
    inherits: [production]
    configuration:
      environment: staging
      debug: true
    variables:
      wp_path: /var/www/staging
      db_host: localhost
```

## Dispatch Rules

Rules determine which executor handles each symbol:

```yaml
dispatches:
  # High-performance actions use Rust
  - pattern:
      type: action
      context: wordpress
    executor: rust_injector
    priority: 100
    conditions:
      performance: critical

  # Queries use PHP
  - pattern:
      type: query
    executor: php_engine
    priority: 50
```

## YAML Format

### Example
```yaml
version: "1.0"
metadata:
  name: "WordPress Backup"
  version: "1.0.0"

symbols:
  - name: backup-database
    type: action
    context: wordpress
    dispatch: rust_injector
    parameters:
      output_dir: "/var/backups"
      compress: true
    dependencies: []
```

### Features
- Human-readable
- Comments with `#`
- Anchors and aliases
- Multi-line strings

## TOML Format

### Example
```toml
version = "1.0"

[metadata]
name = "WordPress Backup"
version = "1.0.0"

[[symbols]]
name = "backup-database"
type = "action"
context = "wordpress"
dispatch = "rust_injector"
dependencies = []

[symbols.parameters]
output_dir = "/var/backups"
compress = true
```

### Features
- Explicit types
- Inline tables
- Array of tables with `[[...]]`
- Datetime support

## Best Practices

### Naming Conventions
- Use kebab-case for symbol names: `backup-database`
- Use descriptive workflow names: `weekly-maintenance`
- Context names reflect environment: `production`, `staging`

### Dependencies
- Keep dependency graphs shallow
- Avoid unnecessary dependencies
- Use workflows for complex orchestration

### Parameters
- Provide sensible defaults
- Document parameter types
- Use environment variables for secrets

### Validation
- Always validate manifests before deployment
- Use `strict_validation` mode in production
- Test manifests with example data

### Version Control
- Version manifests semantically
- Tag releases in git
- Document breaking changes

## Validation Rules

The parser enforces:

1. **Schema**: All required fields present
2. **Types**: Correct data types for all fields
3. **References**: Symbol dependencies exist
4. **Cycles**: No circular dependencies
5. **Uniqueness**: Symbol and workflow names are unique
6. **Constraints**: Valid enum values (e.g., symbol types)

## Examples

See `examples/` directory for complete examples:

- `simple.yaml` - Basic manifest
- `complex.toml` - Advanced features
- `wordpress.yaml` - WordPress-specific
- `macros.lfe` - Using LFE macros

## Schema Definition

JSON Schema available via CLI:
```bash
manifest-parser schema > schema.json
```

## Future Extensions

Planned features:

- **Dhall support**: Type-safe configuration
- **Include directives**: Modular manifests
- **Conditional compilation**: Environment-specific symbols
- **Macro expansion**: Template-based symbol generation
- **Schema evolution**: Version migration support

---

For implementation details, see the [API Documentation](API.md).
