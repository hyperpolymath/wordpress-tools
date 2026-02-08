/**
 * WP Praxis Swarm - Worker Node
 *
 * Worker node that:
 * - Registers with the dispatcher/coordinator
 * - Receives and executes symbolic tasks
 * - Reports progress and results
 * - Sends heartbeats
 * - Handles graceful shutdown
 */

import { v4 as uuidv4 } from 'uuid';
import WebSocket from 'ws';
import type {
  Node,
  Task,
  WorkerConfig,
  WebSocketMessage,
  RegisterMessage,
  HeartbeatMessage,
  TaskAssignMessage,
  TaskCompleteMessage,
  TaskFailedMessage,
  ExecutionResult,
  ExecutorContext,
  NodeHealth,
} from './types';
import { createNode } from './types';
import { Executor, createExecutor } from './executor';
import { StateManager } from './state-manager';
import { Logger } from './logger';

export class Worker {
  private node: Node;
  private ws?: WebSocket;
  private executor: Executor;
  private stateManager: StateManager;
  private logger: Logger;

  private heartbeatInterval?: Timer;
  private activeTasks: Map<string, Task> = new Map();
  private isShuttingDown = false;

  constructor(config: WorkerConfig, stateManager: StateManager, logger?: Logger) {
    this.logger = logger ?? new Logger('Worker');
    this.stateManager = stateManager;

    // Create node instance
    this.node = createNode({
      id: config.nodeId ?? uuidv4(),
      name: config.nodeName,
      capabilities: config.capabilities,
    });

    // Initialize executor
    this.executor = createExecutor(config.backends, this.logger.child('Executor'));

    this.logger.info(`Worker initialized: ${this.node.name} (${this.node.id})`);
  }

  // ============================================================================
  // Lifecycle Management
  // ============================================================================

