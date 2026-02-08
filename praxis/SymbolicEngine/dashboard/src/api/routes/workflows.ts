/**
 * Workflow API Routes
 * Endpoints for workflow management
 */

import type { Elysia } from 'elysia';
import type { WorkflowController } from '../controllers/workflow-controller';

export function setupWorkflowRoutes(app: Elysia, controller: WorkflowController) {
  return app.group('/workflows', (app) =>
    app
      // List workflows
      .get('/', async ({ query }) => {
        const result = await controller.list({
          page: query.page ? parseInt(query.page as string) : 1,
          limit: query.limit ? parseInt(query.limit as string) : 20,
          status: query.status as string | undefined,
        });
        return result;
      })

      // Get workflow by ID
      .get('/:id', async ({ params }) => {
        const result = await controller.get(params.id);
        return result;
      })

      // Create workflow
      .post('/', async ({ body }) => {
        const data = body as {
          name: string;
          description?: string;
          manifest_path: string;
          status?: string;
        };
        const result = await controller.create(data);
        return result;
      })

      // Update workflow
      .patch('/:id', async ({ params, body }) => {
        const updates = body as {
          name?: string;
          description?: string;
          status?: string;
          manifest_path?: string;
        };
        const result = await controller.update(params.id, updates);
        return result;
      })

      // Delete workflow
      .delete('/:id', async ({ params }) => {
        const result = await controller.delete(params.id);
        return result;
      })

      // Get workflow symbols
      .get('/:id/symbols', async ({ params }) => {
        const result = await controller.getSymbols(params.id);
        return result;
      })
  );
}
