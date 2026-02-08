# Tutorial 03: Swarm Setup - Distributed Execution

## Overview

Learn how to set up and use WP Praxis swarm for distributed parallel execution of workflows across multiple workers.

**Time Required**: 30 minutes
**Difficulty**: Advanced
**Prerequisites**:
- Completed Tutorials 01 and 02
- Multiple machines or containers for workers
- Network connectivity between dispatcher and workers

## Architecture

```
┌─────────────┐
│  Dispatcher │  (Coordinator)
└──────┬──────┘
       │
       ├──────────┬──────────┬──────────┐
       │          │          │          │
    ┌──▼───┐  ┌──▼───┐  ┌──▼───┐  ┌──▼───┐
    │Worker│  │Worker│  │Worker│  │Worker│
    │  #1  │  │  #2  │  │  #3  │  │  #4  │
    └──────┘  └──────┘  └──────┘  └──────┘
```

## Step 1: Start the Dispatcher

The dispatcher coordinates workflow execution across workers.

```bash
cd /home/user/wp-praxis/SymbolicEngine/swarm

# Install dependencies
bun install

# Start dispatcher
bun run src/dispatcher.ts --port 8080 --workers-min 2 --workers-max 10
```

**Expected Output**:
```
[INFO] WP Praxis Swarm Dispatcher starting...
[INFO] Listening on https://0.0.0.0:8080
[INFO] Worker requirements: min=2, max=10
[INFO] Load balancing: least_busy
[INFO] Health check interval: 5s
[INFO] Dispatcher ready and awaiting workers
```

## Step 2: Start Workers

On each worker machine:

```bash
cd /home/user/wp-praxis/SymbolicEngine/swarm

# Start worker
bun run src/worker.ts \
  --dispatcher https://dispatcher-host:8080 \
  --capabilities rust,php,powershell \
  --max-concurrent 3
```

**Worker Output**:
```
[INFO] WP Praxis Swarm Worker starting...
[INFO] Connecting to dispatcher: https://dispatcher-host:8080
[INFO] Capabilities: rust, php, powershell
[INFO] Max concurrent tasks: 3
[INFO] Registration successful
[INFO] Worker ID: worker-a1b2c3d4
[INFO] Worker ready and awaiting tasks
```

## Step 3: Verify Swarm Status

Check dispatcher logs to see registered workers:

```
[INFO] Worker registered: worker-a1b2c3d4
  - Host: 192.168.1.10
  - Capabilities: rust, php, powershell
  - Max concurrent: 3
  - Status: idle

[INFO] Worker registered: worker-e5f6g7h8
  - Host: 192.168.1.11
  - Capabilities: rust, php, powershell
  - Max concurrent: 3
  - Status: idle

[INFO] Swarm ready: 2 workers available
```

## Step 4: Execute Distributed Workflow

Use the provided `swarm-distributed.yaml` workflow:

```bash
cd /home/user/wp-praxis

pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath examples/workflows/swarm-distributed.yaml \
  -SwarmDispatcher "http://localhost:8080" \
  -Verbose
```

**Execution Output**:
```
[INFO] Workflow: swarm-distributed
[INFO] Swarm mode: enabled
[INFO] Dispatcher: http://localhost:8080
[INFO] Discovering workers...
[INFO] Workers available: 2
[INFO] Executing symbol: update_general_settings
[INFO]   Assigned to worker: worker-a1b2c3d4
[INFO] Executing symbol: update_reading_settings
[INFO]   Assigned to worker: worker-e5f6g7h8
[INFO] Executing symbol: update_discussion_settings
[INFO]   Assigned to worker: worker-a1b2c3d4
[INFO] Parallel group 'options_update' completed (3 symbols, 0.25s)
[INFO] Executing symbol: create_bulk_posts_1
[INFO]   Assigned to worker: worker-a1b2c3d4
[INFO] Executing symbol: create_bulk_posts_2
[INFO]   Assigned to worker: worker-e5f6g7h8
[INFO] Executing symbol: create_bulk_posts_3
[INFO]   Assigned to worker: worker-a1b2c3d4
[INFO] Parallel group 'content_creation' completed (300 posts, 2.1s)
[INFO] Workflow completed successfully
[INFO] Total duration: 3.5s
[INFO] Speedup vs sequential: 4.2x
```

## Step 5: Monitor Swarm Dashboard

Access the web-based swarm dashboard:

```
http://localhost:8080/dashboard
```

**Dashboard shows**:
- Worker status and health
- Active tasks per worker
- Performance metrics
- Load distribution charts

## Configuration Options

### Dispatcher Config

Create `swarm-dispatcher-config.toml`:

```toml
[dispatcher]
host = "0.0.0.0"
port = 8080

[workers]
min_count = 2
max_count = 10
auto_scale = true
health_check_interval = 5

[load_balancing]
strategy = "least_busy"  # Options: least_busy, round_robin, random
rebalance_threshold = 0.3

[monitoring]
enabled = true
metrics_export_interval = 10
metrics_destination = "./swarm-metrics/"
```

### Worker Config

Create `swarm-worker-config.toml`:

```toml
[worker]
capabilities = ["rust", "php", "powershell", "elixir"]
max_concurrent = 5

[dispatcher]
host = "https://dispatcher-host"
port = 8080
reconnect_interval = 5
heartbeat_interval = 3

[resources]
max_memory_mb = 2048
max_cpu_percent = 80
```

## Advanced Features

### Auto-scaling

Workers automatically scale based on load:

```toml
[auto_scaling]
enabled = true
scale_up_threshold = 0.8  # Add worker at 80% capacity
scale_down_threshold = 0.2  # Remove worker at 20% capacity
cooldown_seconds = 60
```

### Task Affinity

Assign specific tasks to specific workers:

```yaml
symbols:
  - name: "heavy_computation"
    execution:
      swarm_enabled: true
      worker_affinity:
        - worker-gpu-enabled
        - worker-high-memory
```

### Fault Tolerance

Automatically retry failed tasks on different workers:

```yaml
config:
  swarm:
    retry_on_worker_failure: true
    max_retries: 3
    rebalance_on_failure: true
```

## Docker Swarm Example

Deploy using Docker:

```bash
cd /home/user/wp-praxis/examples/docker

# Start dispatcher
docker-compose up -d dispatcher

# Start workers (scale to 4)
docker-compose up -d --scale worker=4
```

## Monitoring & Metrics

### Real-time Metrics

```bash
# Get swarm status
curl http://localhost:8080/api/status

# Get worker metrics
curl http://localhost:8080/api/workers

# Get execution statistics
curl http://localhost:8080/api/stats
```

### Performance Report

After execution, check performance report:

```json
{
  "workflow": "swarm-distributed",
  "total_duration": 3.5,
  "sequential_estimate": 14.7,
  "speedup": 4.2,
  "efficiency": 84.0,
  "workers_used": 2,
  "symbols_executed": 17,
  "parallel_groups": 3
}
```

## Troubleshooting

### Workers Not Connecting

**Check network connectivity**:
```bash
# From worker machine
curl https://dispatcher-host:8080/health
```

### Uneven Load Distribution

**Monitor worker utilization**:
- Check dashboard for CPU/memory usage
- Adjust `max_concurrent` on busy workers
- Change load balancing strategy

### Task Failures

**Check worker logs**:
```bash
tail -f /home/user/wp-praxis/SymbolicEngine/swarm/logs/worker.log
```

## Next Steps

Continue to [Tutorial 04: Database Integration](../04-database-integration/README.md)!
