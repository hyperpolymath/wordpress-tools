#!/usr/bin/env bun

/**
 * WP Praxis Swarm - CLI Interface
 *
 * Command-line interface for swarm coordination with commands:
 * - start: Start dispatcher or worker
 * - stop: Stop running components
 * - status: Show swarm status
 * - deploy: Deploy a workflow
 * - scale: Scale worker nodes
 * - config: Manage configuration
 */

import { existsSync, readFileSync, writeFileSync } from 'fs';
import { resolve, join } from 'path';
import { parse as parseTOML } from 'toml';
import type { SwarmConfig, WorkerConfig } from '../src/types';
import { createDispatcher } from '../src/dispatch';
import { createWorker } from '../src/worker';
import { StateManager } from '../src/state-manager';
import { Logger } from '../src/logger';

// ============================================================================
// Configuration
// ============================================================================

const DEFAULT_CONFIG_PATH = './swarm-config.toml';
const DEFAULT_STATE_DB = './swarm-state.db';
const DEFAULT_LOG_FILE = './swarm.log';

/**
 * Load configuration from file
 */
function loadConfig(configPath: string): SwarmConfig {
  if (!existsSync(configPath)) {
    console.error(`Configuration file not found: ${configPath}`);
    process.exit(1);
  }

  try {
    const content = readFileSync(configPath, 'utf-8');
    const config = parseTOML(content) as any;

    return {
      dispatcher: {
        coordinatorEndpoint: config.dispatcher?.coordinator_endpoint ?? 'ws://localhost:8080',
        stateDbPath: config.dispatcher?.state_db_path ?? DEFAULT_STATE_DB,
        enableWebSocket: config.dispatcher?.enable_websocket ?? true,
        websocketPort: config.dispatcher?.websocket_port ?? 8080,
      },
      coordinator: {
        maxWorkers: config.coordinator?.max_workers ?? 100,
        heartbeatInterval: config.coordinator?.heartbeat_interval ?? 5000,
        heartbeatTimeout: config.coordinator?.heartbeat_timeout ?? 15000,
        taskRetryLimit: config.coordinator?.task_retry_limit ?? 3,
        enableLoadBalancing: config.coordinator?.enable_load_balancing ?? true,
        priorityQueueEnabled: config.coordinator?.priority_queue_enabled ?? true,
      },
      worker: {
        nodeName: config.worker?.node_name ?? 'worker-node',
        dispatcherUrl: config.worker?.dispatcher_url ?? 'ws://localhost:8080',
        heartbeatInterval: config.worker?.heartbeat_interval ?? 5000,
        maxConcurrentTasks: config.worker?.max_concurrent_tasks ?? 4,
        capabilities: {
          rust: config.worker?.capabilities?.rust ?? false,
          php: config.worker?.capabilities?.php ?? false,
          powershell: config.worker?.capabilities?.powershell ?? false,
          maxConcurrentTasks: config.worker?.capabilities?.max_concurrent_tasks ?? 4,
        },
        backends: {
          rustInjector: config.backends?.rust_injector
            ? {
                enabled: config.backends.rust_injector.enabled ?? false,
                binaryPath: config.backends.rust_injector.binary_path ?? '/path/to/wp_injector',
                timeout: config.backends.rust_injector.timeout ?? 30000,
              }
            : undefined,
          phpEngine: config.backends?.php_engine
            ? {
                enabled: config.backends.php_engine.enabled ?? false,
                scriptPath: config.backends.php_engine.script_path ?? '/path/to/symbolic-engine.php',
                phpBinary: config.backends.php_engine.php_binary ?? 'php',
                timeout: config.backends.php_engine.timeout ?? 30000,
              }
            : undefined,
          powershellEngine: config.backends?.powershell_engine
            ? {
                enabled: config.backends.powershell_engine.enabled ?? false,
                scriptPath: config.backends.powershell_engine.script_path ?? '/path/to/symbolic.ps1',
                pwshBinary: config.backends.powershell_engine.pwsh_binary ?? 'pwsh',
                timeout: config.backends.powershell_engine.timeout ?? 30000,
              }
            : undefined,
        },
      },
      logging: {
        level: config.logging?.level ?? 'info',
        file: config.logging?.file ?? DEFAULT_LOG_FILE,
        console: config.logging?.console ?? true,
        format: config.logging?.format ?? 'text',
      },
    };
  } catch (error) {
    console.error('Failed to load configuration:', error);
    process.exit(1);
  }
}

