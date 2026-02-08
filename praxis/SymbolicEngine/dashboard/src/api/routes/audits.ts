/**
 * Audit API Routes
 * Endpoints for audit reports and deviations
 */

import type { Elysia } from 'elysia';
import type { AuditController } from '../controllers/audit-controller';

export function setupAuditRoutes(app: Elysia, controller: AuditController) {
  return app.group('/audits', (app) =>
    app
      // List audits
      .get('/', async ({ query }) => {
        const result = await controller.list({
          page: query.page ? parseInt(query.page as string) : 1,
          limit: query.limit ? parseInt(query.limit as string) : 20,
          workflow_id: query.workflow_id as string | undefined,
        });
        return result;
      })

      // Get audit by ID
      .get('/:id', async ({ params }) => {
        const result = await controller.get(params.id);
        return result;
      })

      // Get audit statistics
      .get('/stats', async () => {
        const result = await controller.getStats();
        return result;
      })
  );
}
