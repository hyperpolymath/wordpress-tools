/**
 * WP Praxis Swarm - Symbol Executor
 *
 * Executes symbolic operations by dispatching to appropriate backend engines
 * (Rust injector, PHP engine, PowerShell engine, or internal handlers).
 */

import { spawn } from 'child_process';
import { promisify } from 'util';
import { exec } from 'child_process';
import type {
  Symbol,
  ExecutionResult,
  ExecutorContext,
  ExecutorBackend,
  BackendConfig,
} from './types';
import { Logger } from './logger';

const execAsync = promisify(exec);

/**
 * Main executor class that coordinates symbol execution
 */
export class Executor {
  private backends: Map<string, ExecutorBackend> = new Map();
  private logger: Logger;

  constructor(config: BackendConfig, logger?: Logger) {
    this.logger = logger ?? new Logger('Executor');
    this.initializeBackends(config);
  }

  /**
   * Initialize backend executors based on configuration
   */
  private initializeBackends(config: BackendConfig): void {
    if (config.rustInjector?.enabled) {
      this.backends.set('rust_injector', new RustInjectorBackend(config.rustInjector, this.logger));
      this.logger.info('Rust injector backend initialized');
    }

    if (config.phpEngine?.enabled) {
      this.backends.set('php_engine', new PHPEngineBackend(config.phpEngine, this.logger));
      this.logger.info('PHP engine backend initialized');
    }

    if (config.powershellEngine?.enabled) {
      this.backends.set(
        'powershell_engine',
        new PowerShellEngineBackend(config.powershellEngine, this.logger)
      );
      this.logger.info('PowerShell engine backend initialized');
    }

    // Internal backend is always available
    this.backends.set('internal', new InternalBackend(this.logger));
    this.logger.info('Internal backend initialized');
  }

  /**
   * Execute a symbol
   */
  async execute(context: ExecutorContext): Promise<ExecutionResult> {
    const startTime = Date.now();
    const { symbol, executionId } = context;

    this.logger.info(`Executing symbol: ${symbol.name} (${executionId})`);

    try {
      // Find appropriate backend
      const backend = this.getBackendForSymbol(symbol);
      if (!backend) {
        throw new Error(`No backend available for dispatch target: ${symbol.dispatch}`);
      }

      // Check backend health
      const healthy = await backend.healthCheck();
      if (!healthy) {
        throw new Error(`Backend ${symbol.dispatch} is not healthy`);
      }

      // Execute with timeout
      const timeout = symbol.timeout ?? 30000;
      const result = await this.executeWithTimeout(backend, context, timeout);

      const duration = Date.now() - startTime;
      this.logger.info(`Symbol executed successfully: ${symbol.name} (${duration}ms)`);

      return {
        ...result,
        duration,
        timestamp: Date.now(),
      };
    } catch (error) {
      const duration = Date.now() - startTime;
      const errorMessage = error instanceof Error ? error.message : String(error);
      const stackTrace = error instanceof Error ? error.stack : undefined;

      this.logger.error(`Symbol execution failed: ${symbol.name}`, error);

      return {
        success: false,
        error: errorMessage,
        stackTrace,
        duration,
        timestamp: Date.now(),
      };
    }
  }

  /**
   * Execute with timeout
   */
  private async executeWithTimeout(
    backend: ExecutorBackend,
    context: ExecutorContext,
    timeoutMs: number
  ): Promise<ExecutionResult> {
    return Promise.race([
      backend.execute(context),
      new Promise<ExecutionResult>((_, reject) =>
        setTimeout(() => reject(new Error(`Execution timeout after ${timeoutMs}ms`)), timeoutMs)
      ),
    ]);
  }

  /**
   * Get backend for symbol
   */
  private getBackendForSymbol(symbol: Symbol): ExecutorBackend | null {
    const backendKey = symbol.dispatch;
    return this.backends.get(backendKey) ?? null;
  }

  /**
   * Execute rollback operation
   */
  async executeRollback(symbol: Symbol, context: ExecutorContext): Promise<ExecutionResult> {
    if (!symbol.rollback) {
      this.logger.warn(`No rollback defined for symbol: ${symbol.name}`);
      return {
        success: true,
        output: 'No rollback operation defined',
        duration: 0,
        timestamp: Date.now(),
      };
    }

    this.logger.info(`Executing rollback for symbol: ${symbol.name}`);

    const rollbackContext: ExecutorContext = {
      ...context,
      symbol: symbol.rollback,
    };

    return this.execute(rollbackContext);
  }

