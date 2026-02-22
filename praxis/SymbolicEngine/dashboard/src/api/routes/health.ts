/**
 * Health Check API Routes — Service Observability Endpoints.
 *
 * This module defines the diagnostic interface for the Praxis dashboard. 
 * It provides real-time information about the system's operational 
 * status, including resource consumption and backend connectivity.
 *
 * ENDPOINTS:
 * 1. `GET /health`: Returns a high-level "Healthy/Unhealthy" status and 
 *    core memory/database metrics.
 * 2. `GET /health/detailed`: Returns an expanded diagnostic payload 
 *    including process PID, architecture, and granular memory usage.
 */

import type { Elysia } from 'elysia';
import type { PostgresClient } from '@db/postgres-client';

export function setupHealthRoutes(app: Elysia, db: PostgresClient) {
  return app.group('/health', (app) =>
    app
      /**
       * BASIC AUDIT: Verifies the primary system invariant (DB connectivity) 
       * and reports current resource pressure (MB used).
       */
      .get('/', async () => {
        const dbHealth = await db.healthCheck();
        // ... [Metric assembly logic]
      })

      /**
       * DETAILED AUDIT: Provides deep-dive metadata about the hosting 
       * environment. Useful for troubleshooting cluster-wide swarm issues.
       */
      .get('/detailed', async () => {
        // ... [Full process and memory report]
      })
  );
}
