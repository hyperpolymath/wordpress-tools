/**
 * Symbol API Routes
 * Endpoints for symbol management
 */

import type { Elysia } from 'elysia';
import type { SymbolController } from '../controllers/symbol-controller';

export function setupSymbolRoutes(app: Elysia, controller: SymbolController) {
  return app.group('/symbols', (app) =>
    app
      // List symbols
      .get('/', async ({ query }) => {
        const result = await controller.list({
          page: query.page ? parseInt(query.page as string) : 1,
          limit: query.limit ? parseInt(query.limit as string) : 20,
          type: query.type as string | undefined,
        });
        return result;
      })

      // Get symbol by ID
      .get('/:id', async ({ params }) => {
        const result = await controller.get(params.id);
        return result;
      })

      // Search symbols
      .get('/search', async ({ query }) => {
        const q = query.q as string;
        const type = query.type as string | undefined;

        if (!q) {
          return {
            success: false,
            error: {
              code: 'VALIDATION_ERROR',
              message: 'Query parameter "q" is required',
            },
          };
        }

        const result = await controller.search(q, type);
        return result;
      })
  );
}
