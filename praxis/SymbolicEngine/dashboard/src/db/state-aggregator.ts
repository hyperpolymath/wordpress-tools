/**
 * State Aggregator
 * Aggregates state from multiple sources: Ecto DB, Swarm State, PowerShell State
 */

import type {
  DashboardStats,
  WorkflowStats,
  ExecutionStats,
  AuditStats,
  SystemStats,
  StateConfig,
} from '@types/index';
import { PostgresClient } from './postgres-client';

export class StateAggregator {
  private postgresClient: PostgresClient;
  private config: StateConfig;
  private cache: Map<string, { data: unknown; timestamp: number }> = new Map();
  private cacheTTL = 5000; // 5 seconds

  constructor(postgresClient: PostgresClient, config: StateConfig) {
    this.postgresClient = postgresClient;
    this.config = config;
  }

  /**
   * Get dashboard statistics from all sources
   */
  async getDashboardStats(): Promise<DashboardStats> {
    const [workflows, executions, audits, system] = await Promise.all([
      this.getWorkflowStats(),
      this.getExecutionStats(),
      this.getAuditStats(),
      this.getSystemStats(),
    ]);

    return {
      workflows,
      executions,
      audits,
      system,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Get workflow statistics
   */
  private async getWorkflowStats(): Promise<WorkflowStats> {
    const cacheKey = 'workflow_stats';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached as WorkflowStats;

    try {
      const [total, active, paused, error] = await Promise.all([
        this.postgresClient.countWorkflows(),
        this.postgresClient.countWorkflows('active'),
        this.postgresClient.countWorkflows('paused'),
        this.postgresClient.countWorkflows('error'),
      ]);

      const stats: WorkflowStats = {
        total,
        active,
        paused,
        error,
      };

      this.setCache(cacheKey, stats);
      return stats;
    } catch (error) {
      console.error('[StateAggregator] Error getting workflow stats:', error);
      return {
        total: 0,
        active: 0,
        paused: 0,
        error: 0,
      };
    }
  }

  /**
   * Get execution statistics
   */
  private async getExecutionStats(): Promise<ExecutionStats> {
    const cacheKey = 'execution_stats';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached as ExecutionStats;

    try {
      const stats = await this.postgresClient.getExecutionStats();

      if (!stats) {
        return {
          total: 0,
          running: 0,
          completed_today: 0,
          failed_today: 0,
          success_rate: 0,
          avg_duration_ms: 0,
        };
      }

      const total = parseInt(stats.total || '0', 10);
      const running = parseInt(stats.running || '0', 10);
      const completedToday = parseInt(stats.completed_today || '0', 10);
      const failedToday = parseInt(stats.failed_today || '0', 10);
      const avgDuration = parseFloat(stats.avg_duration_ms || '0');

      const totalToday = completedToday + failedToday;
      const successRate = totalToday > 0 ? (completedToday / totalToday) * 100 : 0;

      const executionStats: ExecutionStats = {
        total,
        running,
        completed_today: completedToday,
        failed_today: failedToday,
        success_rate: Math.round(successRate * 100) / 100,
        avg_duration_ms: Math.round(avgDuration * 100) / 100,
      };

      this.setCache(cacheKey, executionStats);
      return executionStats;
    } catch (error) {
      console.error('[StateAggregator] Error getting execution stats:', error);
      return {
        total: 0,
        running: 0,
        completed_today: 0,
        failed_today: 0,
        success_rate: 0,
        avg_duration_ms: 0,
      };
    }
  }

  /**
   * Get audit statistics
   */
  private async getAuditStats(): Promise<AuditStats> {
    const cacheKey = 'audit_stats';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached as AuditStats;

    try {
      const stats = await this.postgresClient.getAuditStats();

      if (!stats) {
        return {
          total_audits: 0,
          total_deviations: 0,
          critical_deviations: 0,
          avg_compliance_score: 0,
        };
      }

      const auditStats: AuditStats = {
        total_audits: parseInt(stats.total_audits || '0', 10),
        total_deviations: parseInt(stats.total_deviations || '0', 10),
        critical_deviations: parseInt(stats.critical_deviations || '0', 10),
        avg_compliance_score: parseFloat(stats.avg_compliance_score || '0'),
      };

      this.setCache(cacheKey, auditStats);
      return auditStats;
    } catch (error) {
      console.error('[StateAggregator] Error getting audit stats:', error);
      return {
        total_audits: 0,
        total_deviations: 0,
        critical_deviations: 0,
        avg_compliance_score: 0,
      };
    }
  }

  /**
   * Get system statistics
   */
  private async getSystemStats(): Promise<SystemStats> {
    const cacheKey = 'system_stats';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached as SystemStats;

    try {
      // Get system stats from various sources
      const stats: SystemStats = {
        uptime_seconds: process.uptime(),
        memory_usage_mb: Math.round((process.memoryUsage().heapUsed / 1024 / 1024) * 100) / 100,
        cpu_usage_percent: 0, // Would need additional monitoring
        active_connections: 0, // Would be set by WebSocket handler
      };

      // Enhance with swarm state if available
      if (this.config.swarm_state.enabled) {
        const swarmStats = await this.getSwarmState();
        if (swarmStats) {
          stats.active_connections = swarmStats.active_connections || 0;
        }
      }

      this.setCache(cacheKey, stats);
      return stats;
    } catch (error) {
      console.error('[StateAggregator] Error getting system stats:', error);
      return {
        uptime_seconds: 0,
        memory_usage_mb: 0,
        cpu_usage_percent: 0,
        active_connections: 0,
      };
    }
  }

  /**
   * Get state from swarm endpoint
   */
  private async getSwarmState(): Promise<Record<string, unknown> | null> {
    if (!this.config.swarm_state.enabled || !this.config.swarm_state.endpoint) {
      return null;
    }

    const cacheKey = 'swarm_state';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached as Record<string, unknown>;

    try {
      const response = await fetch(this.config.swarm_state.endpoint);
      if (!response.ok) {
        throw new Error(`Swarm state fetch failed: ${response.statusText}`);
      }

      const data = await response.json();
      this.setCache(cacheKey, data, this.config.swarm_state.refresh_interval);
      return data;
    } catch (error) {
      console.error('[StateAggregator] Error fetching swarm state:', error);
      return null;
    }
  }

  /**
   * Get state from PowerShell script
   */
  async getPowerShellState(): Promise<Record<string, unknown> | null> {
    if (!this.config.powershell_state.enabled) {
      return null;
    }

    const cacheKey = 'powershell_state';
    const cached = this.getFromCache(cacheKey);
    if (cached) return cached as Record<string, unknown>;

    try {
      // Execute PowerShell script to get state
      const proc = Bun.spawn(['pwsh', '-NoProfile', '-Command', this.config.powershell_state.script_path, '-GetState'], {
        stdout: 'pipe',
        stderr: 'pipe',
      });

      const output = await new Response(proc.stdout).text();
      const data = JSON.parse(output);

      this.setCache(cacheKey, data, this.config.powershell_state.refresh_interval);
      return data;
    } catch (error) {
      console.error('[StateAggregator] Error getting PowerShell state:', error);
      return null;
    }
  }

  /**
   * Get aggregated state from all sources
   */
  async getAggregatedState(): Promise<Record<string, unknown>> {
    const state: Record<string, unknown> = {};

    // Get Ecto DB state
    if (this.config.ecto_db.enabled) {
      try {
        state.ecto_db = {
          connected: this.postgresClient.isConnected(),
          health: await this.postgresClient.healthCheck(),
        };
      } catch (error) {
        state.ecto_db = { error: String(error) };
      }
    }

    // Get Swarm state
    if (this.config.swarm_state.enabled) {
      state.swarm = await this.getSwarmState();
    }

    // Get PowerShell state
    if (this.config.powershell_state.enabled) {
      state.powershell = await this.getPowerShellState();
    }

    return state;
  }

  /**
   * Clear all caches
   */
  clearCache(): void {
    this.cache.clear();
  }

  /**
   * Set active connections count
   */
  setActiveConnections(count: number): void {
    const stats = this.getFromCache('system_stats') as SystemStats | null;
    if (stats) {
      stats.active_connections = count;
      this.setCache('system_stats', stats);
    }
  }

  // ============================================================================
  // Cache Helpers
  // ============================================================================

  private getFromCache(key: string): unknown | null {
    const cached = this.cache.get(key);
    if (!cached) return null;

    const now = Date.now();
    if (now - cached.timestamp > this.cacheTTL) {
      this.cache.delete(key);
      return null;
    }

    return cached.data;
  }

  private setCache(key: string, data: unknown, ttl?: number): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
    });

    // Auto-expire after TTL
    if (ttl || this.cacheTTL) {
      setTimeout(() => {
        this.cache.delete(key);
      }, ttl || this.cacheTTL);
    }
  }
}
