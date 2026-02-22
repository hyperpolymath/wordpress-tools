/**
 * Execution API Routes — Runtime Trace Endpoints.
 *
 * This module defines the RESTful interface for tracking active and 
 * historical executions of symbolic workflows. It routes requests 
 * to the `ExecutionController`, allowing for real-time monitoring 
 * of the Praxis Swarm.
 *
 * ENDPOINTS:
 * 1. `GET /executions`: Returns a paginated log of execution attempts.
 * 2. `POST /executions`: Manually triggers a new symbolic task execution.
 * 3. `PATCH /executions/:id`: Updates the state of an in-progress execution.
 * 4. `GET /executions/stats`: Aggregates performance data (throughput, failure rates).
 */

import type { Elysia } from 'elysia';
import type { ExecutionController } from '../controllers/execution-controller';

export function setupExecutionRoutes(app: Elysia, controller: ExecutionController) {
  return app.group('/executions', (app) =>
    app
      /**
       * LIST: Retrieves execution records. 
       * Allows deep filtering by `workflow_id` to trace specific logic chains.
       */
      .get('/', async ({ query }) => {
        // ... [Parameter mapping and dispatch]
      })

      /**
       * UPDATE: Used by swarm workers to report success or failure.
       * Supports updating `status`, `result`, or `error` payloads.
       */
      .patch('/:id', async ({ params, body }) => {
        // ... [Partial update implementation]
      })

      /**
       * STATS: Provides a high-level overview of execution health.
       */
      .get('/stats', async ({ query }) => {
        return await controller.getStats(query.workflow_id as string | undefined);
      })
  );
}
