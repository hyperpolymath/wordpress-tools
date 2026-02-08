/**
 * Statistics API Routes
 * Endpoints for real-time dashboard statistics
 */

import type { Elysia } from 'elysia';
import type { StateAggregator } from '@db/state-aggregator';

export function setupStatsRoutes(app: Elysia, stateAggregator: StateAggregator) {
  return app.group('/stats', (app) =>
    app
      // Get dashboard statistics
      .get('/', async () => {
        try {
          const stats = await stateAggregator.getDashboardStats();
          return {
            success: true,
            data: stats,
            metadata: {
              timestamp: new Date().toISOString(),
            },
          };
        } catch (error) {
          return {
            success: false,
            error: {
              code: 'STATS_ERROR',
              message: 'Failed to get dashboard statistics',
              details: { error: String(error) },
            },
          };
        }
      })

      // Get aggregated state from all sources
      .get('/state', async () => {
        try {
          const state = await stateAggregator.getAggregatedState();
          return {
            success: true,
            data: state,
            metadata: {
              timestamp: new Date().toISOString(),
            },
          };
        } catch (error) {
          return {
            success: false,
            error: {
              code: 'STATE_ERROR',
              message: 'Failed to get aggregated state',
              details: { error: String(error) },
            },
          };
        }
      })
  );
}