/**
 * Initialize logger
 */
function initLogger(config: SwarmConfig): void {
  Logger.configure(config.logging);
}

// ============================================================================
// Commands
// ============================================================================

/**
 * Start dispatcher command
 */
async function startDispatcher(configPath: string): Promise<void> {
  console.log('Starting WP Praxis Swarm Dispatcher...\n');

  const config = loadConfig(configPath);
  initLogger(config);

  const logger = new Logger('CLI');
  const dispatcher = createDispatcher(config.dispatcher, logger.child('Dispatcher'));

  // Handle graceful shutdown
  process.on('SIGINT', async () => {
    console.log('\nShutting down dispatcher...');
    await dispatcher.stop();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    console.log('\nShutting down dispatcher...');
    await dispatcher.stop();
    process.exit(0);
  });

  // Start dispatcher
  await dispatcher.start();

  console.log(`Dispatcher started successfully!`);
  console.log(`WebSocket server: ws://localhost:${config.dispatcher.websocketPort}`);
  console.log(`State database: ${config.dispatcher.stateDbPath}`);
  console.log('\nPress Ctrl+C to stop\n');

  // Keep process alive
  await new Promise(() => {});
}

/**
 * Start worker command
 */
async function startWorker(configPath: string, nodeName?: string): Promise<void> {
  console.log('Starting WP Praxis Swarm Worker...\n');

  const config = loadConfig(configPath);
  initLogger(config);

  const logger = new Logger('CLI');

  // Override node name if provided
  if (nodeName) {
    config.worker.nodeName = nodeName;
  }

  const stateManager = new StateManager(
    `./worker-${config.worker.nodeName}.db`,
    logger.child('StateManager')
  );

  const worker = createWorker(config.worker, stateManager, logger.child('Worker'));

  // Handle graceful shutdown
  process.on('SIGINT', async () => {
    console.log('\nShutting down worker...');
    await worker.stop();
    stateManager.close();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    console.log('\nShutting down worker...');
    await worker.stop();
    stateManager.close();
    process.exit(0);
  });

  // Start worker
  await worker.start(config.worker.dispatcherUrl);

  console.log(`Worker started successfully!`);
  console.log(`Node name: ${config.worker.nodeName}`);
  console.log(`Connected to: ${config.worker.dispatcherUrl}`);
  console.log(`Capabilities: ${JSON.stringify(config.worker.capabilities, null, 2)}`);
  console.log('\nPress Ctrl+C to stop\n');

  // Keep process alive
  await new Promise(() => {});
}

/**
 * Deploy workflow command
 */
async function deployWorkflow(configPath: string, manifestPath: string): Promise<void> {
  console.log('Deploying workflow...\n');

  const config = loadConfig(configPath);
  initLogger(config);

  const logger = new Logger('CLI');
  const dispatcher = createDispatcher(config.dispatcher, logger.child('Dispatcher'));

  await dispatcher.start();

  console.log(`Loading manifest: ${manifestPath}`);
  const result = await dispatcher.dispatchFromFile(manifestPath);

  console.log('\nWorkflow Deployment Results:');
  console.log(`Workflow ID: ${result.workflowId}`);
  console.log(`Total tasks: ${result.totalTasks}`);
  console.log(`Completed: ${result.completedTasks}`);
  console.log(`Failed: ${result.failedTasks}`);
  console.log(`Duration: ${result.duration}ms`);

  await dispatcher.stop();

  if (result.failedTasks > 0) {
    console.error('\nWorkflow deployment had failures');
    process.exit(1);
  } else {
    console.log('\nWorkflow deployed successfully!');
    process.exit(0);
  }
}

/**
 * Show status command
 */
