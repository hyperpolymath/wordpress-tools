/**
 * WP Praxis Swarm - Main Entry Point
 *
 * Exports all public APIs for programmatic usage
 */

// Core types
export * from './types';

// State management
export { StateManager } from './state-manager';

// Logging
export { Logger, createLogger } from './logger';

// Execution
export { Executor, createExecutor } from './executor';

// Coordination
export { Coordinator, createCoordinator } from './coordinator';

// Worker
export { Worker, createWorker } from './worker';

// Dispatcher
export { Dispatcher, createDispatcher } from './dispatch';

// WebSocket server
export { WebSocketServer, createWebSocketServer } from './websocket-server';

// Version
export const VERSION = '0.1.0';
export const NAME = '@wp-praxis/swarm';
