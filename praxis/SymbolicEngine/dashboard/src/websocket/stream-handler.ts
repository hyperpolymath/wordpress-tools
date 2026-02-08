/**
 * Stream Handler
 * Handles streaming execution logs and real-time data
 */

import type { ServerWebSocket } from 'bun';
import type { DashboardEvents } from './dashboard-events';

export class StreamHandler {
  private activeStreams: Map<string, Set<ServerWebSocket<unknown>>> = new Map();

  constructor(private events: DashboardEvents) {}

  /**
   * Subscribe to an execution stream
   */
  subscribe(executionId: string, ws: ServerWebSocket<unknown>): void {
    if (!this.activeStreams.has(executionId)) {
      this.activeStreams.set(executionId, new Set());
    }

    this.activeStreams.get(executionId)!.add(ws);
    console.log(`[StreamHandler] Client subscribed to execution ${executionId}`);

    // Send subscription confirmation
    this.events.sendToClient(ws, 'log_entry', {
      level: 'info',
      message: `Subscribed to execution ${executionId}`,
      execution_id: executionId,
    });
  }

  /**
   * Unsubscribe from an execution stream
   */
  unsubscribe(executionId: string, ws: ServerWebSocket<unknown>): void {
    const subscribers = this.activeStreams.get(executionId);
    if (subscribers) {
      subscribers.delete(ws);
      console.log(`[StreamHandler] Client unsubscribed from execution ${executionId}`);

      // Clean up empty stream sets
      if (subscribers.size === 0) {
        this.activeStreams.delete(executionId);
      }
    }
  }

  /**
   * Stream log entry to subscribers
   */
  streamLog(
    executionId: string,
    level: string,
    message: string,
    context?: unknown
  ): void {
    const subscribers = this.activeStreams.get(executionId);
    if (!subscribers || subscribers.size === 0) {
      return;
    }

    const logData = {
      execution_id: executionId,
      level,
      message,
      context,
      timestamp: new Date().toISOString(),
    };

    for (const ws of subscribers) {
      try {
        this.events.sendToClient(ws, 'log_entry', logData);
      } catch (error) {
        console.error('[StreamHandler] Error streaming log:', error);
        subscribers.delete(ws);
      }
    }
  }

  /**
   * Stream progress update to subscribers
   */
  streamProgress(executionId: string, progress: number, message?: string): void {
    const subscribers = this.activeStreams.get(executionId);
    if (!subscribers || subscribers.size === 0) {
      return;
    }

    const progressData = {
      execution_id: executionId,
      progress,
      message,
      timestamp: new Date().toISOString(),
    };

    for (const ws of subscribers) {
      try {
        this.events.sendToClient(ws, 'execution_progress', progressData);
      } catch (error) {
        console.error('[StreamHandler] Error streaming progress:', error);
        subscribers.delete(ws);
      }
    }
  }

  /**
   * Complete a stream
   */
  completeStream(executionId: string): void {
    const subscribers = this.activeStreams.get(executionId);
    if (subscribers) {
      for (const ws of subscribers) {
        this.events.sendToClient(ws, 'log_entry', {
          level: 'info',
          message: `Execution ${executionId} stream completed`,
          execution_id: executionId,
        });
      }
      this.activeStreams.delete(executionId);
      console.log(`[StreamHandler] Stream ${executionId} completed`);
    }
  }

  /**
   * Get active stream count
   */
  getActiveStreamCount(): number {
    return this.activeStreams.size;
  }

  /**
   * Get subscriber count for an execution
   */
  getSubscriberCount(executionId: string): number {
    return this.activeStreams.get(executionId)?.size || 0;
  }

  /**
   * Cleanup all streams
   */
  cleanup(): void {
    this.activeStreams.clear();
    console.log('[StreamHandler] All streams cleaned up');
  }
}
