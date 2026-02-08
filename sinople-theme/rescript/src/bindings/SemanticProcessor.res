/**
 * ReScript bindings for the Semantic Processor WASM module
 *
 * This module provides type-safe bindings to the Rust WASM semantic processor.
 * It handles RDF/OWL processing, construct queries, and relationship graphs.
 *
 * Usage:
 * ```rescript
 * let processor = SemanticProcessor.make()
 * let _ = await processor->SemanticProcessor.loadTurtle(ontologyTTL)
 * let constructs = await processor->SemanticProcessor.queryConstructs()
 * ```
 */

// Domain types
type gloss = {
  id: string,
  text: string,
  language: string,
  position: option<int>,
}

type construct = {
  id: string,
  label: string,
  description: option<string>,
  glosses: array<gloss>,
  relationships: array<string>,
}

type entanglement = {
  id: string,
  label: string,
  source: string,
  target: string,
  @as("relationship_type") relationshipType: string,
  description: option<string>,
}

type character = {
  id: string,
  name: string,
  description: option<string>,
  constructs: array<string>,
}

type graphNode = {
  id: string,
  label: string,
  @as("node_type") nodeType: string,
}

type graphEdge = {
  source: string,
  target: string,
  label: string,
}

type networkGraph = {
  nodes: array<graphNode>,
  edges: array<graphEdge>,
}

// Error types
type loadError =
  | ParseError(string)
  | SerializationError(string)
  | UnknownError(string)

// Result alias using built-in result type
type loadResult<'a> = result<'a, loadError>

// Main processor type (opaque)
type t

// WASM module bindings
@module("../../wasm/semantic_processor/pkg/semantic_processor.js") @new
external make: unit => t = "SemanticProcessor"

@send
external _loadTurtle: (t, string) => promise<unit> = "load_turtle"

@send
external _queryConstructs: t => promise<array<construct>> = "query_constructs"

@send
external _queryEntanglements: t => promise<array<entanglement>> = "query_entanglements"

@send
external _findRelationships: (t, string) => promise<array<string>> = "find_relationships"

@send
external _queryCharacters: t => promise<array<character>> = "query_characters"

@send
external _generateNetworkGraph: t => promise<networkGraph> = "generate_network_graph"

@send
external tripleCount: t => int = "triple_count"

@send
external clear: t => unit = "clear"

// Safe wrapper functions with error handling

/**
 * Load RDF data from Turtle format
 */
let loadTurtle = async (processor: t, ttl: string): loadResult<unit> => {
  try {
    await processor->_loadTurtle(ttl)
    Ok()
  } catch {
  | Js.Exn.Error(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) if Js.String2.includes(msg, "parse") => Error(ParseError(msg))
      | Some(msg) => Error(UnknownError(msg))
      | None => Error(UnknownError("Unknown error loading Turtle"))
      }
  }
}

/**
 * Query all constructs from the graph
 */
let queryConstructs = async (processor: t): loadResult<array<construct>> => {
  try {
    let constructs = await processor->_queryConstructs
    Ok(constructs)
  } catch {
  | Js.Exn.Error(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Error(SerializationError(msg))
      | None => Error(UnknownError("Failed to query constructs"))
      }
  }
}

/**
 * Query all entanglements from the graph
 */
let queryEntanglements = async (processor: t): loadResult<array<entanglement>> => {
  try {
    let entanglements = await processor->_queryEntanglements
    Ok(entanglements)
  } catch {
  | Js.Exn.Error(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Error(SerializationError(msg))
      | None => Error(UnknownError("Failed to query entanglements"))
      }
  }
}

/**
 * Find relationships for a specific construct
 */
let findRelationships = async (processor: t, constructId: string): loadResult<array<string>> => {
  try {
    let relationships = await processor->_findRelationships(constructId)
    Ok(relationships)
  } catch {
  | Js.Exn.Error(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Error(UnknownError(msg))
      | None => Error(UnknownError("Failed to find relationships"))
      }
  }
}

/**
 * Query all characters from the graph
 */
let queryCharacters = async (processor: t): loadResult<array<character>> => {
  try {
    let characters = await processor->_queryCharacters
    Ok(characters)
  } catch {
  | Js.Exn.Error(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Error(SerializationError(msg))
      | None => Error(UnknownError("Failed to query characters"))
      }
  }
}

/**
 * Generate network graph for visualization
 */
let generateNetworkGraph = async (processor: t): loadResult<networkGraph> => {
  try {
    let graph = await processor->_generateNetworkGraph
    Ok(graph)
  } catch {
  | Js.Exn.Error(obj) =>
      switch Js.Exn.message(obj) {
      | Some(msg) => Error(SerializationError(msg))
      | None => Error(UnknownError("Failed to generate network graph"))
      }
  }
}

// Utility functions

/**
 * Get error message from loadError
 */
let errorToString = (error: loadError): string => {
  switch error {
  | ParseError(msg) => `Parse error: ${msg}`
  | SerializationError(msg) => `Serialization error: ${msg}`
  | UnknownError(msg) => `Error: ${msg}`
  }
}

/**
 * Check if processor has data loaded
 */
let hasData = (processor: t): bool => {
  processor->tripleCount > 0
}

/**
 * Get construct by ID
 */
let findConstruct = async (processor: t, constructId: string): loadResult<option<construct>> => {
  switch await queryConstructs(processor) {
  | Ok(constructs) => {
      let found = constructs->Js.Array2.find(c => c.id === constructId)
      Ok(found)
    }
  | Error(e) => Error(e)
  }
}

/**
 * Get entanglement by ID
 */
let findEntanglement = async (
  processor: t,
  entanglementId: string,
): loadResult<option<entanglement>> => {
  switch await queryEntanglements(processor) {
  | Ok(entanglements) => {
      let found = entanglements->Js.Array2.find(e => e.id === entanglementId)
      Ok(found)
    }
  | Error(e) => Error(e)
  }
}

/**
 * Get character by ID
 */
let findCharacter = async (processor: t, characterId: string): loadResult<option<character>> => {
  switch await queryCharacters(processor) {
  | Ok(characters) => {
      let found = characters->Js.Array2.find(c => c.id === characterId)
      Ok(found)
    }
  | Error(e) => Error(e)
  }
}

/**
 * Initialize processor with ontology
 */
let initWithOntology = async (ontologyTTL: string): loadResult<t> => {
  let processor = make()

  switch await loadTurtle(processor, ontologyTTL) {
  | Ok() => Ok(processor)
  | Error(e) => Error(e)
  }
}
