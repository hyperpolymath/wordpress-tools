/**
 * Audit Resolvers
 *
 * GraphQL resolvers for Audit queries and mutations
 */

import type { GraphQLContext } from '../types.js';
import { requirePermission } from '../auth/permissions.js';
import { SUBSCRIPTION_TOPICS } from '../types.js';

export const auditResolvers = {
  Query: {
    audit: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      const id = parseInt(args.id, 10);
      return context.loaders.auditLoader.load(id);
    },

    audits: async (_parent: any, args: any, context: GraphQLContext) => {
      return context.dataSources.ecto.getAudits({
        baselineId: args.baselineId ? parseInt(args.baselineId, 10) : undefined,
        severity: args.severity?.toLowerCase(),
        status: args.status?.toLowerCase(),
        limit: args.limit,
        offset: args.offset,
      });
    },

    auditsConnection: async (_parent: any, args: any, context: GraphQLContext) => {
      const limit = args.first || args.last || 20;
      const offset = args.after ? parseInt(Buffer.from(args.after, 'base64').toString(), 10) : 0;

      const audits = await context.dataSources.ecto.getAudits({
        baselineId: args.baselineId ? parseInt(args.baselineId, 10) : undefined,
        severity: args.severity?.toLowerCase(),
        status: args.status?.toLowerCase(),
        limit: limit + 1,
        offset,
      });

      const hasNextPage = audits.length > limit;
      const edges = audits.slice(0, limit).map((node, index) => ({
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
    runAudit: async (_parent: any, args: { input: any }, context: GraphQLContext) => {
      requirePermission(context, 'audits:run');

      const baselineId = parseInt(args.input.baselineId, 10);
      const workflowId = args.input.workflowId ? parseInt(args.input.workflowId, 10) : undefined;

      // Create audit record
      const audit = await context.dataSources.ecto.createAudit({
        baselineId,
        workflowId,
        auditType: args.input.auditType || 'manual',
        metadata: args.input.metadata || {},
      });

      // Update audit to running
      await context.dataSources.ecto.updateAudit(audit.id, {
        status: 'running',
        started_at: new Date(),
      });

      // Execute PowerShell audit script asynchronously
      context.dataSources.powershell
        .runSymbolicAudit(baselineId, workflowId)
        .then(async (result) => {
          // Update audit with results
          await context.dataSources.ecto.updateAudit(audit.id, {
            status: 'completed',
            completed_at: new Date(),
            deviations: result.deviations || [],
            deviation_count: result.deviations?.length || 0,
            severity: result.severity || 'info',
            passed_checks: result.passedChecks || 0,
            failed_checks: result.failedChecks || 0,
            recommendations: result.recommendations || [],
          });

          const completedAudit = await context.dataSources.ecto.getAudit(audit.id);
          context.pubsub.publish(SUBSCRIPTION_TOPICS.AUDIT_COMPLETED, { auditCompleted: completedAudit });

          if (result.severity === 'error' || result.severity === 'critical') {
            context.pubsub.publish(SUBSCRIPTION_TOPICS.AUDIT_DEVIATION_DETECTED, {
              auditDeviationDetected: completedAudit,
            });
          }
        })
        .catch(async (error) => {
          context.logger.error('Audit execution failed:', error);
          await context.dataSources.ecto.updateAudit(audit.id, {
            status: 'failed',
            completed_at: new Date(),
            metadata: { error: String(error) },
          });
        });

      return audit;
    },

    cancelAudit: async (_parent: any, args: { id: string }, context: GraphQLContext) => {
      requirePermission(context, 'audits:cancel');
      const id = parseInt(args.id, 10);
      return context.dataSources.ecto.updateAudit(id, {
        status: 'cancelled',
        completed_at: new Date(),
      });
    },
  },

  Audit: {
    id: (audit: any) => String(audit.id),
    auditType: (audit: any) => audit.audit_type?.toUpperCase(),
    status: (audit: any) => audit.status?.toUpperCase(),
    severity: (audit: any) => audit.severity?.toUpperCase(),
    deviationCount: (audit: any) => audit.deviation_count,
    passedChecks: (audit: any) => audit.passed_checks,
    failedChecks: (audit: any) => audit.failed_checks,
    createdAt: (audit: any) => audit.inserted_at,
    updatedAt: (audit: any) => audit.updated_at,
    startedAt: (audit: any) => audit.started_at,
    completedAt: (audit: any) => audit.completed_at,

    baseline: async (audit: any, _args: any, context: GraphQLContext) => {
      return context.loaders.baselineLoader.load(audit.baseline_id);
    },

    workflow: async (audit: any, _args: any, context: GraphQLContext) => {
      if (audit.workflow_id) {
        return context.loaders.workflowLoader.load(audit.workflow_id);
      }
      return null;
    },

    deviations: (audit: any) => {
      return audit.deviations.map((d: any) => ({
        path: d.path,
        expected: d.expected,
        actual: d.actual,
        severity: d.severity?.toUpperCase(),
        message: d.message,
      }));
    },

    recommendations: (audit: any) => audit.recommendations,
  },
};
