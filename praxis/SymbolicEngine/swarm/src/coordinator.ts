/**
 * WP Praxis Swarm - Coordinator
 *
 * Coordinates task distribution across worker nodes with:
 * - Load balancing
 * - Priority queue management
 * - Dependency resolution
 * - Node health monitoring
 * - Failure handling and retry logic
 */

import { v4 as uuidv4 } from 'uuid';
import type {
  Node,
  Task,
  Symbol,
  Execution,
  CoordinatorConfig,
  ExecutionStatus,
  NodeStatus,
  WebSocketMessage,
  TaskAssignMessage,
  HeartbeatMessage,
} from './types';
import { createTask, createExecution } from './types';
import { StateManager } from './state-manager';
import { Logger } from './logger';

export class Coordinator {
  private activeNodes: Map<string, Node> = new Map();
  private taskQueue: Task[] = [];
  private runningTasks: Map<string, Task> = new Map();
  private completedTasks: Set<string> = new Set();
  private failedTasks: Map<string, string> = new Map();
  private executionMap: Map<string, Execution> = new Map();
  private dependencyGraph: Map<string, Set<string>> = new Map(); // taskId -> dependencies

  private heartbeatInterval?: Timer;
  private messageHandler?: (message: WebSocketMessage) => void;

  constructor(
    private config: CoordinatorConfig,
    private stateManager: StateManager,
    private logger: Logger
  ) {
    this.startHeartbeatMonitor();
    this.logger.info('Coordinator initialized');
  }

  // ============================================================================
  // Node Management
  // ============================================================================

  /**
   * Register a new worker node
   */
  registerNode(node: Node): void {
    this.activeNodes.set(node.id, node);
    this.stateManager.saveNode(node);
    this.logger.info(`Node registered: ${node.name} (${node.id})`);

    // Try to assign pending tasks
    this.scheduleTasks();
  }

  /**
   * Unregister a worker node
   */
  unregisterNode(nodeId: string): void {
    const node = this.activeNodes.get(nodeId);
    if (node) {
      node.status = 'offline';
      this.stateManager.saveNode(node);
      this.activeNodes.delete(nodeId);
      this.logger.info(`Node unregistered: ${node.name} (${nodeId})`);

      // Reassign tasks from this node
      this.reassignNodeTasks(nodeId);
    }
  }

  /**
   * Update node heartbeat
   */
  updateHeartbeat(nodeId: string, health: HeartbeatMessage['health']): void {
    const node = this.activeNodes.get(nodeId);
    if (node) {
      node.lastHeartbeat = Date.now();
      node.health = health;
      this.stateManager.saveNode(node);
      this.logger.debug(`Heartbeat received from: ${node.name}`);
    }
  }

  /**
   * Get active nodes
   */
  getActiveNodes(): Node[] {
    return Array.from(this.activeNodes.values()).filter((node) => node.status !== 'offline');
  }

  /**
   * Get best node for task (load balancing)
   */
  private getBestNodeForTask(task: Task): Node | null {
    const availableNodes = this.getActiveNodes().filter((node) => {
      // Node must be idle or have capacity
      if (node.status === 'offline' || node.status === 'failed') {
        return false;
      }

      // Check if node can handle the symbol type
      const canHandle = this.canNodeHandleSymbol(node, task.symbol);
      if (!canHandle) {
        return false;
      }

      // Check capacity
      return node.health.activeTasks < node.capabilities.maxConcurrentTasks;
    });

    if (availableNodes.length === 0) {
      return null;
    }

    if (!this.config.enableLoadBalancing) {
      return availableNodes[0] ?? null;
    }

    // Load balancing: choose node with lowest load
    availableNodes.sort((a, b) => {
      const loadA = a.health.activeTasks / a.capabilities.maxConcurrentTasks;
      const loadB = b.health.activeTasks / b.capabilities.maxConcurrentTasks;
      return loadA - loadB;
    });

    return availableNodes[0] ?? null;
  }

  /**
   * Check if node can handle symbol
   */
  private canNodeHandleSymbol(node: Node, symbol: Symbol): boolean {
    switch (symbol.dispatch) {
      case 'rust_injector':
        return node.capabilities.rust;
      case 'php_engine':
        return node.capabilities.php;
      case 'powershell_engine':
        return node.capabilities.powershell;
      case 'internal':
        return true;
      default:
        return false;
    }
  }

  // ============================================================================
  // Task Management
  // ============================================================================

