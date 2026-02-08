/**
 * PostgreSQL Client for Ecto Database
 * Connects to the WP Praxis Ecto database and provides query capabilities
 */

import postgres from 'postgres';
import type { DatabaseConfig } from '@types/index';

export class PostgresClient {
  private sql: ReturnType<typeof postgres>;
  private connected: boolean = false;

  constructor(private config: DatabaseConfig) {
    this.sql = postgres({
      host: config.host,
      port: config.port,
      database: config.database,
      username: config.user,
      password: config.password,
      max: config.max_connections,
      idle_timeout: config.idle_timeout / 1000, // Convert to seconds
      connect_timeout: config.connection_timeout / 1000,
      ssl: config.ssl.enabled
        ? {
            rejectUnauthorized: config.ssl.reject_unauthorized,
          }
        : false,
      onnotice: () => {}, // Suppress NOTICE messages
      debug: process.env.NODE_ENV === 'development',
    });
  }

  /**
   * Connect to the database and verify connection
   */
  async connect(): Promise<void> {
    try {
      await this.sql`SELECT 1 as connected`;
      this.connected = true;
      console.log('[PostgresClient] Connected to Ecto database');
    } catch (error) {
      console.error('[PostgresClient] Connection failed:', error);
      throw new Error(`Failed to connect to database: ${error}`);
    }
  }

  /**
   * Check if database is connected
   */
  isConnected(): boolean {
    return this.connected;
  }

  /**
   * Disconnect from the database
   */
  async disconnect(): Promise<void> {
    await this.sql.end();
    this.connected = false;
    console.log('[PostgresClient] Disconnected from database');
  }

  // ============================================================================
  // Workflow Queries
  // ============================================================================

  async getWorkflows(params: {
    limit?: number;
    offset?: number;
    status?: string;
  } = {}) {
    const { limit = 20, offset = 0, status } = params;

    let query = this.sql`
      SELECT * FROM workflows
      ${status ? this.sql`WHERE status = ${status}` : this.sql``}
      ORDER BY updated_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;

    return await query;
  }

  async getWorkflowById(id: string) {
    const result = await this.sql`
      SELECT * FROM workflows
      WHERE id = ${id}
      LIMIT 1
    `;
    return result[0] || null;
  }

  async createWorkflow(workflow: {
    name: string;
    description?: string;
    manifest_path: string;
    status?: string;
  }) {
    const result = await this.sql`
      INSERT INTO workflows (name, description, manifest_path, status)
      VALUES (${workflow.name}, ${workflow.description || null}, ${workflow.manifest_path}, ${workflow.status || 'draft'})
      RETURNING *
    `;
    return result[0];
  }

  async updateWorkflow(
    id: string,
    updates: {
      name?: string;
      description?: string;
      status?: string;
      manifest_path?: string;
    }
  ) {
    const setClauses = [];
    const values = [];

    if (updates.name !== undefined) {
      setClauses.push('name = $' + (values.length + 1));
      values.push(updates.name);
    }
    if (updates.description !== undefined) {
      setClauses.push('description = $' + (values.length + 1));
      values.push(updates.description);
    }
    if (updates.status !== undefined) {
      setClauses.push('status = $' + (values.length + 1));
      values.push(updates.status);
    }
    if (updates.manifest_path !== undefined) {
      setClauses.push('manifest_path = $' + (values.length + 1));
      values.push(updates.manifest_path);
    }

    if (setClauses.length === 0) {
      return null;
    }

    const result = await this.sql`
      UPDATE workflows
      SET ${this.sql(setClauses.join(', '))}, updated_at = NOW()
      WHERE id = ${id}
      RETURNING *
    `;
    return result[0] || null;
  }

  async deleteWorkflow(id: string) {
    const result = await this.sql`
      DELETE FROM workflows
      WHERE id = ${id}
      RETURNING id
    `;
    return result.length > 0;
  }

  async countWorkflows(status?: string) {
    const result = await this.sql`
      SELECT COUNT(*) as count FROM workflows
      ${status ? this.sql`WHERE status = ${status}` : this.sql``}
    `;
    return parseInt(result[0]?.count || '0', 10);
  }

  // ============================================================================
  // Symbol Queries
  // ============================================================================

  async getSymbols(params: { limit?: number; offset?: number; type?: string } = {}) {
    const { limit = 20, offset = 0, type } = params;

    let query = this.sql`
      SELECT * FROM symbols
      ${type ? this.sql`WHERE type = ${type}` : this.sql``}
      ORDER BY created_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;

    return await query;
  }

  async getSymbolById(id: string) {
    const result = await this.sql`
      SELECT * FROM symbols
      WHERE id = ${id}
      LIMIT 1
    `;
    return result[0] || null;
  }

  async getSymbolsByWorkflow(workflowId: string) {
    return await this.sql`
      SELECT s.* FROM symbols s
      JOIN workflow_symbols ws ON s.id = ws.symbol_id
      WHERE ws.workflow_id = ${workflowId}
      ORDER BY ws.sequence
    `;
  }

  // ============================================================================
  // Execution Queries
  // ============================================================================

