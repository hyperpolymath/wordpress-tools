/**
 * Dashboard WebSocket Events
 * Real-time event broadcasting for dashboard updates
 */

import type { ServerWebSocket } from 'bun';
import type { WebSocketMessage, WebSocketMessageType } from '@types/index';

export class DashboardEvents {
  private connections: Set<ServerWebSocket<unknown>> = new Set();
  private heartbeatInterval: Timer | null = null;

  constructor(private heartbeatMs: number = 30000) {}

  /**
   * Add a new WebSocket connection
   */
  addConnection(ws: ServerWebSocket<unknown>): void {
    this.connections.add(ws);
    console.log(`[DashboardEvents] New connection added. Total: ${this.connections.size}`);

    // Send initial connection success message
    this.sendToClient(ws, 'heartbeat', { connected: true });

    // Start heartbeat if not already running
    if (!this.heartbeatInterval && this.heartbeatMs > 0) {
      this.startHeartbeat();
    }
  }

  /**
   * Remove a WebSocket connection
   */
  removeConnection(ws: ServerWebSocket<unknown>): void {
    this.connections.delete(ws);
    console.log(`[DashboardEvents] Connection removed. Total: ${this.connections.size}`);

    // Stop heartbeat if no more connections
    if (this.connections.size === 0 && this.heartbeatInterval) {
      this.stopHeartbeat();
    }
  }

  /**
   * Get number of active connections
   */
  getConnectionCount(): number {
    return this.connections.size;
  }

  /**
   * Broadcast message to all connected clients
   */
  broadcast(type: WebSocketMessageType, payload: unknown): void {
    const message = this.createMessage(type, payload);
    const messageStr = JSON.stringify(message);

    for (const ws of this.connections) {
      try {
        ws.send(messageStr);
      } catch (error) {
        console.error('[DashboardEvents] Error broadcasting to client:', error);
        this.connections.delete(ws);
      }
    }
  }

  /**
   * Send message to specific client
   */
  sendToClient(ws: ServerWebSocket<unknown>, type: WebSocketMessageType, payload: unknown): void {
    const message = this.createMessage(type, payload);
    try {
      ws.send(JSON.stringify(message));
    } catch (error) {
      console.error('[DashboardEvents] Error sending to client:', error);
      this.connections.delete(ws);
    }
  }

  /**
   * Broadcast execution started event
   */
  broadcastExecutionStarted(executionId: string, workflowId: string): void {
    this.broadcast('execution_started', {
      execution_id: executionId,
      workflow_id: workflowId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast execution progress event
   */
  broadcastExecutionProgress(
    executionId: string,
    progress: number,
    message?: string
  ): void {
    this.broadcast('execution_progress', {
      execution_id: executionId,
      progress,
      message,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast execution completed event
   */
  broadcastExecutionCompleted(
    executionId: string,
    result: unknown,
    duration_ms: number
  ): void {
    this.broadcast('execution_completed', {
      execution_id: executionId,
      result,
      duration_ms,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast execution failed event
   */
  broadcastExecutionFailed(executionId: string, error: unknown): void {
    this.broadcast('execution_failed', {
      execution_id: executionId,
      error,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast audit started event
   */
  broadcastAuditStarted(auditId: string, workflowId: string): void {
    this.broadcast('audit_started', {
      audit_id: auditId,
      workflow_id: workflowId,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast audit completed event
   */
  broadcastAuditCompleted(auditId: string, summary: unknown): void {
    this.broadcast('audit_completed', {
      audit_id: auditId,
      summary,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast deviation detected event
   */
  broadcastDeviationDetected(deviation: unknown): void {
    this.broadcast('deviation_detected', {
      deviation,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast statistics update
   */
  broadcastStatsUpdate(stats: unknown): void {
    this.broadcast('stats_update', {
      stats,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast log entry
   */
  broadcastLogEntry(level: string, message: string, context?: unknown): void {
    this.broadcast('log_entry', {
      level,
      message,
      context,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Broadcast error
   */
  broadcastError(code: string, message: string, details?: unknown): void {
    this.broadcast('error', {
      code,
      message,
      details,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Create a WebSocket message
   */
  private createMessage(type: WebSocketMessageType, payload: unknown): WebSocketMessage {
    return {
      type,
      payload,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Start heartbeat interval
   */
  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      this.broadcast('heartbeat', { timestamp: new Date().toISOString() });
    }, this.heartbeatMs);
    console.log(`[DashboardEvents] Heartbeat started (${this.heartbeatMs}ms)`);
  }

  /**
   * Stop heartbeat interval
   */
  private stopHeartbeat(): void {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
      console.log('[DashboardEvents] Heartbeat stopped');
    }
  }

  /**
   * Cleanup all connections and timers
   */
  cleanup(): void {
    this.stopHeartbeat();
    this.connections.clear();
    console.log('[DashboardEvents] Cleanup completed');
  }
}
