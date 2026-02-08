/**
 * Workflow Controller
 * Business logic for workflow operations
 */

import type { PostgresClient } from '@db/postgres-client';
import type { Workflow, PaginationParams, ApiResponse } from '@types/index';

export class WorkflowController {
  constructor(private db: PostgresClient) {}

  /**
   * List all workflows with pagination
   */
  async list(params: PaginationParams & { status?: string }): Promise<ApiResponse<Workflow[]>> {
    try {
      const { page = 1, limit = 20, status } = params;
      const offset = (page - 1) * limit;

      const workflows = await this.db.getWorkflows({ limit, offset, status });
      const total = await this.db.countWorkflows(status);

      return {
        success: true,
        data: workflows as Workflow[],
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
      console.error('[WorkflowController] Error listing workflows:', error);
      return {
        success: false,
        error: {
          code: 'WORKFLOW_LIST_ERROR',
          message: 'Failed to list workflows',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get a workflow by ID
   */
  async get(id: string): Promise<ApiResponse<Workflow>> {
    try {
      const workflow = await this.db.getWorkflowById(id);

      if (!workflow) {
        return {
          success: false,
          error: {
            code: 'WORKFLOW_NOT_FOUND',
            message: `Workflow with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: workflow as Workflow,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[WorkflowController] Error getting workflow:', error);
      return {
        success: false,
        error: {
          code: 'WORKFLOW_GET_ERROR',
          message: 'Failed to get workflow',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Create a new workflow
   */
  async create(data: {
    name: string;
    description?: string;
    manifest_path: string;
    status?: string;
  }): Promise<ApiResponse<Workflow>> {
    try {
      // Validate required fields
      if (!data.name || !data.manifest_path) {
        return {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Name and manifest_path are required',
          },
        };
      }

      const workflow = await this.db.createWorkflow(data);

      return {
        success: true,
        data: workflow as Workflow,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[WorkflowController] Error creating workflow:', error);
      return {
        success: false,
        error: {
          code: 'WORKFLOW_CREATE_ERROR',
          message: 'Failed to create workflow',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Update a workflow
   */
  async update(
    id: string,
    updates: {
      name?: string;
      description?: string;
      status?: string;
      manifest_path?: string;
    }
  ): Promise<ApiResponse<Workflow>> {
    try {
      const workflow = await this.db.updateWorkflow(id, updates);

      if (!workflow) {
        return {
          success: false,
          error: {
            code: 'WORKFLOW_NOT_FOUND',
            message: `Workflow with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: workflow as Workflow,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[WorkflowController] Error updating workflow:', error);
      return {
        success: false,
        error: {
          code: 'WORKFLOW_UPDATE_ERROR',
          message: 'Failed to update workflow',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Delete a workflow
   */
  async delete(id: string): Promise<ApiResponse<{ deleted: boolean }>> {
    try {
      const deleted = await this.db.deleteWorkflow(id);

      if (!deleted) {
        return {
          success: false,
          error: {
            code: 'WORKFLOW_NOT_FOUND',
            message: `Workflow with ID ${id} not found`,
          },
        };
      }

      return {
        success: true,
        data: { deleted: true },
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[WorkflowController] Error deleting workflow:', error);
      return {
        success: false,
        error: {
          code: 'WORKFLOW_DELETE_ERROR',
          message: 'Failed to delete workflow',
          details: { error: String(error) },
        },
      };
    }
  }

  /**
   * Get workflow symbols
   */
  async getSymbols(workflowId: string): Promise<ApiResponse> {
    try {
      const symbols = await this.db.getSymbolsByWorkflow(workflowId);

      return {
        success: true,
        data: symbols,
        metadata: {
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      console.error('[WorkflowController] Error getting workflow symbols:', error);
      return {
        success: false,
        error: {
          code: 'WORKFLOW_SYMBOLS_ERROR',
          message: 'Failed to get workflow symbols',
          details: { error: String(error) },
        },
      };
    }
  }
}
