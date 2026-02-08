/**
 * Configuration Loader
 * Loads and parses the dashboard configuration from TOML file
 */

import { readFileSync } from 'fs';
import { join } from 'path';
import type { DashboardConfig } from '@types/index';

/**
 * Parse TOML configuration file
 * Note: Bun has native TOML support via Bun.file().toml()
 */
export async function loadConfig(configPath?: string): Promise<DashboardConfig> {
  const path = configPath || join(import.meta.dir, '..', 'dashboard-config.toml');

  try {
    // Use Bun's native TOML parser
    const file = Bun.file(path);
    const config = (await file.text()).trim();

    // Simple TOML parser for our config structure
    const parsed = parseSimpleTOML(config);

    return parsed as DashboardConfig;
  } catch (error) {
    console.error('[ConfigLoader] Error loading config:', error);
    console.log('[ConfigLoader] Using default configuration');
    return getDefaultConfig();
  }
}

/**
 * Simple TOML parser (basic implementation)
 * For production, consider using a proper TOML library
 */
function parseSimpleTOML(content: string): Record<string, any> {
  const result: Record<string, any> = {};
  let currentSection: any = result;
  let currentPath: string[] = [];

  const lines = content.split('\n');

  for (const line of lines) {
    const trimmed = line.trim();

    // Skip comments and empty lines
    if (!trimmed || trimmed.startsWith('#')) continue;

    // Section headers [section] or [section.subsection]
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      const sectionPath = trimmed.slice(1, -1).split('.');
      currentPath = sectionPath;

      // Create nested sections
      currentSection = result;
      for (const key of sectionPath) {
        if (!currentSection[key]) {
          currentSection[key] = {};
        }
        currentSection = currentSection[key];
      }
      continue;
    }

    // Key-value pairs
    const eqIndex = trimmed.indexOf('=');
    if (eqIndex === -1) continue;

    const key = trimmed.slice(0, eqIndex).trim();
    let value: any = trimmed.slice(eqIndex + 1).trim();

    // Parse value types
    value = parseValue(value);

    currentSection[key] = value;
  }

  return result;
}

/**
 * Parse TOML value to appropriate JavaScript type
 */
function parseValue(value: string): any {
  // Remove quotes from strings
  if ((value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))) {
    return value.slice(1, -1);
  }

  // Boolean
  if (value === 'true') return true;
  if (value === 'false') return false;

  // Array
  if (value.startsWith('[') && value.endsWith(']')) {
    const arrayContent = value.slice(1, -1);
    return arrayContent.split(',').map(item => parseValue(item.trim()));
  }

  // Number
  if (!isNaN(Number(value))) {
    return Number(value);
  }

  // String (unquoted)
  return value;
}

/**
 * Get default configuration
 */
function getDefaultConfig(): DashboardConfig {
  return {
    server: {
      host: process.env.HOST || 'localhost',
      port: parseInt(process.env.PORT || '3000', 10),
      env: (process.env.NODE_ENV as any) || 'development',
      cors: {
        enabled: true,
        origins: ['http://localhost:3000'],
        methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
        credentials: true,
      },
      websocket: {
        enabled: true,
        path: '/ws',
        heartbeat_interval: 30000,
        max_payload: 1048576,
      },
    },
    database: {
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT || '5432', 10),
      database: process.env.DB_NAME || 'wp_praxis_dev',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || '',
      max_connections: 20,
      idle_timeout: 30000,
      connection_timeout: 5000,
      ssl: {
        enabled: false,
        reject_unauthorized: true,
      },
    },
    api: {
      prefix: '/api',
      version: 'v1',
      rate_limit_enabled: false,
      rate_limit_max: 100,
      rate_limit_window: 60000,
      pagination: {
        default_limit: 20,
        max_limit: 100,
      },
    },
    auth: {
      enabled: false,
      jwt_secret: process.env.JWT_SECRET || '',
      jwt_expiry: 3600,
      session_timeout: 86400,
    },
    logging: {
      level: 'info',
      format: 'pretty',
      log_requests: true,
      log_responses: false,
    },
    state: {
      sources: ['ecto_db'],
      ecto_db: {
        enabled: true,
        refresh_interval: 5000,
      },
      swarm_state: {
        enabled: false,
        refresh_interval: 3000,
        endpoint: 'http://localhost:8080/state',
      },
      powershell_state: {
        enabled: false,
        refresh_interval: 10000,
        script_path: '../core/symbolic.ps1',
      },
    },
    cache: {
      enabled: true,
      ttl: 300,
      max_size: 1000,
    },
    features: {
      real_time_updates: true,
      workflow_visualization: true,
      symbol_inspection: true,
      audit_reports: true,
      baseline_management: true,
      execution_tracking: true,
      performance_metrics: true,
    },
    ui: {
      theme: 'auto',
      auto_refresh: true,
      refresh_interval: 5000,
      max_log_lines: 1000,
      chart_animation: true,
      colors: {
        primary: '#6366f1',
        secondary: '#8b5cf6',
        success: '#10b981',
        warning: '#f59e0b',
        error: '#ef4444',
        info: '#3b82f6',
      },
    },
    monitoring: {
      health_check_enabled: true,
      health_check_interval: 30000,
      metrics_enabled: true,
      metrics_endpoint: '/metrics',
    },
    security: {
      helmet_enabled: true,
      csrf_enabled: false,
      xss_protection: true,
      content_security_policy: true,
      headers: {
        'X-Frame-Options': 'DENY',
        'X-Content-Type-Options': 'nosniff',
        'Referrer-Policy': 'strict-origin-when-cross-origin',
      },
    },
  };
}

/**
 * Validate configuration
 */
export function validateConfig(config: DashboardConfig): boolean {
  // Basic validation
  if (!config.server.host || !config.server.port) {
    console.error('[ConfigLoader] Invalid server configuration');
    return false;
  }

  if (!config.database.host || !config.database.database) {
    console.error('[ConfigLoader] Invalid database configuration');
    return false;
  }

  return true;
}
