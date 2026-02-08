# GraphQL Schema Guide

Complete guide to the WP Praxis GraphQL schema design and usage patterns.

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Core Types](#core-types)
3. [Query Patterns](#query-patterns)
4. [Mutation Patterns](#mutation-patterns)
5. [Subscription Patterns](#subscription-patterns)
6. [Pagination](#pagination)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)

## Schema Overview

The WP Praxis GraphQL schema is organized around these core concepts:

- **Symbols**: Declarative representations of operations
- **Workflows**: Collections of symbols executed in sequence
- **Executions**: Runtime instances of symbol execution
- **Baselines**: Normative symbolic state snapshots
- **Audits**: Deviation detection from baselines
- **Nodes**: Distributed swarm worker nodes
- **Tasks**: Execution units assigned to nodes

## Core Types

### Symbol

Represents a symbolic operation that can be executed.

```graphql
type Symbol {
  id: ID!
  name: String!
  type: SymbolType!           # ACTION, FILTER, STATE, QUERY, TRANSFORM
  context: SymbolContext!     # WORDPRESS, FILESYSTEM, DATABASE, NETWORK, GENERIC
  status: SymbolStatus!       # ACTIVE, INACTIVE, DEPRECATED, ARCHIVED
  dispatchTarget: SymbolDispatchTarget! # RUST_INJECTOR, PHP_ENGINE, POWERSHELL_ENGINE
  parameters: JSONObject!
  description: String
  priority: Int!
  timeout: Int!
  retryCount: Int!
  dependencies: [String!]
  rollbackSymbol: Symbol
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

**Key Relationships:**
- Can have dependencies on other symbols (by name)
- Can have a rollback symbol for failure recovery
- Used by Executions and Tasks

**Usage Example:**
```graphql
query {
  symbol(name: "wordpress_install") {
    id
    type
    context
    dispatchTarget
    parameters
  }
}
```

### Workflow

Orchestrates multiple symbols into a cohesive execution flow.

```graphql
type Workflow {
  id: ID!
  name: String!
  description: String
  manifestPath: String!
  status: WorkflowStatus!  # PENDING, RUNNING, COMPLETED, FAILED, CANCELLED, PAUSED
  executionLog: [JSON!]!
  metadata: JSONObject!
  symbols: [Symbol!]!
  executions(status: ExecutionStatus, limit: Int, offset: Int): [Execution!]!
  startedAt: DateTime
  completedAt: DateTime
  duration: Int
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

**Key Relationships:**
- Contains multiple symbols
- Generates executions for each symbol
- Can be referenced by audits

**Usage Example:**
```graphql
query {
  workflow(id: "1") {
    name
    status
    symbols {
      name
      type
    }
    executions(status: COMPLETED) {
      id
      result {
        success
        duration
      }
    }
  }
}
```

### Execution

Runtime instance of symbol execution within a workflow.

```graphql
type Execution {
  id: ID!
  workflow: Workflow!
  symbol: Symbol!
  status: ExecutionStatus!  # PENDING, QUEUED, ASSIGNED, RUNNING, COMPLETED, FAILED, etc.
  node: Node
  result: ExecutionResult
  attempts: Int!
  exitCode: Int
  rollbackState: JSONObject
  startedAt: DateTime
  completedAt: DateTime
  duration: Int
  createdAt: DateTime!
  updatedAt: DateTime!
}

type ExecutionResult {
  success: Boolean!
  output: JSON
  error: String
  stackTrace: String
  duration: Int!
  timestamp: DateTime!
  metadata: JSONObject
}
```

**Key Relationships:**
- Belongs to a Workflow
- Executes a Symbol
- May be assigned to a Node

**Usage Example:**
```graphql
query {
  execution(id: "42") {
    status
    attempts
    symbol {
      name
      type
    }
    result {
      success
      output
      error
      duration
    }
  }
}
```

### Baseline

Normative symbolic state snapshot used for audit comparisons.

```graphql
type Baseline {
  id: ID!
  name: String!
  description: String
  symbolicState: JSONObject!
  version: String!
  isActive: Boolean!
  baselineType: BaselineType!  # SYSTEM, CUSTOM, SNAPSHOT, TEMPLATE
  scope: BaselineScope!         # GLOBAL, PROJECT, SITE, USER
  createdBy: String
  metadata: JSONObject
  audits(limit: Int, offset: Int): [Audit!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

**Key Relationships:**
- Referenced by audits
- Only one baseline is typically active at a time

**Usage Example:**
```graphql
query {
  baselines(active: true) {
    id
    name
    version
    symbolicState
  }
}
```

### Audit

Deviation detection by comparing current state to a baseline.

```graphql
type Audit {
  id: ID!
  baseline: Baseline!
  workflow: Workflow
  auditType: AuditType!      # MANUAL, SCHEDULED, TRIGGERED, CONTINUOUS
  status: AuditStatus!       # PENDING, RUNNING, COMPLETED, FAILED, CANCELLED
  deviations: [Deviation!]!
  severity: AuditSeverity!   # INFO, WARNING, ERROR, CRITICAL
  deviationCount: Int!
  passedChecks: Int!
  failedChecks: Int!
  recommendations: [Recommendation!]!
  startedAt: DateTime
  completedAt: DateTime
  duration: Int
  metadata: JSONObject
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Deviation {
  path: String!
  expected: JSON
  actual: JSON
  severity: AuditSeverity!
  message: String!
}

type Recommendation {
  title: String!
  description: String!
  actionable: Boolean!
  priority: Int!
}
```

**Key Relationships:**
- References a Baseline
- Optionally references a Workflow
- Contains deviation details

**Usage Example:**
```graphql
query {
  audits(severity: CRITICAL, limit: 10) {
    id
    baseline {
      name
    }
    deviations {
      path
      message
      severity
    }
    recommendations {
      title
      description
    }
  }
}
```

### Node

Swarm worker node for distributed execution.

```graphql
type Node {
  id: ID!
  name: String!
  status: NodeStatus!  # INITIALIZING, IDLE, BUSY, OFFLINE, FAILED
  capabilities: NodeCapabilities!
  health: NodeHealth!
  tasks(status: ExecutionStatus, limit: Int): [Task!]!
  lastHeartbeat: DateTime!
  connectedAt: DateTime!
  metadata: JSONObject
}

type NodeCapabilities {
  rust: Boolean!
  php: Boolean!
  powershell: Boolean!
  maxConcurrentTasks: Int!
}

type NodeHealth {
  cpuUsage: Float!
  memoryUsage: Float!
  activeTasks: Int!
  completedTasks: Int!
  failedTasks: Int!
  uptime: Int!
}
```

**Key Relationships:**
- Executes Tasks
- Referenced by Executions

**Usage Example:**
```graphql
query {
  nodes(status: BUSY) {
    id
    name
    health {
      cpuUsage
      memoryUsage
      activeTasks
    }
    capabilities {
      rust
      php
      powershell
    }
  }
}
```

### Task

Execution unit assigned to a swarm node.

```graphql
type Task {
  id: ID!
  execution: Execution!
  symbol: Symbol!
  node: Node
  status: ExecutionStatus!
  priority: Int!
  dependencies: [Task!]!
  createdAt: DateTime!
  assignedAt: DateTime
}
```

**Key Relationships:**
- Belongs to an Execution
- Executes a Symbol
- May be assigned to a Node
- Can depend on other Tasks

## Query Patterns

### Simple Queries

Get a single resource by ID:

```graphql
query {
  symbol(id: "1") { ... }
  workflow(id: "1") { ... }
  execution(id: "1") { ... }
}
```

Get a symbol by name:

```graphql
query {
  symbol(name: "wordpress_install") {
    id
    type
    parameters
  }
}
```

### Filtered Queries

```graphql
query {
  symbols(
    type: ACTION
    context: WORDPRESS
    status: ACTIVE
    limit: 20
    offset: 0
  ) {
    id
    name
  }
}
```

### Nested Queries

Fetch related data in a single request:

```graphql
query {
  workflow(id: "1") {
    name
    status
    symbols {
      name
      type
    }
    executions {
      id
      status
      symbol {
        name
      }
      node {
        name
        health {
          cpuUsage
        }
      }
    }
  }
}
```

### Relay-style Pagination

For large result sets:

```graphql
query {
  symbolsConnection(first: 20, after: "cursor123") {
    edges {
      node {
        id
        name
      }
      cursor
    }
    pageInfo {
      hasNextPage
      hasPreviousPage
      startCursor
      endCursor
      total
    }
  }
}
```

## Mutation Patterns

### Create Operations

```graphql
mutation {
  createSymbol(input: {
    name: "my_symbol"
    type: ACTION
    context: WORDPRESS
    dispatchTarget: RUST_INJECTOR
    parameters: { key: "value" }
  }) {
    id
    name
    status
  }
}
```

### Update Operations

```graphql
mutation {
  updateSymbol(
    id: "1"
    input: {
      status: INACTIVE
      description: "Updated"
    }
  ) {
    id
    status
    description
  }
}
```

### Execute Operations

```graphql
mutation {
  executeWorkflow(input: {
    workflowId: "1"
    parameters: { env: "production" }
    priority: 5
  }) {
    id
    status
    startedAt
  }
}
```

### State Transitions

```graphql
mutation {
  # Retry failed execution
  retryExecution(id: "42") {
    id
    status
    attempts
  }

  # Cancel running workflow
  cancelWorkflow(id: "1") {
    id
    status
    completedAt
  }

  # Activate baseline
  activateBaseline(id: "2") {
    id
    isActive
  }
}
```

## Subscription Patterns

### Resource-specific Subscriptions

Subscribe to updates for a specific resource:

```graphql
subscription {
  workflowUpdated(id: "1") {
    id
    status
    executions {
      status
    }
  }
}
```

### Filtered Subscriptions

Subscribe with filters:

```graphql
subscription {
  executionStatusChanged(
    workflowId: "1"
    status: COMPLETED
  ) {
    id
    status
    result {
      success
    }
  }
}
```

### Broadcast Subscriptions

Subscribe to all updates:

```graphql
subscription {
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

## Pagination

### Offset-based Pagination

Simple pagination for smaller datasets:

```graphql
query {
  symbols(limit: 20, offset: 40) {
    id
    name
  }
}
```

**Pros:**
- Simple to implement
- Easy to jump to specific pages

**Cons:**
- Performance degrades with large offsets
- Inconsistent results if data changes during pagination

### Cursor-based Pagination (Relay)

Recommended for large datasets:

```graphql
query {
  symbolsConnection(first: 20, after: "cursor123") {
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

**Pros:**
- Consistent performance
- Stable across data changes

**Cons:**
- Can't jump to specific pages
- Slightly more complex to implement

## Error Handling

### Error Types

1. **Authentication Error** (401)
```json
{
  "errors": [{
    "message": "Not authenticated",
    "extensions": {
      "code": "UNAUTHENTICATED"
    }
  }]
}
```

2. **Authorization Error** (403)
```json
{
  "errors": [{
    "message": "Not authorized",
    "extensions": {
      "code": "FORBIDDEN"
    }
  }]
}
```

3. **Validation Error** (400)
```json
{
  "errors": [{
    "message": "Invalid input",
    "extensions": {
      "code": "BAD_USER_INPUT"
    }
  }]
}
```

4. **Not Found Error**
```json
{
  "errors": [{
    "message": "Symbol with id 999 not found",
    "path": ["symbol"]
  }]
}
```

### Handling Errors in Client

```typescript
const { data, errors } = await client.query({ query });

if (errors) {
  errors.forEach(error => {
    switch (error.extensions?.code) {
      case 'UNAUTHENTICATED':
        // Redirect to login
        break;
      case 'FORBIDDEN':
        // Show access denied message
        break;
      case 'BAD_USER_INPUT':
        // Show validation errors
        break;
      default:
        // Show generic error
    }
  });
}
```

## Best Practices

### 1. Request Only What You Need

❌ Bad:
```graphql
query {
  symbols {
    id
    name
    type
    context
    status
    dispatchTarget
    parameters
    description
    priority
    timeout
    retryCount
    createdAt
    updatedAt
  }
}
```

✅ Good:
```graphql
query {
  symbols {
    id
    name
    type
  }
}
```

### 2. Use Fragments for Reusable Fields

```graphql
fragment SymbolBasics on Symbol {
  id
  name
  type
  context
}

query {
  symbols {
    ...SymbolBasics
  }

  symbol(id: "1") {
    ...SymbolBasics
    parameters
  }
}
```

### 3. Use Variables for Dynamic Queries

❌ Bad:
```graphql
query {
  symbol(id: "1") { ... }
}
```

✅ Good:
```graphql
query GetSymbol($id: ID!) {
  symbol(id: $id) { ... }
}

# Variables: { "id": "1" }
```

### 4. Handle Null Values

All nullable fields should be handled:

```typescript
workflow.executions?.forEach(exec => {
  const duration = exec.duration ?? 0;
  const node = exec.node?.name ?? 'unassigned';
});
```

### 5. Use Subscriptions Wisely

Only subscribe to data you need real-time updates for:

```graphql
# Good: Specific workflow updates
subscription {
  workflowUpdated(id: "1") {
    status
  }
}

# Avoid: All workflow updates
subscription {
  workflowUpdated {
    id
    name
    status
    executions { ... }
    # Too much data
  }
}
```

### 6. Implement Error Boundaries

Always handle potential errors:

```typescript
try {
  const { data, errors } = await client.query({ ... });

  if (errors) {
    handleErrors(errors);
  }

  if (data) {
    processData(data);
  }
} catch (error) {
  handleNetworkError(error);
}
```

### 7. Cache Efficiently

Use DataLoader batching automatically:

```graphql
query {
  workflow(id: "1") {
    executions {
      symbol { name }  # Batched
      workflow { name } # Cached
    }
  }
}
```

### 8. Limit Query Depth

Avoid deeply nested queries:

```graphql
# Avoid
query {
  workflow {
    executions {
      symbol {
        # Don't go too deep
      }
    }
  }
}
```

## Schema Evolution

### Adding Fields

✅ Safe: Adding nullable fields
```graphql
type Symbol {
  newField: String  # Safe to add
}
```

❌ Breaking: Adding required fields
```graphql
type Symbol {
  newField: String!  # Breaking change
}
```

### Deprecating Fields

Use `@deprecated` directive:

```graphql
type Symbol {
  oldField: String @deprecated(reason: "Use newField instead")
  newField: String
}
```

### Versioning

Consider schema versioning for major changes:
- Use different endpoints: `/graphql/v1`, `/graphql/v2`
- Or use field aliases: `symbolV2`

## Additional Resources

- Main README: `README.md`
- Example Queries: `client/example-queries.graphql`
- GraphQL Playground: `http://localhost:4000/graphql`
- Schema File: `schema.graphql`
