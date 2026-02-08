/**
 * PowerShell Data Source
 *
 * Executes PowerShell symbolic engine scripts
 */

import { spawn } from 'child_process';
import { promisify } from 'util';
import { exec } from 'child_process';
import type { Logger } from 'winston';
import type { PowerShellDataSource } from '../types.js';

const execAsync = promisify(exec);

export class PowerShellDataSourceImpl implements PowerShellDataSource {
  private logger: Logger;
  private pwshBinary: string;
  private scriptPath: string;

  constructor(logger: Logger) {
    this.logger = logger;
    this.pwshBinary = process.env.PWSH_BINARY || 'pwsh';
    this.scriptPath = process.env.SYMBOLIC_ENGINE_PATH || '../core';
  }

  async executeScript(script: string, params: Record<string, any> = {}): Promise<any> {
    try {
      const paramString = Object.entries(params)
        .map(([key, value]) => `-${key} "${value}"`)
        .join(' ');

      const command = `${this.pwshBinary} -File "${script}" ${paramString}`;

      this.logger.debug('Executing PowerShell script:', { command });

      const { stdout, stderr } = await execAsync(command, {
        timeout: 60000, // 60 second timeout
      });

      if (stderr) {
        this.logger.warn('PowerShell stderr:', stderr);
      }

      // Try to parse JSON output
      try {
        return JSON.parse(stdout);
      } catch {
        return { output: stdout };
      }
    } catch (error) {
      this.logger.error('PowerShell execution error:', error);
      throw error;
    }
  }

  async runSymbolicAudit(baselineId: number, workflowId?: number): Promise<any> {
    const script = `${this.scriptPath}/Run-SymbolicAudit.ps1`;
    const params: Record<string, any> = { BaselineId: baselineId };

    if (workflowId) {
      params.WorkflowId = workflowId;
    }

    return this.executeScript(script, params);
  }

  async setBaseline(baselineId: number): Promise<boolean> {
    const script = `${this.scriptPath}/Set-NormativeBaseline.ps1`;
    const params = { BaselineId: baselineId };

    try {
      await this.executeScript(script, params);
      return true;
    } catch (error) {
      this.logger.error('Failed to set baseline:', error);
      return false;
    }
  }

  async visualizeDiff(baseline1: number, baseline2: number): Promise<any> {
    const script = `${this.scriptPath}/Visualize-SymbolicDiff.ps1`;
    const params = {
      Baseline1: baseline1,
      Baseline2: baseline2,
    };

    return this.executeScript(script, params);
  }
}
