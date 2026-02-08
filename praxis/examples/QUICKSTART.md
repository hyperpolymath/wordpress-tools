# WP Praxis Quick Start Guide

Get up and running with WP Praxis in under 5 minutes!

## Prerequisites

- **Docker & Docker Compose** (recommended) OR
- **Rust**, **PowerShell**, **PHP**, **Elixir**, **Bun** (for manual setup)

## Method 1: Docker (Recommended)

### Start Everything

```bash
cd /home/user/wp-praxis/examples/demos/full-stack-demo
docker-compose up -d
```

### Access Applications

- **WordPress**: http://localhost:8000
- **Dashboard**: http://localhost:3000
- **GraphQL API**: http://localhost:4000/graphql
- **Swarm Dispatcher**: http://localhost:8080

### Run Your First Workflow

```bash
docker exec wp-praxis-dispatcher \
  pwsh /app/SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath /wp-praxis/examples/workflows/simple-option-update.yaml
```

### View Results

Open http://localhost:3000 to see execution results, baselines, and visual diffs.

### Cleanup

```bash
docker-compose down
# To remove all data:
docker-compose down -v
```

**That's it!** You're running WP Praxis. Continue to [Tutorials](tutorials/) to learn more.

---

## Method 2: Quick Setup Script

### One Command Setup

```bash
cd /home/user/wp-praxis/examples/quickstart
./quickstart.sh
```

This script will:
1. Check prerequisites
2. Build Rust injector
3. Setup Elixir CLI
4. Install TypeScript dependencies
5. Create configuration
6. Run example workflow

### Next Steps

After running the script:

1. **Edit Configuration**:
   ```bash
   nano ~/.wp-praxis/config.yaml
   ```

2. **Run a Workflow**:
   ```bash
   cd /home/user/wp-praxis
   pwsh SymbolicEngine/core/symbolic.ps1 \
     -WorkflowPath examples/workflows/simple-option-update.yaml
   ```

3. **Start Dashboard**:
   ```bash
   cd SymbolicEngine/dashboard
   bun run dev
   # Open http://localhost:3000
   ```

---

## Method 3: Manual Setup

### 1. Build Components

```bash
# Rust injector
cd /home/user/wp-praxis/wp_injector
cargo build --release

# Elixir CLI
cd /home/user/wp-praxis/Core/cli-wrapper
mix deps.get && mix compile

# TypeScript (Swarm & Dashboard)
cd /home/user/wp-praxis/SymbolicEngine/swarm
bun install
cd /home/user/wp-praxis/SymbolicEngine/dashboard
bun install
```

### 2. Configure

Create `~/.wp-praxis/config.yaml`:

```yaml
wordpress:
  path: "/var/www/html"
  url: "http://localhost"

outputs:
  directory: "./outputs"

logging:
  level: "info"
  file: "./wp-praxis.log"
```

### 3. Run Workflow

```bash
cd /home/user/wp-praxis
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath examples/tutorials/01-getting-started/simple-workflow.yaml \
  -Verbose
```

---

## Common First Tasks

### Create a Baseline

```bash
pwsh SymbolicEngine/core/Set-NormativeBaseline.ps1 \
  -BaselineName "initial_state" \
  -IncludeOptions \
  -IncludePosts
```

### Run an Audit

```bash
pwsh SymbolicEngine/core/Run-SymbolicAudit.ps1 \
  -AuditType comprehensive
```

### Compare Baselines

```bash
pwsh SymbolicEngine/core/Visualize-SymbolicDiff.ps1 \
  -BaselineBefore "baseline_1" \
  -BaselineAfter "baseline_2" \
  -OutputFormat html
```

### Execute with Swarm

```bash
# Start dispatcher
cd SymbolicEngine/swarm
bun run src/dispatcher.ts &

# Start workers (in new terminals)
bun run src/worker.ts --dispatcher http://localhost:8080 &
bun run src/worker.ts --dispatcher http://localhost:8080 &

# Execute distributed workflow
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath examples/workflows/swarm-distributed.yaml \
  -SwarmDispatcher "http://localhost:8080"
```

---

## Next Steps

### Learning Path

1. **Read the Basics**
   - [CLAUDE.md](/home/user/wp-praxis/CLAUDE.md) - Project overview
   - [EXPLAINME.md](/home/user/wp-praxis/Docs/EXPLAINME.md) - Core concepts

2. **Follow Tutorials**
   - [Tutorial 01: Getting Started](tutorials/01-getting-started/README.md)
   - [Tutorial 02: WordPress Integration](tutorials/02-wordpress-integration/README.md)
   - [Tutorial 03: Swarm Setup](tutorials/03-swarm-setup/README.md)

3. **Explore Examples**
   - Browse [workflows/](workflows/)
   - Check [use-cases/](use-cases/)
   - Review [demos/](demos/)

4. **Build Your Own**
   - Copy an example workflow
   - Modify for your needs
   - Test and iterate

### Documentation

- **Architecture**: [Docs/UML/](../Docs/UML/)
- **Stack Details**: [Docs/STACK.md](../Docs/STACK.md)
- **Philosophy**: [Docs/philosophy.md](../Docs/philosophy.md)
- **Requirements**: [Docs/REQUIREMENTS.md](../Docs/REQUIREMENTS.md)

### Support

- **Examples Index**: [examples/README.md](README.md)
- **FAQ**: [examples/FAQ.md](FAQ.md)
- **Troubleshooting**: [examples/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Quick Reference

### Execute Workflow
```bash
pwsh SymbolicEngine/core/symbolic.ps1 -WorkflowPath <path>
```

### Validate Workflow
```bash
pwsh SymbolicEngine/core/symbolic.ps1 -WorkflowPath <path> -ValidateOnly
```

### Start Dashboard
```bash
cd SymbolicEngine/dashboard && bun run dev
```

### Start Swarm
```bash
cd SymbolicEngine/swarm && bun run src/dispatcher.ts
```

### Query Database
```bash
cd Core/cli-wrapper && mix wp_praxis.list_executions
```

---

**Ready to dive deeper?** Start with [Tutorial 01: Getting Started](tutorials/01-getting-started/README.md)!
