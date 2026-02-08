/**
 * WP Praxis Swarm - WebSocket Server
 *
 * Real-time communication server for:
 * - Worker node communication
 * - State synchronization
 * - Real-time monitoring
 * - Dashboard integration
 */

import { WebSocketServer as WSServer, WebSocket } from 'ws';
import { createServer, Server as HTTPServer } from 'http';
import type { WebSocketMessage } from './types';
import { Logger } from './logger';

export class WebSocketServer {
  private wss?: WSServer;
  private httpServer?: HTTPServer;
  private clients: Map<string, WebSocket> = new Map();
  private logger: Logger;
  private messageHandler: (message: WebSocketMessage, senderId: string) => void;

  constructor(
    private port: number,
    messageHandler: (message: WebSocketMessage, senderId: string) => void,
    logger?: Logger
  ) {
    this.logger = logger ?? new Logger('WebSocketServer');
    this.messageHandler = messageHandler;
  }

  // ============================================================================
  // Server Lifecycle
  // ============================================================================

  /**
   * Start WebSocket server
   */
  async start(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        // Create HTTP server
        this.httpServer = createServer();

        // Create WebSocket server
        this.wss = new WSServer({ server: this.httpServer });

        // Set up WebSocket event handlers
        this.wss.on('connection', (ws: WebSocket, req) => {
          this.handleConnection(ws, req);
        });

        this.wss.on('error', (error) => {
          this.logger.error('WebSocket server error:', error);
        });

        // Start HTTP server
        this.httpServer.listen(this.port, () => {
          this.logger.info(`WebSocket server listening on port ${this.port}`);
          resolve();
        });

        this.httpServer.on('error', (error) => {
          this.logger.error('HTTP server error:', error);
          reject(error);
        });
      } catch (error) {
        this.logger.error('Failed to start WebSocket server:', error);
        reject(error);
      }
    });
  }

  /**
   * Stop WebSocket server
   */
  async stop(): Promise<void> {
    return new Promise((resolve) => {
      this.logger.info('Stopping WebSocket server...');

      // Close all client connections
      for (const [clientId, ws] of this.clients.entries()) {
        this.logger.debug(`Closing connection: ${clientId}`);
        ws.close(1000, 'Server shutting down');
      }
      this.clients.clear();

      // Close WebSocket server
      if (this.wss) {
        this.wss.close(() => {
          this.logger.debug('WebSocket server closed');

          // Close HTTP server
          if (this.httpServer) {
            this.httpServer.close(() => {
              this.logger.info('WebSocket server stopped');
              resolve();
            });
          } else {
            resolve();
          }
        });
      } else {
        resolve();
      }
    });
  }

  // ============================================================================
  // Connection Handling
  // ============================================================================

  /**
   * Handle new WebSocket connection
   */
  private handleConnection(ws: WebSocket, req: any): void {
    const clientId = this.generateClientId();
    this.clients.set(clientId, ws);

    this.logger.info(`Client connected: ${clientId} (${req.socket.remoteAddress})`);

    // Set up message handler
    ws.on('message', (data: Buffer) => {
      this.handleMessage(data, clientId);
    });

    // Handle disconnection
    ws.on('close', (code: number, reason: Buffer) => {
      this.handleDisconnection(clientId, code, reason.toString());
    });

    // Handle errors
    ws.on('error', (error: Error) => {
      this.logger.error(`Client error (${clientId}):`, error);
    });

    // Handle pong (keep-alive)
    ws.on('pong', () => {
      this.logger.verbose(`Pong received from ${clientId}`);
    });

    // Send welcome message
    this.sendToClient(clientId, {
      type: 'node_update',
      senderId: 'server',
      timestamp: Date.now(),
      payload: {
        message: 'Connected to WP Praxis Swarm',
        clientId,
      },
    });

    // Start ping interval
    this.startPingInterval(clientId);
  }

  /**
   * Handle client disconnection
   */
  private handleDisconnection(clientId: string, code: number, reason: string): void {
    this.clients.delete(clientId);
    this.logger.info(`Client disconnected: ${clientId} (code: ${code}, reason: ${reason})`);
  }

  /**
   * Handle incoming message
   */
  private handleMessage(data: Buffer, clientId: string): void {
    try {
      const message = JSON.parse(data.toString()) as WebSocketMessage;

      this.logger.debug(`Message from ${clientId}: ${message.type}`);

      // Set sender ID if not provided
      if (!message.senderId || message.senderId === 'unknown') {
        message.senderId = clientId;
      }

      // Pass message to handler
      this.messageHandler(message, clientId);
    } catch (error) {
      this.logger.error(`Failed to parse message from ${clientId}:`, error);

      // Send error response
      this.sendToClient(clientId, {
        type: 'node_update',
        senderId: 'server',
        timestamp: Date.now(),
        payload: {
          error: 'Invalid message format',
        },
      });
    }
  }

  /**
   * Generate unique client ID
   */
  private generateClientId(): string {
    return `client-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
  }

  // ============================================================================
  // Message Sending
  // ============================================================================

  /**
   * Send message to specific client
   */
  sendToClient(clientId: string, message: WebSocketMessage): void {
    const ws = this.clients.get(clientId);
    if (!ws || ws.readyState !== WebSocket.OPEN) {
      this.logger.warn(`Cannot send to client ${clientId} - not connected`);
      return;
    }

    try {
      ws.send(JSON.stringify(message));
      this.logger.verbose(`Message sent to ${clientId}: ${message.type}`);
    } catch (error) {
      this.logger.error(`Failed to send message to ${clientId}:`, error);
    }
  }

  /**
   * Broadcast message to all connected clients
   */
  broadcast(message: WebSocketMessage): void {
    const clientCount = this.clients.size;
    let sentCount = 0;

    for (const [clientId, ws] of this.clients.entries()) {
      if (ws.readyState === WebSocket.OPEN) {
        try {
          ws.send(JSON.stringify(message));
          sentCount++;
        } catch (error) {
          this.logger.error(`Failed to broadcast to ${clientId}:`, error);
        }
      }
    }

    this.logger.debug(`Broadcast: ${message.type} (${sentCount}/${clientCount} clients)`);
  }

  /**
   * Broadcast to clients matching filter
   */
  broadcastFiltered(
    message: WebSocketMessage,
    filter: (clientId: string) => boolean
  ): void {
    let sentCount = 0;

    for (const [clientId, ws] of this.clients.entries()) {
      if (filter(clientId) && ws.readyState === WebSocket.OPEN) {
        try {
          ws.send(JSON.stringify(message));
          sentCount++;
        } catch (error) {
          this.logger.error(`Failed to send to ${clientId}:`, error);
        }
      }
    }

    this.logger.debug(`Filtered broadcast: ${message.type} (${sentCount} clients)`);
  }

  // ============================================================================
  // Keep-Alive
  // ============================================================================

  /**
   * Start ping interval for client
   */
  private startPingInterval(clientId: string): void {
    const interval = setInterval(() => {
      const ws = this.clients.get(clientId);
      if (!ws || ws.readyState !== WebSocket.OPEN) {
        clearInterval(interval);
        return;
      }

      try {
        ws.ping();
        this.logger.verbose(`Ping sent to ${clientId}`);
      } catch (error) {
        this.logger.error(`Failed to ping ${clientId}:`, error);
        clearInterval(interval);
      }
    }, 30000); // Ping every 30 seconds
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  /**
   * Get server statistics
   */
  getStats(): {
    port: number;
    connectedClients: number;
    clients: Array<{ id: string; state: string }>;
  } {
    const clients = Array.from(this.clients.entries()).map(([id, ws]) => ({
      id,
      state: this.getReadyStateString(ws.readyState),
    }));

    return {
      port: this.port,
      connectedClients: this.clients.size,
      clients,
    };
  }

  /**
   * Get WebSocket ready state as string
   */
  private getReadyStateString(state: number): string {
    switch (state) {
      case WebSocket.CONNECTING:
        return 'CONNECTING';
      case WebSocket.OPEN:
        return 'OPEN';
      case WebSocket.CLOSING:
        return 'CLOSING';
      case WebSocket.CLOSED:
        return 'CLOSED';
      default:
        return 'UNKNOWN';
    }
  }

  /**
   * Get connected client IDs
   */
  getClientIds(): string[] {
    return Array.from(this.clients.keys());
  }

  /**
   * Check if client is connected
   */
  isClientConnected(clientId: string): boolean {
    const ws = this.clients.get(clientId);
    return ws !== undefined && ws.readyState === WebSocket.OPEN;
  }

  /**
   * Disconnect client
   */
  disconnectClient(clientId: string, reason?: string): void {
    const ws = this.clients.get(clientId);
    if (ws) {
      ws.close(1000, reason ?? 'Disconnected by server');
      this.clients.delete(clientId);
      this.logger.info(`Client disconnected by server: ${clientId}`);
    }
  }
}

/**
 * Create a WebSocket server instance
 */
export function createWebSocketServer(
  port: number,
  messageHandler: (message: WebSocketMessage, senderId: string) => void,
  logger?: Logger
): WebSocketServer {
  return new WebSocketServer(port, messageHandler, logger);
}
