/**
 * Resolvers Index
 *
 * Combines all GraphQL resolvers into a single export
 */

import { GraphQLDateTime, GraphQLJSON, GraphQLJSONObject } from 'graphql-scalars';
import { symbolResolvers } from './symbol-resolvers.js';
import { workflowResolvers } from './workflow-resolvers.js';
import { executionResolvers } from './execution-resolvers.js';
import { baselineResolvers } from './baseline-resolvers.js';
import { auditResolvers } from './audit-resolvers.js';
import { nodeResolvers } from './node-resolvers.js';
import { statsResolvers } from './stats-resolvers.js';
import { subscriptionResolvers } from './subscription-resolvers.js';

export const resolvers = {
  // Scalar types
  DateTime: GraphQLDateTime,
  JSON: GraphQLJSON,
  JSONObject: GraphQLJSONObject,

  // Query resolvers
  Query: {
    ...symbolResolvers.Query,
    ...workflowResolvers.Query,
    ...executionResolvers.Query,
    ...baselineResolvers.Query,
    ...auditResolvers.Query,
    ...nodeResolvers.Query,
    ...statsResolvers.Query,
  },

  // Mutation resolvers
  Mutation: {
    ...symbolResolvers.Mutation,
    ...workflowResolvers.Mutation,
    ...executionResolvers.Mutation,
    ...baselineResolvers.Mutation,
    ...auditResolvers.Mutation,
    ...nodeResolvers.Mutation,
  },

  // Subscription resolvers
  Subscription: {
    ...subscriptionResolvers.Subscription,
  },

  // Type resolvers
  Symbol: symbolResolvers.Symbol,
  Workflow: workflowResolvers.Workflow,
  Execution: executionResolvers.Execution,
  Baseline: baselineResolvers.Baseline,
  Audit: auditResolvers.Audit,
  Node: nodeResolvers.Node,
  Task: nodeResolvers.Task,
  SystemStats: statsResolvers.SystemStats,
  SymbolStats: statsResolvers.SymbolStats,
  WorkflowStats: statsResolvers.WorkflowStats,
  ExecutionStats: statsResolvers.ExecutionStats,
};
