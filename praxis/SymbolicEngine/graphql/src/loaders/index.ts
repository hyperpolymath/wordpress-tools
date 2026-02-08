/**
 * DataLoader Configuration
 *
 * Creates DataLoaders for batching and caching database queries
 */

import DataLoader from 'dataloader';
import type {
  SymbolModel,
  WorkflowModel,
  ExecutionModel,
  BaselineModel,
  AuditModel,
  NodeModel,
  TaskModel,
} from '../types.js';

export function createDataLoaders(dataSources: any) {
  return {
    // Symbol loader - batch load symbols by ID
    symbolLoader: new DataLoader<number, SymbolModel | null>(
      async (ids) => {
        const symbols = await Promise.all(
          ids.map((id) => dataSources.ecto.getSymbol(id))
        );
        return symbols;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),

    // Workflow loader - batch load workflows by ID
    workflowLoader: new DataLoader<number, WorkflowModel | null>(
      async (ids) => {
        const workflows = await Promise.all(
          ids.map((id) => dataSources.ecto.getWorkflow(id))
        );
        return workflows;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),

    // Execution loader - batch load executions by ID
    executionLoader: new DataLoader<number, ExecutionModel | null>(
      async (ids) => {
        const executions = await Promise.all(
          ids.map((id) => dataSources.ecto.getExecution(id))
        );
        return executions;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),

    // Baseline loader - batch load baselines by ID
    baselineLoader: new DataLoader<number, BaselineModel | null>(
      async (ids) => {
        const baselines = await Promise.all(
          ids.map((id) => dataSources.ecto.getBaseline(id))
        );
        return baselines;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),

    // Audit loader - batch load audits by ID
    auditLoader: new DataLoader<number, AuditModel | null>(
      async (ids) => {
        const audits = await Promise.all(
          ids.map((id) => dataSources.ecto.getAudit(id))
        );
        return audits;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),

    // Node loader - batch load nodes by ID
    nodeLoader: new DataLoader<string, NodeModel | null>(
      async (ids) => {
        const nodes = await Promise.all(
          ids.map((id) => dataSources.swarm.getNode(id))
        );
        return nodes;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),

    // Task loader - batch load tasks by ID
    taskLoader: new DataLoader<string, TaskModel | null>(
      async (ids) => {
        const tasks = await Promise.all(
          ids.map((id) => dataSources.swarm.getTask(id))
        );
        return tasks;
      },
      {
        cache: true,
        batchScheduleFn: (callback) => setTimeout(callback, 10),
      }
    ),
  };
}
