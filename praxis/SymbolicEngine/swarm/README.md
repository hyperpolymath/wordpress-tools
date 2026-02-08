# WP Praxis Swarm

**Distributed Symbolic Execution System for WordPress Workflows**

A high-performance TypeScript-based swarm coordination system that distributes symbolic execution tasks across multiple worker nodes with real-time monitoring, state synchronization, and fault tolerance.

## Overview

The WP Praxis Swarm is the distributed execution layer of the WP Praxis meta-programming framework. It orchestrates symbolic workflow execution by:

- **Loading and parsing** declarative manifests (YAML/TOML)
- **Distributing tasks** across swarm worker nodes
- **Coordinating execution** with dependency resolution and priority queuing
- **Managing state** with SQLite-based distributed state management
- **Providing real-time communication** via WebSocket
- **Handling failures** with automatic retry logic and rollback support

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Dispatcher                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Manifest   │  │ Coordinator  │  │  WebSocket   │      │
│  │   Parser     │  │   Logic      │  │   Server     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│           │                │                  │              │
│           └────────────────┴──────────────────┘              │
│                            │                                 │
│                  ┌─────────┴─────────┐                      │
│                  │  State Manager    │                      │
│                  │    (SQLite)       │                      │
│                  └───────────────────┘                      │
└─────────────────────────┬───────────────────────────────────┘
                          │ WebSocket
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼─────┐     ┌────▼─────┐     ┌────▼─────┐
   │  Worker  │     │  Worker  │     │  Worker  │
   │  Node 1  │     │  Node 2  │     │  Node N  │
   └────┬─────┘     └────┬─────┘     └────┬─────┘
        │                │                 │
   ┌────▼─────┐     ┌────▼─────┐     ┌────▼─────┐
   │ Executor │     │ Executor │     │ Executor │
   └────┬─────┘     └────┬─────┘     └────┬─────┘
        │                │                 │
   ┌────┴────┬────┬──────┴────┬────┬──────┴─────┐
   │  Rust   │PHP │PowerShell │... │  Backends  │
   └─────────┴────┴───────────┴────┴────────────┘
```

## Features

### Core Capabilities

- **Declarative Workflows**: Define workflows in YAML or TOML manifests
- **Distributed Execution**: Automatic task distribution across worker nodes
- **Load Balancing**: Intelligent task assignment based on node capacity
- **Priority Queue**: Execute high-priority tasks first
- **Dependency Resolution**: Automatic ordering of dependent tasks
- **Fault Tolerance**: Automatic retry on failure with configurable limits
- **State Management**: SQLite-based distributed state with transactions
- **Real-time Monitoring**: WebSocket-based live status updates
- **Graceful Shutdown**: Clean termination with task completion

### Backend Support

Execute symbolic operations through multiple backends:

- **Rust Injector** (`wp_injector`): High-performance symbolic logic injection
- **PHP Engine**: WordPress-native symbolic operations
- **PowerShell Engine**: Core symbolic workflow execution
- **Internal Operations**: Built-in handlers for simple tasks

## Installation

```bash
# Navigate to swarm directory
cd SymbolicEngine/swarm

# Install dependencies
bun install

# Build the project
bun run build

# Make CLI executable (optional)
chmod +x bin/swarm-cli.ts
```

## Quick Start

### 1. Generate Configuration

```bash
bun run bin/swarm-cli.ts config ./swarm-config.toml
```

Edit `swarm-config.toml` to configure:
- Backend paths (Rust, PHP, PowerShell)
- Worker capabilities
- Network settings
- Logging preferences

### 2. Start Dispatcher

In one terminal:

```bash
bun run bin/swarm-cli.ts start-dispatcher
```

This starts:
- Coordinator for task management
- WebSocket server on port 8080
- State database at `./swarm-state.db`

### 3. Start Worker Nodes

In separate terminals:

```bash
# Worker 1
bun run bin/swarm-cli.ts start-worker ./swarm-config.toml worker-1

# Worker 2
bun run bin/swarm-cli.ts start-worker ./swarm-config.toml worker-2

# Worker N
bun run bin/swarm-cli.ts start-worker ./swarm-config.toml worker-N
```

### 4. Deploy Workflow

Create a workflow manifest (see [Workflow Format](#workflow-format)), then:

```bash
bun run bin/swarm-cli.ts deploy ./my-workflow.yaml
```

### 5. Monitor Status

```bash
bun run bin/swarm-cli.ts status
```

## Workflow Format

Workflows are defined in YAML or TOML format:

### YAML Example

```yaml
name: "example-workflow"
version: "1.0.0"
description: "Example symbolic workflow"