  /**
   * Submit a workflow for execution
   */
  submitWorkflow(workflowId: string, symbols: Symbol[]): string[] {
    this.logger.info(`Submitting workflow: ${workflowId} (${symbols.length} symbols)`);

    const taskIds: string[] = [];

    for (const symbol of symbols) {
      const execution = createExecution({
        id: uuidv4(),
        workflowId,
        symbolName: symbol.name,
      });

      const task = createTask({
        id: uuidv4(),
        executionId: execution.id,
        symbol,
      });

      this.executionMap.set(execution.id, execution);
      this.taskQueue.push(task);
      taskIds.push(task.id);

      // Build dependency graph
      if (symbol.dependencies && symbol.dependencies.length > 0) {
        this.dependencyGraph.set(
          task.id,
          new Set(
            symbol.dependencies
              .map((depName) => this.findTaskBySymbolName(depName, workflowId))
              .filter((t): t is Task => t !== null)
              .map((t) => t.id)
          )
        );
      }

      this.stateManager.saveExecution(execution);
      this.stateManager.saveTask(task);
    }

    // Sort queue by priority if enabled
    if (this.config.priorityQueueEnabled) {
      this.taskQueue.sort((a, b) => b.priority - a.priority);
    }

    this.logger.info(`Workflow submitted: ${workflowId} (${taskIds.length} tasks created)`);

    // Try to schedule tasks immediately
    this.scheduleTasks();

    return taskIds;
  }

  /**
   * Find task by symbol name in workflow
   */
  private findTaskBySymbolName(symbolName: string, workflowId: string): Task | null {
    return (
      this.taskQueue.find(
        (t) =>
          t.symbol.name === symbolName &&
          this.executionMap.get(t.executionId)?.workflowId === workflowId
      ) ?? null
    );
  }

  /**
   * Schedule tasks to available workers
   */
  private scheduleTasks(): void {
    if (this.taskQueue.length === 0) {
      return;
    }

    this.logger.debug(`Scheduling tasks: ${this.taskQueue.length} in queue`);

    const readyTasks = this.taskQueue.filter((task) => this.isTaskReady(task));

    for (const task of readyTasks) {
      const node = this.getBestNodeForTask(task);
      if (!node) {
        this.logger.debug(`No available node for task: ${task.id}`);
        continue;
      }

      this.assignTaskToNode(task, node);
    }
  }

  /**
   * Check if task is ready to execute (dependencies satisfied)
   */
  private isTaskReady(task: Task): boolean {
    if (task.status !== 'pending') {
      return false;
    }

    const dependencies = this.dependencyGraph.get(task.id);
    if (!dependencies || dependencies.size === 0) {
      return true;
    }

    // Check if all dependencies are completed
    for (const depId of dependencies) {
      if (!this.completedTasks.has(depId)) {
        return false;
      }
    }

    return true;
  }

  /**
   * Assign task to node
   */
  private assignTaskToNode(task: Task, node: Node): void {
    // Remove from queue
    const index = this.taskQueue.indexOf(task);
    if (index > -1) {
      this.taskQueue.splice(index, 1);
    }

    // Update task
    task.status = 'assigned';
    task.assignedTo = node.id;
    task.assignedAt = Date.now();

    // Update execution
    const execution = this.executionMap.get(task.executionId);
    if (execution) {
      execution.status = 'assigned';
      execution.nodeId = node.id;
      execution.updatedAt = Date.now();
      this.stateManager.saveExecution(execution);
    }

    // Update node
    node.health.activeTasks++;
    if (node.health.activeTasks >= node.capabilities.maxConcurrentTasks) {
      node.status = 'busy';
    }
    this.stateManager.saveNode(node);

    // Track running task
    this.runningTasks.set(task.id, task);
    this.stateManager.saveTask(task);

    this.logger.info(`Task assigned: ${task.id} -> ${node.name}`);

    // Send task to node via message handler
    if (this.messageHandler) {
      const message: WebSocketMessage = {
        type: 'task_assign',
        senderId: 'coordinator',
        timestamp: Date.now(),
        payload: { task } as TaskAssignMessage,
      };
      this.messageHandler(message);
    }
  }

  /**
   * Mark task as completed
   */
  completeTask(taskId: string, success: boolean, error?: string): void {
    const task = this.runningTasks.get(taskId);
    if (!task) {
      this.logger.warn(`Task not found: ${taskId}`);
      return;
    }

    const execution = this.executionMap.get(task.executionId);
    if (!execution) {
      this.logger.warn(`Execution not found for task: ${taskId}`);
      return;
    }

    // Update task
    task.status = success ? 'completed' : 'failed';
    this.runningTasks.delete(taskId);

    if (success) {
      this.completedTasks.add(taskId);
    } else {
      this.failedTasks.set(taskId, error ?? 'Unknown error');
    }

    // Update execution
    execution.status = success ? 'completed' : 'failed';
    execution.completedAt = Date.now();
    execution.updatedAt = Date.now();

    // Update node
    if (task.assignedTo) {
      const node = this.activeNodes.get(task.assignedTo);
      if (node) {
        node.health.activeTasks--;
        if (success) {
          node.health.completedTasks++;
        } else {
          node.health.failedTasks++;
        }

        if (node.health.activeTasks < node.capabilities.maxConcurrentTasks) {
          node.status = 'idle';
        }

        this.stateManager.saveNode(node);
      }
    }

    this.stateManager.saveTask(task);
    this.stateManager.saveExecution(execution);

    this.logger.info(
      `Task ${success ? 'completed' : 'failed'}: ${taskId}${error ? ` (${error})` : ''}`
    );

    // Handle failure with retry
    if (!success && execution.attempts < (task.symbol.retries ?? this.config.taskRetryLimit)) {
      this.retryTask(task);
    }

    // Schedule next tasks
    this.scheduleTasks();
  }

