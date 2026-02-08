/**
 * Symbol Resolvers
 *
 * GraphQL resolvers for Symbol queries and mutations
 */

import type { GraphQLContext, NotFoundError } from '../types.js';
import { requirePermission } from '../auth/permissions.js';

export const symbolResolvers = {
  Query: {
    symbol: async (_parent: any, args: { id?: string; name?: string }, context: GraphQLContext) => {
      if (args.id) {
        return context.loaders.symbolLoader.load(parseInt(args.id, 10));
      } else if (args.name) {
        return context.dataSources.ecto.getSymbolByName(args.name);
      }
      return null;
    },

    symbols: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getSymbols({
        type: args.type?.toLowerCase(),
        context: args.context?.toLowerCase(),
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },

    symbolsConnection: async (_parent: any, args: any, context: GraphQLContext) => {
      // Relay-style pagination
      const limit = args.first || args.last || 20;
      const offset = args.after ? parseInt(Buffer.from(args.after, 'base64').toString(), 10) : 0;

      const symbols = await context.dataSources.ecto.getSymbols({
        type: args.type?.toLowerCase(),
        context: args.context?.toLowerCase(),
        status: args.status?.toLowerCase(),
        limit: limit + 1, // Fetch one extra to determine hasNextPage
        offset,
      });

      const hasNextPage = symbols.length > limit;
      const edges = symbols.slice(0, limit).map((node, index) => ({
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
    createSymbol: async (_parent: any, args: { input: any }, context: GraphQLContext) => {
      requirePermission(context, 'symbols:write');
      return context.dataSources.ecto.createSymbol(args.input);
    },

    updateSymbol: async (_parent: any, args: { id: string; input: any }, context: GraphQLContext) => {
      requirePermission(context, 'symbols:write');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateSymbol(id, args.input);
    },

    deleteSymbol: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'symbols:delete');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.deleteSymbol(id);
    },

    activateSymbol: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'symbols:write');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateSymbol(id, { status: 'active' });
    },

    deactivateSymbol: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'symbols:write');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateSymbol(id, { status: 'inactive' });
    },
  },

  Symbol: {
    id: (symbol: any) => String(symbol.id),
    dispatchTarget: (symbol: any) => symbol.dispatch_target?.toUpperCase().replace(/_/g, '_'),
    status: (symbol: any) => symbol.status?.toUpperCase(),
    type: (symbol: any) => symbol.type?.toUpperCase(),
    context: (symbol: any) => symbol.context?.toUpperCase(),
    retryCount: (symbol: any) => symbol.retry_count,
    createdAt: (symbol: any) => symbol.inserted_at,
    updatedAt: (symbol: any) => symbol.updated_at,
  },
};
