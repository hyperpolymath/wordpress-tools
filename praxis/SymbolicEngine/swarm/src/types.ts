/**
 * WP Praxis Swarm - Type Definitions
 *
 * Comprehensive TypeScript interfaces for distributed symbolic execution
 */

// ============================================================================
// Symbol Types
// ============================================================================

export type SymbolType = 'action' | 'filter' | 'state' | 'query' | 'transform';

export type SymbolContext = 'wordpress' | 'filesystem' | 'database' | 'network' | 'generic';

export type SymbolDispatchTarget = 'rust_injector' | 'php_engine' | 'powershell_engine' | 'internal';

export interface Symbol {
  name: string;
  type: SymbolType;
  context: SymbolContext;
  dispatch: SymbolDispatchTarget;
  parameters: Record<string, unknown>;
  dependencies?: string[]; // Names of symbols that must execute first
  priority?: number; // Higher = earlier execution (default: 0)
  timeout?: number; // Execution timeout in milliseconds
  retries?: number; // Number of retry attempts on failure
  rollback?: Symbol; // Symbol to execute on rollback
}

export interface Workflow {
  name: string;
  version: string;
  description?: string;
  symbols: Symbol[];
  metadata?: Record<string, unknown>;
}

// ============================================================================
// Execution Types
// ============================================================================

export type ExecutionStatus =
  | 'pending'
  | 'queued'
  | 'assigned'
  | 'running'
  | 'completed'
  | 'failed'
  | 'cancelled'
  | 'rolled_back';

export interface ExecutionResult {
  success: boolean;
  output?: unknown;
  error?: string;
  stackTrace?: string;
  duration: number; // milliseconds
  timestamp: number;
  metadata?: Record<string, unknown>;
}

export interface Execution {
  id: string;
  workflowId: string;
  symbolName: string;
  status: ExecutionStatus;
  nodeId?: string; // Worker node assigned to this execution
  result?: ExecutionResult;
  attempts: number;
  createdAt: number;
  updatedAt: number;
  startedAt?: number;
  completedAt?: number;
}

// ============================================================================
// Task Types
// ============================================================================

export interface Task {
  id: string;
  executionId: string;
  symbol: Symbol;
  priority: number;
  dependencies: string[]; // Task IDs that must complete first
  status: ExecutionStatus;
  assignedTo?: string; // Node ID
  createdAt: number;
  assignedAt?: number;
}

// ============================================================================
// Node Types
// ============================================================================

export type NodeStatus = 'initializing' | 'idle' | 'busy' | 'offline' | 'failed';

export interface NodeCapabilities {
  rust: boolean;
  php: boolean;
  powershell: boolean;
  maxConcurrentTasks: number;
}

export interface NodeHealth {
  cpuUsage: number; // Percentage 0-100
  memoryUsage: number; // Percentage 0-100
  activeTasks: number;
  completedTasks: number;
  failedTasks: number;
  uptime: number; // milliseconds
}

export interface Node {
  id: string;
  name: string;
  status: NodeStatus;
  capabilities: NodeCapabilities;
  health: NodeHealth;
  lastHeartbeat: number;
  connectedAt: number;
  metadata?: Record<string, unknown>;
}

// ============================================================================
// Coordinator Types
// ============================================================================

export interface CoordinatorConfig {
  maxWorkers: number;
  heartbeatInterval: number; // milliseconds
  heartbeatTimeout: number; // milliseconds
  taskRetryLimit: number;
  enableLoadBalancing: boolean;
  priorityQueueEnabled: boolean;
}

export interface CoordinatorState {
  activeNodes: Map<string, Node>;
  taskQueue: Task[];
  runningTasks: Map<string, Task>;
  completedTasks: Set<string>;
  failedTasks: Map<string, string>; // taskId -> error
}

// ============================================================================
// Dispatcher Types
// ============================================================================

export interface DispatcherConfig {
  manifestPath?: string;
  workflowName?: string;
  coordinatorEndpoint: string;
  stateDbPath: string;
  enableWebSocket: boolean;
  websocketPort: number;
}

export interface DispatchResult {
  workflowId: string;
  totalTasks: number;
  completedTasks: number;
  failedTasks: number;
  duration: number;
  results: ExecutionResult[];
}

// ============================================================================
// Worker Types
// ============================================================================

export interface WorkerConfig {
  nodeId?: string;
  nodeName: string;
  dispatcherUrl: string;
  capabilities: NodeCapabilities;
  heartbeatInterval: number;
  maxConcurrentTasks: number;
  backends: BackendConfig;
}

export interface BackendConfig {
  rustInjector?: {
    enabled: boolean;
    binaryPath: string;
    timeout: number;
  };
  phpEngine?: {
    enabled: boolean;
    scriptPath: string;
    phpBinary: string;
    timeout: number;
  };
  powershellEngine?: {
    enabled: boolean;
    scriptPath: string;
    pwshBinary: string;
    timeout: number;
  };
}

