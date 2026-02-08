/**
 * WP Praxis Dashboard - Type Definitions
 * Shared types for the symbolic engine dashboard
 */

// ============================================================================
// Core Symbol Types
// ============================================================================

export interface Symbol {
  id: string;
  name: string;
  type: SymbolType;
  context: string;
  dispatch: string;
  parameters: Record<string, unknown>;
  metadata: SymbolMetadata;
  created_at: string;
  updated_at: string;
}

export type SymbolType = 'action' | 'query' | 'transformation' | 'validation' | 'audit';

export interface SymbolMetadata {
  description?: string;
  version?: string;
  author?: string;
  tags?: string[];
  dependencies?: string[];
}

// ============================================================================
// Workflow Types
// ============================================================================

export interface Workflow {
  id: string;
  name: string;
  description?: string;
  symbols: Symbol[];
  dependencies: WorkflowDependency[];
  status: WorkflowStatus;
  manifest_path: string;
  created_at: string;
  updated_at: string;
  last_execution?: string;
}

export interface WorkflowDependency {
  from_symbol: string;
  to_symbol: string;
  type: 'required' | 'optional' | 'conditional';
}

export type WorkflowStatus = 'draft' | 'active' | 'paused' | 'archived' | 'error';

// ============================================================================
// Execution Types
// ============================================================================

export interface Execution {
  id: string;
  workflow_id: string;
  symbol_id?: string;
  status: ExecutionStatus;
  started_at: string;
  completed_at?: string;
  duration_ms?: number;
  result?: ExecutionResult;
  error?: ExecutionError;
  logs: ExecutionLog[];
  metadata: Record<string, unknown>;
}

export type ExecutionStatus =
  | 'pending'
  | 'running'
  | 'completed'
  | 'failed'
  | 'cancelled'
  | 'timeout';

export interface ExecutionResult {
  success: boolean;
  output?: unknown;
  changes?: Change[];
  metrics?: ExecutionMetrics;
}

export interface ExecutionError {
  code: string;
  message: string;
  stack?: string;
  context?: Record<string, unknown>;
}

export interface ExecutionLog {
  timestamp: string;
  level: LogLevel;
  message: string;
  context?: Record<string, unknown>;
}

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface ExecutionMetrics {
  cpu_time_ms?: number;
  memory_mb?: number;
  io_operations?: number;
  cache_hits?: number;
  cache_misses?: number;
}

// ============================================================================
// Audit Types
// ============================================================================

export interface Audit {
  id: string;
  workflow_id: string;
  execution_id: string;
  baseline_id?: string;
  started_at: string;
  completed_at?: string;
  status: 'running' | 'completed' | 'failed';
  deviations: Deviation[];
  summary: AuditSummary;
}

export interface Deviation {
  id: string;
  type: DeviationType;
  severity: 'low' | 'medium' | 'high' | 'critical';
  path: string;
  expected: unknown;
  actual: unknown;
  message: string;
  context?: Record<string, unknown>;
}

export type DeviationType =
  | 'missing'
  | 'unexpected'
  | 'modified'
  | 'type_mismatch'
  | 'value_mismatch'
  | 'permission'
  | 'integrity';

export interface AuditSummary {
  total_deviations: number;
  by_severity: Record<string, number>;
  by_type: Record<string, number>;
  compliance_score: number;
}

// ============================================================================
// Baseline Types
// ============================================================================

export interface Baseline {
  id: string;
  name: string;
  description?: string;
  workflow_id: string;
  snapshot: BaselineSnapshot;
  created_at: string;
  created_by?: string;
  is_normative: boolean;
}

export interface BaselineSnapshot {
  version: string;
  timestamp: string;
  state: Record<string, unknown>;
  checksums: Record<string, string>;
  metadata: Record<string, unknown>;
}

// ============================================================================
// Statistics Types
// ============================================================================

export interface DashboardStats {
  workflows: WorkflowStats;
  executions: ExecutionStats;
  audits: AuditStats;
  system: SystemStats;
  timestamp: string;
}

export interface WorkflowStats {
  total: number;
  active: number;
  paused: number;
  error: number;
}

export interface ExecutionStats {
  total: number;
  running: number;
  completed_today: number;
  failed_today: number;
  success_rate: number;
  avg_duration_ms: number;
}

export interface AuditStats {
  total_audits: number;
  total_deviations: number;
  critical_deviations: number;
  avg_compliance_score: number;
}