  /**
   * Retry failed task
   */
  private retryTask(task: Task): void {
    const execution = this.executionMap.get(task.executionId);
    if (!execution) {
      return;
    }

    execution.attempts++;
    execution.status = 'pending';
    execution.nodeId = undefined;
    execution.updatedAt = Date.now();

    task.status = 'pending';
    task.assignedTo = undefined;
    task.assignedAt = undefined;

    // Add back to queue
    this.taskQueue.push(task);

    this.stateManager.saveTask(task);
    this.stateManager.saveExecution(execution);

    this.logger.info(`Task retry scheduled: ${task.id} (attempt ${execution.attempts})`);
  }

  /**
   * Reassign tasks from failed/offline node
   */
  private reassignNodeTasks(nodeId: string): void {
    const tasksToReassign: Task[] = [];

    for (const [taskId, task] of this.runningTasks.entries()) {
      if (task.assignedTo === nodeId) {
        tasksToReassign.push(task);
        this.runningTasks.delete(taskId);
      }
    }

    for (const task of tasksToReassign) {
      task.status = 'pending';
      task.assignedTo = undefined;
      task.assignedAt = undefined;
      this.taskQueue.push(task);
      this.stateManager.saveTask(task);

      this.logger.info(`Task reassigned from offline node: ${task.id}`);
    }

    if (tasksToReassign.length > 0) {
      this.scheduleTasks();
    }
  }

  // ============================================================================
  // Heartbeat Monitoring
  // ============================================================================

  /**
   * Start heartbeat monitor
   */
  private startHeartbeatMonitor(): void {
    this.heartbeatInterval = setInterval(() => {
      this.checkNodeHeartbeats();
    }, this.config.heartbeatInterval);

    this.logger.debug('Heartbeat monitor started');
  }

  /**
   * Check node heartbeats and mark stale nodes as offline
   */
  private checkNodeHeartbeats(): void {
    const now = Date.now();
    const timeout = this.config.heartbeatTimeout;

    for (const [nodeId, node] of this.activeNodes.entries()) {
      if (now - node.lastHeartbeat > timeout) {
        this.logger.warn(`Node heartbeat timeout: ${node.name} (${nodeId})`);
        this.unregisterNode(nodeId);
      }
    }
  }

  /**
   * Stop heartbeat monitor
   */
  private stopHeartbeatMonitor(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = undefined;
      this.logger.debug('Heartbeat monitor stopped');
    }
  }

  // ============================================================================
  // Statistics & Monitoring
  // ============================================================================

  /**
   * Get coordinator statistics
   */
  getStats(): {
    nodes: {
      total: number;
      active: number;
      idle: number;
      busy: number;
      offline: number;
    };
    tasks: {
      queued: number;
      running: number;
      completed: number;
      failed: number;
    };
    executions: number;
  } {
    const nodes = {
      total: this.activeNodes.size,
      active: 0,
      idle: 0,
      busy: 0,
      offline: 0,
    };

    for (const node of this.activeNodes.values()) {
      switch (node.status) {
        case 'idle':
          nodes.active++;
          nodes.idle++;
          break;
        case 'busy':
          nodes.active++;
          nodes.busy++;
          break;
        case 'offline':
          nodes.offline++;
          break;
      }
    }

    return {
      nodes,
      tasks: {
        queued: this.taskQueue.length,
        running: this.runningTasks.size,
        completed: this.completedTasks.size,
        failed: this.failedTasks.size,
      },
      executions: this.executionMap.size,
    };
  }

  /**
   * Set message handler for WebSocket communication
   */
  setMessageHandler(handler: (message: WebSocketMessage) => void): void {
    this.messageHandler = handler;
  }

  /**
   * Shutdown coordinator
   */
  shutdown(): void {
    this.stopHeartbeatMonitor();
    this.logger.info('Coordinator shutdown');
  }
}

/**
 * Create a coordinator instance
 */
export function createCoordinator(
  config: CoordinatorConfig,
  stateManager: StateManager,
  logger?: Logger
): Coordinator {
  return new Coordinator(config, stateManager, logger ?? new Logger('Coordinator'));
}