  /**
   * Check health of all backends
   */
  async healthCheck(): Promise<Record<string, boolean>> {
    const health: Record<string, boolean> = {};

    for (const [name, backend] of this.backends.entries()) {
      try {
        health[name] = await backend.healthCheck();
      } catch (error) {
        this.logger.error(`Health check failed for ${name}:`, error);
        health[name] = false;
      }
    }

    return health;
  }
}

// ============================================================================
// Backend Implementations
// ============================================================================

/**
 * Rust Injector Backend
 */
class RustInjectorBackend implements ExecutorBackend {
  constructor(
    private config: NonNullable<BackendConfig['rustInjector']>,
    private logger: Logger
  ) {}

  async execute(context: ExecutorContext): Promise<ExecutionResult> {
    const { symbol } = context;
    const args = this.buildArgs(symbol);

    this.logger.debug(`Executing Rust injector: ${this.config.binaryPath} ${args.join(' ')}`);

    return new Promise((resolve) => {
      const proc = spawn(this.config.binaryPath, args);

      let stdout = '';
      let stderr = '';

      proc.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      proc.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve({
            success: true,
            output: this.parseOutput(stdout),
            duration: 0,
            timestamp: Date.now(),
          });
        } else {
          resolve({
            success: false,
            error: `Rust injector exited with code ${code}`,
            stackTrace: stderr,
            duration: 0,
            timestamp: Date.now(),
          });
        }
      });

      proc.on('error', (error) => {
        resolve({
          success: false,
          error: error.message,
          stackTrace: error.stack,
          duration: 0,
          timestamp: Date.now(),
        });
      });
    });
  }

  canHandle(symbol: Symbol): boolean {
    return symbol.dispatch === 'rust_injector';
  }

  async healthCheck(): Promise<boolean> {
    try {
      const { stdout } = await execAsync(`${this.config.binaryPath} --version`);
      return stdout.includes('wp_injector');
    } catch (error) {
      this.logger.error('Rust injector health check failed:', error);
      return false;
    }
  }

  private buildArgs(symbol: Symbol): string[] {
    const args: string[] = [];

    args.push('--symbol', symbol.name);
    args.push('--type', symbol.type);
    args.push('--context', symbol.context);

    if (Object.keys(symbol.parameters).length > 0) {
      args.push('--params', JSON.stringify(symbol.parameters));
    }

    return args;
  }

  private parseOutput(stdout: string): unknown {
    try {
      return JSON.parse(stdout);
    } catch {
      return stdout.trim();
    }
  }
}

/**
 * PHP Engine Backend
 */
class PHPEngineBackend implements ExecutorBackend {
  constructor(
    private config: NonNullable<BackendConfig['phpEngine']>,
    private logger: Logger
  ) {}

  async execute(context: ExecutorContext): Promise<ExecutionResult> {
    const { symbol } = context;
    const args = this.buildArgs(symbol);

    this.logger.debug(`Executing PHP engine: ${this.config.phpBinary} ${args.join(' ')}`);

    return new Promise((resolve) => {
      const proc = spawn(this.config.phpBinary, args);

      let stdout = '';
      let stderr = '';

      proc.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      proc.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve({
            success: true,
            output: this.parseOutput(stdout),
            duration: 0,
            timestamp: Date.now(),
          });
        } else {
          resolve({
            success: false,
            error: `PHP engine exited with code ${code}`,
            stackTrace: stderr,
            duration: 0,
            timestamp: Date.now(),
          });
        }
      });

      proc.on('error', (error) => {
        resolve({
          success: false,
          error: error.message,
          stackTrace: error.stack,
          duration: 0,
          timestamp: Date.now(),
        });
      });
    });
  }

  canHandle(symbol: Symbol): boolean {
    return symbol.dispatch === 'php_engine';
  }

  async healthCheck(): Promise<boolean> {
    try {
      const { stdout } = await execAsync(`${this.config.phpBinary} --version`);
      return stdout.toLowerCase().includes('php');
    } catch (error) {
      this.logger.error('PHP engine health check failed:', error);
      return false;
    }
  }

  private buildArgs(symbol: Symbol): string[] {
    const args: string[] = [];

    args.push(this.config.scriptPath);
    args.push('--symbol', symbol.name);
    args.push('--type', symbol.type);
    args.push('--context', symbol.context);

    if (Object.keys(symbol.parameters).length > 0) {
      args.push('--params', JSON.stringify(symbol.parameters));
    }

    return args;
  }

  private parseOutput(stdout: string): unknown {
    try {
      return JSON.parse(stdout);
    } catch {
      return stdout.trim();
    }
  }
}

