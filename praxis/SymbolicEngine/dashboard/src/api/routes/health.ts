/**
 * Health Check API Routes
 * Endpoints for service health monitoring
 */

import type { Elysia } from 'elysia';
import type { PostgresClient } from '@db/postgres-client';

export function setupHealthRoutes(app: Elysia, db: PostgresClient) {
  return app.group('/health', (app) =>
    app
      // Basic health check
      .get('/', async () => {
        const dbHealth = await db.healthCheck();

        return {
          success: true,
          data: {
            status: dbHealth.healthy ? 'healthy' : 'unhealthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: {
              used_mb: Math.round((process.memoryUsage().heapUsed / 1024 / 1024) * 100) / 100,
              total_mb: Math.round((process.memoryUsage().heapTotal / 1024 / 1024) * 100) / 100,
            },
            database: dbHealth,
          },
        };
      })

      // Detailed health check
      .get('/detailed', async () => {
        const dbHealth = await db.healthCheck();

        return {
          success: true,
          data: {
            status: dbHealth.healthy ? 'healthy' : 'unhealthy',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            process: {
              pid: process.pid,
              platform: process.platform,
              arch: process.arch,
              node_version: process.version,
            },
            database: dbHealth,
          },
        };
      })
  );
}
