/**
 * Example usage of the Semantic Processor
 *
 * This demonstrates how to use the WASM semantic processor
 * from ReScript code.
 */

open SemanticProcessor

/**
 * Example: Load ontology and query constructs
 */
let loadAndQueryConstructs = async () => {
  // Create processor instance
  let processor = SemanticProcessor.make()

  // Sample Turtle ontology
  let ontologyTTL = `
    @prefix sn: <http://sinople.org/ontology#> .
    @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
    @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

    <http://sinople.org/constructs/time> a sn:Construct ;
        rdfs:label "Time" ;
        rdfs:comment "The concept of temporal progression" ;
        sn:hasGloss "A dimension in which events occur in sequence" .

    <http://sinople.org/constructs/space> a sn:Construct ;
        rdfs:label "Space" ;
        rdfs:comment "The boundless three-dimensional extent" ;
        sn:hasGloss "A continuous area or expanse which is free, available, or unoccupied" .

    <http://sinople.org/entanglements/time-space> a sn:Entanglement ;
        rdfs:label "Time-Space Relationship" ;
        sn:hasSource <http://sinople.org/constructs/time> ;
        sn:hasTarget <http://sinople.org/constructs/space> ;
        sn:relationshipType "interdependent" ;
        rdfs:comment "The fundamental relationship between temporal and spatial dimensions" .
  `

  // Load ontology
  switch await processor->loadTurtle(ontologyTTL) {
  | Ok() => Js.log("✅ Ontology loaded successfully")
  | Error(e) => Js.log2("❌ Error loading ontology:", errorToString(e))
  }

  // Query constructs
  switch await processor->queryConstructs {
  | Ok(constructs) => {
      Js.log(`📊 Found ${Belt.Int.toString(constructs->Js.Array2.length)} constructs:`)
      constructs->Js.Array2.forEach(c => {
        Js.log(`  - ${c.label} (${c.id})`)
        switch c.description {
        | Some(desc) => Js.log(`    Description: ${desc}`)
        | None => ()
        }
      })
    }
  | Error(e) => Js.log2("❌ Error querying constructs:", errorToString(e))
  }

  // Query entanglements
  switch await processor->queryEntanglements {
  | Ok(entanglements) => {
      Js.log(`🔗 Found ${Belt.Int.toString(entanglements->Js.Array2.length)} entanglements:`)
      entanglements->Js.Array2.forEach(e => {
        Js.log(`  - ${e.label}: ${e.source} → ${e.target}`)
      })
    }
  | Error(e) => Js.log2("❌ Error querying entanglements:", errorToString(e))
  }

  // Generate network graph
  switch await processor->generateNetworkGraph {
  | Ok(graph) => {
      Js.log(`🕸️  Network graph:`)
      Js.log(`  Nodes: ${Belt.Int.toString(graph.nodes->Js.Array2.length)}`)
      Js.log(`  Edges: ${Belt.Int.toString(graph.edges->Js.Array2.length)}`)
    }
  | Error(e) => Js.log2("❌ Error generating graph:", errorToString(e))
  }
}

/**
 * Example: Find specific construct and its relationships
 */
let findConstructWithRelationships = async (processor: t, constructId: string) => {
  // Find construct
  switch await processor->findConstruct(constructId) {
  | Ok(Some(construct)) => {
      Js.log(`📌 Found construct: ${construct.label}`)

      // Find relationships
      switch await processor->findRelationships(constructId) {
      | Ok(relationships) => {
          Js.log(`  Related to ${Belt.Int.toString(relationships->Js.Array2.length)} entities:`)
          relationships->Js.Array2.forEach(rel => Js.log(`    - ${rel}`))
        }
      | Error(e) => Js.log2("❌ Error finding relationships:", errorToString(e))
      }
    }
  | Ok(None) => Js.log(`⚠️  Construct not found: ${constructId}`)
  | Error(e) => Js.log2("❌ Error finding construct:", errorToString(e))
  }
}

/**
 * Example: Initialize processor from file
 */
let initFromFile = async (filePath: string) => {
  // In a real application, you'd fetch the file contents
  // For example, using fetch in browser or Deno.readTextFile in Deno

  let ontologyContent = "..." // Load from file

  switch await initWithOntology(ontologyContent) {
  | Ok(processor) => {
      Js.log("✅ Processor initialized with ontology")
      Ok(processor)
    }
  | Error(e) => {
      Js.log2("❌ Failed to initialize processor:", errorToString(e))
      Error(e)
    }
  }
}

/**
 * Example: Working with glosses
 */
let displayConstructGlosses = async (processor: t, constructId: string) => {
  switch await processor->findConstruct(constructId) {
  | Ok(Some(construct)) => {
      if construct.glosses->Js.Array2.length > 0 {
        Js.log(`💡 Glosses for ${construct.label}:`)
        construct.glosses->Js.Array2.forEach(gloss => {
          Js.log(`  [${gloss.language}] ${gloss.text}`)
        })
      } else {
        Js.log(`⚠️  No glosses found for ${construct.label}`)
      }
    }
  | Ok(None) => Js.log(`⚠️  Construct not found: ${constructId}`)
  | Error(e) => Js.log2("❌ Error:", errorToString(e))
  }
}

// Export example functions for testing
let examples = {
  "loadAndQueryConstructs": loadAndQueryConstructs,
  "findConstructWithRelationships": findConstructWithRelationships,
  "initFromFile": initFromFile,
  "displayConstructGlosses": displayConstructGlosses,
}
