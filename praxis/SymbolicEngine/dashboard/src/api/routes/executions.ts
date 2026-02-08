/**
 * Execution API Routes
 * Endpoints for execution tracking and management
 */

import type { Elysia } from 'elysia';
import type { ExecutionController } from '../controllers/execution-controller';

export function setupExecutionRoutes(app: Elysia, controller: ExecutionController) {
  return app.group('/executions', (app) =>
    app
      // List executions
      .get('/', async ({ query }) => {
        const result = await controller.list({
          page: query.page ? parseInt(query.page as string) : 1,
          limit: query.limit ? parseInt(query.limit as string) : 20,
          workflow_id: query.workflow_id as string | undefined,
          status: query.status as string | undefined,
        });
        return result;
      })

      // Get execution by ID
      .get('/:id', async ({ params }) => {
        const result = await controller.get(params.id);
        return result;
      })

      // Create execution
      .post('/', async ({ body }) => {
        const data = body as {
          workflow_id: string;
          symbol_id?: string;
          metadata?: Record<string, unknown>;
        };
        const result = await controller.create(data);
        return result;
      })

      // Update execution
      .patch('/:id', async ({ params, body }) => {
        const updates = body as {
          status?: string;
          result?: Record<string, unknown>;
          error?: Record<string, unknown>;
        };
        const result = await controller.update(params.id, updates);
        return result;
      })

      // Get execution statistics
      .get('/stats', async ({ query }) => {
        const workflowId = query.workflow_id as string | undefined;
        const result = await controller.getStats(workflowId);
        return result;
      })
  );
}
