/**
 * WP Praxis GraphQL API - Type Definitions
 *
 * Core TypeScript types for the GraphQL server
 */

import type { IncomingMessage } from 'http';
import type { PubSub } from 'graphql-subscriptions';
import type DataLoader from 'dataloader';
import type { Logger } from 'winston';

// ============================================================================
// Database Models (matching Ecto schema)
// ============================================================================

export interface SymbolModel {
  id: number;
  name: string;
  type: string;
  context: string;
  status: string;
  dispatch_target: string;
  parameters: Record<string, any>;
  description: string | null;
  priority: number;
  timeout: number;
  retry_count: number;
  inserted_at: Date;
  updated_at: Date;
}

export interface WorkflowModel {
  id: number;
  name: string;
  description: string | null;
  manifest_path: string;
  status: string;
  execution_log: Array<Record<string, any>>;
  metadata: Record<string, any>;
  started_at: Date | null;
  completed_at: Date | null;
  duration: number | null;
  inserted_at: Date;
  updated_at: Date;
}

export interface ExecutionModel {
  id: number;
  workflow_id: number;
  symbol_id: number;
  status: string;
  started_at: Date | null;
  completed_at: Date | null;
  duration: number | null;
  output: Record<string, any>;
  error_log: string | null;
  rollback_state: Record<string, any>;
  retry_attempt: number;
  exit_code: number | null;
  metadata: Record<string, any>;
  inserted_at: Date;
  updated_at: Date;
}

export interface BaselineModel {
  id: number;
  name: string;
  description: string | null;
  symbolic_state: Record<string, any>;
  version: string;
  is_active: boolean;
  created_by: string | null;
  metadata: Record<string, any>;
  baseline_type: string;
  scope: string;
  inserted_at: Date;
  updated_at: Date;
}

export interface AuditModel {
  id: number;
  baseline_id: number;
  workflow_id: number | null;
  audit_type: string;
  status: string;
  deviations: Array<Record<string, any>>;
  severity: string;
  deviation_count: number;
  passed_checks: number;
  failed_checks: number;
  recommendations: Array<Record<string, any>>;
  started_at: Date | null;
  completed_at: Date | null;
  duration: number | null;
  metadata: Record<string, any>;
  inserted_at: Date;
  updated_at: Date;
}

// ============================================================================
// Swarm Models (from TypeScript swarm)
// ============================================================================

export interface NodeModel {
  id: string;
  name: string;
  status: string;
  capabilities: {
    rust: boolean;
    php: boolean;
    powershell: boolean;
    maxConcurrentTasks: number;
  };
  health: {
    cpuUsage: number;
    memoryUsage: number;
    activeTasks: number;
    completedTasks: number;
    failedTasks: number;
    uptime: number;
  };
  lastHeartbeat: number;
  connectedAt: number;
  metadata?: Record<string, any>;
}

export interface TaskModel {
  id: string;
  executionId: string;
  symbol: any;
  priority: number;
  dependencies: string[];
  status: string;
  assignedTo?: string;
  createdAt: number;
  assignedAt?: number;
}

// ============================================================================
// GraphQL Context
// ============================================================================

export interface AuthUser {
  id: string;
  username: string;
  roles: string[];
  permissions: string[];
}

export interface GraphQLContext {
  // Authentication
  user: AuthUser | null;
  token: string | null;

  // Data sources
  dataSources: {
    ecto: EctoDataSource;
    swarm: SwarmDataSource;
    powershell: PowerShellDataSource;
    injector: InjectorDataSource;
  };

  // DataLoaders
  loaders: {
    symbolLoader: DataLoader<number, SymbolModel | null>;
    workflowLoader: DataLoader<number, WorkflowModel | null>;
    executionLoader: DataLoader<number, ExecutionModel | null>;
    baselineLoader: DataLoader<number, BaselineModel | null>;
    auditLoader: DataLoader<number, AuditModel | null>;
    nodeLoader: DataLoader<string, NodeModel | null>;
    taskLoader: DataLoader<string, TaskModel | null>;
  };

  // Subscriptions
  pubsub: PubSub;

  // Utilities
  logger: Logger;
  request: IncomingMessage;
}

// ============================================================================
// Data Source Interfaces
// ============================================================================

export interface EctoDataSource {
  // Symbol operations
  getSymbol(id: number): Promise<SymbolModel | null>;
  getSymbolByName(name: string): Promise<SymbolModel | null>;
  getSymbols(filters?: SymbolFilters): Promise<SymbolModel[]>;
  createSymbol(input: any): Promise<SymbolModel>;
  updateSymbol(id: number, input: any): Promise<SymbolModel>;
  deleteSymbol(id: number): Promise<boolean>;

  // Workflow operations
  getWorkflow(id: number): Promise<WorkflowModel | null>;
  getWorkflows(filters?: WorkflowFilters): Promise<WorkflowModel[]>;
  createWorkflow(input: any): Promise<WorkflowModel>;
  updateWorkflow(id: number, updates: any): Promise<WorkflowModel>;
  deleteWorkflow(id: number): Promise<boolean>;