/**
 * PowerShell Engine Backend
 */
class PowerShellEngineBackend implements ExecutorBackend {
  constructor(
    private config: NonNullable<BackendConfig['powershellEngine']>,
    private logger: Logger
  ) {}

  async execute(context: ExecutorContext): Promise<ExecutionResult> {
    const { symbol } = context;
    const args = this.buildArgs(symbol);

    this.logger.debug(`Executing PowerShell engine: ${this.config.pwshBinary} ${args.join(' ')}`);

    return new Promise((resolve) => {
      const proc = spawn(this.config.pwshBinary, args);

      let stdout = '';
      let stderr = '';

      proc.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      proc.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      proc.on('close', (code) => {
        if (code === 0) {
          resolve({
            success: true,
            output: this.parseOutput(stdout),
            duration: 0,
            timestamp: Date.now(),
          });
        } else {
          resolve({
            success: false,
            error: `PowerShell engine exited with code ${code}`,
            stackTrace: stderr,
            duration: 0,
            timestamp: Date.now(),
          });
        }
      });

      proc.on('error', (error) => {
        resolve({
          success: false,
          error: error.message,
          stackTrace: error.stack,
          duration: 0,
          timestamp: Date.now(),
        });
      });
    });
  }

  canHandle(symbol: Symbol): boolean {
    return symbol.dispatch === 'powershell_engine';
  }

  async healthCheck(): Promise<boolean> {
    try {
      const { stdout } = await execAsync(`${this.config.pwshBinary} -Version`);
      return stdout.toLowerCase().includes('powershell');
    } catch (error) {
      this.logger.error('PowerShell engine health check failed:', error);
      return false;
    }
  }

  private buildArgs(symbol: Symbol): string[] {
    const args: string[] = [];

    args.push('-File', this.config.scriptPath);
    args.push('-SymbolName', symbol.name);
    args.push('-SymbolType', symbol.type);
    args.push('-Context', symbol.context);

    if (Object.keys(symbol.parameters).length > 0) {
      args.push('-Parameters', JSON.stringify(symbol.parameters));
    }

    return args;
  }

  private parseOutput(stdout: string): unknown {
    try {
      return JSON.parse(stdout);
    } catch {
      return stdout.trim();
    }
  }
}

/**
 * Internal Backend (for built-in operations)
 */
class InternalBackend implements ExecutorBackend {
  constructor(private logger: Logger) {}

  async execute(context: ExecutorContext): Promise<ExecutionResult> {
    const { symbol } = context;

    this.logger.debug(`Executing internal operation: ${symbol.name}`);

    // Built-in operations
    switch (symbol.name) {
      case 'noop':
        return this.noop();
      case 'echo':
        return this.echo(symbol.parameters);
      case 'delay':
        return this.delay(symbol.parameters);
      default:
        return {
          success: false,
          error: `Unknown internal operation: ${symbol.name}`,
          duration: 0,
          timestamp: Date.now(),
        };
    }
  }

  canHandle(symbol: Symbol): boolean {
    return symbol.dispatch === 'internal';
  }

  async healthCheck(): Promise<boolean> {
    return true; // Internal backend is always healthy
  }

  private async noop(): Promise<ExecutionResult> {
    return {
      success: true,
      output: 'noop',
      duration: 0,
      timestamp: Date.now(),
    };
  }

  private async echo(parameters: Record<string, unknown>): Promise<ExecutionResult> {
    return {
      success: true,
      output: parameters.message ?? parameters,
      duration: 0,
      timestamp: Date.now(),
    };
  }

  private async delay(parameters: Record<string, unknown>): Promise<ExecutionResult> {
    const ms = Number(parameters.ms ?? 1000);
    await new Promise((resolve) => setTimeout(resolve, ms));

    return {
      success: true,
      output: `Delayed ${ms}ms`,
      duration: ms,
      timestamp: Date.now(),
    };
  }
}

/**
 * Create an executor instance
 */
export function createExecutor(config: BackendConfig, logger?: Logger): Executor {
  return new Executor(config, logger);
}
