# WP Praxis Database Schema

Ecto-based database schema and state management for the WP Praxis symbolic workflow system.

## Overview

This Elixir/Ecto project provides:

- **Database schemas** for symbolic system entities (Symbols, Workflows, Executions, Baselines, Audits)
- **Migrations** with proper indexing for performance
- **Query modules** with common database operations
- **State management** for the symbolic workflow system

## Requirements

- Elixir 1.14 or higher
- PostgreSQL 12 or higher
- Erlang/OTP 24 or higher

## Installation

```bash
cd Core/db-schema

# Install dependencies
mix deps.get

# Create the database
mix ecto.create

# Run migrations
mix ecto.migrate
```

## Database Schemas

### Symbol

Declarative operation definitions that can be dispatched to execution engines.

**Fields:**
- `name` - Unique symbol identifier
- `type` - Symbol type (action, transform, query, validator, generator)
- `context` - Execution context (wordpress, system, database, etc.)
- `status` - Current status (active, inactive, deprecated)
- `dispatch_target` - Target executor (rust_injector, powershell, php, etc.)
- `parameters` - JSON map of symbol-specific parameters
- `priority` - Execution priority (1-10)
- `timeout` - Execution timeout in seconds
- `retry_count` - Number of retry attempts on failure

### Workflow

Collections of symbols organized into execution plans.

**Fields:**
- `name` - Unique workflow identifier
- `manifest_path` - Path to YAML/TOML manifest
- `status` - Workflow status (pending, running, completed, failed, paused)
- `execution_log` - JSON array of execution events
- `started_at` / `completed_at` - Timing information
- `duration` - Total execution time in seconds

### Execution

Runtime tracking of individual symbol invocations within workflows.

**Fields:**
- `workflow_id` - Reference to parent workflow
- `symbol_id` - Reference to symbol being executed
- `status` - Execution status (pending, running, completed, failed, retrying)
- `output` - JSON map of execution output
- `error_log` - Error messages if failed
- `rollback_state` - Snapshot for potential rollback
- `retry_attempt` - Current retry attempt number

### Baseline

Normative states for symbolic auditing and deviation detection.

**Fields:**
- `name` - Unique baseline identifier
- `symbolic_state` - JSON snapshot of system state
- `version` - Semantic version number
- `is_active` - Whether baseline is active for auditing
- `baseline_type` - Type (system, workflow, component, custom)
- `scope` - Scope (global, workflow, symbol, component)

### Audit

Deviation tracking from baselines for compliance and debugging.

**Fields:**
- `baseline_id` - Reference to baseline being audited
- `workflow_id` - Optional workflow that triggered audit
- `audit_type` - Type (scheduled, triggered, manual, continuous)
- `status` - Audit status (pending, running, completed, failed)
- `deviations` - JSON array of detected deviations
- `severity` - Overall severity (info, warning, error, critical)
- `recommendations` - JSON array of remediation actions

## Usage Examples

### Working with Symbols

```elixir
alias WpPraxis.Schema.Symbol
alias WpPraxis.Queries.SymbolQueries

# Create a symbol
{:ok, symbol} = Symbol.create(%{
  name: "wordpress_plugin_activate",
  type: "action",
  context: "wordpress",
  dispatch_target: "php",
  parameters: %{plugin_slug: "my-plugin"}
})

# Query symbols
active_symbols = SymbolQueries.active_symbols()
wp_symbols = SymbolQueries.by_context("wordpress")
actions = SymbolQueries.by_type("action")
```

### Working with Workflows

```elixir
alias WpPraxis.Schema.Workflow
alias WpPraxis.Queries.WorkflowQueries

# Create a workflow
{:ok, workflow} = Workflow.create(%{
  name: "plugin_deployment",
  manifest_path: "/path/to/manifest.yml"
})

# Start workflow execution
{:ok, workflow} = Workflow.start(workflow)

# Log events
{:ok, workflow} = Workflow.log_event(workflow, %{
  type: "symbol_executed",
  symbol: "wordpress_plugin_activate",
  result: "success"
})

# Complete workflow
{:ok, workflow} = Workflow.complete(workflow, "completed")

# Query workflows
active = WorkflowQueries.active_workflows()
recent = WorkflowQueries.recently_completed(24)
```

### Working with Executions