// ============================================================================
// WebSocket Message Types
// ============================================================================

export type MessageType =
  | 'register'
  | 'heartbeat'
  | 'task_assign'
  | 'task_update'
  | 'task_complete'
  | 'task_failed'
  | 'node_update'
  | 'workflow_start'
  | 'workflow_complete'
  | 'state_sync'
  | 'shutdown';

export interface WebSocketMessage {
  type: MessageType;
  senderId: string;
  timestamp: number;
  payload: unknown;
}

export interface RegisterMessage {
  node: Omit<Node, 'id'>;
}

export interface HeartbeatMessage {
  nodeId: string;
  health: NodeHealth;
}

export interface TaskAssignMessage {
  task: Task;
}

export interface TaskUpdateMessage {
  taskId: string;
  status: ExecutionStatus;
  progress?: number; // 0-100
}

export interface TaskCompleteMessage {
  taskId: string;
  result: ExecutionResult;
}

export interface TaskFailedMessage {
  taskId: string;
  error: string;
  stackTrace?: string;
}

// ============================================================================
// State Manager Types
// ============================================================================

export interface StateTransaction {
  id: string;
  operations: StateOperation[];
  timestamp: number;
  committed: boolean;
}

export interface StateOperation {
  type: 'set' | 'delete' | 'update';
  key: string;
  value?: unknown;
  previousValue?: unknown;
}

export interface StateSnapshot {
  timestamp: number;
  data: Record<string, unknown>;
  checksum: string;
}

// ============================================================================
// Executor Types
// ============================================================================

export interface ExecutorContext {
  symbol: Symbol;
  executionId: string;
  workflowId: string;
  nodeId: string;
  stateManager: unknown; // Will be StateManager instance
  logger: unknown; // Will be Logger instance
}

export interface ExecutorBackend {
  execute(context: ExecutorContext): Promise<ExecutionResult>;
  canHandle(symbol: Symbol): boolean;
  healthCheck(): Promise<boolean>;
}

// ============================================================================
// Configuration Types
// ============================================================================

export interface SwarmConfig {
  dispatcher: DispatcherConfig;
  coordinator: CoordinatorConfig;
  worker: WorkerConfig;
  logging: LoggingConfig;
  security?: SecurityConfig;
}

export interface LoggingConfig {
  level: 'error' | 'warn' | 'info' | 'debug' | 'verbose';
  file?: string;
  console: boolean;
  format: 'json' | 'text';
}

export interface SecurityConfig {
  enableAuth: boolean;
  apiKey?: string;
  allowedHosts: string[];
  maxMessageSize: number; // bytes
}

// ============================================================================
// CLI Types
// ============================================================================

export interface CLICommand {
  name: string;
  description: string;
  options?: CLIOption[];
  action: (args: Record<string, unknown>) => Promise<void>;
}

export interface CLIOption {
  name: string;
  alias?: string;
  description: string;
  type: 'string' | 'number' | 'boolean';
  required?: boolean;
  default?: unknown;
}

// ============================================================================
// Utility Types
// ============================================================================

export type AsyncResult<T> = Promise<{ success: true; data: T } | { success: false; error: string }>;

export interface Retryable<T> {
  attempt: () => Promise<T>;
  maxAttempts: number;
  delayMs: number;
  backoffMultiplier?: number;
}

export interface TimeoutOptions {
  timeoutMs: number;
  onTimeout?: () => void;
}

// ============================================================================
// Export Helper Functions
// ============================================================================

export function createSymbol(partial: Partial<Symbol> & Pick<Symbol, 'name' | 'type'>): Symbol {
  return {
    context: 'generic',
    dispatch: 'internal',
    parameters: {},
    priority: 0,
    timeout: 30000,
    retries: 3,
    ...partial,
  };
}

export function createNode(partial: Partial<Node> & Pick<Node, 'id' | 'name'>): Node {
  return {
    status: 'initializing',
    capabilities: {
      rust: false,
      php: false,
      powershell: false,
      maxConcurrentTasks: 4,
    },
    health: {
      cpuUsage: 0,
      memoryUsage: 0,
      activeTasks: 0,
      completedTasks: 0,
      failedTasks: 0,
      uptime: 0,
    },
    lastHeartbeat: Date.now(),
    connectedAt: Date.now(),
    ...partial,
  };
}

export function createTask(partial: Partial<Task> & Pick<Task, 'id' | 'executionId' | 'symbol'>): Task {
  return {
    priority: partial.symbol.priority ?? 0,
    dependencies: partial.symbol.dependencies ?? [],
    status: 'pending',
    createdAt: Date.now(),
    ...partial,
  };
}

export function createExecution(
  partial: Partial<Execution> & Pick<Execution, 'id' | 'workflowId' | 'symbolName'>
): Execution {
  return {
    status: 'pending',
    attempts: 0,
    createdAt: Date.now(),
    updatedAt: Date.now(),
    ...partial,
  };
}
