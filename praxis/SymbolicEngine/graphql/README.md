# WP Praxis GraphQL API

Comprehensive GraphQL API for WP Praxis symbolic workflow execution and introspection.

## Overview

This GraphQL API provides a complete interface to the WP Praxis symbolic execution engine, enabling:

- **Symbol Management**: Create, query, and manage symbolic operations
- **Workflow Orchestration**: Execute and monitor multi-step workflows
- **Execution Tracking**: Real-time execution monitoring with detailed results
- **Baseline Management**: Create and manage symbolic state baselines
- **Audit System**: Run audits and track deviations from baselines
- **Swarm Coordination**: Monitor distributed execution across nodes
- **Real-time Updates**: WebSocket subscriptions for live updates
- **Statistics**: Comprehensive system statistics and analytics

## Quick Start

### Installation

```bash
cd SymbolicEngine/graphql
bun install
```

### Configuration

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
GRAPHQL_PORT=4000
DB_HOST=localhost
DB_NAME=wp_praxis_dev
DB_USER=postgres
DB_PASSWORD=postgres
JWT_SECRET=your-secret-key
```

### Running the Server

```bash
# Development mode (with auto-reload)
bun run dev

# Production mode
bun run start

# Build for production
bun run build
```

The server will start at `http://localhost:4000/graphql`

### GraphQL Playground

Visit `http://localhost:4000/graphql` in your browser to access the interactive GraphQL Playground.

## Architecture

### Technology Stack

- **Runtime**: Bun (high-performance JavaScript runtime)
- **GraphQL Server**: Apollo Server 4
- **TypeScript**: Full type safety
- **Database**: PostgreSQL (via pg driver, connects to Ecto schema)
- **Swarm State**: SQLite (better-sqlite3)
- **WebSocket**: graphql-ws for real-time subscriptions
- **Caching**: DataLoader for query optimization
- **Authentication**: JWT tokens

### Project Structure

```
graphql/
├── schema.graphql              # GraphQL schema definition
├── package.json                # Dependencies and scripts
├── tsconfig.json              # TypeScript configuration
├── codegen.yml                # GraphQL codegen config
├── .env.example               # Environment template
│
├── src/
│   ├── server.ts              # Main Apollo Server
│   ├── context.ts             # GraphQL context builder
│   ├── types.ts               # TypeScript type definitions
│   │
│   ├── resolvers/             # GraphQL resolvers
│   │   ├── index.ts           # Combined resolvers
│   │   ├── symbol-resolvers.ts
│   │   ├── workflow-resolvers.ts
│   │   ├── execution-resolvers.ts
│   │   ├── baseline-resolvers.ts
│   │   ├── audit-resolvers.ts
│   │   ├── node-resolvers.ts
│   │   ├── stats-resolvers.ts
│   │   └── subscription-resolvers.ts
│   │
│   ├── datasources/           # Data source connectors
│   │   ├── index.ts           # Data source factory
│   │   ├── ecto-datasource.ts # PostgreSQL/Ecto
│   │   ├── swarm-datasource.ts # Swarm coordinator
│   │   ├── powershell-datasource.ts # PowerShell engine
│   │   └── injector-datasource.ts # Rust injector
│   │
│   ├── loaders/               # DataLoader instances
│   │   └── index.ts           # DataLoader factory
│   │
│   ├── auth/                  # Authentication & authorization
│   │   ├── jwt.ts             # JWT token handling
│   │   └── permissions.ts     # Permission checking
│   │
│   └── utils/                 # Utilities
│       ├── logger.ts          # Winston logger
│       └── error-formatter.ts # Error formatting
│
├── client/                    # Client tools
│   ├── playground.html        # GraphiQL playground
│   ├── example-queries.graphql # Example queries
│   └── js/
│       └── graphql-client.ts  # TypeScript client
│
└── tests/                     # Tests
    ├── schema.test.ts         # Schema validation
    └── integration.test.ts    # Integration tests
```

## API Usage

### Authentication

Include JWT token in the `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

### Basic Queries

#### Get Symbols

```graphql
query GetSymbols {
  symbols(type: ACTION, context: WORDPRESS, limit: 10) {
    id
    name
    type
    context
    status
    dispatchTarget
  }
}
```

#### Get Workflow with Executions

```graphql
query GetWorkflow {
  workflow(id: "1") {
    id
    name
    status
    executions {
      id
      status
      symbol {
        name
      }
      result {
        success
        output
        error
      }
    }
  }
}
```

#### Get System Statistics

```graphql
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
      successRate
    }
  }
}
```

### Mutations

#### Create Symbol

```graphql
mutation CreateSymbol {
  createSymbol(
    input: {
      name: "my_symbol"
      type: ACTION
      context: WORDPRESS
      dispatchTarget: RUST_INJECTOR
      parameters: { action: "process" }
    }
  ) {
    id
    name
    status
  }
}
```

#### Execute Workflow

```graphql
mutation ExecuteWorkflow {
  executeWorkflow(input: { workflowId: "1" }) {
    id
    status
    startedAt
  }
}
```

#### Run Audit

```graphql
mutation RunAudit {
  runAudit(input: { baselineId: "1", auditType: MANUAL }) {
    id
    status
    baseline {
      name
    }
  }
}
```

### Subscriptions

#### Subscribe to Workflow Updates

```graphql
subscription WorkflowUpdates {
  workflowUpdated(id: "1") {
    id
    name
    status
    executions {
      id
      status
    }
  }
}
```

#### Subscribe to Audit Completions

```graphql
subscription AuditCompletions {
  auditCompleted {
    id
    baseline {
      name
    }
    severity
    deviationCount
  }
}
```

## TypeScript Client

Use the TypeScript client library for type-safe API access:

```typescript
import { createClient } from './client/js/graphql-client';

