/**
 * Subscription Resolvers
 *
 * GraphQL subscription resolvers for real-time updates
 */

import { withFilter } from 'graphql-subscriptions';
import type { GraphQLContext } from '../types.js';
import { SUBSCRIPTION_TOPICS } from '../types.js';

export const subscriptionResolvers = {
  Subscription: {
    workflowUpdated: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.WORKFLOW_UPDATED]);
        },
        (payload: any, args: { id?: string }) => {
          // If ID filter provided, only send updates for that workflow
          if (args.id) {
            return String(payload.workflowUpdated.id) === args.id;
          }
          return true;
        }
      ),
    },

    workflowStatusChanged: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.WORKFLOW_STATUS_CHANGED]);
        },
        (payload: any, args: { id?: string }) => {
          if (args.id) {
            return String(payload.workflowStatusChanged.id) === args.id;
          }
          return true;
        }
      ),
    },

    executionUpdated: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.EXECUTION_UPDATED]);
        },
        (payload: any, args: { workflowId?: string }) => {
          if (args.workflowId) {
            return String(payload.executionUpdated.workflow_id) === args.workflowId;
          }
          return true;
        }
      ),
    },

    executionStatusChanged: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.EXECUTION_STATUS_CHANGED]);
        },
        (payload: any, args: { workflowId?: string; status?: string }) => {
          const execution = payload.executionStatusChanged;

          if (args.workflowId && String(execution.workflow_id) !== args.workflowId) {
            return false;
          }

          if (args.status && execution.status?.toUpperCase() !== args.status) {
            return false;
          }

          return true;
        }
      ),
    },

    auditCompleted: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.AUDIT_COMPLETED]);
        },
        (payload: any, args: { baselineId?: string }) => {
          if (args.baselineId) {
            return String(payload.auditCompleted.baseline_id) === args.baselineId;
          }
          return true;
        }
      ),
    },

    auditDeviationDetected: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.AUDIT_DEVIATION_DETECTED]);
        },
        (payload: any, args: { severity?: string }) => {
          if (args.severity) {
            return payload.auditDeviationDetected.severity?.toUpperCase() === args.severity;
          }
          return true;
        }
      ),
    },

    nodeStatusChanged: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.NODE_STATUS_CHANGED]);
        },
        (payload: any, args: { id?: string }) => {
          if (args.id) {
            return payload.nodeStatusChanged.id === args.id;
          }
          return true;
        }
      ),
    },

    nodeHealthUpdated: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.NODE_HEALTH_UPDATED]);
        },
        (payload: any, args: { id?: string }) => {
          if (args.id) {
            return payload.nodeHealthUpdated.id === args.id;
          }
          return true;
        }
      ),
    },

    taskAssigned: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.TASK_ASSIGNED]);
        },
        (payload: any, args: { nodeId?: string }) => {
          if (args.nodeId) {
            return payload.taskAssigned.assignedTo === args.nodeId;
          }
          return true;
        }
      ),
    },

    taskUpdated: {
      subscribe: withFilter(
        (_parent: any, _args: any, context: GraphQLContext) => {
          return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.TASK_UPDATED]);
        },
        (payload: any, args: { nodeId?: string }) => {
          if (args.nodeId) {
            return payload.taskUpdated.assignedTo === args.nodeId;
          }
          return true;
        }
      ),
    },

    statsUpdated: {
      subscribe: (_parent: any, _args: any, context: GraphQLContext) => {
        return context.pubsub.asyncIterator([SUBSCRIPTION_TOPICS.STATS_UPDATED]);
      },
    },
  },
};
