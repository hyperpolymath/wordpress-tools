/**
 * Data Sources Index
 *
 * Creates and exports all data sources
 */

import type { Logger } from 'winston';
import { EctoDataSourceImpl } from './ecto-datasource.js';
import { SwarmDataSourceImpl } from './swarm-datasource.js';
import { PowerShellDataSourceImpl } from './powershell-datasource.js';
import { InjectorDataSourceImpl } from './injector-datasource.js';

export async function createDataSources(logger: Logger) {
  return {
    ecto: new EctoDataSourceImpl(logger),
    swarm: new SwarmDataSourceImpl(logger),
    powershell: new PowerShellDataSourceImpl(logger),
    injector: new InjectorDataSourceImpl(logger),
  };
}

export { EctoDataSourceImpl, SwarmDataSourceImpl, PowerShellDataSourceImpl, InjectorDataSourceImpl };
