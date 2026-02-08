/**
 * Injector Data Source
 *
 * Executes Rust injector binary
 */

import { spawn } from 'child_process';
import type { Logger } from 'winston';
import type { InjectorDataSource } from '../types.js';

export class InjectorDataSourceImpl implements InjectorDataSource {
  private logger: Logger;
  private binaryPath: string;

  constructor(logger: Logger) {
    this.logger = logger;
    this.binaryPath = process.env.INJECTOR_BINARY_PATH || '../../wp_injector/target/release/wp_injector';
  }

  async getInjectorStatus(): Promise<any> {
    try {
      const result = await this.execInjector(['--version']);
      return {
        available: true,
        version: result.output,
      };
    } catch (error) {
      this.logger.error('Injector not available:', error);
      return {
        available: false,
        error: String(error),
      };
    }
  }

  async executeInjection(symbolId: number, params: Record<string, any>): Promise<any> {
    const args = [
      'inject',
      '--symbol-id',
      String(symbolId),
      '--params',
      JSON.stringify(params),
    ];

    return this.execInjector(args);
  }

  private execInjector(args: string[]): Promise<any> {
    return new Promise((resolve, reject) => {
      const child = spawn(this.binaryPath, args);

      let stdout = '';
      let stderr = '';

      child.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      child.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      child.on('close', (code) => {
        if (code === 0) {
          try {
            const output = JSON.parse(stdout);
            resolve(output);
          } catch {
            resolve({ output: stdout });
          }
        } else {
          reject(new Error(`Injector exited with code ${code}: ${stderr}`));
        }
      });

      child.on('error', (error) => {
        reject(error);
      });
    });
  }
}
