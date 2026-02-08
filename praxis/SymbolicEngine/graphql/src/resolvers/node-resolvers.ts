/**
 * Node and Task Resolvers
 *
 * GraphQL resolvers for swarm Nodes and Tasks
 */

import type { GraphQLContext } from '../types.js';
import { requireRole } from '../auth/permissions.js';

export const nodeResolvers = {
  Query: {
    node: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      return context.loaders.nodeLoader.load(args.id);
    },

    nodes: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.swarm.getNodes({
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },

    task: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      return context.loaders.taskLoader.load(args.id);
    },

    tasks: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.swarm.getTasks({
        nodeId: args.nodeId,
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },
  },

  Mutation: {
    removeNode: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requireRole(context, 'admin');
      // This would require adding a method to swarm data source
      // For now, this is a placeholder
      context.logger.warn('removeNode mutation not fully implemented');
      return true;
    },
  },

  Node: {
    status: (node: any) => node.status?.toUpperCase(),
    lastHeartbeat: (node: any) => new Date(node.lastHeartbeat),
    connectedAt: (node: any) => new Date(node.connectedAt),

    tasks: async (node: any, args: any, context: GraphQLContext) => {
      return context.dataSources.swarm.getTasks({
        nodeId: node.id,
        status: args.status?.toLowerCase(),
        limit: args.limit,
      });
    },
  },

  Task: {
    status: (task: any) => task.status?.toUpperCase(),
    createdAt: (task: any) => new Date(task.createdAt),
    assignedAt: (task: any) => (task.assignedAt ? new Date(task.assignedAt) : null),

    execution: async (task: any, _args: any, context: GraphQLContext) => {
      const execId = parseInt(task.executionId, 10);
      return context.loaders.executionLoader.load(execId);
    },

    symbol: (task: any) => task.symbol,

    node: async (task: any, _args: any, context: GraphQLContext) => {
      if (task.assignedTo) {
        return context.loaders.nodeLoader.load(task.assignedTo);
      }
      return null;
    },

    dependencies: async (task: any, _args: any, context: GraphQLContext) => {
      if (task.dependencies && task.dependencies.length > 0) {
        return Promise.all(task.dependencies.map((id: string) => context.loaders.taskLoader.load(id)));
      }
      return [];
    },
  },
};
