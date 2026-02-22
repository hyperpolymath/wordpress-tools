/**
 * Stream Handler — Real-Time Execution Observability.
 *
 * This module manages the distribution of streaming data (logs, progress) 
 * to active dashboard clients. It implements a "Subscription" pattern 
 * where clients can listen to the live output of specific symbolic 
 * execution tasks.
 *
 * DESIGN PILLARS:
 * 1. **Multiplexing**: Routes events from the swarm to the correct 
 *    set of interested UI clients.
 * 2. **Fault Tolerance**: Detects and removes stale or disconnected 
 *    WebSockets during broadcast loops.
 * 3. **Concurrency**: Uses `Set` objects for efficient subscriber 
 *    management within the Bun runtime.
 */

import type { ServerWebSocket } from 'bun';
import type { DashboardEvents } from './dashboard-events';

export class StreamHandler {
  /**
   * REGISTRY: Maps active `executionId` strings to the set of 
   * connected WebSocket clients.
   */
  private activeStreams: Map<string, Set<ServerWebSocket<unknown>>> = new Map();

  constructor(private events: DashboardEvents) {}

  /**
   * SUBSCRIBE: Adds a WebSocket client to the listener set for 
   * a specific execution.
   */
  subscribe(executionId: string, ws: ServerWebSocket<unknown>): void {
    if (!this.activeStreams.has(executionId)) {
      this.activeStreams.set(executionId, new Set());
    }
    this.activeStreams.get(executionId)!.add(ws);
    // ... [Confirmation messaging logic]
  }

  /**
   * BROADCAST (streamLog): Pushes a new log entry to all subscribers 
   * of the specified `executionId`. 
   * Includes a UTC timestamp for ordering in the UI.
   */
  streamLog(executionId: string, level: string, message: string, context?: unknown): void {
    const subscribers = this.activeStreams.get(executionId);
    if (!subscribers) return;

    for (const ws of subscribers) {
      try {
        this.events.sendToClient(ws, 'log_entry', { execution_id: executionId, level, message, timestamp: new Date().toISOString() });
      } catch (error) {
        subscribers.delete(ws); // Cleanup on failure.
      }
    }
  }
}
