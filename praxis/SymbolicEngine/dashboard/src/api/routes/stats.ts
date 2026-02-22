/**
 * Statistics API Routes — Real-Time Metrics Endpoints.
 *
 * This module defines the RESTful interface for the Praxis dashboard 
 * analytics. It utilizes the `StateAggregator` to provide a unified 
 * view of the swarm's health and symbolic execution performance.
 *
 * ENDPOINTS:
 * 1. `GET /stats`: Returns a snapshot of high-level dashboard metrics 
 *    (Active Workflows, Error Rates, Node Load).
 * 2. `GET /stats/state`: Returns the full, aggregated state from all 
 *    active data sources (Postgres, Swarm State, etc.).
 */

import type { Elysia } from 'elysia';
import type { StateAggregator } from '@db/state-aggregator';

export function setupStatsRoutes(app: Elysia, stateAggregator: StateAggregator) {
  return app.group('/stats', (app) =>
    app
      /**
       * DASHBOARD STATS: Primary data source for the main UI overview. 
       * Includes a UTC timestamp for temporal consistency.
       */
      .get('/', async () => {
        // ... [Implementation using stateAggregator.getDashboardStats]
      })

      /**
       * AGGREGATED STATE: A deep-dive into the raw state data. 
       * Used for debugging and advanced analytics views.
       */
      .get('/state', async () => {
        // ... [Implementation using stateAggregator.getAggregatedState]
      })
  );
}
