/**
 * Execution Controller
 * Business logic for execution tracking and management
 */

import type { PostgresClient } from '@db/postgres-client';
import type { Execution, PaginationParams, ApiResponse } from '@types/index';

export class ExecutionController {
  constructor(private db: PostgresClient) {}

  /**
   * List executions with pagination and filtering
   */
  async list(
    params: PaginationParams & { workflow_id?: string; status?: string }
  ): Promise<ApiResponse<Execution[]>> {
    try {
      const { page = 1, limit = 20, workflow_id, status } = params;
      const offset = (page - 1) * limit;

      const executions = await this.db.getExecutions({ limit, offset, workflow_id, status });

      // Simplified total count
      const total = executions.length;

      return {
        success: true,
        data: executions as Execution[],
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
      console.error('[ExecutionController] Error listing executions:', error);
      return {
        success: false,
        error: {
          code: 'EXECUTION_LIST_ERROR',
          message: 'Failed to list executions',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get an execution by ID
   */
  async get(id: string): Promise<ApiResponse<Execution>> {
    try {
      const execution = await this.db.getExecutionById(id);

      if (!execution) {
        return {
          success: false,
          error: {
            code: 'EXECUTION_NOT_FOUND',
            message: `Execution with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: execution as Execution,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[ExecutionController] Error getting execution:', error);
      return {
        success: false,
        error: {
          code: 'EXECUTION_GET_ERROR',
          message: 'Failed to get execution',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Create a new execution
   */
  async create(data: {
    workflow_id: string;
    symbol_id?: string;
    metadata?: Record<string, unknown>;
  }): Promise<ApiResponse<Execution>> {
    try {
      if (!data.workflow_id) {
        return {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'workflow_id is required',
          },
        };
      }

      const execution = await this.db.createExecution({
        workflow_id: data.workflow_id,
        symbol_id: data.symbol_id,
        status: 'pending',
        metadata: data.metadata,
      });

      return {
        success: true,
        data: execution as Execution,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[ExecutionController] Error creating execution:', error);
      return {
        success: false,
        error: {
          code: 'EXECUTION_CREATE_ERROR',
          message: 'Failed to create execution',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Update execution status and results
   */
  async update(
    id: string,
    updates: {
      status?: string;
      result?: Record<string, unknown>;
      error?: Record<string, unknown>;
    }
  ): Promise<ApiResponse<Execution>> {
    try {
      const completed_at = updates.status === 'completed' || updates.status === 'failed'
        ? new Date()
        : undefined;

      const execution = await this.db.updateExecution(id, {
        ...updates,
        completed_at,
      });

      if (!execution) {
        return {
          success: false,
          error: {
            code: 'EXECUTION_NOT_FOUND',
            message: `Execution with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: execution as Execution,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[ExecutionController] Error updating execution:', error);
      return {
        success: false,
        error: {
          code: 'EXECUTION_UPDATE_ERROR',
          message: 'Failed to update execution',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get execution statistics
   */
  async getStats(workflowId?: string): Promise<ApiResponse> {
    try {
      const stats = await this.db.getExecutionStats(workflowId);

      return {
        success: true,
        data: stats,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[ExecutionController] Error getting execution stats:', error);
      return {
        success: false,
        error: {
          code: 'EXECUTION_STATS_ERROR',
          message: 'Failed to get execution statistics',
          details: { error: String(error) },
        },
      };
    }
  }
}
