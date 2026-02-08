/**
 * Baseline Resolvers
 *
 * GraphQL resolvers for Baseline queries and mutations
 */

import type { GraphQLContext } from '../types.js';
import { requirePermission } from '../auth/permissions.js';

export const baselineResolvers = {
  Query: {
    baseline: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      const id = parseInt(args.id, 10);
      return context.loaders.baselineLoader.load(id);
    },

    baselines: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getBaselines({
        active: args.active,
        baselineType: args.baselineType?.toLowerCase(),
        scope: args.scope?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },
  },

  Mutation: {
    createBaseline: async (_parent: any, args: { input: any }, context: GraphQLContext) => {
      requirePermission(context, 'baselines:write');
      return context.dataSources.ecto.createBaseline(args.input);
    },

    activateBaseline: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'baselines:activate');
      const id = parseInt(args.id, 10);

      // Deactivate all other baselines first
      const baselines = await context.dataSources.ecto.getBaselines({ active: true });
      await Promise.all(
        baselines.map((b) => context.dataSources.ecto.updateBaseline(b.id, { is_active: false }))
      );

      // Activate the target baseline
      const baseline = await context.dataSources.ecto.updateBaseline(id, { is_active: true });

      // Call PowerShell script to set baseline
      await context.dataSources.powershell.setBaseline(id);

      return baseline;
    },

    deactivateBaseline: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'baselines:activate');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateBaseline(id, { is_active: false });
    },

    deleteBaseline: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'baselines:delete');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.deleteBaseline(id);
    },
  },

  Baseline: {
    id: (baseline: any) => String(baseline.id),
    symbolicState: (baseline: any) => baseline.symbolic_state,
    isActive: (baseline: any) => baseline.is_active,
    baselineType: (baseline: any) => baseline.baseline_type?.toUpperCase(),
    scope: (baseline: any) => baseline.scope?.toUpperCase(),
    createdBy: (baseline: any) => baseline.created_by,
    createdAt: (baseline: any) => baseline.inserted_at,
    updatedAt: (baseline: any) => baseline.updated_at,

    audits: async (baseline: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getAudits({
        baselineId: baseline.id,
        limit: args.limit,
        offset: args.offset,
      });
    },
  },
};