symbols:
  - name: "initialize"
    type: "action"
    context: "wordpress"
    dispatch: "php_engine"
    priority: 10
    parameters:
      operation: "init"

  - name: "process_data"
    type: "transform"
    context: "database"
    dispatch: "rust_injector"
    dependencies:
      - "initialize"
    parameters:
      table: "wp_posts"
      filter: "status = 'publish'"

  - name: "finalize"
    type: "action"
    context: "wordpress"
    dispatch: "php_engine"
    dependencies:
      - "process_data"
    parameters:
      operation: "cleanup"
    rollback:
      name: "rollback_finalize"
      type: "action"
      context: "wordpress"
      dispatch: "php_engine"
      parameters:
        operation: "restore"
```

### TOML Example

```toml
name = "example-workflow"
version = "1.0.0"
description = "Example symbolic workflow"

[[symbols]]
name = "initialize"
type = "action"
context = "wordpress"
dispatch = "php_engine"
priority = 10

[symbols.parameters]
operation = "init"

[[symbols]]
name = "process_data"
type = "transform"
context = "database"
dispatch = "rust_injector"
dependencies = ["initialize"]

[symbols.parameters]
table = "wp_posts"
filter = "status = 'publish'"
```

### Symbol Fields

- **name** (required): Unique symbol identifier
- **type** (required): Symbol type (`action`, `filter`, `state`, `query`, `transform`)
- **context**: Execution context (`wordpress`, `filesystem`, `database`, `network`, `generic`)
- **dispatch**: Target backend (`rust_injector`, `php_engine`, `powershell_engine`, `internal`)
- **parameters**: Symbol-specific parameters (object)
- **dependencies**: Array of symbol names that must execute first
- **priority**: Execution priority (higher = earlier, default: 0)
- **timeout**: Execution timeout in milliseconds (default: 30000)
- **retries**: Number of retry attempts on failure (default: 3)
- **rollback**: Rollback symbol to execute on failure (optional)

## CLI Commands

### start-dispatcher

Start the swarm dispatcher.

```bash
bun run bin/swarm-cli.ts start-dispatcher [config]
```

**Options:**
- `config`: Path to config file (default: `./swarm-config.toml`)

**Example:**
```bash
bun run bin/swarm-cli.ts start-dispatcher ./my-config.toml
```

### start-worker

Start a swarm worker node.

```bash
bun run bin/swarm-cli.ts start-worker [config] [name]
```

**Options:**
- `config`: Path to config file (default: `./swarm-config.toml`)
- `name`: Worker node name (overrides config)

**Example:**
```bash
bun run bin/swarm-cli.ts start-worker ./my-config.toml worker-prod-1
```

### deploy

Deploy a workflow from a manifest file.

```bash
bun run bin/swarm-cli.ts deploy <manifest> [config]
```

**Options:**
- `manifest`: Path to workflow manifest (YAML/TOML) **[required]**
- `config`: Path to config file (default: `./swarm-config.toml`)

**Example:**
```bash
bun run bin/swarm-cli.ts deploy ./workflows/production.yaml
```

### status

Show current swarm status and statistics.

```bash
bun run bin/swarm-cli.ts status [config]
```

**Example:**
```bash
bun run bin/swarm-cli.ts status
```

**Output:**
```
Coordinator Status:
  Active nodes: 3
    Idle: 2
    Busy: 1
  Queued tasks: 5
  Running tasks: 3
  Completed tasks: 42
  Failed tasks: 1

Active workflows: 2

State database:
  state: 156 records
  executions: 45 records
  tasks: 48 records
  nodes: 3 records
```

### config

Generate default configuration file.

```bash
bun run bin/swarm-cli.ts config [output]
```

**Options:**
- `output`: Output path (default: `./swarm-config.toml`)

**Example:**
```bash
bun run bin/swarm-cli.ts config ./production-config.toml
```

## Configuration

Configuration is defined in TOML format. See [`swarm-config.toml`](./swarm-config.toml) for a fully documented example.

### Key Sections

#### Dispatcher

```toml
[dispatcher]
coordinator_endpoint = "ws://localhost:8080"
state_db_path = "./swarm-state.db"
enable_websocket = true
websocket_port = 8080
```

#### Coordinator

```toml
[coordinator]
max_workers = 100
heartbeat_interval = 5000
heartbeat_timeout = 15000
task_retry_limit = 3
enable_load_balancing = true
priority_queue_enabled = true
```

#### Worker

```toml
[worker]
node_name = "worker-node-1"
dispatcher_url = "ws://localhost:8080"
heartbeat_interval = 5000
max_concurrent_tasks = 4

[worker.capabilities]
rust = true
php = true
powershell = true
```

#### Backends

```toml
[backends.rust_injector]
enabled = true
binary_path = "../../wp_injector/target/release/wp_injector"
timeout = 30000

