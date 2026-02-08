/**
 * Permission Checking
 *
 * Authorization helpers for GraphQL resolvers
 */

import { AuthenticationError, AuthorizationError, type GraphQLContext } from '../types.js';

export function requireAuth(context: GraphQLContext): asserts context is GraphQLContext & { user: NonNullable<GraphQLContext['user']> } {
  if (!context.user) {
    throw new AuthenticationError('You must be logged in to perform this action');
  }
}

export function requireRole(context: GraphQLContext, role: string): void {
  requireAuth(context);

  if (!context.user.roles.includes(role) && !context.user.roles.includes('admin')) {
    throw new AuthorizationError(`You must have the ${role} role to perform this action`);
  }
}

export function requirePermission(context: GraphQLContext, permission: string): void {
  requireAuth(context);

  if (!context.user.permissions.includes(permission) && !context.user.roles.includes('admin')) {
    throw new AuthorizationError(`You must have the ${permission} permission to perform this action`);
  }
}

export function hasPermission(context: GraphQLContext, permission: string): boolean {
  if (!context.user) {
    return false;
  }

  return context.user.permissions.includes(permission) || context.user.roles.includes('admin');
}

export function isAdmin(context: GraphQLContext): boolean {
  return context.user?.roles.includes('admin') ?? false;
}
