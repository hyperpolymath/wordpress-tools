/**
 * WP Praxis Swarm - Dispatcher
 *
 * Main dispatcher that:
 * - Loads and parses manifest files (YAML/TOML)
 * - Distributes symbolic workflows across swarm nodes
 * - Coordinates execution state
 * - Collects and aggregates results
 * - Handles failures and retries
 */

import { readFileSync, existsSync } from 'fs';
import { parse as parseYAML } from 'yaml';
import { parse as parseTOML } from 'toml';
import { v4 as uuidv4 } from 'uuid';
import type {
  Workflow,
  Symbol,
  DispatcherConfig,
  DispatchResult,
  Execution,
  WebSocketMessage,
  TaskCompleteMessage,
  TaskFailedMessage,
} from './types';
import { Coordinator, createCoordinator } from './coordinator';
import { StateManager } from './state-manager';
import { WebSocketServer } from './websocket-server';
import { Logger } from './logger';

export class Dispatcher {
  private coordinator: Coordinator;
  private stateManager: StateManager;
  private wsServer?: WebSocketServer;
  private logger: Logger;
  private config: DispatcherConfig;

  private activeWorkflows: Map<string, string[]> = new Map(); // workflowId -> taskIds

  constructor(config: DispatcherConfig, logger?: Logger) {
    this.config = config;
    this.logger = logger ?? new Logger('Dispatcher');

    // Initialize state manager
    this.stateManager = new StateManager(config.stateDbPath, this.logger.child('StateManager'));

    // Initialize coordinator
    this.coordinator = createCoordinator(
      {
        maxWorkers: 100,
        heartbeatInterval: 5000,
        heartbeatTimeout: 15000,
        taskRetryLimit: 3,
        enableLoadBalancing: true,
        priorityQueueEnabled: true,
      },
      this.stateManager,
      this.logger.child('Coordinator')
    );

    // Initialize WebSocket server if enabled
    if (config.enableWebSocket) {
      this.wsServer = new WebSocketServer(
        config.websocketPort,
        this.handleWebSocketMessage.bind(this),
        this.logger.child('WebSocketServer')
      );
    }

    this.logger.info('Dispatcher initialized');
  }

  // ============================================================================
  // Workflow Loading & Parsing
  // ============================================================================

  /**
   * Load workflow from manifest file
   */
  loadManifest(manifestPath: string): Workflow {
    this.logger.info(`Loading manifest: ${manifestPath}`);

    if (!existsSync(manifestPath)) {
      throw new Error(`Manifest file not found: ${manifestPath}`);
    }

    const content = readFileSync(manifestPath, 'utf-8');
    const workflow = this.parseManifest(content, manifestPath);

    this.logger.info(`Manifest loaded: ${workflow.name} (${workflow.symbols.length} symbols)`);
    return workflow;
  }

  /**
   * Parse manifest content
   */
  private parseManifest(content: string, filePath: string): Workflow {
    const ext = filePath.split('.').pop()?.toLowerCase();

    let parsed: any;

    try {
      if (ext === 'yaml' || ext === 'yml') {
        parsed = parseYAML(content);
      } else if (ext === 'toml') {
        parsed = parseTOML(content);
      } else {
        throw new Error(`Unsupported manifest format: ${ext}`);
      }
    } catch (error) {
      this.logger.error('Failed to parse manifest:', error);
      throw new Error(`Manifest parsing failed: ${error instanceof Error ? error.message : String(error)}`);
    }

    return this.validateWorkflow(parsed);
  }

  /**
   * Validate workflow structure
   */
  private validateWorkflow(data: any): Workflow {
    if (!data.name || typeof data.name !== 'string') {
      throw new Error('Workflow must have a name');
    }

    if (!data.version || typeof data.version !== 'string') {
      throw new Error('Workflow must have a version');
    }

    if (!Array.isArray(data.symbols)) {
      throw new Error('Workflow must have a symbols array');
    }

    const symbols: Symbol[] = data.symbols.map((s: any, index: number) => {
      if (!s.name || typeof s.name !== 'string') {
        throw new Error(`Symbol at index ${index} must have a name`);
      }

      if (!s.type || typeof s.type !== 'string') {
        throw new Error(`Symbol ${s.name} must have a type`);
      }

      return {
        name: s.name,
        type: s.type,
        context: s.context ?? 'generic',
        dispatch: s.dispatch ?? 'internal',
        parameters: s.parameters ?? {},
        dependencies: s.dependencies ?? [],
        priority: s.priority ?? 0,
        timeout: s.timeout ?? 30000,
        retries: s.retries ?? 3,
        rollback: s.rollback,
      } as Symbol;
    });

    return {
      name: data.name,
      version: data.version,
      description: data.description,
      symbols,
      metadata: data.metadata,
    };
  }

