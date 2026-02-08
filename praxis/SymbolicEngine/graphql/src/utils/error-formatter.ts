/**
 * GraphQL Error Formatter
 *
 * Formats errors for GraphQL responses
 */

import { GraphQLError, GraphQLFormattedError } from 'graphql';
import { AuthenticationError, AuthorizationError, ValidationError } from '../types.js';

export function formatError(formattedError: GraphQLFormattedError, error: unknown): GraphQLFormattedError {
  const originalError = error instanceof GraphQLError ? error.originalError : error;

  // Authentication errors
  if (originalError instanceof AuthenticationError) {
    return {
      ...formattedError,
      extensions: {
        code: 'UNAUTHENTICATED',
        http: { status: 401 },
      },
    };
  }

  // Authorization errors
  if (originalError instanceof AuthorizationError) {
    return {
      ...formattedError,
      extensions: {
        code: 'FORBIDDEN',
        http: { status: 403 },
      },
    };
  }

  // Validation errors
  if (originalError instanceof ValidationError) {
    return {
      ...formattedError,
      extensions: {
        code: 'BAD_USER_INPUT',
        http: { status: 400 },
      },
    };
  }

  // Don't expose internal errors in production
  if (process.env.NODE_ENV === 'production') {
    return {
      message: 'Internal server error',
      extensions: {
        code: 'INTERNAL_SERVER_ERROR',
        http: { status: 500 },
      },
    };
  }

  return formattedError;
}
