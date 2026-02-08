# WP Praxis Database Schema - Quick Start Guide

## Installation & Setup

```bash
cd /home/user/wp-praxis/Core/db-schema

# Install dependencies
mix deps.get

# Create and setup database
mix ecto.setup

# This runs:
#   - mix ecto.create (creates database)
#   - mix ecto.migrate (runs migrations)
#   - mix run priv/repo/seeds.exs (loads sample data)
```

## Interactive Console

```bash
# Start interactive Elixir shell with database access
iex -S mix

# Try these commands:
iex> SymbolQueries.active_symbols()
iex> WorkflowQueries.workflow_stats()
iex> AuditQueries.recent_audits(24)
```

## Common Operations

### Create a Symbol

```elixir
Symbol.create(%{
  name: "my_operation",
  type: "action",
  context: "wordpress",
  dispatch_target: "php",
  description: "My custom operation"
})
```

### Create a Workflow

```elixir
Workflow.create(%{
  name: "my_workflow",
  manifest_path: "/path/to/manifest.yml"
})
```

### Run a Workflow

```elixir
# Get workflow
{:ok, workflow} = Workflow.create(%{...})

# Start it
{:ok, workflow} = Workflow.start(workflow)

# Log events
Workflow.log_event(workflow, %{type: "started", message: "Beginning execution"})

# Complete it
Workflow.complete(workflow, "completed")
```

### Create an Execution

```elixir
# Create execution for a symbol in a workflow
{:ok, execution} = Execution.create(%{
  workflow_id: workflow.id,
  symbol_id: symbol.id
})

# Start execution
{:ok, execution} = Execution.start(execution)

# Complete with output
{:ok, execution} = Execution.complete(execution, %{result: "success"})
```

### Create and Run Audit

```elixir
# Create baseline
{:ok, baseline} = Baseline.create(%{
  name: "prod_baseline",
  symbolic_state: %{plugins: ["woocommerce"], theme: "storefront"}
})

# Run audit
{:ok, audit} = Audit.create(%{baseline_id: baseline.id})
{:ok, audit} = Audit.start(audit)

# Complete with deviations
deviations = [
  %{type: "plugin_missing", severity: "warning", expected: "woocommerce", actual: nil}
]
{:ok, audit} = Audit.complete(audit, deviations)
```

## Query Examples

```elixir
# Get active symbols
SymbolQueries.active_symbols()

# Search symbols
SymbolQueries.search_by_name("wordpress")

# Get workflows by status
WorkflowQueries.by_status("running")

# Get recent audits
AuditQueries.recent_audits(48)  # last 48 hours

# Get critical audits
AuditQueries.critical_audits()

# Get workflow statistics
WorkflowQueries.workflow_stats()
# => %{total: 10, pending: 2, running: 1, completed: 6, failed: 1, paused: 0}
```

## Testing

```bash
# Run all tests
mix test

# Run specific test file
mix test test/schema/symbol_test.exs

# Run with coverage
mix test --cover
```

## Code Formatting

```bash
# Format all code
mix format

# Check if code is formatted
mix format --check-formatted
```

## Database Commands

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback last migration
mix ecto.rollback

# Reset database (drop, create, migrate)
mix ecto.reset

# Run seeds
mix run priv/repo/seeds.exs

# Generate new migration
mix ecto.gen.migration add_custom_field
```

## Project Structure

```
Core/db-schema/
├── lib/
│   └── wp_praxis/
│       ├── schema/          # Database schemas (5 files)
│       │   ├── symbol.ex
│       │   ├── workflow.ex
│       │   ├── execution.ex
│       │   ├── baseline.ex
│       │   └── audit.ex
│       ├── queries/         # Query modules (3 files)
│       │   ├── symbol_queries.ex
│       │   ├── workflow_queries.ex
│       │   └── audit_queries.ex
│       ├── application.ex   # Application supervisor
│       └── repo.ex          # Ecto repository
├── priv/repo/
│   ├── migrations/          # Database migrations (5 files)
│   └── seeds.exs           # Sample data
├── test/                    # Test suite
├── config/                  # Configuration files
└── mix.exs                 # Project definition
```

## Integration with WP Praxis

This database schema is used by:

1. **CLI Wrapper** (`Core/cli-wrapper/`) - Command-line interface
2. **Runtime** (`Core/runtime/`) - Execution orchestration
3. **Symbolic Engine** (`SymbolicEngine/core/`) - PowerShell operations

## Next Steps

1. Review the comprehensive [README.md](README.md) for detailed documentation
2. Explore the schema files in `lib/wp_praxis/schema/`
3. Check out query modules in `lib/wp_praxis/queries/`
4. Run `iex -S mix` to explore the database interactively
5. Read migrations in `priv/repo/migrations/` to understand the schema

## Troubleshooting

**Database connection issues:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify config in config/dev.exs
```

**Migration errors:**
```bash
# Check migration status
mix ecto.migrations

# Rollback and retry
mix ecto.rollback
mix ecto.migrate
```

**Test failures:**
```bash
# Ensure test database exists
MIX_ENV=test mix ecto.create
MIX_ENV=test mix ecto.migrate
```

## Documentation

- Full documentation: [README.md](README.md)
- Schema docs: [lib/wp_praxis/schema/](lib/wp_praxis/schema/)
- Query docs: [lib/wp_praxis/queries/](lib/wp_praxis/queries/)
- CLAUDE.md: Project-wide AI assistant guide

## Version

0.1.0 (Early development)