  async getExecutions(params: {
    limit?: number;
    offset?: number;
    workflow_id?: string;
    status?: string;
  } = {}) {
    const { limit = 20, offset = 0, workflow_id, status } = params;

    const conditions = [];
    if (workflow_id) conditions.push(this.sql`workflow_id = ${workflow_id}`);
    if (status) conditions.push(this.sql`status = ${status}`);

    const whereClause =
      conditions.length > 0 ? this.sql`WHERE ${this.sql.join(conditions, this.sql` AND `)}` : this.sql``;

    return await this.sql`
      SELECT * FROM executions
      ${whereClause}
      ORDER BY started_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  }

  async getExecutionById(id: string) {
    const result = await this.sql`
      SELECT * FROM executions
      WHERE id = ${id}
      LIMIT 1
    `;
    return result[0] || null;
  }

  async createExecution(execution: {
    workflow_id: string;
    symbol_id?: string;
    status: string;
    metadata?: Record<string, unknown>;
  }) {
    const result = await this.sql`
      INSERT INTO executions (workflow_id, symbol_id, status, metadata, started_at)
      VALUES (${execution.workflow_id}, ${execution.symbol_id || null}, ${execution.status}, ${JSON.stringify(execution.metadata || {})}, NOW())
      RETURNING *
    `;
    return result[0];
  }

  async updateExecution(
    id: string,
    updates: {
      status?: string;
      completed_at?: Date;
      duration_ms?: number;
      result?: Record<string, unknown>;
      error?: Record<string, unknown>;
    }
  ) {
    const result = await this.sql`
      UPDATE executions
      SET
        status = COALESCE(${updates.status || null}, status),
        completed_at = COALESCE(${updates.completed_at || null}, completed_at),
        duration_ms = COALESCE(${updates.duration_ms || null}, duration_ms),
        result = COALESCE(${JSON.stringify(updates.result || null)}, result),
        error = COALESCE(${JSON.stringify(updates.error || null)}, error)
      WHERE id = ${id}
      RETURNING *
    `;
    return result[0] || null;
  }

  async getExecutionStats(workflowId?: string) {
    const whereClause = workflowId ? this.sql`WHERE workflow_id = ${workflowId}` : this.sql``;

    const result = await this.sql`
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN status = 'running' THEN 1 ELSE 0 END) as running,
        SUM(CASE WHEN status = 'completed' AND started_at >= NOW() - INTERVAL '1 day' THEN 1 ELSE 0 END) as completed_today,
        SUM(CASE WHEN status = 'failed' AND started_at >= NOW() - INTERVAL '1 day' THEN 1 ELSE 0 END) as failed_today,
        ROUND(AVG(duration_ms)::numeric, 2) as avg_duration_ms
      FROM executions
      ${whereClause}
    `;

    return result[0] || null;
  }

  // ============================================================================
  // Audit Queries
  // ============================================================================

  async getAudits(params: {
    limit?: number;
    offset?: number;
    workflow_id?: string;
  } = {}) {
    const { limit = 20, offset = 0, workflow_id } = params;

    const whereClause = workflow_id ? this.sql`WHERE workflow_id = ${workflow_id}` : this.sql``;

    return await this.sql`
      SELECT * FROM audits
      ${whereClause}
      ORDER BY started_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  }

  async getAuditById(id: string) {
    const result = await this.sql`
      SELECT * FROM audits
      WHERE id = ${id}
      LIMIT 1
    `;
    return result[0] || null;
  }

  async getAuditStats() {
    const result = await this.sql`
      SELECT
        COUNT(*) as total_audits,
        SUM((summary->>'total_deviations')::int) as total_deviations,
        SUM((summary->'by_severity'->>'critical')::int) as critical_deviations,
        ROUND(AVG((summary->>'compliance_score')::numeric), 2) as avg_compliance_score
      FROM audits
      WHERE summary IS NOT NULL
    `;

    return result[0] || null;
  }

  // ============================================================================
  // Baseline Queries
  // ============================================================================

  async getBaselines(params: { limit?: number; offset?: number; workflow_id?: string } = {}) {
    const { limit = 20, offset = 0, workflow_id } = params;

    const whereClause = workflow_id ? this.sql`WHERE workflow_id = ${workflow_id}` : this.sql``;

    return await this.sql`
      SELECT * FROM baselines
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT ${limit}
      OFFSET ${offset}
    `;
  }

  async getBaselineById(id: string) {
    const result = await this.sql`
      SELECT * FROM baselines
      WHERE id = ${id}
      LIMIT 1
    `;
    return result[0] || null;
  }

  async getNormativeBaseline(workflowId: string) {
    const result = await this.sql`
      SELECT * FROM baselines
      WHERE workflow_id = ${workflowId} AND is_normative = true
      ORDER BY created_at DESC
      LIMIT 1
    `;
    return result[0] || null;
  }

  // ============================================================================
  // Health Check
  // ============================================================================

  async healthCheck() {
    try {
      const result = await this.sql`SELECT NOW() as timestamp, version() as version`;
      return {
        healthy: true,
        timestamp: result[0].timestamp,
        version: result[0].version,
      };
    } catch (error) {
      return {
        healthy: false,
        error: String(error),
      };
    }
  }
}
