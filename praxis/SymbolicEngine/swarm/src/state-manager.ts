/**
 * WP Praxis Swarm - State Manager
 *
 * Distributed state management using SQLite with transaction support,
 * state synchronization, and recovery capabilities.
 */

import Database from 'better-sqlite3';
import { createHash } from 'crypto';
import type {
  StateTransaction,
  StateOperation,
  StateSnapshot,
  Execution,
  Task,
  Node,
} from './types';
import { Logger } from './logger';

export class StateManager {
  private db: Database.Database;
  private logger: Logger;
  private currentTransaction: StateTransaction | null = null;

  constructor(dbPath: string, logger?: Logger) {
    this.logger = logger ?? new Logger('StateManager');
    this.db = new Database(dbPath);
    this.initializeSchema();
    this.logger.info(`State manager initialized with database: ${dbPath}`);
  }

  /**
   * Initialize database schema
   */
  private initializeSchema(): void {
    // State table - generic key-value store
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        type TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        checksum TEXT NOT NULL
      );
    `);

    // Executions table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS executions (
        id TEXT PRIMARY KEY,
        workflow_id TEXT NOT NULL,
        symbol_name TEXT NOT NULL,
        status TEXT NOT NULL,
        node_id TEXT,
        result TEXT,
        attempts INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        started_at INTEGER,
        completed_at INTEGER
      );
      CREATE INDEX IF NOT EXISTS idx_executions_workflow ON executions(workflow_id);
      CREATE INDEX IF NOT EXISTS idx_executions_status ON executions(status);
    `);

    // Tasks table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        execution_id TEXT NOT NULL,
        symbol TEXT NOT NULL,
        priority INTEGER NOT NULL,
        dependencies TEXT NOT NULL,
        status TEXT NOT NULL,
        assigned_to TEXT,
        created_at INTEGER NOT NULL,
        assigned_at INTEGER,
        FOREIGN KEY(execution_id) REFERENCES executions(id)
      );
      CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
      CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority DESC);
    `);

    // Nodes table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS nodes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        capabilities TEXT NOT NULL,
        health TEXT NOT NULL,
        last_heartbeat INTEGER NOT NULL,
        connected_at INTEGER NOT NULL,
        metadata TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_nodes_status ON nodes(status);
    `);

    // Transactions log table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS transaction_log (
        id TEXT PRIMARY KEY,
        operations TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        committed INTEGER NOT NULL DEFAULT 0
      );
      CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transaction_log(timestamp);
    `);

    // Snapshots table
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS snapshots (
        timestamp INTEGER PRIMARY KEY,
        data TEXT NOT NULL,
        checksum TEXT NOT NULL
      );
    `);

    this.logger.debug('Database schema initialized');
  }

  // ============================================================================
  // Generic State Operations
  // ============================================================================

  /**
   * Set a state value
   */
  set(key: string, value: unknown, type: string = 'generic'): void {
    const serialized = JSON.stringify(value);
    const checksum = this.calculateChecksum(serialized);
    const timestamp = Date.now();

    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO state (key, value, type, updated_at, checksum)
      VALUES (?, ?, ?, ?, ?)
    `);

    stmt.run(key, serialized, type, timestamp, checksum);

    if (this.currentTransaction) {
      this.currentTransaction.operations.push({
        type: 'set',
        key,
        value,
      });
    }

    this.logger.debug(`State set: ${key} = ${serialized.substring(0, 100)}...`);
  }

  /**
   * Get a state value
   */
  get<T = unknown>(key: string): T | null {
    const stmt = this.db.prepare('SELECT value FROM state WHERE key = ?');
    const row = stmt.get(key) as { value: string } | undefined;

    if (!row) {
      return null;
    }

    try {
      return JSON.parse(row.value) as T;
    } catch (error) {
      this.logger.error(`Failed to parse state value for key ${key}:`, error);
      return null;
    }
  }

  /**
   * Delete a state value
   */
  delete(key: string): boolean {
    const previousValue = this.get(key);
    const stmt = this.db.prepare('DELETE FROM state WHERE key = ?');
    const result = stmt.run(key);

    if (this.currentTransaction && result.changes > 0) {
      this.currentTransaction.operations.push({
        type: 'delete',
        key,
        previousValue,
      });
    }

    return result.changes > 0;
  }

  /**
   * Update a state value (partial update for objects)
   */
  update(key: string, updates: Record<string, unknown>): void {
    const current = this.get<Record<string, unknown>>(key) ?? {};
    const updated = { ...current, ...updates };
    this.set(key, updated);

    if (this.currentTransaction) {
      this.currentTransaction.operations.push({
        type: 'update',
        key,
        value: updates,
        previousValue: current,
      });
    }
  }

  // ============================================================================
  // Execution Management
  // ============================================================================

  saveExecution(execution: Execution): void {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO executions
      (id, workflow_id, symbol_name, status, node_id, result, attempts,
       created_at, updated_at, started_at, completed_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      execution.id,
      execution.workflowId,
      execution.symbolName,
      execution.status,
      execution.nodeId ?? null,
      execution.result ? JSON.stringify(execution.result) : null,
      execution.attempts,
      execution.createdAt,
      execution.updatedAt,
      execution.startedAt ?? null,
      execution.completedAt ?? null
    );

    this.logger.debug(`Execution saved: ${execution.id} (${execution.status})`);
  }

  getExecution(id: string): Execution | null {
    const stmt = this.db.prepare('SELECT * FROM executions WHERE id = ?');
    const row = stmt.get(id) as any;

    if (!row) {
      return null;
    }

    return {
      id: row.id,
      workflowId: row.workflow_id,
      symbolName: row.symbol_name,
      status: row.status,
      nodeId: row.node_id ?? undefined,
      result: row.result ? JSON.parse(row.result) : undefined,
      attempts: row.attempts,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      startedAt: row.started_at ?? undefined,
      completedAt: row.completed_at ?? undefined,
    };
  }

  getExecutionsByWorkflow(workflowId: string): Execution[] {
    const stmt = this.db.prepare('SELECT * FROM executions WHERE workflow_id = ?');
    const rows = stmt.all(workflowId) as any[];

    return rows.map((row) => ({
      id: row.id,
      workflowId: row.workflow_id,
      symbolName: row.symbol_name,
      status: row.status,
      nodeId: row.node_id ?? undefined,
      result: row.result ? JSON.parse(row.result) : undefined,
      attempts: row.attempts,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      startedAt: row.started_at ?? undefined,
      completedAt: row.completed_at ?? undefined,
    }));
  }

  // ============================================================================
  // Task Management
  // ============================================================================

  saveTask(task: Task): void {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO tasks
      (id, execution_id, symbol, priority, dependencies, status, assigned_to, created_at, assigned_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      task.id,
      task.executionId,
      JSON.stringify(task.symbol),
      task.priority,
      JSON.stringify(task.dependencies),
      task.status,
      task.assignedTo ?? null,
      task.createdAt,
      task.assignedAt ?? null
    );

    this.logger.debug(`Task saved: ${task.id} (${task.status})`);
  }

  getTask(id: string): Task | null {
    const stmt = this.db.prepare('SELECT * FROM tasks WHERE id = ?');
    const row = stmt.get(id) as any;

    if (!row) {
      return null;
    }

    return {
      id: row.id,
      executionId: row.execution_id,
      symbol: JSON.parse(row.symbol),
      priority: row.priority,
      dependencies: JSON.parse(row.dependencies),
      status: row.status,
      assignedTo: row.assigned_to ?? undefined,
      createdAt: row.created_at,
      assignedAt: row.assigned_at ?? undefined,
    };
  }

  getTasksByStatus(status: string): Task[] {
    const stmt = this.db.prepare('SELECT * FROM tasks WHERE status = ? ORDER BY priority DESC');
    const rows = stmt.all(status) as any[];

    return rows.map((row) => ({
      id: row.id,
      executionId: row.execution_id,
      symbol: JSON.parse(row.symbol),
      priority: row.priority,
      dependencies: JSON.parse(row.dependencies),
      status: row.status,
      assignedTo: row.assigned_to ?? undefined,
      createdAt: row.created_at,
      assignedAt: row.assigned_at ?? undefined,
    }));
  }

  // ============================================================================
  // Node Management
  // ============================================================================

  saveNode(node: Node): void {
    const stmt = this.db.prepare(`
      INSERT OR REPLACE INTO nodes
      (id, name, status, capabilities, health, last_heartbeat, connected_at, metadata)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    stmt.run(
      node.id,
      node.name,
      node.status,
      JSON.stringify(node.capabilities),
      JSON.stringify(node.health),
      node.lastHeartbeat,
      node.connectedAt,
      node.metadata ? JSON.stringify(node.metadata) : null
    );

    this.logger.debug(`Node saved: ${node.id} (${node.status})`);
  }

  getNode(id: string): Node | null {
    const stmt = this.db.prepare('SELECT * FROM nodes WHERE id = ?');
    const row = stmt.get(id) as any;

    if (!row) {
      return null;
    }

    return {
      id: row.id,
      name: row.name,
      status: row.status,
      capabilities: JSON.parse(row.capabilities),
      health: JSON.parse(row.health),
      lastHeartbeat: row.last_heartbeat,
      connectedAt: row.connected_at,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
    };
  }

  getAllNodes(): Node[] {
    const stmt = this.db.prepare('SELECT * FROM nodes');
    const rows = stmt.all() as any[];

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      status: row.status,
      capabilities: JSON.parse(row.capabilities),
      health: JSON.parse(row.health),
      lastHeartbeat: row.last_heartbeat,
      connectedAt: row.connected_at,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
    }));
  }

  // ============================================================================
  // Transaction Support
  // ============================================================================

  beginTransaction(id: string): void {
    if (this.currentTransaction) {
      throw new Error('Transaction already in progress');
    }

    this.currentTransaction = {
      id,
      operations: [],
      timestamp: Date.now(),
      committed: false,
    };

    this.db.prepare('BEGIN TRANSACTION').run();
    this.logger.debug(`Transaction started: ${id}`);
  }

  commitTransaction(): void {
    if (!this.currentTransaction) {
      throw new Error('No transaction in progress');
    }

    // Save transaction log
    const stmt = this.db.prepare(`
      INSERT INTO transaction_log (id, operations, timestamp, committed)
      VALUES (?, ?, ?, 1)
    `);

    stmt.run(
      this.currentTransaction.id,
      JSON.stringify(this.currentTransaction.operations),
      this.currentTransaction.timestamp
    );

    this.db.prepare('COMMIT').run();
    this.logger.info(`Transaction committed: ${this.currentTransaction.id}`);
    this.currentTransaction = null;
  }

  rollbackTransaction(): void {
    if (!this.currentTransaction) {
      throw new Error('No transaction in progress');
    }

    this.db.prepare('ROLLBACK').run();
    this.logger.warn(`Transaction rolled back: ${this.currentTransaction.id}`);
    this.currentTransaction = null;
  }

  // ============================================================================
  // Snapshot & Recovery
  // ============================================================================

  createSnapshot(): StateSnapshot {
    const timestamp = Date.now();
    const stmt = this.db.prepare('SELECT key, value FROM state');
    const rows = stmt.all() as Array<{ key: string; value: string }>;

    const data: Record<string, unknown> = {};
    for (const row of rows) {
      data[row.key] = JSON.parse(row.value);
    }

    const serialized = JSON.stringify(data);
    const checksum = this.calculateChecksum(serialized);

    // Save snapshot
    const insertStmt = this.db.prepare(`
      INSERT INTO snapshots (timestamp, data, checksum)
      VALUES (?, ?, ?)
    `);
    insertStmt.run(timestamp, serialized, checksum);

    this.logger.info(`Snapshot created: ${timestamp} (checksum: ${checksum})`);

    return { timestamp, data, checksum };
  }

  restoreSnapshot(timestamp: number): boolean {
    const stmt = this.db.prepare('SELECT data, checksum FROM snapshots WHERE timestamp = ?');
    const row = stmt.get(timestamp) as { data: string; checksum: string } | undefined;

    if (!row) {
      this.logger.error(`Snapshot not found: ${timestamp}`);
      return false;
    }

    // Verify checksum
    const calculatedChecksum = this.calculateChecksum(row.data);
    if (calculatedChecksum !== row.checksum) {
      this.logger.error('Snapshot checksum mismatch - data may be corrupted');
      return false;
    }

    const data = JSON.parse(row.data) as Record<string, unknown>;

    // Clear current state
    this.db.prepare('DELETE FROM state').run();

    // Restore snapshot data
    const insertStmt = this.db.prepare(`
      INSERT INTO state (key, value, type, updated_at, checksum)
      VALUES (?, ?, ?, ?, ?)
    `);

    for (const [key, value] of Object.entries(data)) {
      const serialized = JSON.stringify(value);
      const checksum = this.calculateChecksum(serialized);
      insertStmt.run(key, serialized, 'generic', timestamp, checksum);
    }

    this.logger.info(`Snapshot restored: ${timestamp}`);
    return true;
  }

  // ============================================================================
  // Utilities
  // ============================================================================

  private calculateChecksum(data: string): string {
    return createHash('sha256').update(data).digest('hex');
  }

  /**
   * Clean up old data
   */
  cleanup(olderThanMs: number): void {
    const cutoff = Date.now() - olderThanMs;

    // Clean old completed executions
    const execStmt = this.db.prepare(`
      DELETE FROM executions
      WHERE status IN ('completed', 'failed', 'cancelled')
      AND completed_at < ?
    `);
    const execResult = execStmt.run(cutoff);

    // Clean old transactions
    const txStmt = this.db.prepare('DELETE FROM transaction_log WHERE timestamp < ?');
    const txResult = txStmt.run(cutoff);

    // Clean old snapshots (keep last 10)
    const snapStmt = this.db.prepare(`
      DELETE FROM snapshots
      WHERE timestamp NOT IN (
        SELECT timestamp FROM snapshots ORDER BY timestamp DESC LIMIT 10
      )
    `);
    const snapResult = snapStmt.run();

    this.logger.info(
      `Cleanup complete: ${execResult.changes} executions, ${txResult.changes} transactions, ${snapResult.changes} snapshots removed`
    );
  }

  /**
   * Get database statistics
   */
  getStats(): Record<string, number> {
    const stats: Record<string, number> = {};

    const tables = ['state', 'executions', 'tasks', 'nodes', 'transaction_log', 'snapshots'];
    for (const table of tables) {
      const stmt = this.db.prepare(`SELECT COUNT(*) as count FROM ${table}`);
      const row = stmt.get() as { count: number };
      stats[table] = row.count;
    }

    return stats;
  }

  /**
   * Close database connection
   */
  close(): void {
    this.db.close();
    this.logger.info('State manager closed');
  }
}

/**
 * Logger class for state manager (will be replaced by actual logger)
 */
class Logger {
  constructor(private context: string) {}

  debug(message: string, ...args: unknown[]): void {
    console.log(`[${this.context}] DEBUG:`, message, ...args);
  }

  info(message: string, ...args: unknown[]): void {
    console.log(`[${this.context}] INFO:`, message, ...args);
  }

  warn(message: string, ...args: unknown[]): void {
    console.warn(`[${this.context}] WARN:`, message, ...args);
  }

  error(message: string, ...args: unknown[]): void {
    console.error(`[${this.context}] ERROR:`, message, ...args);
  }
}
