# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

# WP Praxis CLI Wrapper

**Elixir orchestration layer for WP Praxis symbolic workflows**

## Overview

The CLI wrapper provides command-line orchestration for WP Praxis, routing operations between:

- **wp_praxis_core** (Rust) - Offline manifest validation
- **wp_injector** (Rust) - Database injection
- **wp_praxis** (Elixir/Ecto) - State management and schemas
- **SymbolicEngine** (PowerShell) - Workflow execution

## Installation

```bash
cd Core/cli-wrapper
mix deps.get
mix escript.build
```

This creates the `wp-praxis` executable.

## Usage

### Validate a Manifest

```bash
./wp-praxis validate manifest.yml

# Strict mode (warnings become errors)
./wp-praxis validate --strict manifest.yml
```

### Execute a Workflow

```bash
# Dry run (no changes applied)
./wp-praxis run manifest.yml --dry-run

# Execute for real
./wp-praxis run manifest.yml
```

### Inject into WordPress Database

```bash
./wp-praxis inject manifest.yml \
  --database mysql://user:pass@localhost/wp_db
```

### Interactive Mode

```bash
./wp-praxis interactive

wp-praxis> validate examples/workflow.yml
wp-praxis> list symbols
wp-praxis> exit
```

## Architecture

```
CLI Wrapper (Elixir)
    ├── Validator → wp_praxis_core (Rust, via Port/FFI)
    ├── Dispatcher → SymbolicEngine (PowerShell, via Port)
    ├── Injector → wp_injector (Rust binary)
    └── State → wp_praxis Ecto schemas
```

## Integration Points

### 1. wp_praxis_core (Rust)

Validation is delegated to the offline Rust library:

```elixir
# In validator.ex
port = Port.open({:spawn, "wp_praxis_core_validator"}, [:binary])
Port.command(port, manifest_content)
```

### 2. wp_injector (Rust)

Database operations call the Rust binary:

```elixir
# In injector.ex
System.cmd("wp_injector", ["inject", manifest_path, "--db", db_url])
```

### 3. wp_praxis (Ecto)

State is persisted via Ecto schemas:

```elixir
# In dispatcher.ex
{:ok, workflow} = Repo.insert(%Workflow{name: "example"})
```

## Development

```bash
# Run tests
mix test

# Format code
mix format

# Type checking
mix dialyzer

# Build escript
mix escript.build
```

## RSR Compliance

- ✅ SPDX headers on all `.ex` files
- ✅ Integration with offline-first Rust core
- ✅ Reversibility via Ecto changesets
- ✅ Type safety via Dialyzer specs

## See Also

- [wp_praxis_core](../../wp_praxis_core/README.adoc) - Rust validation library
- [wp_injector](../../wp_injector/README.md) - Rust database injector
- [Core/db-schema](../db-schema/README.md) - Ecto schemas
- [CLAUDE.md](../../CLAUDE.md) - Full architecture guide

---

**Status**: Alpha (needs integration work)
**Version**: 0.1.0
**License**: AGPL-3.0-or-later