  // Execution operations
  getExecution(id: number): Promise<ExecutionModel | null>;
  getExecutions(filters?: ExecutionFilters): Promise<ExecutionModel[]>;
  getExecutionsByWorkflow(workflowId: number): Promise<ExecutionModel[]>;
  getExecutionsBySymbol(symbolId: number): Promise<ExecutionModel[]>;
  createExecution(input: any): Promise<ExecutionModel>;
  updateExecution(id: number, updates: any): Promise<ExecutionModel>;

  // Baseline operations
  getBaseline(id: number): Promise<BaselineModel | null>;
  getBaselines(filters?: BaselineFilters): Promise<BaselineModel[]>;
  createBaseline(input: any): Promise<BaselineModel>;
  updateBaseline(id: number, updates: any): Promise<BaselineModel>;
  deleteBaseline(id: number): Promise<boolean>;

  // Audit operations
  getAudit(id: number): Promise<AuditModel | null>;
  getAudits(filters?: AuditFilters): Promise<AuditModel[]>;
  createAudit(input: any): Promise<AuditModel>;
  updateAudit(id: number, updates: any): Promise<AuditModel>;

  // Statistics
  getSymbolStats(): Promise<any>;
  getWorkflowStats(): Promise<any>;
  getExecutionStats(): Promise<any>;
}

export interface SwarmDataSource {
  getNode(id: string): Promise<NodeModel | null>;
  getNodes(filters?: NodeFilters): Promise<NodeModel[]>;
  getTask(id: string): Promise<TaskModel | null>;
  getTasks(filters?: TaskFilters): Promise<TaskModel[]>;
  getNodeStats(): Promise<any>;
}

export interface PowerShellDataSource {
  executeScript(script: string, params?: Record<string, any>): Promise<any>;
  runSymbolicAudit(baselineId: number, workflowId?: number): Promise<any>;
  setBaseline(baselineId: number): Promise<boolean>;
  visualizeDiff(baseline1: number, baseline2: number): Promise<any>;
}

export interface InjectorDataSource {
  getInjectorStatus(): Promise<any>;
  executeInjection(symbolId: number, params: Record<string, any>): Promise<any>;
}

// ============================================================================
// Filter Types
// ============================================================================

export interface SymbolFilters {
  type?: string;
  context?: string;
  status?: string;
  limit?: number;
  offset?: number;
}

export interface WorkflowFilters {
  status?: string;
  limit?: number;
  offset?: number;
}

export interface ExecutionFilters {
  workflowId?: number;
  symbolId?: number;
  status?: string;
  limit?: number;
  offset?: number;
}

export interface BaselineFilters {
  active?: boolean;
  baselineType?: string;
  scope?: string;
  limit?: number;
  offset?: number;
}

export interface AuditFilters {
  baselineId?: number;
  severity?: string;
  status?: string;
  limit?: number;
  offset?: number;
}

export interface NodeFilters {
  status?: string;
  limit?: number;
  offset?: number;
}

export interface TaskFilters {
  nodeId?: string;
  status?: string;
  limit?: number;
  offset?: number;
}

// ============================================================================
// Subscription Events
// ============================================================================

export const SUBSCRIPTION_TOPICS = {
  WORKFLOW_UPDATED: 'WORKFLOW_UPDATED',
  WORKFLOW_STATUS_CHANGED: 'WORKFLOW_STATUS_CHANGED',
  EXECUTION_UPDATED: 'EXECUTION_UPDATED',
  EXECUTION_STATUS_CHANGED: 'EXECUTION_STATUS_CHANGED',
  AUDIT_COMPLETED: 'AUDIT_COMPLETED',
  AUDIT_DEVIATION_DETECTED: 'AUDIT_DEVIATION_DETECTED',
  NODE_STATUS_CHANGED: 'NODE_STATUS_CHANGED',
  NODE_HEALTH_UPDATED: 'NODE_HEALTH_UPDATED',
  TASK_ASSIGNED: 'TASK_ASSIGNED',
  TASK_UPDATED: 'TASK_UPDATED',
  STATS_UPDATED: 'STATS_UPDATED',
} as const;

export type SubscriptionTopic = typeof SUBSCRIPTION_TOPICS[keyof typeof SUBSCRIPTION_TOPICS];

// ============================================================================
// Error Types
// ============================================================================

export class AuthenticationError extends Error {
  constructor(message: string = 'Not authenticated') {
    super(message);
    this.name = 'AuthenticationError';
  }
}

export class AuthorizationError extends Error {
  constructor(message: string = 'Not authorized') {
    super(message);
    this.name = 'AuthorizationError';
  }
}

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class NotFoundError extends Error {
  constructor(resource: string, id: string | number) {
    super(`${resource} with id ${id} not found`);
    this.name = 'NotFoundError';
  }
}
