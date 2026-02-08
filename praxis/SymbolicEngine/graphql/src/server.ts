/**
 * WP Praxis GraphQL API Server
 *
 * Apollo Server implementation with subscriptions, authentication, and DataLoader
 */

import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { makeExecutableSchema } from '@graphql-tools/schema';
import { WebSocketServer } from 'ws';
import { useServer } from 'graphql-ws/lib/use/ws';
import { PubSub } from 'graphql-subscriptions';
import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

import { createContext } from './context.js';
import { resolvers } from './resolvers/index.js';
import { createLogger } from './utils/logger.js';
import { formatError } from './utils/error-formatter.js';
import { createDataSources } from './datasources/index.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ============================================================================
// Configuration
// ============================================================================

const PORT = parseInt(process.env.GRAPHQL_PORT || '4000', 10);
const HOST = process.env.GRAPHQL_HOST || 'localhost';
const NODE_ENV = process.env.NODE_ENV || 'development';

const config = {
  port: PORT,
  host: HOST,
  corsOrigins: process.env.CORS_ORIGINS?.split(',') || ['http://localhost:3000'],
  enablePlayground: process.env.ENABLE_PLAYGROUND !== 'false',
  enableIntrospection: process.env.ENABLE_INTROSPECTION !== 'false',
  logLevel: (process.env.LOG_LEVEL as any) || 'info',
};

// ============================================================================
// Schema Loading
// ============================================================================

const typeDefs = readFileSync(join(__dirname, '../schema.graphql'), 'utf-8');

const schema = makeExecutableSchema({
  typeDefs,
  resolvers,
});

// ============================================================================
// Server Setup
// ============================================================================

async function startServer() {
  const logger = createLogger(config.logLevel);
  const pubsub = new PubSub();

  // Create Express app
  const app = express();
  const httpServer = createServer(app);

  // Create WebSocket server for subscriptions
  const wsServer = new WebSocketServer({
    server: httpServer,
    path: '/graphql',
  });

  // Create data sources (shared across requests)
  const dataSources = await createDataSources(logger);

  // Setup WebSocket subscription server
  const serverCleanup = useServer(
    {
      schema,
      context: async (ctx) => {
        // WebSocket context (for subscriptions)
        return createContext({
          req: ctx.extra.request,
          dataSources,
          pubsub,
          logger,
        });
      },
    },
    wsServer
  );

  // Create Apollo Server
  const server = new ApolloServer({
    schema,
    plugins: [
      // Proper shutdown for HTTP server
      ApolloServerPluginDrainHttpServer({ httpServer }),

      // Proper shutdown for WebSocket server
      {
        async serverWillStart() {
          return {
            async drainServer() {
              await serverCleanup.dispose();
            },
          };
        },
      },

      // Custom logging plugin
      {
        async requestDidStart() {
          return {
            async didEncounterErrors(requestContext) {
              logger.error('GraphQL Errors:', {
                errors: requestContext.errors,
                operation: requestContext.operationName,
              });
            },
          };
        },
      },
    ],
    formatError,
    introspection: config.enableIntrospection,
  });

  await server.start();

  // Apply middleware
  app.use(
    '/graphql',
    cors({
      origin: config.corsOrigins,
      credentials: true,
    }),
    express.json(),
    expressMiddleware(server, {
      context: async ({ req }) => {
        return createContext({
          req,
          dataSources,
          pubsub,
          logger,
        });
      },
    })
  );

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  });

  // Metrics endpoint (basic)
  app.get('/metrics', async (req, res) => {
    try {
      const stats = {
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        connections: {
          http: (httpServer as any).connections || 0,
          ws: wsServer.clients.size,
        },
      };
      res.json(stats);
    } catch (error) {
      logger.error('Metrics endpoint error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Start HTTP server
  await new Promise<void>((resolve) => {
    httpServer.listen({ port: config.port, host: config.host }, resolve);
  });

  logger.info(`🚀 GraphQL API Server ready at http://${config.host}:${config.port}/graphql`);
  logger.info(`🔌 WebSocket subscriptions ready at ws://${config.host}:${config.port}/graphql`);

  if (config.enablePlayground) {
    logger.info(`🎮 GraphQL Playground available at http://${config.host}:${config.port}/graphql`);
  }

  // Graceful shutdown
  const shutdown = async () => {
    logger.info('Shutting down GraphQL server...');
    await server.stop();
    httpServer.close();
    await dataSources.ecto.close?.();
    logger.info('Server shutdown complete');
    process.exit(0);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

// ============================================================================
// Start Server
// ============================================================================

startServer().catch((error) => {
  console.error('Failed to start server:', error);
  process.exit(1);
});
