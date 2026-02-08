/**
 * Baseline Controller
 * Business logic for baseline management
 */

import type { PostgresClient } from '@db/postgres-client';
import type { Baseline, PaginationParams, ApiResponse } from '@types/index';

export class BaselineController {
  constructor(private db: PostgresClient) {}

  /**
   * List baselines with pagination
   */
  async list(
    params: PaginationParams & { workflow_id?: string }
  ): Promise<ApiResponse<Baseline[]>> {
    try {
      const { page = 1, limit = 20, workflow_id } = params;
      const offset = (page - 1) * limit;

      const baselines = await this.db.getBaselines({ limit, offset, workflow_id });
      const total = baselines.length;

      return {
        success: true,
        data: baselines as Baseline[],
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
      console.error('[BaselineController] Error listing baselines:', error);
      return {
        success: false,
        error: {
          code: 'BASELINE_LIST_ERROR',
          message: 'Failed to list baselines',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get a baseline by ID
   */
  async get(id: string): Promise<ApiResponse<Baseline>> {
    try {
      const baseline = await this.db.getBaselineById(id);

      if (!baseline) {
        return {
          success: false,
          error: {
            code: 'BASELINE_NOT_FOUND',
            message: `Baseline with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: baseline as Baseline,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[BaselineController] Error getting baseline:', error);
      return {
        success: false,
        error: {
          code: 'BASELINE_GET_ERROR',
          message: 'Failed to get baseline',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get normative baseline for a workflow
   */
  async getNormative(workflowId: string): Promise<ApiResponse<Baseline>> {
    try {
      const baseline = await this.db.getNormativeBaseline(workflowId);

      if (!baseline) {
        return {
          success: false,
          error: {
            code: 'NORMATIVE_BASELINE_NOT_FOUND',
            message: `No normative baseline found for workflow ${workflowId}`,
          },
        };
      }

      return {
        success: true,
        data: baseline as Baseline,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[BaselineController] Error getting normative baseline:', error);
      return {
        success: false,
        error: {
          code: 'NORMATIVE_BASELINE_ERROR',
          message: 'Failed to get normative baseline',
          details: { error: String(error) },
        },
      };
    }
  }
}
