/**
 * Audit Controller
 * Business logic for audit operations
 */

import type { PostgresClient } from '@db/postgres-client';
import type { Audit, PaginationParams, ApiResponse } from '@types/index';

export class AuditController {
  constructor(private db: PostgresClient) {}

  /**
   * List audits with pagination
   */
  async list(
    params: PaginationParams & { workflow_id?: string }
  ): Promise<ApiResponse<Audit[]>> {
    try {
      const { page = 1, limit = 20, workflow_id } = params;
      const offset = (page - 1) * limit;

      const audits = await this.db.getAudits({ limit, offset, workflow_id });
      const total = audits.length;

      return {
        success: true,
        data: audits as Audit[],
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
      console.error('[AuditController] Error listing audits:', error);
      return {
        success: false,
        error: {
          code: 'AUDIT_LIST_ERROR',
          message: 'Failed to list audits',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get an audit by ID
   */
  async get(id: string): Promise<ApiResponse<Audit>> {
    try {
      const audit = await this.db.getAuditById(id);

      if (!audit) {
        return {
          success: false,
          error: {
            code: 'AUDIT_NOT_FOUND',
            message: `Audit with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: audit as Audit,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[AuditController] Error getting audit:', error);
      return {
        success: false,
        error: {
          code: 'AUDIT_GET_ERROR',
          message: 'Failed to get audit',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get audit statistics
   */
  async getStats(): Promise<ApiResponse> {
    try {
      const stats = await this.db.getAuditStats();

      return {
        success: true,
        data: stats,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[AuditController] Error getting audit stats:', error);
      return {
        success: false,
        error: {
          code: 'AUDIT_STATS_ERROR',
          message: 'Failed to get audit statistics',
          details: { error: String(error) },
        },
      };
    }
  }
}
