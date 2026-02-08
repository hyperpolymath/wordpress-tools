/**
 * WP Praxis Dashboard API Server
 * Main entry point for the symbolic engine dashboard backend
 */

import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { staticPlugin } from '@elysiajs/static';
import { html } from '@elysiajs/html';

import { loadConfig, validateConfig } from './config-loader';
import { PostgresClient } from './db/postgres-client';
import { StateAggregator } from './db/state-aggregator';
import { DashboardEvents } from './websocket/dashboard-events';
import { StreamHandler } from './websocket/stream-handler';

// Controllers
import { WorkflowController } from './api/controllers/workflow-controller';
import { SymbolController } from './api/controllers/symbol-controller';
import { ExecutionController } from './api/controllers/execution-controller';
import { AuditController } from './api/controllers/audit-controller';
import { BaselineController } from './api/controllers/baseline-controller';

// Routes
import {
  setupWorkflowRoutes,
  setupSymbolRoutes,
  setupExecutionRoutes,
  setupAuditRoutes,
  setupBaselineRoutes,
  setupStatsRoutes,
  setupHealthRoutes,
} from './api/routes';

/**
 * Main application class
 */
class DashboardServer {
  private app!: Elysia;
  private config!: any;
  private db!: PostgresClient;
  private stateAggregator!: StateAggregator;
  private dashboardEvents!: DashboardEvents;
  private streamHandler!: StreamHandler;

  async initialize() {
    console.log('[Dashboard] Initializing WP Praxis Dashboard Server...');

    // Load configuration
    this.config = await loadConfig();
    if (!validateConfig(this.config)) {
      throw new Error('Invalid configuration');
    }

    console.log(`[Dashboard] Environment: ${this.config.server.env}`);
    console.log(`[Dashboard] Server: ${this.config.server.host}:${this.config.server.port}`);

    // Initialize database client
    this.db = new PostgresClient(this.config.database);
    await this.db.connect();

    // Initialize state aggregator
    this.stateAggregator = new StateAggregator(this.db, this.config.state);

    // Initialize WebSocket handlers
    this.dashboardEvents = new DashboardEvents(this.config.server.websocket.heartbeat_interval);
    this.streamHandler = new StreamHandler(this.dashboardEvents);

    // Initialize Elysia app
    this.app = new Elysia();

    // Setup middleware
    this.setupMiddleware();

    // Setup routes
    this.setupRoutes();

    // Setup WebSocket
    if (this.config.server.websocket.enabled) {
      this.setupWebSocket();
    }

    // Setup static file serving
    this.setupStatic();

    console.log('[Dashboard] Initialization complete');
  }

  /**
   * Setup middleware
   */
  private setupMiddleware() {
    // CORS
    if (this.config.server.cors.enabled) {
      this.app.use(
        cors({
          origin: this.config.server.cors.origins,
          methods: this.config.server.cors.methods,
          credentials: this.config.server.cors.credentials,
        })
      );
    }

    // HTML support
    this.app.use(html());

    // Request logging
    if (this.config.logging.log_requests) {
      this.app.onRequest(({ request }) => {
        console.log(`[Request] ${request.method} ${request.url}`);
      });
    }

    // Error handling
    this.app.onError(({ code, error, set }) => {
      console.error('[Error]', code, error);

      set.status = code === 'NOT_FOUND' ? 404 : 500;

      return {
        success: false,
        error: {
          code: code,
          message: error.message || 'Internal server error',
        },
      };
    });
  }

  /**
   * Setup API routes
   */
  private setupRoutes() {
    const apiPrefix = this.config.api.prefix;

    // Initialize controllers
    const workflowController = new WorkflowController(this.db);
    const symbolController = new SymbolController(this.db);
    const executionController = new ExecutionController(this.db);
    const auditController = new AuditController(this.db);
    const baselineController = new BaselineController(this.db);

    // Setup routes under API prefix
    this.app.group(apiPrefix, (app) =>
      app
        .use((app) => setupWorkflowRoutes(app, workflowController))
        .use((app) => setupSymbolRoutes(app, symbolController))
        .use((app) => setupExecutionRoutes(app, executionController))
        .use((app) => setupAuditRoutes(app, auditController))
        .use((app) => setupBaselineRoutes(app, baselineController))
        .use((app) => setupStatsRoutes(app, this.stateAggregator))
        .use((app) => setupHealthRoutes(app, this.db))
    );

    console.log(`[Dashboard] API routes configured at ${apiPrefix}`);
  }