[backends.php_engine]
enabled = true
script_path = "../../engine/php/symbolic-engine.php"
php_binary = "php"
timeout = 30000

[backends.powershell_engine]
enabled = true
script_path = "../../SymbolicEngine/core/symbolic.ps1"
pwsh_binary = "pwsh"
timeout = 30000
```

## Programmatic Usage

You can use the swarm system programmatically in your TypeScript code:

```typescript
import { createDispatcher, createWorker } from '@wp-praxis/swarm';
import { StateManager } from '@wp-praxis/swarm/state-manager';
import { Logger } from '@wp-praxis/swarm/logger';

// Configure logger
Logger.configure({
  level: 'info',
  console: true,
  format: 'json',
});

// Create dispatcher
const dispatcher = createDispatcher({
  coordinatorEndpoint: 'ws://localhost:8080',
  stateDbPath: './swarm.db',
  enableWebSocket: true,
  websocketPort: 8080,
});

// Start dispatcher
await dispatcher.start();

// Deploy workflow
const result = await dispatcher.dispatchFromFile('./workflow.yaml');

console.log(`Completed: ${result.completedTasks}/${result.totalTasks}`);

// Stop dispatcher
await dispatcher.stop();
```

## Development

### Project Structure

```
swarm/
├── bin/
│   └── swarm-cli.ts          # CLI interface
├── src/
│   ├── types.ts              # TypeScript type definitions
│   ├── logger.ts             # Logging system
│   ├── state-manager.ts      # SQLite state management
│   ├── executor.ts           # Symbol execution
│   ├── coordinator.ts        # Task coordination
│   ├── worker.ts             # Worker node
│   ├── dispatch.ts           # Main dispatcher
│   └── websocket-server.ts   # WebSocket server
├── package.json              # Dependencies
├── tsconfig.json             # TypeScript config
├── swarm-config.toml         # Default configuration
└── README.md                 # This file
```

### Building

```bash
# TypeScript type checking
bun run lint

# Build project
bun run build

# Run tests
bun test

# Watch mode for development
bun run dev
```

### Testing

Create test manifests in the `examples/` directory:

```bash
# Test with sample workflow
bun run bin/swarm-cli.ts deploy ../../examples/sample-workflow.toml
```

## Troubleshooting

### Workers not connecting

**Problem**: Workers fail to connect to dispatcher.

**Solution**:
- Ensure dispatcher is running: `bun run bin/swarm-cli.ts start-dispatcher`
- Check WebSocket port is not blocked: `netstat -an | grep 8080`
- Verify `dispatcher_url` in worker config matches dispatcher endpoint

### Tasks failing immediately

**Problem**: All tasks fail with execution errors.

**Solution**:
- Check backend paths in configuration
- Ensure backends are executable: `chmod +x /path/to/backend`
- Verify worker capabilities match task requirements
- Check backend health: Run backends manually to test

### State database locked

**Problem**: SQLite database lock errors.

**Solution**:
- Stop all dispatcher and worker processes
- Remove lock file: `rm swarm-state.db-shm swarm-state.db-wal`
- Restart dispatcher

### High memory usage

**Problem**: Memory usage grows over time.

**Solution**:
- Reduce `max_concurrent_tasks` in worker config
- Enable state cleanup: Call `stateManager.cleanup(olderThanMs)`
- Increase `heartbeat_timeout` to reduce churn

## Performance Tuning

### For High Throughput

```toml
[coordinator]
max_workers = 200
enable_load_balancing = true
priority_queue_enabled = true

[worker]
max_concurrent_tasks = 8
```

### For Low Latency

```toml
[coordinator]
heartbeat_interval = 2000
heartbeat_timeout = 6000

[worker]
max_concurrent_tasks = 2
```

### For Reliability

```toml
[coordinator]
task_retry_limit = 5
heartbeat_timeout = 30000

[backends.rust_injector]
timeout = 60000
```

## Integration with WP Praxis

The swarm system integrates with the broader WP Praxis framework:

- **Manifests**: Created by CLI wrapper (`Core/cli-wrapper/`)
- **Rust Injector**: Binary at `wp_injector/target/release/wp_injector`
- **PHP Engine**: Script at `engine/php/symbolic-engine.php`
- **PowerShell Engine**: Script at `SymbolicEngine/core/symbolic.ps1`

## License

GNU AGPL v3 - See project root LICENSE file

## Contributing

This is part of the WP Praxis meta-programming framework. See main project CLAUDE.md for contribution guidelines.

## Support

For issues, questions, or contributions, please refer to the main WP Praxis project documentation.

---

**WP Praxis Swarm** - Distributed symbolic execution at scale.
