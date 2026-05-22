// SPDX-License-Identifier: MPL-2.0
/**
 * WP Praxis Dashboard - Type Definitions
 * Shared types for the symbolic engine dashboard
 * Fully ported to ReScript v12
 */

// ============================================================================
// Core Symbol Types
// ============================================================================

type symbolType = [
  | #action
  | #query
  | #transformation
  | #validation
  | #audit
]

type symbolMetadata = {
  description?: string,
  version?: string,
  author?: string,
  tags?: array<string>,
  dependencies?: array<string>,
}

type symbol = {
  id: string,
  name: string,
  @as("type") type_: symbolType,
  context: string,
  dispatch: string,
  parameters: Dict.t<JSON.t>,
  metadata: symbolMetadata,
  created_at: string,
  updated_at: string,
}

// ============================================================================
// Workflow Types
// ============================================================================

type workflowDependencyType = [
  | #required
  | #optional
  | #conditional
]

type workflowDependency = {
  from_symbol: string,
  to_symbol: string,
  @as("type") type_: workflowDependencyType,
}

type workflowStatus = [
  | #draft
  | #active
  | #paused
  | #archived
  | #error
]

type workflow = {
  id: string,
  name: string,
  description?: string,
  symbols: array<symbol>,
  dependencies: array<workflowDependency>,
  status: workflowStatus,
  manifest_path: string,
  created_at: string,
  updated_at: string,
  last_execution?: string,
}

// ============================================================================
// Execution Types
// ============================================================================

type executionStatus = [
  | #pending
  | #running
  | #completed
  | #failed
  | #cancelled
  | #timeout
]

type log_level = [
  | #debug
  | #info
  | #warn
  | #error
]

type executionLog = {
  timestamp: string,
  level: log_level,
  message: string,
  context?: Dict.t<JSON.t>,
}

type executionMetrics = {
  cpu_time_ms?: float,
  memory_mb?: float,
  io_operations?: int,
  cache_hits?: int,
  cache_misses?: int,
}

type changeType = [
  | #create
  | #update
  | #delete
  | #move
  | #copy
]

type change = {
  id: string,
  @as("type") type_: changeType,
  path: string,
  old_value?: JSON.t,
  new_value?: JSON.t,
  timestamp: string,
}

type executionResult = {
  success: bool,
  output?: JSON.t,
  changes?: array<change>,
  metrics?: executionMetrics,
}

type executionError = {
  code: string,
  message: string,
  stack?: string,
  context?: Dict.t<JSON.t>,
}

type execution = {
  id: string,
  workflow_id: string,
  symbol_id?: string,
  status: executionStatus,
  started_at: string,
  completed_at?: string,
  duration_ms?: float,
  result?: executionResult,
  error?: executionError,
  logs: array<executionLog>,
  metadata: Dict.t<JSON.t>,
}

// ============================================================================
// Audit Types
// ============================================================================

type deviationType = [
  | #missing
  | #unexpected
  | #modified
  | #type_mismatch
  | #value_mismatch
  | #permission
  | #integrity
]

type severity = [
  | #low
  | #medium
  | #high
  | #critical
]

type deviation = {
  id: string,
  @as("type") type_: deviationType,
  severity: severity,
  path: string,
  expected: JSON.t,
  actual: JSON.t,
  message: string,
  context?: Dict.t<JSON.t>,
}

type auditSummary = {
  total_deviations: int,
  by_severity: Dict.t<int>,
  by_type: Dict.t<int>,
  compliance_score: float,
}

type audit = {
  id: string,
  workflow_id: string,
  execution_id: string,
  baseline_id?: string,
  started_at: string,
  completed_at?: string,
  status: [ | #running | #completed | #failed ],
  deviations: array<deviation>,
  summary: auditSummary,
}

// ============================================================================
// Baseline Types
// ============================================================================

type baselineSnapshot = {
  version: string,
  timestamp: string,
  state: Dict.t<JSON.t>,
  checksums: Dict.t<string>,
  metadata: Dict.t<JSON.t>,
}

type baseline = {
  id: string,
  name: string,
  description?: string,
  workflow_id: string,
  snapshot: baselineSnapshot,
  created_at: string,
  created_by?: string,
  is_normative: bool,
}

// ============================================================================
// Statistics Types
// ============================================================================

type workflowStats = {
  total: int,
  active: int,
  paused: int,
  error: int,
}

type executionStats = {
  total: int,
  running: int,
  completed_today: int,
  failed_today: int,
  success_rate: float,
  avg_duration_ms: float,
}

type auditStats = {
  total_audits: int,
  total_deviations: int,
  critical_deviations: int,
  avg_compliance_score: float,
}

type systemStats = {
  uptime_seconds: float,
  memory_usage_mb: float,
  cpu_usage_percent: float,
  active_connections: int,
}

type dashboardStats = {
  workflows: workflowStats,
  executions: executionStats,
  audits: auditStats,
  system: systemStats,
  timestamp: string,
}

// ============================================================================
// API Request/Response Types
// ============================================================================

type pagination = {
  page: int,
  limit: int,
  total: int,
  pages: int,
}

type apiMetadata = {
  timestamp: string,
  request_id?: string,
  pagination?: pagination,
}

type apiError = {
  code: string,
  message: string,
  details?: Dict.t<JSON.t>,
}

type apiResponse<'a> = {
  success: bool,
  data?: 'a,
  error?: apiError,
  metadata?: apiMetadata,
}

// ============================================================================
// Config Types
// ============================================================================

type corsConfig = {
  enabled: bool,
  origins: array<string>,
  methods: array<string>,
  credentials: bool,
}

type webSocketConfig = {
  enabled: bool,
  path: string,
  heartbeat_interval: int,
  max_payload: int,
}

type serverConfig = {
  host: string,
  port: int,
  env: [ | #development | #staging | #production ],
  cors: corsConfig,
  websocket: webSocketConfig,
}

type databaseConfig = {
  host: string,
  port: int,
  database: string,
  user: string,
  password: string,
  max_connections: int,
  idle_timeout: int,
  connection_timeout: int,
  ssl: {
    enabled: bool,
    reject_unauthorized: bool,
  },
}

type dashboardConfig = {
  server: serverConfig,
  database: databaseConfig,
  // Additional config types omitted for brevity, can be added as needed
}
