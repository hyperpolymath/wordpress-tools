/**
 * Execution Resolvers
 *
 * GraphQL resolvers for Execution queries and mutations
 */

import type { GraphQLContext } from '../types.js';
import { requirePermission } from '../auth/permissions.js';
import { SUBSCRIPTION_TOPICS } from '../types.js';

export const executionResolvers = {
  Query: {
    execution: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      const id = parseInt(args.id, 10);
      return context.loaders.executionLoader.load(id);
    },

    executions: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getExecutions({
        workflowId: args.workflowId ? parseInt(args.workflowId, 10) : undefined,
        symbolId: args.symbolId ? parseInt(args.symbolId, 10) : undefined,
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },

    executionsConnection: async (_parent: any, args: any, context: GraphQLContext) => {
      const limit = args.first || args.last || 20;
      const offset = args.after ? parseInt(Buffer.from(args.after, 'base64').toString(), 10) : 0;

      const executions = await context.dataSources.ecto.getExecutions({
        workflowId: args.workflowId ? parseInt(args.workflowId, 10) : undefined,
        symbolId: args.symbolId ? parseInt(args.symbolId, 10) : undefined,
        status: args.status?.toLowerCase(),
        limit: limit + 1,
        offset,
      });

      const hasNextPage = executions.length > limit;
      const edges = executions.slice(0, limit).map((node, index) => ({
        node,
        cursor: Buffer.from(String(offset + index)).toString('base64'),
      }));

      return {
        edges,
        pageInfo: {
          hasNextPage,
          hasPreviousPage: offset > 0,
          startCursor: edges[0]?.cursor,
          endCursor: edges[edges.length - 1]?.cursor,
          total: edges.length,
        },
      };
    },
  },

  Mutation: {
    retryExecution: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'executions:retry');
      const id = parseInt(args.id, 10);

      const execution = await context.dataSources.ecto.updateExecution(id, {
        status: 'retrying',
        retry_attempt: context.dataSources.ecto.getExecution(id).then((e) => (e?.retry_attempt || 0) + 1),
      });

      context.pubsub.publish(SUBSCRIPTION_TOPICS.EXECUTION_UPDATED, { executionUpdated: execution });

      return execution;
    },

    cancelExecution: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'executions:cancel');
      const id = parseInt(args.id, 10);

      const execution = await context.dataSources.ecto.updateExecution(id, {
        status: 'cancelled',
        completed_at: new Date(),
      });

      context.pubsub.publish(SUBSCRIPTION_TOPICS.EXECUTION_UPDATED, { executionUpdated: execution });

      return execution;
    },

    rollbackExecution: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'executions:rollback');
      const id = parseInt(args.id, 10);

      const execution = await context.dataSources.ecto.updateExecution(id, {
        status: 'rolled_back',
        completed_at: new Date(),
      });

      context.pubsub.publish(SUBSCRIPTION_TOPICS.EXECUTION_UPDATED, { executionUpdated: execution });

      return execution;
    },
  },

  Execution: {
    id: (execution: any) => String(execution.id),
    status: (execution: any) => execution.status?.toUpperCase(),
    attempts: (execution: any) => execution.retry_attempt,
    exitCode: (execution: any) => execution.exit_code,
    rollbackState: (execution: any) => execution.rollback_state,
    createdAt: (execution: any) => execution.inserted_at,
    updatedAt: (execution: any) => execution.updated_at,
    startedAt: (execution: any) => execution.started_at,
    completedAt: (execution: any) => execution.completed_at,

    workflow: async (execution: any, _args: any, context: GraphQLContext) => {
      return context.loaders.workflowLoader.load(execution.workflow_id);
    },

    symbol: async (execution: any, _args: any, context: GraphQLContext) => {
      return context.loaders.symbolLoader.load(execution.symbol_id);
    },

    node: async (execution: any, _args: any, context: GraphQLContext) => {
      // Get node from execution metadata if available
      const nodeId = execution.metadata?.nodeId;
      if (nodeId) {
        return context.loaders.nodeLoader.load(nodeId);
      }
      return null;
    },

    result: (execution: any) => {
      if (execution.status === 'completed' || execution.status === 'failed') {
        return {
          success: execution.status === 'completed',
          output: execution.output,
          error: execution.error_log,
          stackTrace: execution.metadata?.stackTrace,
          duration: execution.duration || 0,
          timestamp: execution.completed_at || execution.updated_at,
          metadata: execution.metadata,
        };
      }
      return null;
    },
  },
};