```elixir
alias WpPraxis.Schema.Execution

# Create execution
{:ok, execution} = Execution.create(%{
  workflow_id: workflow.id,
  symbol_id: symbol.id
})

# Start execution
{:ok, execution} = Execution.start(execution)

# Complete successfully
{:ok, execution} = Execution.complete(execution, %{result: "success"}, 0)

# Or mark as failed
{:ok, execution} = Execution.fail(execution, "Error message", 1)
```

### Working with Baselines and Audits

```elixir
alias WpPraxis.Schema.Baseline
alias WpPraxis.Schema.Audit

# Create baseline
{:ok, baseline} = Baseline.create(%{
  name: "production_baseline_v1",
  symbolic_state: %{
    wordpress_version: "6.4",
    active_plugins: ["plugin-a", "plugin-b"]
  }
})

# Activate baseline (deactivates others)
{:ok, baseline} = Baseline.activate(baseline)

# Run audit against baseline
{:ok, audit} = Audit.create(%{baseline_id: baseline.id})
{:ok, audit} = Audit.start(audit)

# Complete audit with deviations
deviations = [
  %{
    type: "plugin_mismatch",
    severity: "warning",
    expected: "plugin-a",
    actual: "plugin-c"
  }
]

{:ok, audit} = Audit.complete(audit, deviations)
```

## Query Modules

### SymbolQueries

- `active_symbols/0` - Get all active symbols
- `by_type/1` - Get symbols by type
- `by_context/1` - Get symbols by context
- `by_type_and_context/2` - Get symbols by type and context
- `find_by_name/1` - Find symbol by name
- `high_priority_symbols/0` - Get high priority symbols
- `search_by_name/1` - Search symbols by name pattern
- And more...

### WorkflowQueries

- `active_workflows/0` - Get active workflows
- `by_status/1` - Get workflows by status
- `recently_completed/1` - Get recently completed workflows
- `execution_history/1` - Get workflow execution history
- `workflow_stats/0` - Get workflow statistics
- And more...

### AuditQueries

- `recent_audits/1` - Get recent audits
- `by_baseline/1` - Get audits by baseline
- `critical_audits/0` - Get critical audits
- `with_deviations/0` - Get audits with deviations
- `deviation_trends/2` - Get deviation trends over time
- And more...

## Database Operations

### Setup

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Reset database (drop, create, migrate)
mix ecto.reset
```

### Migrations

```bash
# Create a new migration
mix ecto.gen.migration migration_name

# Run pending migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Rollback N migrations
mix ecto.rollback --step 3
```

### Seeds

Create a `priv/repo/seeds.exs` file to populate initial data:

```elixir
# priv/repo/seeds.exs
alias WpPraxis.Schema.Symbol

Symbol.create(%{
  name: "wordpress_init",
  type: "action",
  context: "wordpress",
  dispatch_target: "php"
})
```

Run seeds:

```bash
mix run priv/repo/seeds.exs
```

## Testing

```bash
# Run tests
mix test

# Run with coverage
mix test --cover
```

## Code Quality

```bash
# Format code
mix format

# Run static analysis (requires Credo)
mix credo

# Run type checking (requires Dialyzer)
mix dialyzer
```

## Configuration

### Development

Database configuration in `config/dev.exs`:

```elixir
config :wp_praxis, WpPraxis.Repo,
  database: "wp_praxis_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"
```

### Production

Set the `DATABASE_URL` environment variable:

```bash
export DATABASE_URL="ecto://user:pass@host/database"
```

## Integration

This database schema is used by:

- **CLI Wrapper** (`Core/cli-wrapper/`) - Elixir CLI for orchestration
- **Runtime** (`Core/runtime/`) - Runtime state management
- **Symbolic Engine** (`SymbolicEngine/core/`) - PowerShell symbolic operations

## Architecture

The database schema supports the WP Praxis symbolic workflow system by:

1. **Storing symbol definitions** parsed from YAML/TOML manifests
2. **Tracking workflow execution** across distributed components
3. **Managing execution state** for runtime introspection
4. **Maintaining baselines** for normative state comparison
5. **Recording audits** for compliance and deviation analysis

## Performance

Migrations include optimized indexes for:

- Common query patterns (status, type, context)
- Foreign key relationships
- Timing-based queries
- Partial indexes for active records
- Composite indexes for multi-field queries

## License

GNU AGPL v3 - See LICENSE file for details

## Version

0.1.0 (Early development)