  // ============================================================================
  // Workflow Dispatch
  // ============================================================================

  /**
   * Dispatch workflow for execution
   */
  async dispatch(workflow: Workflow): Promise<DispatchResult> {
    const workflowId = uuidv4();
    const startTime = Date.now();

    this.logger.info(`Dispatching workflow: ${workflow.name} (${workflowId})`);

    // Submit workflow to coordinator
    const taskIds = this.coordinator.submitWorkflow(workflowId, workflow.symbols);
    this.activeWorkflows.set(workflowId, taskIds);

    // Wait for workflow to complete
    const results = await this.waitForWorkflowCompletion(workflowId, taskIds);

    const duration = Date.now() - startTime;

    const dispatchResult: DispatchResult = {
      workflowId,
      totalTasks: taskIds.length,
      completedTasks: results.filter((r) => r.success).length,
      failedTasks: results.filter((r) => !r.success).length,
      duration,
      results,
    };

    this.logger.info(
      `Workflow completed: ${workflow.name} (${dispatchResult.completedTasks}/${dispatchResult.totalTasks} successful, ${duration}ms)`
    );

    return dispatchResult;
  }

  /**
   * Dispatch workflow from manifest file
   */
  async dispatchFromFile(manifestPath: string): Promise<DispatchResult> {
    const workflow = this.loadManifest(manifestPath);
    return this.dispatch(workflow);
  }

  /**
   * Wait for workflow completion
   */
  private async waitForWorkflowCompletion(
    workflowId: string,
    taskIds: string[]
  ): Promise<Array<{ success: boolean; output?: unknown; error?: string }>> {
    return new Promise((resolve) => {
      const results: Array<{ success: boolean; output?: unknown; error?: string }> = [];
      const completedTasks = new Set<string>();

      const checkInterval = setInterval(() => {
        // Get execution status for all tasks
        for (const taskId of taskIds) {
          if (completedTasks.has(taskId)) {
            continue;
          }

          const task = this.stateManager.getTask(taskId);
          if (!task) {
            continue;
          }

          const execution = this.stateManager.getExecution(task.executionId);
          if (!execution) {
            continue;
          }

          if (execution.status === 'completed' || execution.status === 'failed') {
            completedTasks.add(taskId);

            if (execution.result) {
              results.push({
                success: execution.result.success,
                output: execution.result.output,
                error: execution.result.error,
              });
            } else {
              results.push({
                success: execution.status === 'completed',
                error: execution.status === 'failed' ? 'Unknown error' : undefined,
              });
            }
          }
        }

        // Check if all tasks are complete
        if (completedTasks.size === taskIds.length) {
          clearInterval(checkInterval);
          this.activeWorkflows.delete(workflowId);
          resolve(results);
        }
      }, 100);

      // Timeout after 10 minutes
      setTimeout(() => {
        clearInterval(checkInterval);
        this.logger.error(`Workflow timeout: ${workflowId}`);

        // Add error results for incomplete tasks
        for (const taskId of taskIds) {
          if (!completedTasks.has(taskId)) {
            results.push({
              success: false,
              error: 'Workflow timeout',
            });
          }
        }

        this.activeWorkflows.delete(workflowId);
        resolve(results);
      }, 600000);
    });
  }

  // ============================================================================
  // WebSocket Message Handling
  // ============================================================================

  /**
   * Handle WebSocket messages from workers
   */
  private handleWebSocketMessage(message: WebSocketMessage, senderId: string): void {
    this.logger.debug(`WebSocket message from ${senderId}: ${message.type}`);

    switch (message.type) {
      case 'register':
        this.handleWorkerRegistration(message);
        break;

      case 'heartbeat':
        this.handleWorkerHeartbeat(message);
        break;

      case 'task_complete':
        this.handleTaskComplete(message);
        break;

      case 'task_failed':
        this.handleTaskFailed(message);
        break;

      default:
        this.logger.warn(`Unknown message type from worker: ${message.type}`);
    }
  }