export interface SystemStats {
  uptime_seconds: number;
  memory_usage_mb: number;
  cpu_usage_percent: number;
  active_connections: number;
}

// ============================================================================
// Change Types
// ============================================================================

export interface Change {
  id: string;
  type: ChangeType;
  path: string;
  old_value?: unknown;
  new_value?: unknown;
  timestamp: string;
}

export type ChangeType = 'create' | 'update' | 'delete' | 'move' | 'copy';

// ============================================================================
// API Request/Response Types
// ============================================================================

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: ApiError;
  metadata?: ApiMetadata;
}

export interface ApiError {
  code: string;
  message: string;
  details?: Record<string, unknown>;
}

export interface ApiMetadata {
  timestamp: string;
  request_id?: string;
  pagination?: Pagination;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

export interface PaginationParams {
  page?: number;
  limit?: number;
  sort?: string;
  order?: 'asc' | 'desc';
}

// ============================================================================
// WebSocket Types
// ============================================================================

export interface WebSocketMessage {
  type: WebSocketMessageType;
  payload: unknown;
  timestamp: string;
}

export type WebSocketMessageType =
  | 'execution_started'
  | 'execution_progress'
  | 'execution_completed'
  | 'execution_failed'
  | 'audit_started'
  | 'audit_completed'
  | 'deviation_detected'
  | 'stats_update'
  | 'log_entry'
  | 'error'
  | 'heartbeat';

// ============================================================================
// Config Types
// ============================================================================

export interface DashboardConfig {
  server: ServerConfig;
  database: DatabaseConfig;
  api: ApiConfig;
  auth: AuthConfig;
  logging: LoggingConfig;
  state: StateConfig;
  cache: CacheConfig;
  features: FeatureFlags;
  ui: UIConfig;
  monitoring: MonitoringConfig;
  security: SecurityConfig;
}

export interface ServerConfig {
  host: string;
  port: number;
  env: 'development' | 'staging' | 'production';
  cors: CorsConfig;
  websocket: WebSocketConfig;
}

export interface CorsConfig {
  enabled: boolean;
  origins: string[];
  methods: string[];
  credentials: boolean;
}

export interface WebSocketConfig {
  enabled: boolean;
  path: string;
  heartbeat_interval: number;
  max_payload: number;
}

export interface DatabaseConfig {
  host: string;
  port: number;
  database: string;
  user: string;
  password: string;
  max_connections: number;
  idle_timeout: number;
  connection_timeout: number;
  ssl: {
    enabled: boolean;
    reject_unauthorized: boolean;
  };
}

export interface ApiConfig {
  prefix: string;
  version: string;
  rate_limit_enabled: boolean;
  rate_limit_max: number;
  rate_limit_window: number;
  pagination: {
    default_limit: number;
    max_limit: number;
  };
}

export interface AuthConfig {
  enabled: boolean;
  jwt_secret: string;
  jwt_expiry: number;
  session_timeout: number;
}

export interface LoggingConfig {
  level: LogLevel;
  format: 'json' | 'pretty';
  log_requests: boolean;
  log_responses: boolean;
}

export interface StateConfig {
  sources: string[];
  ecto_db: StateSourceConfig;
  swarm_state: StateSourceConfig;
  powershell_state: PowerShellStateConfig;
}

export interface StateSourceConfig {
  enabled: boolean;
  refresh_interval: number;
  endpoint?: string;
}

export interface PowerShellStateConfig extends StateSourceConfig {
  script_path: string;
}

export interface CacheConfig {
  enabled: boolean;
  ttl: number;
  max_size: number;
}

export interface FeatureFlags {
  real_time_updates: boolean;
  workflow_visualization: boolean;
  symbol_inspection: boolean;
  audit_reports: boolean;
  baseline_management: boolean;
  execution_tracking: boolean;
  performance_metrics: boolean;
}

export interface UIConfig {
  theme: 'light' | 'dark' | 'auto';
  auto_refresh: boolean;
  refresh_interval: number;
  max_log_lines: number;
  chart_animation: boolean;
  colors: {
    primary: string;
    secondary: string;
    success: string;
    warning: string;
    error: string;
    info: string;
  };
}

export interface MonitoringConfig {
  health_check_enabled: boolean;
  health_check_interval: number;
  metrics_enabled: boolean;
  metrics_endpoint: string;
}

export interface SecurityConfig {
  helmet_enabled: boolean;
  csrf_enabled: boolean;
  xss_protection: boolean;
  content_security_policy: boolean;
  headers: Record<string, string>;
}
