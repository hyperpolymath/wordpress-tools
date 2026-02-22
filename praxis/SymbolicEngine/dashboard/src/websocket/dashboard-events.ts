/**
 * Dashboard Events — Real-Time WebSocket Broadcasting.
 *
 * This module implements the event-driven communication layer for the 
 * Praxis dashboard. It provides high-level abstractions for broadcasting 
 * symbolic execution and audit events to all connected clients.
 *
 * KEY FEATURES:
 * 1. **Connection Registry**: Tracks active WebSockets via a strict `Set`.
 * 2. **Heartbeat Engine**: Periodically probes clients to maintain 
 *    active state and prune dead connections.
 * 3. **Semantic Broadcasting**: Specialized methods for specific domain 
 *    events (e.g. `broadcastExecutionProgress`, `broadcastDeviationDetected`).
 * 4. **Standardized Schema**: Wraps all payloads in a `WebSocketMessage` 
 *    envelope with mandatory type and timestamp fields.
 */

import type { ServerWebSocket } from 'bun';
import type { WebSocketMessage, WebSocketMessageType } from '@types/index';

export class DashboardEvents {
  private connections: Set<ServerWebSocket<unknown>> = new Set();
  private heartbeatInterval: Timer | null = null;

  /**
   * BROADCAST: Iterates through the active connection set and sends 
   * a serialized JSON message to each client. 
   * AUTOMATIC CLEANUP: Removes the socket from the set if sending fails.
   */
  broadcast(type: WebSocketMessageType, payload: unknown): void {
    const message = this.createMessage(type, payload);
    const messageStr = JSON.stringify(message);

    for (const ws of this.connections) {
      try {
        ws.send(messageStr);
      } catch (error) {
        this.connections.delete(ws);
      }
    }
  }

  /**
   * EXECUTION FEEDBACK: Pushes a progress percentage and an optional 
   * status message to the UI.
   */
  broadcastExecutionProgress(executionId: string, progress: number, message?: string): void {
    this.broadcast('execution_progress', {
      execution_id: executionId,
      progress,
      message,
      timestamp: new Date().toISOString(),
    });
  }
}
