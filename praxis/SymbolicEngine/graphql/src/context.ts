/**
 * GraphQL Context Builder
 *
 * Creates the context object for each GraphQL request
 */

import type { IncomingMessage } from 'http';
import type { PubSub } from 'graphql-subscriptions';
import type { Logger } from 'winston';
import DataLoader from 'dataloader';

import type { GraphQLContext } from './types.js';
import { extractToken, verifyToken } from './auth/jwt.js';
import { createDataLoaders } from './loaders/index.js';

interface CreateContextOptions {
  req: IncomingMessage;
  dataSources: any;
  pubsub: PubSub;
  logger: Logger;
}

export async function createContext({
  req,
  dataSources,
  pubsub,
  logger,
}: CreateContextOptions): Promise<GraphQLContext> {
  // Extract and verify authentication token
  const token = extractToken(req);
  let user = null;

  if (token) {
    try {
      user = await verifyToken(token);
    } catch (error) {
      logger.warn('Invalid authentication token:', error);
      // Continue without user - some operations might not require auth
    }
  }

  // Create DataLoaders for this request
  const loaders = createDataLoaders(dataSources);

  return {
    user,
    token,
    dataSources,
    loaders,
    pubsub,
    logger,
    request: req,
  };
}