const client = createClient({
  endpoint: 'http://localhost:4000/graphql',
  token: 'your-jwt-token',
});

// Query symbols
const { data } = await client.getSymbols({ type: 'ACTION', limit: 10 });

// Execute workflow
await client.executeWorkflow('1', { param: 'value' });

// Subscribe to updates
const unsubscribe = client.subscribeToWorkflow('1', (workflow) => {
  console.log('Workflow updated:', workflow);
});
```

## Performance Optimization

### DataLoader

All database queries are batched and cached using DataLoader to prevent N+1 query problems:

```typescript
// These resolve efficiently even in nested queries
workflow {
  executions {
    symbol { ... }  # Batched symbol loads
    workflow { ... } # Cached workflow load
  }
}
```

### Relay-style Pagination

Use connection-style pagination for large result sets:

```graphql
query GetSymbolsConnection {
  symbolsConnection(first: 20, after: "cursor") {
    edges {
      node {
        id
        name
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

## Security

### Authentication

- JWT-based authentication
- Configurable token expiration
- Secure token storage recommendations

### Authorization

Permission-based access control:

- `symbols:read`, `symbols:write`, `symbols:delete`
- `workflows:read`, `workflows:write`, `workflows:execute`, `workflows:delete`
- `executions:read`, `executions:retry`, `executions:cancel`, `executions:rollback`
- `baselines:read`, `baselines:write`, `baselines:activate`, `baselines:delete`
- `audits:read`, `audits:run`, `audits:cancel`

Admin role has all permissions.

### Best Practices

1. **Never expose JWT_SECRET**: Use strong, randomly generated secrets
2. **Use HTTPS in production**: Encrypt all traffic
3. **Validate inputs**: All inputs are validated before execution
4. **Limit query complexity**: Prevent resource exhaustion attacks
5. **Rate limiting**: Consider implementing rate limiting in production

## Monitoring

### Health Check

```bash
curl http://localhost:4000/health
```

Response:
```json
{
  "status": "ok",
  "uptime": 12345,
  "timestamp": "2025-11-22T00:00:00.000Z"
}
```

### Metrics

```bash
curl http://localhost:4000/metrics
```

### Logging

Logs are written to:
- Console (development)
- `logs/graphql-error.log` (production errors)
- `logs/graphql-combined.log` (production all logs)

## Development

### Code Generation

Generate TypeScript types from schema:

```bash
bun run codegen
```

### Linting

```bash
bun run lint
```

### Testing

```bash
# Run all tests
bun test

# Watch mode
bun test --watch
```

### Schema Validation

```bash
bun run validate-schema
```

## Deployment

### Environment Variables

Required for production:

```env
NODE_ENV=production
GRAPHQL_PORT=4000
DB_HOST=your-db-host
DB_NAME=wp_praxis_production
DB_USER=your-db-user
DB_PASSWORD=your-db-password
JWT_SECRET=your-strong-secret
ENABLE_PLAYGROUND=false
ENABLE_INTROSPECTION=false
CORS_ORIGINS=https://your-domain.com
```

### Docker (Optional)

```dockerfile
FROM oven/bun:1

WORKDIR /app

COPY package.json bun.lockb ./
RUN bun install --production

COPY . .

EXPOSE 4000

CMD ["bun", "run", "start"]
```

## Troubleshooting

### Common Issues

**Database Connection Failed**
- Verify PostgreSQL is running
- Check database credentials in `.env`
- Ensure database exists and Ecto migrations are run

**WebSocket Subscriptions Not Working**
- Check that GraphQL endpoint supports WebSocket protocol
- Verify `graphql-ws` protocol is used (not `subscriptions-transport-ws`)

**Permission Denied Errors**
- Verify JWT token is valid and not expired
- Check user has required permissions/roles

**Slow Queries**
- Review DataLoader configuration
- Check database indexes (see Ecto migrations)
- Enable query logging to identify bottlenecks

## Contributing

See main WP Praxis `CLAUDE.md` for development guidelines.

## License

AGPL-3.0 - See LICENSE file for details.

## Support

For issues and questions:
- Review documentation in `/Docs`
- Check example queries in `client/example-queries.graphql`
- See `SCHEMA_GUIDE.md` for detailed schema documentation
