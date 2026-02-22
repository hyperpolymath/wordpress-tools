/**
 * Baseline API Routes — Normative State Endpoints.
 *
 * This module defines the RESTful interface for managing baselines within 
 * the Praxis ecosystem. Baselines represent formally verified snapshots of 
 * symbolic logic used for future verification.
 *
 * ENDPOINTS:
 * 1. `GET /baselines`: Returns a paginated list of historical baselines.
 * 2. `GET /baselines/:id`: Retrieves detailed metadata for a specific snapshot.
 * 3. `GET /baselines/normative/:workflow_id`: Fetches the active policy 
 *    baseline for a specific symbolic execution chain.
 */

import type { Elysia } from 'elysia';
import type { BaselineController } from '../controllers/baseline-controller';

export function setupBaselineRoutes(app: Elysia, controller: BaselineController) {
  return app.group('/baselines', (app) =>
    app
      /**
       * LIST: Retrieves historical snapshots. 
       * Optionally filtered by `workflow_id`.
       */
      .get('/', async ({ query }) => {
        // ... [Parameter mapping and dispatch]
      })

      /**
       * NORMATIVE: Special accessor for the "Current Gold Standard" baseline.
       */
      .get('/normative/:workflow_id', async ({ params }) => {
        return await controller.getNormative(params.workflow_id);
      })
  );
}
