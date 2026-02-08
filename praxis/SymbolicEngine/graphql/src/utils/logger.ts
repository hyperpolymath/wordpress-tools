/**
 * Logger Configuration
 *
 * Winston logger setup for GraphQL server
 */

import winston from 'winston';

export function createLogger(level: string = 'info'): winston.Logger {
  const logger = winston.createLogger({
    level,
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    ),
    transports: [
      // Console output
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        ),
      }),
    ],
  });

  // Add file transport in production
  if (process.env.NODE_ENV === 'production') {
    logger.add(
      new winston.transports.File({
        filename: 'logs/graphql-error.log',
        level: 'error',
      })
    );
    logger.add(
      new winston.transports.File({
        filename: 'logs/graphql-combined.log',
      })
    );
  }

  return logger;
}
