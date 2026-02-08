/**
 * Symbol Controller
 * Business logic for symbol operations
 */

import type { PostgresClient } from '@db/postgres-client';
import type { Symbol, PaginationParams, ApiResponse } from '@types/index';

export class SymbolController {
  constructor(private db: PostgresClient) {}

  /**
   * List all symbols with pagination
   */
  async list(params: PaginationParams & { type?: string }): Promise<ApiResponse<Symbol[]>> {
    try {
      const { page = 1, limit = 20, type } = params;
      const offset = (page - 1) * limit;

      const symbols = await this.db.getSymbols({ limit, offset, type });

      // For total count, we'd need a count query (simplified for now)
      const total = symbols.length;

      return {
        success: true,
        data: symbols as Symbol[],
        metadata: {
          timestamp: new Date().toISOString(),
          pagination: {
            page,
            limit,
            total,
            pages: Math.ceil(total / limit),
          },
        },
      };
    } catch (error) {
      console.error('[SymbolController] Error listing symbols:', error);
      return {
        success: false,
        error: {
          code: 'SYMBOL_LIST_ERROR',
          message: 'Failed to list symbols',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get a symbol by ID
   */
  async get(id: string): Promise<ApiResponse<Symbol>> {
    try {
      const symbol = await this.db.getSymbolById(id);

      if (!symbol) {
        return {
          success: false,
          error: {
            code: 'SYMBOL_NOT_FOUND',
            message: `Symbol with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: symbol as Symbol,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[SymbolController] Error getting symbol:', error);
      return {
        success: false,
        error: {
          code: 'SYMBOL_GET_ERROR',
          message: 'Failed to get symbol',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Search symbols by name or type
   */
  async search(query: string, type?: string): Promise<ApiResponse<Symbol[]>> {
    try {
      // Simplified search - in production, use full-text search
      const symbols = await this.db.getSymbols({ type });
      const filtered = symbols.filter((s: any) =>
        s.name.toLowerCase().includes(query.toLowerCase())
      );

      return {
        success: true,
        data: filtered as Symbol[],
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[SymbolController] Error searching symbols:', error);
      return {
        success: false,
        error: {
          code: 'SYMBOL_SEARCH_ERROR',
          message: 'Failed to search symbols',
          details: { error: String(error) },
        },
      };
    }
  }
}