  /**
   * Handle worker registration
   */
  private handleWorkerRegistration(message: WebSocketMessage): void {
    const payload = message.payload as any;
    if (payload && payload.node) {
      this.coordinator.registerNode(payload.node);
      this.logger.info(`Worker registered: ${payload.node.name}`);
    }
  }

  /**
   * Handle worker heartbeat
   */
  private handleWorkerHeartbeat(message: WebSocketMessage): void {
    const payload = message.payload as any;
    if (payload && payload.nodeId && payload.health) {
      this.coordinator.updateHeartbeat(payload.nodeId, payload.health);
    }
  }

  /**
   * Handle task completion
   */
  private handleTaskComplete(message: WebSocketMessage): void {
    const payload = message.payload as TaskCompleteMessage;
    if (payload && payload.taskId && payload.result) {
      // Update execution with result
      const task = this.stateManager.getTask(payload.taskId);
      if (task) {
        const execution = this.stateManager.getExecution(task.executionId);
        if (execution) {
          execution.result = payload.result;
          execution.status = 'completed';
          execution.completedAt = Date.now();
          execution.updatedAt = Date.now();
          this.stateManager.saveExecution(execution);
        }
      }

      this.coordinator.completeTask(payload.taskId, true);
    }
  }

  /**
   * Handle task failure
   */
  private handleTaskFailed(message: WebSocketMessage): void {
    const payload = message.payload as TaskFailedMessage;
    if (payload && payload.taskId && payload.error) {
      // Update execution with error
      const task = this.stateManager.getTask(payload.taskId);
      if (task) {
        const execution = this.stateManager.getExecution(task.executionId);
        if (execution) {
          execution.result = {
            success: false,
            error: payload.error,
            stackTrace: payload.stackTrace,
            duration: 0,
            timestamp: Date.now(),
          };
          execution.status = 'failed';
          execution.completedAt = Date.now();
          execution.updatedAt = Date.now();
          this.stateManager.saveExecution(execution);
        }
      }

      this.coordinator.completeTask(payload.taskId, false, payload.error);
    }
  }

  // ============================================================================
  // Server Management
  // ============================================================================

  /**
   * Start dispatcher server
   */
  async start(): Promise<void> {
    this.logger.info('Starting dispatcher...');

    if (this.wsServer) {
      await this.wsServer.start();
      this.logger.info(`WebSocket server started on port ${this.config.websocketPort}`);
    }

    // Set up coordinator message handler
    this.coordinator.setMessageHandler((message) => {
      if (this.wsServer) {
        this.wsServer.broadcast(message);
      }
    });

    this.logger.info('Dispatcher started');
  }

  /**
   * Stop dispatcher server
   */
  async stop(): Promise<void> {
    this.logger.info('Stopping dispatcher...');

    this.coordinator.shutdown();

    if (this.wsServer) {
      await this.wsServer.stop();
    }

    this.stateManager.close();

    this.logger.info('Dispatcher stopped');
  }

  // ============================================================================
  // Statistics & Monitoring
  // ============================================================================

  /**
   * Get dispatcher statistics
   */
  getStats(): {
    coordinator: ReturnType<typeof this.coordinator.getStats>;
    activeWorkflows: number;
    state: Record<string, number>;
  } {
    return {
      coordinator: this.coordinator.getStats(),
      activeWorkflows: this.activeWorkflows.size,
      state: this.stateManager.getStats(),
    };
  }

  /**
   * Get all active workflows
   */
  getActiveWorkflows(): Array<{ workflowId: string; taskCount: number }> {
    return Array.from(this.activeWorkflows.entries()).map(([workflowId, taskIds]) => ({
      workflowId,
      taskCount: taskIds.length,
    }));
  }

  /**
   * Get workflow execution status
   */
  getWorkflowStatus(workflowId: string): {
    executions: Execution[];
    totalTasks: number;
    completedTasks: number;
    failedTasks: number;
    runningTasks: number;
  } {
    const executions = this.stateManager.getExecutionsByWorkflow(workflowId);

    return {
      executions,
      totalTasks: executions.length,
      completedTasks: executions.filter((e) => e.status === 'completed').length,
      failedTasks: executions.filter((e) => e.status === 'failed').length,
      runningTasks: executions.filter((e) => e.status === 'running').length,
    };
  }
}

/**
 * Create a dispatcher instance
 */
export function createDispatcher(config: DispatcherConfig, logger?: Logger): Dispatcher {
  return new Dispatcher(config, logger);
}