async function showStatus(configPath: string): Promise<void> {
  console.log('WP Praxis Swarm Status\n');

  const config = loadConfig(configPath);
  initLogger(config);

  const logger = new Logger('CLI');
  const dispatcher = createDispatcher(config.dispatcher, logger.child('Dispatcher'));

  await dispatcher.start();

  const stats = dispatcher.getStats();

  console.log('Coordinator Status:');
  console.log(`  Active nodes: ${stats.coordinator.nodes.active}`);
  console.log(`    Idle: ${stats.coordinator.nodes.idle}`);
  console.log(`    Busy: ${stats.coordinator.nodes.busy}`);
  console.log(`  Queued tasks: ${stats.coordinator.tasks.queued}`);
  console.log(`  Running tasks: ${stats.coordinator.tasks.running}`);
  console.log(`  Completed tasks: ${stats.coordinator.tasks.completed}`);
  console.log(`  Failed tasks: ${stats.coordinator.tasks.failed}`);
  console.log(`\nActive workflows: ${stats.activeWorkflows}`);
  console.log(`\nState database:`);
  Object.entries(stats.state).forEach(([table, count]) => {
    console.log(`  ${table}: ${count} records`);
  });

  await dispatcher.stop();
}

/**
 * Generate default configuration
 */
function generateConfig(outputPath: string): void {
  const defaultConfig = `# WP Praxis Swarm Configuration

[dispatcher]
coordinator_endpoint = "ws://localhost:8080"
state_db_path = "./swarm-state.db"
enable_websocket = true
websocket_port = 8080

[coordinator]
max_workers = 100
heartbeat_interval = 5000
heartbeat_timeout = 15000
task_retry_limit = 3
enable_load_balancing = true
priority_queue_enabled = true

[worker]
node_name = "worker-node-1"
dispatcher_url = "ws://localhost:8080"
heartbeat_interval = 5000
max_concurrent_tasks = 4

[worker.capabilities]
rust = true
php = true
powershell = true
max_concurrent_tasks = 4

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

[logging]
level = "info"
file = "./swarm.log"
console = true
format = "text"
`;

  writeFileSync(outputPath, defaultConfig, 'utf-8');
  console.log(`Configuration file created: ${outputPath}`);
}

// ============================================================================
// Main CLI
// ============================================================================

async function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  if (!command || command === 'help' || command === '--help' || command === '-h') {
    console.log(`
WP Praxis Swarm - Distributed Symbolic Execution System

Usage:
  swarm <command> [options]

Commands:
  start-dispatcher [config]    Start the swarm dispatcher
  start-worker [config] [name] Start a swarm worker node
  deploy <manifest> [config]   Deploy a workflow from manifest
  status [config]              Show swarm status
  config [output]              Generate default configuration

Options:
  config                       Path to config file (default: ./swarm-config.toml)
  name                         Worker node name
  manifest                     Path to workflow manifest (YAML/TOML)
  output                       Output path for config file

Examples:
  swarm start-dispatcher
  swarm start-worker ./swarm-config.toml worker-1
  swarm deploy ./workflow.yaml
  swarm status
  swarm config ./my-config.toml
`);
    process.exit(0);
  }

  try {
    switch (command) {
      case 'start-dispatcher':
        await startDispatcher(args[1] ?? DEFAULT_CONFIG_PATH);
        break;

      case 'start-worker':
        await startWorker(args[1] ?? DEFAULT_CONFIG_PATH, args[2]);
        break;

      case 'deploy':
        if (!args[1]) {
          console.error('Error: Manifest path required');
          console.log('Usage: swarm deploy <manifest> [config]');
          process.exit(1);
        }
        await deployWorkflow(args[2] ?? DEFAULT_CONFIG_PATH, args[1]);
        break;

      case 'status':
        await showStatus(args[1] ?? DEFAULT_CONFIG_PATH);
        break;

      case 'config':
        generateConfig(args[1] ?? DEFAULT_CONFIG_PATH);
        break;

      default:
        console.error(`Unknown command: ${command}`);
        console.log('Run "swarm help" for usage information');
        process.exit(1);
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

// Run CLI
main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
