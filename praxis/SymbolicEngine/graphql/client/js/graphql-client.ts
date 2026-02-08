/**
 * WP Praxis GraphQL Client
 *
 * TypeScript client library for interacting with the GraphQL API
 */

export interface GraphQLClientConfig {
  endpoint: string;
  token?: string;
  headers?: Record<string, string>;
}

export interface GraphQLRequest {
  query: string;
  variables?: Record<string, any>;
  operationName?: string;
}

export interface GraphQLResponse<T = any> {
  data?: T;
  errors?: Array<{
    message: string;
    locations?: Array<{ line: number; column: number }>;
    path?: string[];
    extensions?: Record<string, any>;
  }>;
}

export class WpPraxisGraphQLClient {
  private endpoint: string;
  private headers: Record<string, string>;

  constructor(config: GraphQLClientConfig) {
    this.endpoint = config.endpoint;
    this.headers = {
      'Content-Type': 'application/json',
      ...(config.token ? { Authorization: `Bearer ${config.token}` } : {}),
      ...config.headers,
    };
  }

  async query<T = any>(request: GraphQLRequest): Promise<GraphQLResponse<T>> {
    const response = await fetch(this.endpoint, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify(request),
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  async mutate<T = any>(request: GraphQLRequest): Promise<GraphQLResponse<T>> {
    return this.query<T>(request);
  }

  subscribe(request: GraphQLRequest, callbacks: {
    onData: (data: any) => void;
    onError?: (error: Error) => void;
    onComplete?: () => void;
  }): () => void {
    // Convert HTTP endpoint to WebSocket endpoint
    const wsEndpoint = this.endpoint.replace(/^http/, 'ws');

    const ws = new WebSocket(wsEndpoint, 'graphql-ws');

    ws.onopen = () => {
      // Send connection init
      ws.send(JSON.stringify({ type: 'connection_init' }));

      // Send subscription
      ws.send(
        JSON.stringify({
          type: 'start',
          id: '1',
          payload: request,
        })
      );
    };

    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);

      switch (message.type) {
        case 'data':
          callbacks.onData(message.payload.data);
          break;
        case 'error':
          callbacks.onError?.(new Error(message.payload.message));
          break;
        case 'complete':
          callbacks.onComplete?.();
          ws.close();
          break;
      }
    };

    ws.onerror = (error) => {
      callbacks.onError?.(new Error('WebSocket error'));
    };

    // Return unsubscribe function
    return () => {
      ws.send(JSON.stringify({ type: 'stop', id: '1' }));
      ws.close();
    };
  }

  // Convenience methods
  async getSymbols(filters?: {
    type?: string;
    context?: string;
    status?: string;
    limit?: number;
  }) {
    return this.query({
      query: `
        query GetSymbols($type: SymbolType, $context: SymbolContext, $status: SymbolStatus, $limit: Int) {
          symbols(type: $type, context: $context, status: $status, limit: $limit) {
            id
            name
            type
            context
            status
            dispatchTarget
            priority
          }
        }
      `,
      variables: filters,
    });
  }

  async getWorkflow(id: string) {
    return this.query({
      query: `
        query GetWorkflow($id: ID!) {
          workflow(id: $id) {
            id
            name
            status
            manifestPath
            startedAt
            completedAt
            executions {
              id
              status
              symbol {
                name
              }
            }
          }
        }
      `,
      variables: { id },
    });
  }

  async executeWorkflow(workflowId: string, parameters?: Record<string, any>) {
    return this.mutate({
      query: `
        mutation ExecuteWorkflow($input: ExecuteWorkflowInput!) {
          executeWorkflow(input: $input) {
            id
            status
            startedAt
          }
        }
      `,
      variables: {
        input: { workflowId, parameters },
      },
    });
  }

  async getStats() {
    return this.query({
      query: `
        query GetStats {
          stats {
            uptime
            version
            symbols {
              total
              byType {
                type
                count
              }
            }
            workflows {
              total
              running
              completed
              failed
              successRate
            }
            nodes {
              total
              online
              utilizationRate
            }
          }
        }
      `,
    });
  }

  subscribeToWorkflow(workflowId: string, onUpdate: (workflow: any) => void) {
    return this.subscribe(
      {
        query: `
          subscription WorkflowUpdates($id: ID) {
            workflowUpdated(id: $id) {
              id
              name
              status
              startedAt
              completedAt
            }
          }
        `,
        variables: { id: workflowId },
      },
      {
        onData: (data) => onUpdate(data.workflowUpdated),
        onError: (error) => console.error('Subscription error:', error),
      }
    );
  }
}

// Export a factory function
export function createClient(config: GraphQLClientConfig): WpPraxisGraphQLClient {
  return new WpPraxisGraphQLClient(config);
}

// Default export
export default WpPraxisGraphQLClient;
