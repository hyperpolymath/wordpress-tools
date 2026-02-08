/**
 * Swarm Data Source
 *
 * Connects to the swarm coordinator for node and task information
 */

import Database from 'better-sqlite3';
import type { Logger } from 'winston';
import type {
  SwarmDataSource,
  NodeModel,
  TaskModel,
  NodeFilters,
  TaskFilters,
} from '../types.js';

export class SwarmDataSourceImpl implements SwarmDataSource {
  private db: Database.Database;
  private logger: Logger;

  constructor(logger: Logger) {
    this.logger = logger;
    const dbPath = process.env.SWARM_DB_PATH || '../swarm/swarm-state.db';
    this.db = new Database(dbPath, { readonly: true });
  }

  async getNode(id: string): Promise<NodeModel | null> {
    try {
      const stmt = this.db.prepare('SELECT * FROM nodes WHERE id = ?');
      const row = stmt.get(id) as any;
      return row ? this.parseNode(row) : null;
    } catch (error) {
      this.logger.error('Error fetching node:', error);
      return null;
    }
  }

  async getNodes(filters: NodeFilters = {}): Promise<NodeModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];

    if (filters.status) {
      conditions.push('status = ?');
      values.push(filters.status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM nodes
      ${whereClause}
      ORDER BY connectedAt DESC
      LIMIT ? OFFSET ?
    `;

    try {
      const stmt = this.db.prepare(query);
      const rows = stmt.all(...values, limit, offset) as any[];
      return rows.map((row) => this.parseNode(row));
    } catch (error) {
      this.logger.error('Error fetching nodes:', error);
      return [];
    }
  }

  async getTask(id: string): Promise<TaskModel | null> {
    try {
      const stmt = this.db.prepare('SELECT * FROM tasks WHERE id = ?');
      const row = stmt.get(id) as any;
      return row ? this.parseTask(row) : null;
    } catch (error) {
      this.logger.error('Error fetching task:', error);
      return null;
    }
  }

  async getTasks(filters: TaskFilters = {}): Promise<TaskModel[]> {
    const conditions: string[] = [];
    const values: any[] = [];

    if (filters.nodeId) {
      conditions.push('assignedTo = ?');
      values.push(filters.nodeId);
    }

    if (filters.status) {
      conditions.push('status = ?');
      values.push(filters.status);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const limit = filters.limit || 100;
    const offset = filters.offset || 0;

    const query = `
      SELECT * FROM tasks
      ${whereClause}
      ORDER BY priority DESC, createdAt DESC
      LIMIT ? OFFSET ?
    `;

    try {
      const stmt = this.db.prepare(query);
      const rows = stmt.all(...values, limit, offset) as any[];
      return rows.map((row) => this.parseTask(row));
    } catch (error) {
      this.logger.error('Error fetching tasks:', error);
      return [];
    }
  }

  async getNodeStats(): Promise<any> {
    try {
      const total = this.db.prepare('SELECT COUNT(*) as count FROM nodes').get() as any;
      const online = this.db.prepare("SELECT COUNT(*) as count FROM nodes WHERE status IN ('idle', 'busy')").get() as any;
      const offline = this.db.prepare("SELECT COUNT(*) as count FROM nodes WHERE status = 'offline'").get() as any;

      const capacityStmt = this.db.prepare(`
        SELECT SUM(json_extract(capabilities, '$.maxConcurrentTasks')) as totalCapacity
        FROM nodes
        WHERE status IN ('idle', 'busy')
      `);
      const capacity = capacityStmt.get() as any;

      const activeTasksStmt = this.db.prepare(`
        SELECT SUM(json_extract(health, '$.activeTasks')) as activeTasks
        FROM nodes
        WHERE status IN ('idle', 'busy')
      `);
      const activeTasks = activeTasksStmt.get() as any;

      const totalCapacity = parseInt(capacity?.totalCapacity || '0', 10);
      const activeTaskCount = parseInt(activeTasks?.activeTasks || '0', 10);

      return {
        total: total.count,
        online: online.count,
        offline: offline.count,
        totalCapacity,
        utilizationRate: totalCapacity > 0 ? activeTaskCount / totalCapacity : 0,
      };
    } catch (error) {
      this.logger.error('Error fetching node stats:', error);
      return {
        total: 0,
        online: 0,
        offline: 0,
        totalCapacity: 0,
        utilizationRate: 0,
      };
    }
  }

  private parseNode(row: any): NodeModel {
    return {
      id: row.id,
      name: row.name,
      status: row.status,
      capabilities: JSON.parse(row.capabilities),
      health: JSON.parse(row.health),
      lastHeartbeat: row.lastHeartbeat,
      connectedAt: row.connectedAt,
      metadata: row.metadata ? JSON.parse(row.metadata) : undefined,
    };
  }

  private parseTask(row: any): TaskModel {
    return {
      id: row.id,
      executionId: row.executionId,
      symbol: JSON.parse(row.symbol),
      priority: row.priority,
      dependencies: JSON.parse(row.dependencies || '[]'),
      status: row.status,
      assignedTo: row.assignedTo || undefined,
      createdAt: row.createdAt,
      assignedAt: row.assignedAt || undefined,
    };
  }
}
