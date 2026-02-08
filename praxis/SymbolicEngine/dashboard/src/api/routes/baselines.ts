/**
 * Baseline API Routes
 * Endpoints for baseline management
 */

import type { Elysia } from 'elysia';
import type { BaselineController } from '../controllers/baseline-controller';

export function setupBaselineRoutes(app: Elysia, controller: BaselineController) {
  return app.group('/baselines', (app) =>
    app
      // List baselines
      .get('/', async ({ query }) => {
        const result = await controller.list({
          page: query.page ? parseInt(query.page as string) : 1,
          limit: query.limit ? parseInt(query.limit as string) : 20,
          workflow_id: query.workflow_id as string | undefined,
        });
        return result;
      })

      // Get baseline by ID
      .get('/:id', async ({ params }) => {
        const result = await controller.get(params.id);
        return result;
      })

      // Get normative baseline for workflow
      .get('/normative/:workflow_id', async ({ params }) => {
        const result = await controller.getNormative(params.workflow_id);
        return result;
      })
  );
}
