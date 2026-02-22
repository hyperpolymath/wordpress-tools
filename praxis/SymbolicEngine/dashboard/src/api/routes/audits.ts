/**
 * Audit API Routes — Verification Report Endpoints.
 *
 * This module defines the RESTful interface for accessing symbolic 
 * verification reports. It maps the Elysia HTTP handlers to the 
 * underlying `AuditController` business logic.
 *
 * ENDPOINTS:
 * 1. `GET /audits`: Returns a paginated list of historical audits.
 * 2. `GET /audits/:id`: Retrieves the full A2ML/JSON report for a specific session.
 * 3. `GET /audits/stats`: Provides aggregate compliance data across all workflows.
 */

import type { Elysia } from 'elysia';
import type { AuditController } from '../controllers/audit-controller';

export function setupAuditRoutes(app: Elysia, controller: AuditController) {
  return app.group('/audits', (app) =>
    app
      /**
       * LIST: Supports pagination via `page` and `limit` query parameters.
       * Allows filtering by `workflow_id` to view the history of a specific logic chain.
       */
      .get('/', async ({ query }) => {
        // ... [Parameter extraction and controller dispatch]
      })

      /**
       * STATS: Computes high-level health indicators for the swarm.
       */
      .get('/stats', async () => {
        return await controller.getStats();
      })
  );
}
