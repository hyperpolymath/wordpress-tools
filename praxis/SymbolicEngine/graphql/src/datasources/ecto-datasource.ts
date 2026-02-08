/**
 * Ecto/PostgreSQL Data Source
 *
 * Connects to the PostgreSQL database used by the Elixir Ecto schema
 */

import pg from 'pg';
import type { Logger } from 'winston';
import type {
  EctoDataSource,
  SymbolModel,
  WorkflowModel,
  ExecutionModel,
  BaselineModel,
  AuditModel,
  SymbolFilters,
  WorkflowFilters,
  ExecutionFilters,
  BaselineFilters,
  AuditFilters,
} from '../types.js';

const { Pool } = pg;

export class EctoDataSourceImpl implements EctoDataSource {
  private pool: pg.Pool;
  private logger: Logger;

  constructor(logger: Logger) {
    this.logger = logger;
    this.pool = new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      database: process.env.DB_NAME || 'wp_praxis_dev',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    this.pool.on('error', (err) => {
      this.logger.error('PostgreSQL pool error:', err);
    });
  }

  async close(): Promise<void> {
    await this.pool.end();
  }

  // ============================================================================
  // Symbol Operations
  // ============================================================================

  async getSymbol(id: number): Promise<SymbolModel | null> {
    const result = await this.pool.query(
      'SELECT * FROM symbols WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async getSymbolByName(name: string): Promise<SymbolModel | null> {
    const result = await this.pool.query(
      'SELECT * FROM symbols WHERE name = $1',
      [name]
    );
    return result.rows[0] || null;
  }

  async getSymbols(filters: SymbolFilters = {}): Promise<SymbolModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (filters.type) {
      conditions.push(`type = $${paramCount++}`);
      values.push(filters.type);
    }

    if (filters.context) {
      conditions.push(`context = $${paramCount++}`);
      values.push(filters.context);
    }

    if (filters.status) {
      conditions.push(`status = $${paramCount++}`);
      values.push(filters.status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM symbols
      ${whereClause}
      ORDER BY priority DESC, name ASC
      LIMIT $${paramCount++} OFFSET $${paramCount++}
    `;

    values.push(limit, offset);

    const result = await this.pool.query(query, values);
    return result.rows;
  }

  async createSymbol(input: any): Promise<SymbolModel> {
    const result = await this.pool.query(
      `INSERT INTO symbols
       (name, type, context, dispatch_target, parameters, description, priority, timeout, retry_count, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        input.name,
        input.type,
        input.context,
        input.dispatchTarget,
        JSON.stringify(input.parameters || {}),
        input.description || null,
        input.priority || 5,
        input.timeout || 300,
        input.retryCount || 0,
        'active',
      ]
    );
    return result.rows[0];
  }

  async updateSymbol(id: number, input: any): Promise<SymbolModel> {
    const updates: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (input.name !== undefined) {
      updates.push(`name = $${paramCount++}`);
      values.push(input.name);
    }
    if (input.type !== undefined) {
      updates.push(`type = $${paramCount++}`);
      values.push(input.type);
    }
    if (input.context !== undefined) {
      updates.push(`context = $${paramCount++}`);
      values.push(input.context);
    }
    if (input.status !== undefined) {
      updates.push(`status = $${paramCount++}`);
      values.push(input.status);
    }
    if (input.dispatchTarget !== undefined) {
      updates.push(`dispatch_target = $${paramCount++}`);
      values.push(input.dispatchTarget);
    }
    if (input.parameters !== undefined) {
      updates.push(`parameters = $${paramCount++}`);
      values.push(JSON.stringify(input.parameters));
    }
    if (input.description !== undefined) {
      updates.push(`description = $${paramCount++}`);
      values.push(input.description);
    }
    if (input.priority !== undefined) {
      updates.push(`priority = $${paramCount++}`);
      values.push(input.priority);
    }
    if (input.timeout !== undefined) {
      updates.push(`timeout = $${paramCount++}`);
      values.push(input.timeout);
    }
    if (input.retryCount !== undefined) {
      updates.push(`retry_count = $${paramCount++}`);
      values.push(input.retryCount);
    }

    updates.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE symbols
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await this.pool.query(query, values);
    return result.rows[0];
  }

  async deleteSymbol(id: number): Promise<boolean> {
    const result = await this.pool.query('DELETE FROM symbols WHERE id = $1', [id]);
    return (result.rowCount ?? 0) > 0;
  }

  // ============================================================================
  // Workflow Operations
  // ============================================================================

  async getWorkflow(id: number): Promise<WorkflowModel | null> {
    const result = await this.pool.query(
      'SELECT * FROM workflows WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async getWorkflows(filters: WorkflowFilters = {}): Promise<WorkflowModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (filters.status) {
      conditions.push(`status = $${paramCount++}`);
      values.push(filters.status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM workflows
      ${whereClause}
      ORDER BY inserted_at DESC
      LIMIT $${paramCount++} OFFSET $${paramCount++}
    `;

    values.push(limit, offset);

    const result = await this.pool.query(query, values);
    return result.rows;
  }

  async createWorkflow(input: any): Promise<WorkflowModel> {
    const result = await this.pool.query(
      `INSERT INTO workflows (name, description, manifest_path, metadata, status)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        input.name,
        input.description || null,
        input.manifestPath,
        JSON.stringify(input.metadata || {}),
        'pending',
      ]
    );
    return result.rows[0];
  }

  async updateWorkflow(id: number, updates: any): Promise<WorkflowModel> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    Object.entries(updates).forEach(([key, value]) => {
      setClauses.push(`${key} = $${paramCount++}`);
      values.push(value);
    });

    setClauses.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE workflows
      SET ${setClauses.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await this.pool.query(query, values);
    return result.rows[0];
  }

  async deleteWorkflow(id: number): Promise<boolean> {
    const result = await this.pool.query('DELETE FROM workflows WHERE id = $1', [id]);
    return (result.rowCount ?? 0) > 0;
  }

  // ============================================================================
  // Execution Operations
  // ============================================================================

  async getExecution(id: number): Promise<ExecutionModel | null> {
    const result = await this.pool.query(
      'SELECT * FROM executions WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async getExecutions(filters: ExecutionFilters = {}): Promise<ExecutionModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (filters.workflowId) {
      conditions.push(`workflow_id = $${paramCount++}`);
      values.push(filters.workflowId);
    }

    if (filters.symbolId) {
      conditions.push(`symbol_id = $${paramCount++}`);
      values.push(filters.symbolId);
    }

    if (filters.status) {
      conditions.push(`status = $${paramCount++}`);
      values.push(filters.status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM executions
      ${whereClause}
      ORDER BY inserted_at DESC
      LIMIT $${paramCount++} OFFSET $${paramCount++}
    `;

    values.push(limit, offset);

    const result = await this.pool.query(query, values);
    return result.rows;
  }

  async getExecutionsByWorkflow(workflowId: number): Promise<ExecutionModel[]> {
    const result = await this.pool.query(
      'SELECT * FROM executions WHERE workflow_id = $1 ORDER BY inserted_at ASC',
      [workflowId]
    );
    return result.rows;
  }

  async getExecutionsBySymbol(symbolId: number): Promise<ExecutionModel[]> {
    const result = await this.pool.query(
      'SELECT * FROM executions WHERE symbol_id = $1 ORDER BY inserted_at DESC LIMIT 100',
      [symbolId]
    );
    return result.rows;
  }

  async createExecution(input: any): Promise<ExecutionModel> {
    const result = await this.pool.query(
      `INSERT INTO executions (workflow_id, symbol_id, status, metadata)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [input.workflowId, input.symbolId, 'pending', JSON.stringify(input.metadata || {})]
    );
    return result.rows[0];
  }

  async updateExecution(id: number, updates: any): Promise<ExecutionModel> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    Object.entries(updates).forEach(([key, value]) => {
      setClauses.push(`${key} = $${paramCount++}`);
      values.push(value);
    });

    setClauses.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE executions
      SET ${setClauses.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await this.pool.query(query, values);
    return result.rows[0];
  }

  // ============================================================================
  // Baseline Operations
  // ============================================================================

  async getBaseline(id: number): Promise<BaselineModel | null> {
    const result = await this.pool.query(
      'SELECT * FROM baselines WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async getBaselines(filters: BaselineFilters = {}): Promise<BaselineModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (filters.active !== undefined) {
      conditions.push(`is_active = $${paramCount++}`);
      values.push(filters.active);
    }

    if (filters.baselineType) {
      conditions.push(`baseline_type = $${paramCount++}`);
      values.push(filters.baselineType);
    }

    if (filters.scope) {
      conditions.push(`scope = $${paramCount++}`);
      values.push(filters.scope);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM baselines
      ${whereClause}
      ORDER BY inserted_at DESC
      LIMIT $${paramCount++} OFFSET $${paramCount++}
    `;

    values.push(limit, offset);

    const result = await this.pool.query(query, values);
    return result.rows;
  }

  async createBaseline(input: any): Promise<BaselineModel> {
    const result = await this.pool.query(
      `INSERT INTO baselines
       (name, description, symbolic_state, version, baseline_type, scope, created_by, metadata)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        input.name,
        input.description || null,
        JSON.stringify(input.symbolicState),
        input.version || '1.0.0',
        input.baselineType || 'system',
        input.scope || 'global',
        input.createdBy || null,
        JSON.stringify(input.metadata || {}),
      ]
    );
    return result.rows[0];
  }

  async updateBaseline(id: number, updates: any): Promise<BaselineModel> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    Object.entries(updates).forEach(([key, value]) => {
      setClauses.push(`${key} = $${paramCount++}`);
      values.push(value);
    });

    setClauses.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE baselines
      SET ${setClauses.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await this.pool.query(query, values);
    return result.rows[0];
  }

  async deleteBaseline(id: number): Promise<boolean> {
    const result = await this.pool.query('DELETE FROM baselines WHERE id = $1', [id]);
    return (result.rowCount ?? 0) > 0;
  }

  // ============================================================================
  // Audit Operations
  // ============================================================================

  async getAudit(id: number): Promise<AuditModel | null> {
    const result = await this.pool.query(
      'SELECT * FROM audits WHERE id = $1',
      [id]
    );
    return result.rows[0] || null;
  }

  async getAudits(filters: AuditFilters = {}): Promise<AuditModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    if (filters.baselineId) {
      conditions.push(`baseline_id = $${paramCount++}`);
      values.push(filters.baselineId);
    }

    if (filters.severity) {
      conditions.push(`severity = $${paramCount++}`);
      values.push(filters.severity);
    }

    if (filters.status) {
      conditions.push(`status = $${paramCount++}`);
      values.push(filters.status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM audits
      ${whereClause}
      ORDER BY inserted_at DESC
      LIMIT $${paramCount++} OFFSET $${paramCount++}
    `;

    values.push(limit, offset);

    const result = await this.pool.query(query, values);
    return result.rows;
  }

  async createAudit(input: any): Promise<AuditModel> {
    const result = await this.pool.query(
      `INSERT INTO audits (baseline_id, workflow_id, audit_type, metadata)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [
        input.baselineId,
        input.workflowId || null,
        input.auditType || 'manual',
        JSON.stringify(input.metadata || {}),
      ]
    );
    return result.rows[0];
  }

  async updateAudit(id: number, updates: any): Promise<AuditModel> {
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramCount = 1;

    Object.entries(updates).forEach(([key, value]) => {
      setClauses.push(`${key} = $${paramCount++}`);
      values.push(value);
    });

    setClauses.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE audits
      SET ${setClauses.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await this.pool.query(query, values);
    return result.rows[0];
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  async getSymbolStats(): Promise<any> {
    const [typeStats, contextStats, statusStats, total] = await Promise.all([
      this.pool.query('SELECT type, COUNT(*) as count FROM symbols GROUP BY type'),
      this.pool.query('SELECT context, COUNT(*) as count FROM symbols GROUP BY context'),
      this.pool.query('SELECT status, COUNT(*) as count FROM symbols GROUP BY status'),
      this.pool.query('SELECT COUNT(*) as total FROM symbols'),
    ]);

    return {
      total: parseInt(total.rows[0]?.total || '0', 10),
      byType: typeStats.rows,
      byContext: contextStats.rows,
      byStatus: statusStats.rows,
    };
  }

  async getWorkflowStats(): Promise<any> {
    const stats = await this.pool.query(`
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pending') as pending,
        COUNT(*) FILTER (WHERE status = 'running') as running,
        COUNT(*) FILTER (WHERE status = 'completed') as completed,
        COUNT(*) FILTER (WHERE status = 'failed') as failed,
        AVG(duration) FILTER (WHERE duration IS NOT NULL) as average_duration,
        (COUNT(*) FILTER (WHERE status = 'completed')::float / NULLIF(COUNT(*), 0)) as success_rate
      FROM workflows
    `);

    return stats.rows[0];
  }

  async getExecutionStats(): Promise<any> {
    const stats = await this.pool.query(`
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pending') as pending,
        COUNT(*) FILTER (WHERE status = 'running') as running,
        COUNT(*) FILTER (WHERE status = 'completed') as completed,
        COUNT(*) FILTER (WHERE status = 'failed') as failed,
        AVG(duration) FILTER (WHERE duration IS NOT NULL) as average_duration,
        (COUNT(*) FILTER (WHERE status = 'completed')::float / NULLIF(COUNT(*), 0)) as success_rate
      FROM executions
    `);

    return stats.rows[0];
  }
}