  /**
   * Setup WebSocket endpoint
   */
  private setupWebSocket() {
    this.app.ws('/ws', {
      open: (ws) => {
        this.dashboardEvents.addConnection(ws);
        this.stateAggregator.setActiveConnections(this.dashboardEvents.getConnectionCount());
      },

      message: (ws, message) => {
        try {
          const data = typeof message === 'string' ? JSON.parse(message) : message;

          // Handle different message types
          if (data.type === 'subscribe' && data.execution_id) {
            this.streamHandler.subscribe(data.execution_id, ws);
          } else if (data.type === 'unsubscribe' && data.execution_id) {
            this.streamHandler.unsubscribe(data.execution_id, ws);
          } else if (data.type === 'ping') {
            this.dashboardEvents.sendToClient(ws, 'heartbeat', { pong: true });
          }
        } catch (error) {
          console.error('[WebSocket] Error handling message:', error);
          this.dashboardEvents.sendToClient(ws, 'error', {
            code: 'MESSAGE_ERROR',
            message: 'Failed to process message',
          });
        }
      },

      close: (ws) => {
        this.dashboardEvents.removeConnection(ws);
        this.stateAggregator.setActiveConnections(this.dashboardEvents.getConnectionCount());
      },

      error: (ws, error) => {
        console.error('[WebSocket] Error:', error);
      },
    });

    console.log('[Dashboard] WebSocket configured at /ws');
  }

  /**
   * Setup static file serving
   */
  private setupStatic() {
    // Serve static files from current directory
    this.app.use(
      staticPlugin({
        assets: './',
        prefix: '/',
      })
    );

    // Root route serves dashboard
    this.app.get('/', () => {
      return Bun.file('./index.html');
    });

    // Injector dashboard
    this.app.get('/injector', () => {
      return Bun.file('./injector/index.html');
    });
  }

  /**
   * Start the server
   */
  async start() {
    const { host, port } = this.config.server;

    this.app.listen(port, () => {
      console.log('');
      console.log('═══════════════════════════════════════════════════');
      console.log('  WP Praxis Symbolic Engine Dashboard');
      console.log('═══════════════════════════════════════════════════');
      console.log('');
      console.log(`  🌐 Dashboard:   https://${host}:${port}`);
      console.log(`  🔧 Injector:    https://${host}:${port}/injector`);
      console.log(`  📡 API:         https://${host}:${port}${this.config.api.prefix}`);
      console.log(`  💬 WebSocket:   ws://${host}:${port}/ws`);
      console.log('');
      console.log(`  📊 Database:    ${this.db.isConnected() ? '✅ Connected' : '❌ Disconnected'}`);
      console.log(`  🔌 Connections: ${this.dashboardEvents.getConnectionCount()}`);
      console.log('');
      console.log('═══════════════════════════════════════════════════');
      console.log('');
    });

    // Setup periodic stats broadcasting
    if (this.config.features.real_time_updates) {
      setInterval(async () => {
        if (this.dashboardEvents.getConnectionCount() > 0) {
          const stats = await this.stateAggregator.getDashboardStats();
          this.dashboardEvents.broadcastStatsUpdate(stats);
        }
      }, this.config.ui.refresh_interval);
    }
  }

  /**
   * Graceful shutdown
   */
  async shutdown() {
    console.log('[Dashboard] Shutting down...');

    this.dashboardEvents.cleanup();
    this.streamHandler.cleanup();
    this.stateAggregator.clearCache();
    await this.db.disconnect();

    console.log('[Dashboard] Shutdown complete');
    process.exit(0);
  }
}

// ============================================================================
// Application Entry Point
// ============================================================================

const server = new DashboardServer();

// Initialize and start server
server
  .initialize()
  .then(() => server.start())
  .catch((error) => {
    console.error('[Dashboard] Fatal error:', error);
    process.exit(1);
  });

// Graceful shutdown on signals
process.on('SIGINT', () => server.shutdown());
process.on('SIGTERM', () => server.shutdown());

// Export for testing
export { DashboardServer };