  /**
   * Start worker and connect to dispatcher
   */
  async start(dispatcherUrl: string): Promise<void> {
    this.logger.info(`Starting worker, connecting to: ${dispatcherUrl}`);

    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(dispatcherUrl);

      this.ws.on('open', () => {
        this.logger.info('Connected to dispatcher');
        this.node.status = 'idle';
        this.register();
        this.startHeartbeat();
        resolve();
      });

      this.ws.on('message', (data) => {
        this.handleMessage(data.toString());
      });

      this.ws.on('error', (error) => {
        this.logger.error('WebSocket error:', error);
        reject(error);
      });

      this.ws.on('close', () => {
        this.logger.warn('Disconnected from dispatcher');
        this.stopHeartbeat();

        // Attempt reconnection if not shutting down
        if (!this.isShuttingDown) {
          setTimeout(() => {
            this.logger.info('Attempting to reconnect...');
            this.start(dispatcherUrl).catch((err) => {
              this.logger.error('Reconnection failed:', err);
            });
          }, 5000);
        }
      });
    });
  }

  /**
   * Stop worker gracefully
   */
  async stop(): Promise<void> {
    this.logger.info('Stopping worker...');
    this.isShuttingDown = true;

    // Wait for active tasks to complete
    if (this.activeTasks.size > 0) {
      this.logger.info(`Waiting for ${this.activeTasks.size} active tasks to complete...`);

      await new Promise<void>((resolve) => {
        const checkInterval = setInterval(() => {
          if (this.activeTasks.size === 0) {
            clearInterval(checkInterval);
            resolve();
          }
        }, 1000);

        // Timeout after 30 seconds
        setTimeout(() => {
          clearInterval(checkInterval);
          this.logger.warn('Shutdown timeout - forcing stop');
          resolve();
        }, 30000);
      });
    }

    this.stopHeartbeat();

    if (this.ws) {
      this.ws.close();
      this.ws = undefined;
    }

    this.logger.info('Worker stopped');
  }

  // ============================================================================
  // Registration & Heartbeat
  // ============================================================================

  /**
   * Register with coordinator
   */
  private register(): void {
    const message: WebSocketMessage = {
      type: 'register',
      senderId: this.node.id,
      timestamp: Date.now(),
      payload: {
        node: this.node,
      } as RegisterMessage,
    };

    this.sendMessage(message);
    this.logger.info('Registration message sent');
  }

  /**
   * Start sending heartbeats
   */
  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      this.sendHeartbeat();
    }, 5000); // Send heartbeat every 5 seconds

    this.logger.debug('Heartbeat started');
  }

  /**
   * Stop sending heartbeats
   */
  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = undefined;
      this.logger.debug('Heartbeat stopped');
    }
  }

  /**
   * Send heartbeat to coordinator
   */
  private sendHeartbeat(): void {
    const health = this.getNodeHealth();

    const message: WebSocketMessage = {
      type: 'heartbeat',
      senderId: this.node.id,
      timestamp: Date.now(),
      payload: {
        nodeId: this.node.id,
        health,
      } as HeartbeatMessage,
    };

    this.sendMessage(message);
    this.logger.verbose(`Heartbeat sent (active tasks: ${health.activeTasks})`);
  }

  /**
   * Get current node health
   */
  private getNodeHealth(): NodeHealth {
    return {
      cpuUsage: this.getCpuUsage(),
      memoryUsage: this.getMemoryUsage(),
      activeTasks: this.activeTasks.size,
      completedTasks: this.node.health.completedTasks,
      failedTasks: this.node.health.failedTasks,
      uptime: Date.now() - this.node.connectedAt,
    };
  }

  /**
   * Get CPU usage percentage (simplified - would need better implementation)
   */
  private getCpuUsage(): number {
    // Simplified placeholder - in production, use proper OS metrics
    return Math.random() * 100;
  }

  /**
   * Get memory usage percentage
   */
  private getMemoryUsage(): number {
    if (typeof process !== 'undefined' && process.memoryUsage) {
      const usage = process.memoryUsage();
      const totalHeap = usage.heapTotal;
      const usedHeap = usage.heapUsed;
      return (usedHeap / totalHeap) * 100;
    }
    return 0;
  }

  // ============================================================================
  // Message Handling
  // ============================================================================

  /**
   * Handle incoming WebSocket message
   */
  private async handleMessage(data: string): Promise<void> {
    try {
      const message = JSON.parse(data) as WebSocketMessage;

      this.logger.debug(`Message received: ${message.type}`);

      switch (message.type) {
        case 'task_assign':
          await this.handleTaskAssign(message.payload as TaskAssignMessage);
          break;

        case 'shutdown':
          this.logger.info('Shutdown command received');
          await this.stop();
          break;

        default:
          this.logger.warn(`Unknown message type: ${message.type}`);
      }
    } catch (error) {
      this.logger.error('Failed to handle message:', error);
    }
  }

  /**
   * Handle task assignment
   */
  private async handleTaskAssign(payload: TaskAssignMessage): Promise<void> {
    const { task } = payload;

    this.logger.info(`Task assigned: ${task.id} (${task.symbol.name})`);

    // Check if we can accept the task
    if (this.activeTasks.size >= this.node.capabilities.maxConcurrentTasks) {
      this.logger.warn(`Cannot accept task - at capacity (${this.activeTasks.size} tasks)`);
      return;
    }

    // Add to active tasks
    this.activeTasks.set(task.id, task);
    this.node.status = 'busy';

    // Execute task asynchronously
    this.executeTask(task).catch((error) => {
      this.logger.error(`Task execution error: ${task.id}`, error);
    });
  }

  /**
   * Execute a task
   */
  private async executeTask(task: Task): Promise<void> {
    this.logger.info(`Executing task: ${task.id} (${task.symbol.name})`);

    try {
      // Create execution context
      const context: ExecutorContext = {
        symbol: task.symbol,
        executionId: task.executionId,
        workflowId: '', // Will be populated by dispatcher
        nodeId: this.node.id,
        stateManager: this.stateManager,
        logger: this.logger,
      };

      // Execute symbol
      const result = await this.executor.execute(context);

      // Report success
      this.reportTaskComplete(task.id, result);

      // Update stats
      this.node.health.completedTasks++;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      const stackTrace = error instanceof Error ? error.stack : undefined;

      this.logger.error(`Task failed: ${task.id}`, error);

      // Report failure
      this.reportTaskFailed(task.id, errorMessage, stackTrace);

      // Update stats
      this.node.health.failedTasks++;
    } finally {
      // Remove from active tasks
      this.activeTasks.delete(task.id);

      // Update status
      if (this.activeTasks.size < this.node.capabilities.maxConcurrentTasks) {
        this.node.status = 'idle';
      }
    }
  }

  /**
   * Report task completion
   */
  private reportTaskComplete(taskId: string, result: ExecutionResult): void {
    const message: WebSocketMessage = {
      type: 'task_complete',
      senderId: this.node.id,
      timestamp: Date.now(),
      payload: {
        taskId,
        result,
      } as TaskCompleteMessage,
    };

    this.sendMessage(message);
    this.logger.info(`Task completed: ${taskId}`);
  }

  /**
   * Report task failure
   */
  private reportTaskFailed(taskId: string, error: string, stackTrace?: string): void {
    const message: WebSocketMessage = {
      type: 'task_failed',
      senderId: this.node.id,
      timestamp: Date.now(),
      payload: {
        taskId,
        error,
        stackTrace,
      } as TaskFailedMessage,
    };

    this.sendMessage(message);
    this.logger.error(`Task failed: ${taskId} - ${error}`);
  }

  // ============================================================================
  // Communication
  // ============================================================================

  /**
   * Send WebSocket message
   */
  private sendMessage(message: WebSocketMessage): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      this.logger.warn('Cannot send message - WebSocket not connected');
      return;
    }

    try {
      this.ws.send(JSON.stringify(message));
    } catch (error) {
      this.logger.error('Failed to send message:', error);
    }
  }

  // ============================================================================
  // Getters
  // ============================================================================

  /**
   * Get node information
   */
  getNode(): Node {
    return this.node;
  }

  /**
   * Get active tasks
   */
  getActiveTasks(): Task[] {
    return Array.from(this.activeTasks.values());
  }

  /**
   * Get worker statistics
   */
  getStats(): {
    nodeId: string;
    nodeName: string;
    status: string;
    activeTasks: number;
    completedTasks: number;
    failedTasks: number;
    uptime: number;
  } {
    return {
      nodeId: this.node.id,
      nodeName: this.node.name,
      status: this.node.status,
      activeTasks: this.activeTasks.size,
      completedTasks: this.node.health.completedTasks,
      failedTasks: this.node.health.failedTasks,
      uptime: Date.now() - this.node.connectedAt,
    };
  }
}

/**
 * Create a worker instance
 */
export function createWorker(config: WorkerConfig, stateManager: StateManager, logger?: Logger): Worker {
  return new Worker(config, stateManager, logger);
}
