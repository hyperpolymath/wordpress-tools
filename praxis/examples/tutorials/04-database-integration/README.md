# Tutorial 04: Database Integration with Ecto

## Overview

Learn how to use the Elixir/Ecto database layer for persistent state management, workflow tracking, and audit logging.

**Time Required**: 25 minutes
**Difficulty**: Intermediate
**Prerequisites**: PostgreSQL installed, Basic Elixir knowledge

## Setup Database

### 1. Install PostgreSQL

```bash
# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
```

### 2. Create Database

```bash
sudo -u postgres psql -c "CREATE DATABASE wp_praxis_dev;"
sudo -u postgres psql -c "CREATE USER wp_praxis WITH PASSWORD 'secure_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE wp_praxis_dev TO wp_praxis;"
```

### 3. Configure Elixir Application

Edit `/home/user/wp-praxis/Core/cli-wrapper/config/dev.exs`:

```elixir
config :wp_praxis, WpPraxis.Repo,
  username: "wp_praxis",
  password: "secure_password",
  database: "wp_praxis_dev",
  hostname: "localhost",
  pool_size: 10
```

## Run Migrations

```bash
cd /home/user/wp-praxis/Core/cli-wrapper

# Get dependencies
mix deps.get

# Create database
mix ecto.create

# Run migrations
mix ecto.migrate
```

**Migrations create these tables**:
- `workflow_executions` - Track workflow runs
- `symbol_executions` - Track individual symbols
- `baselines` - Store baseline snapshots
- `audit_logs` - Comprehensive audit trail

## Using the CLI

### Execute Workflow with DB Tracking

```bash
mix wp_praxis.execute \
  --workflow ../../examples/workflows/multi-language-workflow.yaml \
  --track-db
```

### Query Workflow History

```bash
# List recent executions
mix wp_praxis.list_executions --limit 10

# Get execution details
mix wp_praxis.execution --id <execution_id>

# Query by status
mix wp_praxis.list_executions --status completed
```

### Baseline Management

```bash
# List baselines
mix wp_praxis.list_baselines

# Compare baselines
mix wp_praxis.compare_baselines --before <id1> --after <id2>

# Export baseline
mix wp_praxis.export_baseline --id <baseline_id> --output ./baseline.json
```

## Schema Reference

### WorkflowExecution

```elixir
schema "workflow_executions" do
  field :workflow_name, :string
  field :status, :string
  field :started_at, :utc_datetime
  field :completed_at, :utc_datetime
  field :duration_ms, :integer
  field :metadata, :map

  has_many :symbol_executions, SymbolExecution
  timestamps()
end
```

### Query Examples

```elixir
# In IEx console
iex -S mix

# Get all completed workflows
WpPraxis.Repo.all(
  from w in WpPraxis.WorkflowExecution,
  where: w.status == "completed",
  order_by: [desc: w.completed_at],
  limit: 10
)

# Get average execution time
WpPraxis.Repo.one(
  from w in WpPraxis.WorkflowExecution,
  select: avg(w.duration_ms)
)

# Get workflow statistics
WpPraxis.Stats.workflow_stats("multi-language-workflow")
```

## GraphQL API

### Start GraphQL Server

```bash
cd /home/user/wp-praxis/SymbolicEngine/graphql

bun install
bun run server.ts
```

Access GraphQL Playground: `http://localhost:4000/graphql`

### Example Queries

```graphql
# Get recent executions
query {
  workflowExecutions(limit: 10, status: "completed") {
    id
    workflowName
    status
    duration
    startedAt
    completedAt
    symbolExecutions {
      symbolName
      status
      duration
    }
  }
}

# Get baseline comparison
query {
  compareBaselines(beforeId: "123", afterId: "456") {
    changes {
      type
      path
      before
      after
    }
    summary {
      totalChanges
      optionsChanged
      postsChanged
    }
  }
}
```

### Example Mutations

```graphql
# Create baseline
mutation {
  createBaseline(input: {
    name: "manual_baseline"
    includeOptions: true
    includePosts: true
  }) {
    id
    name
    createdAt
  }
}

# Execute workflow
mutation {
  executeWorkflow(input: {
    workflowPath: "/path/to/workflow.yaml"
    trackInDatabase: true
  }) {
    executionId
    status
  }
}
```

## Advanced Queries

### Performance Analytics

```elixir
# Get slowest symbols
WpPraxis.Analytics.slowest_symbols(limit: 10)

# Get failure rate by workflow
WpPraxis.Analytics.failure_rates()

# Get execution trends
WpPraxis.Analytics.execution_trends(days: 30)
```

### Audit Trail

```elixir
# Get all changes for a workflow execution
WpPraxis.Audit.get_changes(execution_id)

# Get audit log for date range
WpPraxis.Audit.get_logs(from: ~D[2025-11-01], to: ~D[2025-11-22])
```

## Next Steps

Continue to [Tutorial 05: Custom Symbols](../05-custom-symbols/README.md)!
