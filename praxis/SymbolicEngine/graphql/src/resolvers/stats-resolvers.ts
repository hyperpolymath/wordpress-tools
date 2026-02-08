/**
 * Statistics Resolvers
 *
 * GraphQL resolvers for system statistics
 */

import type { GraphQLContext } from '../types.js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

export const statsResolvers = {
  Query: {
    stats: async (_parent: any, _args: any, context: GraphQLContext) => {
      const [symbolStats, workflowStats, executionStats, nodeStats] = await Promise.all([
        context.dataSources.ecto.getSymbolStats(),
        context.dataSources.ecto.getWorkflowStats(),
        context.dataSources.ecto.getExecutionStats(),
        context.dataSources.swarm.getNodeStats(),
      ]);

      // Get version from package.json
      let version = '0.1.0';
      try {
        const pkg = JSON.parse(readFileSync(join(__dirname, '../../package.json'), 'utf-8'));
        version = pkg.version;
      } catch {
        // Ignore if package.json not found
      }

      return {
        symbols: symbolStats,
        workflows: workflowStats,
        executions: executionStats,
        nodes: nodeStats,
        uptime: Math.floor(process.uptime()),
        version,
      };
    },
  },

  SystemStats: {
    // All fields are returned by the query resolver
  },

  SymbolStats: {
    byType: (stats: any) =>
      stats.byType.map((item: any) => ({
        type: item.type?.toUpperCase(),
        count: parseInt(item.count, 10),
      })),

    byContext: (stats: any) =>
      stats.byContext.map((item: any) => ({
        context: item.context?.toUpperCase(),
        count: parseInt(item.count, 10),
      })),

    byStatus: (stats: any) =>
      stats.byStatus.map((item: any) => ({
        status: item.status?.toUpperCase(),
        count: parseInt(item.count, 10),
      })),
  },

  WorkflowStats: {
    total: (stats: any) => parseInt(stats.total, 10),
    pending: (stats: any) => parseInt(stats.pending, 10),
    running: (stats: any) => parseInt(stats.running, 10),
    completed: (stats: any) => parseInt(stats.completed, 10),
    failed: (stats: any) => parseInt(stats.failed, 10),
    averageDuration: (stats: any) => parseFloat(stats.average_duration) || null,
    successRate: (stats: any) => parseFloat(stats.success_rate) || 0,
  },

  ExecutionStats: {
    total: (stats: any) => parseInt(stats.total, 10),
    pending: (stats: any) => parseInt(stats.pending, 10),
    running: (stats: any) => parseInt(stats.running, 10),
    completed: (stats: any) => parseInt(stats.completed, 10),
    failed: (stats: any) => parseInt(stats.failed, 10),
    averageDuration: (stats: any) => parseFloat(stats.average_duration) || null,
    successRate: (stats: any) => parseFloat(stats.success_rate) || 0,
  },
};
