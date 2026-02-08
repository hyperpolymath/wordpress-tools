/**
 * Workflow Resolvers
 *
 * GraphQL resolvers for Workflow queries and mutations
 */

import type { GraphQLContext } from '../types.js';
import { requirePermission } from '../auth/permissions.js';
import { SUBSCRIPTION_TOPICS } from '../types.js';

export const workflowResolvers = {
  Query: {
    workflow: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      const id = parseInt(args.id, 10);
      return context.loaders.workflowLoader.load(id);
    },

    workflows: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getWorkflows({
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },

    workflowsConnection: async (_parent: any, args: any, context: GraphQLContext) => {
      const limit = args.first || args.last || 20;
      const offset = args.after ? parseInt(Buffer.from(args.after, 'base64').toString(), 10) : 0;

      const workflows = await context.dataSources.ecto.getWorkflows({
        status: args.status?.toLowerCase(),
        limit: limit + 1,
        offset,
      });

      const hasNextPage = workflows.length > limit;
      const edges = workflows.slice(0, limit).map((node, index) => ({
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
    createWorkflow: async (_parent: any, args: { input: any }, context: GraphQLContext) => {
      requirePermission(context, 'workflows:write');
      return context.dataSources.ecto.createWorkflow(args.input);
    },

    executeWorkflow: async (_parent: any, args: { input: any }, context: GraphQLContext) => {
      requirePermission(context, 'workflows:execute');
      const workflowId = parseInt(args.input.workflowId, 10);

      // Update workflow status to running
      const workflow = await context.dataSources.ecto.updateWorkflow(workflowId, {
        status: 'running',
        started_at: new Date(),
      });

      // Publish to subscription
      context.pubsub.publish(SUBSCRIPTION_TOPICS.WORKFLOW_UPDATED, { workflowUpdated: workflow });
      context.pubsub.publish(SUBSCRIPTION_TOPICS.WORKFLOW_STATUS_CHANGED, { workflowStatusChanged: workflow });

      return workflow;
    },

    cancelWorkflow: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'workflows:execute');
      const id = parseInt(args.id, 10);

      const workflow = await context.dataSources.ecto.updateWorkflow(id, {
        status: 'cancelled',
        completed_at: new Date(),
      });

      context.pubsub.publish(SUBSCRIPTION_TOPICS.WORKFLOW_UPDATED, { workflowUpdated: workflow });
      context.pubsub.publish(SUBSCRIPTION_TOPICS.WORKFLOW_STATUS_CHANGED, { workflowStatusChanged: workflow });

      return workflow;
    },

    pauseWorkflow: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'workflows:execute');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateWorkflow(id, { status: 'paused' });
    },

    resumeWorkflow: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'workflows:execute');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateWorkflow(id, { status: 'running' });
    },

    deleteWorkflow: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'workflows:delete');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.deleteWorkflow(id);
    },
  },

  Workflow: {
    id: (workflow: any) => String(workflow.id),
    status: (workflow: any) => workflow.status?.toUpperCase(),
    manifestPath: (workflow: any) => workflow.manifest_path,
    executionLog: (workflow: any) => workflow.execution_log,
    createdAt: (workflow: any) => workflow.inserted_at,
    updatedAt: (workflow: any) => workflow.updated_at,
    startedAt: (workflow: any) => workflow.started_at,
    completedAt: (workflow: any) => workflow.completed_at,

    symbols: async (workflow: any, _args: any, context: GraphQLContext) => {
      // Get all executions for this workflow and extract unique symbols
      const executions = await context.dataSources.ecto.getExecutionsByWorkflow(workflow.id);
      const symbolIds = [...new Set(executions.map((e) => e.symbol_id))];
      return Promise.all(symbolIds.map((id) => context.loaders.symbolLoader.load(id)));
    },

    executions: async (workflow: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getExecutions({
        workflowId: workflow.id,
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },
  },
};
