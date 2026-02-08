/**
 * Schema Validation Tests
 *
 * Tests for GraphQL schema validation
 */

import { describe, test, expect } from 'bun:test';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { buildSchema, GraphQLSchema } from 'graphql';

const __dirname = dirname(fileURLToPath(import.meta.url));

describe('GraphQL Schema', () => {
  let schema: GraphQLSchema;

  test('should load and parse schema file', () => {
    const schemaPath = join(__dirname, '../schema.graphql');
    const typeDefs = readFileSync(schemaPath, 'utf-8');

    expect(() => {
      schema = buildSchema(typeDefs);
    }).not.toThrow();

    expect(schema).toBeDefined();
  });

  test('should have Query type', () => {
    const schemaPath = join(__dirname, '../schema.graphql');
    const typeDefs = readFileSync(schemaPath, 'utf-8');
    schema = buildSchema(typeDefs);

    const queryType = schema.getQueryType();
    expect(queryType).toBeDefined();
    expect(queryType?.name).toBe('Query');
  });

  test('should have Mutation type', () => {
    const schemaPath = join(__dirname, '../schema.graphql');
    const typeDefs = readFileSync(schemaPath, 'utf-8');
    schema = buildSchema(typeDefs);

    const mutationType = schema.getMutationType();
    expect(mutationType).toBeDefined();
    expect(mutationType?.name).toBe('Mutation');
  });

  test('should have Subscription type', () => {
    const schemaPath = join(__dirname, '../schema.graphql');
    const typeDefs = readFileSync(schemaPath, 'utf-8');
    schema = buildSchema(typeDefs);

    const subscriptionType = schema.getSubscriptionType();
    expect(subscriptionType).toBeDefined();
    expect(subscriptionType?.name).toBe('Subscription');
  });

  test('should have Symbol type with required fields', () => {
    const schemaPath = join(__dirname, '../schema.graphql');
    const typeDefs = readFileSync(schemaPath, 'utf-8');
    schema = buildSchema(typeDefs);

    const symbolType = schema.getType('Symbol');
    expect(symbolType).toBeDefined();

    const fields = (symbolType as any).getFields();
    expect(fields.id).toBeDefined();
    expect(fields.name).toBeDefined();
    expect(fields.type).toBeDefined();
    expect(fields.context).toBeDefined();
    expect(fields.status).toBeDefined();
  });

  test('should have Workflow type with required fields', () => {
    const schemaPath = join(__dirname, '../schema.graphql');
    const typeDefs = readFileSync(schemaPath, 'utf-8');
    schema = buildSchema(typeDefs);

    const workflowType = schema.getType('Workflow');
    expect(workflowType).toBeDefined();

    const fields = (workflowType as any).getFields();
    expect(fields.id).toBeDefined();
    expect(fields.name).toBeDefined();
    expect(fields.status).toBeDefined();
    expect(fields.executions).toBeDefined();
  });
});
