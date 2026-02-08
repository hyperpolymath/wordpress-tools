/**
 * WP Praxis Swarm - Logger
 *
 * Centralized logging with support for console and file output,
 * different log levels, and structured logging.
 */

import { writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import type { LoggingConfig } from './types';

type LogLevel = 'error' | 'warn' | 'info' | 'debug' | 'verbose';

const LOG_LEVELS: Record<LogLevel, number> = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
  verbose: 4,
};

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  context: string;
  message: string;
  data?: unknown;
}

export class Logger {
  private context: string;
  private static config: LoggingConfig = {
    level: 'info',
    console: true,
    format: 'text',
  };

  constructor(context: string) {
    this.context = context;
  }

  /**
   * Configure global logger settings
   */
  static configure(config: LoggingConfig): void {
    Logger.config = config;

    // Create log directory if file logging is enabled
    if (config.file) {
      const dir = dirname(config.file);
      if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
      }
    }
  }

  /**
   * Log an error message
   */
  error(message: string, ...data: unknown[]): void {
    this.log('error', message, ...data);
  }

  /**
   * Log a warning message
   */
  warn(message: string, ...data: unknown[]): void {
    this.log('warn', message, ...data);
  }

  /**
   * Log an info message
   */
  info(message: string, ...data: unknown[]): void {
    this.log('info', message, ...data);
  }

  /**
   * Log a debug message
   */
  debug(message: string, ...data: unknown[]): void {
    this.log('debug', message, ...data);
  }

  /**
   * Log a verbose message
   */
  verbose(message: string, ...data: unknown[]): void {
    this.log('verbose', message, ...data);
  }

  /**
   * Core logging method
   */
  private log(level: LogLevel, message: string, ...data: unknown[]): void {
    // Check if this log level should be output
    if (LOG_LEVELS[level] > LOG_LEVELS[Logger.config.level]) {
      return;
    }

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      context: this.context,
      message,
      data: data.length > 0 ? data : undefined,
    };

    // Console output
    if (Logger.config.console) {
      this.outputToConsole(entry);
    }

    // File output
    if (Logger.config.file) {
      this.outputToFile(entry);
    }
  }

  /**
   * Output log entry to console
   */
  private outputToConsole(entry: LogEntry): void {
    const formatted = this.formatEntry(entry);

    switch (entry.level) {
      case 'error':
        console.error(formatted);
        break;
      case 'warn':
        console.warn(formatted);
        break;
      case 'debug':
      case 'verbose':
        console.log(formatted);
        break;
      default:
        console.log(formatted);
    }
  }

  /**
   * Output log entry to file
   */
  private outputToFile(entry: LogEntry): void {
    if (!Logger.config.file) return;

    const formatted =
      Logger.config.format === 'json'
        ? JSON.stringify(entry) + '\n'
        : this.formatEntry(entry) + '\n';

    try {
      appendFileSync(Logger.config.file, formatted, 'utf8');
    } catch (error) {
      console.error('Failed to write to log file:', error);
    }
  }

  /**
   * Format log entry for text output
   */
  private formatEntry(entry: LogEntry): string {
    const levelStr = entry.level.toUpperCase().padEnd(7);
    const contextStr = `[${entry.context}]`.padEnd(20);
    const dataStr = entry.data ? ' ' + JSON.stringify(entry.data) : '';

    return `${entry.timestamp} ${levelStr} ${contextStr} ${entry.message}${dataStr}`;
  }

  /**
   * Create a child logger with additional context
   */
  child(subContext: string): Logger {
    return new Logger(`${this.context}:${subContext}`);
  }

  /**
   * Measure execution time of an async operation
   */
  async measure<T>(operation: string, fn: () => Promise<T>): Promise<T> {
    const start = Date.now();
    this.debug(`Starting: ${operation}`);

    try {
      const result = await fn();
      const duration = Date.now() - start;
      this.info(`Completed: ${operation} (${duration}ms)`);
      return result;
    } catch (error) {
      const duration = Date.now() - start;
      this.error(`Failed: ${operation} (${duration}ms)`, error);
      throw error;
    }
  }
}

/**
 * Create a logger instance
 */
export function createLogger(context: string): Logger {
  return new Logger(context);
}
