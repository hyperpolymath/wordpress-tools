//! Semantic Processor WASM Module
//!
//! This module provides RDF/OWL processing capabilities for the Sinople WordPress theme.
//! It uses Sophia 0.8 for in-memory RDF graph management and SPARQL-like querying.
//!
//! # Features
//! - Load and parse Turtle (TTL) format ontologies
//! - Query constructs, entanglements, and character relationships
//! - Find glosses and annotations
//! - Export semantic data for visualization
//!
//! # Usage
//! ```javascript
//! import { SemanticProcessor } from './pkg/semantic_processor.js';
//!
//! const processor = new SemanticProcessor();
//! await processor.load_turtle(ontologyTTL);
//! const constructs = await processor.query_constructs();
//! ```

use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use sophia_api::graph::Graph;
use sophia_api::term::{SimpleTerm, Term};
use sophia_inmem::graph::FastGraph;
use sophia_turtle::parser::turtle::TurtleParser;
use sophia_api::parser::TripleParser;
use std::collections::HashMap;

/// Initialize panic hook for better error messages in console
#[wasm_bindgen(start)]
pub fn init() {
    console_error_panic_hook::set_once();
}

/// Represents a Construct in the Sinople ontology
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Construct {
    pub id: String,
    pub label: String,
    pub description: Option<String>,
    pub glosses: Vec<Gloss>,
    pub relationships: Vec<String>,
}

/// Represents an Entanglement (relationship between constructs)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entanglement {
    pub id: String,
    pub label: String,
    pub source: String,
    pub target: String,
    pub relationship_type: String,
    pub description: Option<String>,
}

/// Represents a Gloss (annotation or explanation)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Gloss {
    pub id: String,
    pub text: String,
    pub language: String,
    pub position: Option<usize>,
}

/// Represents a Character in the semantic universe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Character {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub constructs: Vec<String>,
}

/// Network graph node for visualization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphNode {
    pub id: String,
    pub label: String,
    pub node_type: String,
}

/// Network graph edge for visualization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphEdge {
    pub source: String,
    pub target: String,
    pub label: String,
}

/// Network graph structure
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkGraph {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

/// Main Semantic Processor struct
///
/// Manages an in-memory RDF graph and provides query methods
#[wasm_bindgen]
pub struct SemanticProcessor {
    graph: FastGraph,
    namespaces: HashMap<String, String>,
}

#[wasm_bindgen]
impl SemanticProcessor {
    /// Create a new SemanticProcessor instance
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        let mut namespaces = HashMap::new();

        // Register common namespaces
        namespaces.insert("sn".to_string(), "https://sinople.org/ontology#".to_string());
        namespaces.insert("rdf".to_string(), "https://www.w3.org/1999/02/22-rdf-syntax-ns#".to_string());
        namespaces.insert("rdfs".to_string(), "https://www.w3.org/2000/01/rdf-schema#".to_string());
        namespaces.insert("owl".to_string(), "https://www.w3.org/2002/07/owl#".to_string());
        namespaces.insert("xsd".to_string(), "https://www.w3.org/2001/XMLSchema#".to_string());

        SemanticProcessor {
            graph: FastGraph::new(),
            namespaces,
        }
    }

    /// Load RDF data from Turtle format
    ///
    /// # Arguments
    /// * `ttl` - Turtle-formatted RDF string
    ///
    /// # Returns
    /// * `Ok(())` if successful
    /// * `Err(JsValue)` with error message if parsing fails
    pub fn load_turtle(&mut self, ttl: &str) -> Result<(), JsValue> {
        let parser = TurtleParser::new(ttl.as_bytes());

        parser
            .parse_all(&mut self.graph)
            .map_err(|e| JsValue::from_str(&format!("Failed to parse Turtle: {}", e)))?;

        Ok(())
    }

    /// Query all constructs from the graph
    ///
    /// # Returns
    /// JsValue containing array of Construct objects
    pub fn query_constructs(&self) -> Result<JsValue, JsValue> {
        let mut constructs = Vec::new();
        let construct_type = self.make_term("sn:Construct");
        let rdf_type = self.make_term("rdf:type");

        // Find all instances of sn:Construct
        for triple in self.graph.triples() {
            let triple = triple.map_err(|e| JsValue::from_str(&format!("Graph error: {}", e)))?;

            if self.term_equals(triple.p(), &rdf_type) && self.term_equals(triple.o(), &construct_type) {
                let subject_iri = self.term_to_string(triple.s());

                // Get properties
                let label = self.get_object_value(&subject_iri, "rdfs:label").unwrap_or_default();
                let description = self.get_object_value(&subject_iri, "rdfs:comment");
                let glosses = self.get_glosses(&subject_iri);
                let relationships = self.get_relationships(&subject_iri);

                constructs.push(Construct {
                    id: subject_iri.clone(),
                    label,
                    description,
                    glosses,
                    relationships,
                });
            }
        }

        serde_wasm_bindgen::to_value(&constructs)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    /// Query all entanglements from the graph
    ///
    /// # Returns
    /// JsValue containing array of Entanglement objects
    pub fn query_entanglements(&self) -> Result<JsValue, JsValue> {
        let mut entanglements = Vec::new();
        let entanglement_type = self.make_term("sn:Entanglement");
        let rdf_type = self.make_term("rdf:type");

        for triple in self.graph.triples() {
            let triple = triple.map_err(|e| JsValue::from_str(&format!("Graph error: {}", e)))?;

            if self.term_equals(triple.p(), &rdf_type) && self.term_equals(triple.o(), &entanglement_type) {
                let subject_iri = self.term_to_string(triple.s());

                let label = self.get_object_value(&subject_iri, "rdfs:label").unwrap_or_default();
                let description = self.get_object_value(&subject_iri, "rdfs:comment");
                let source = self.get_object_value(&subject_iri, "sn:hasSource").unwrap_or_default();
                let target = self.get_object_value(&subject_iri, "sn:hasTarget").unwrap_or_default();
                let rel_type = self.get_object_value(&subject_iri, "sn:relationshipType").unwrap_or_else(|| "related".to_string());

                entanglements.push(Entanglement {
                    id: subject_iri,
                    label,
                    source,
                    target,
                    relationship_type: rel_type,
                    description,
                });
            }
        }

        serde_wasm_bindgen::to_value(&entanglements)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    /// Find relationships for a specific construct
    ///
    /// # Arguments
    /// * `construct_id` - IRI of the construct
    ///
    /// # Returns
    /// JsValue containing array of related construct IRIs
    pub fn find_relationships(&self, construct_id: &str) -> Result<JsValue, JsValue> {
        let relationships = self.get_relationships(construct_id);

        serde_wasm_bindgen::to_value(&relationships)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    /// Query all characters from the graph
    ///
    /// # Returns
    /// JsValue containing array of Character objects
    pub fn query_characters(&self) -> Result<JsValue, JsValue> {
        let mut characters = Vec::new();
        let character_type = self.make_term("sn:Character");
        let rdf_type = self.make_term("rdf:type");

        for triple in self.graph.triples() {
            let triple = triple.map_err(|e| JsValue::from_str(&format!("Graph error: {}", e)))?;

            if self.term_equals(triple.p(), &rdf_type) && self.term_equals(triple.o(), &character_type) {
                let subject_iri = self.term_to_string(triple.s());

                let name = self.get_object_value(&subject_iri, "rdfs:label").unwrap_or_default();
                let description = self.get_object_value(&subject_iri, "rdfs:comment");
                let constructs = self.get_character_constructs(&subject_iri);

                characters.push(Character {
                    id: subject_iri,
                    name,
                    description,
                    constructs,
                });
            }
        }

        serde_wasm_bindgen::to_value(&characters)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    /// Generate a network graph for visualization
    ///
    /// # Returns
    /// JsValue containing NetworkGraph with nodes and edges
    pub fn generate_network_graph(&self) -> Result<JsValue, JsValue> {
        let mut nodes = Vec::new();
        let mut edges = Vec::new();
        let rdf_type = self.make_term("rdf:type");

        // Collect all nodes (constructs and characters)
        for triple in self.graph.triples() {
            let triple = triple.map_err(|e| JsValue::from_str(&format!("Graph error: {}", e)))?;

            if self.term_equals(triple.p(), &rdf_type) {
                let subject_iri = self.term_to_string(triple.s());
                let object_iri = self.term_to_string(triple.o());
                let label = self.get_object_value(&subject_iri, "rdfs:label")
                    .unwrap_or_else(|| self.extract_local_name(&subject_iri));

                let node_type = if object_iri.contains("Construct") {
                    "construct"
                } else if object_iri.contains("Character") {
                    "character"
                } else if object_iri.contains("Entanglement") {
                    "entanglement"
                } else {
                    "other"
                };

                nodes.push(GraphNode {
                    id: subject_iri.clone(),
                    label,
                    node_type: node_type.to_string(),
                });
            }
        }

        // Collect all edges (relationships)
        let entanglement_type = self.make_term("sn:Entanglement");

        for triple in self.graph.triples() {
            let triple = triple.map_err(|e| JsValue::from_str(&format!("Graph error: {}", e)))?;

            if self.term_equals(triple.p(), &rdf_type) && self.term_equals(triple.o(), &entanglement_type) {
                let entanglement_iri = self.term_to_string(triple.s());

                if let (Some(source), Some(target)) = (
                    self.get_object_value(&entanglement_iri, "sn:hasSource"),
                    self.get_object_value(&entanglement_iri, "sn:hasTarget")
                ) {
                    let label = self.get_object_value(&entanglement_iri, "sn:relationshipType")
                        .unwrap_or_else(|| "related".to_string());

                    edges.push(GraphEdge {
                        source,
                        target,
                        label,
                    });
                }
            }
        }

        let graph = NetworkGraph { nodes, edges };

        serde_wasm_bindgen::to_value(&graph)
            .map_err(|e| JsValue::from_str(&format!("Serialization error: {}", e)))
    }

    /// Get the number of triples in the graph
    pub fn triple_count(&self) -> usize {
        self.graph.triples().count()
    }

    /// Clear all data from the graph
    pub fn clear(&mut self) {
        self.graph = FastGraph::new();
    }
}

// Private helper methods
impl SemanticProcessor {
    /// Get object value for a subject-predicate pair
    fn get_object_value(&self, subject: &str, predicate: &str) -> Option<String> {
        let subject_term = SimpleTerm::Iri(subject.parse().ok()?);
        let predicate_term = self.make_term(predicate);

        for triple in self.graph.triples() {
            if let Ok(triple) = triple {
                if self.term_equals(triple.s(), &subject_term) &&
                   self.term_equals(triple.p(), &predicate_term) {
                    return Some(self.term_to_string(triple.o()));
                }
            }
        }
        None
    }

    /// Get all glosses for a construct
    fn get_glosses(&self, construct_id: &str) -> Vec<Gloss> {
        let mut glosses = Vec::new();
        let subject_term = SimpleTerm::Iri(construct_id.parse().unwrap_or_else(|_| "".parse().unwrap()));
        let has_gloss = self.make_term("sn:hasGloss");

        for triple in self.graph.triples() {
            if let Ok(triple) = triple {
                if self.term_equals(triple.s(), &subject_term) &&
                   self.term_equals(triple.p(), &has_gloss) {
                    glosses.push(Gloss {
                        id: format!("{}#gloss", construct_id),
                        text: self.term_to_string(triple.o()),
                        language: "en".to_string(),
                        position: None,
                    });
                }
            }
        }
        glosses
    }

    /// Get all relationships for a construct
    fn get_relationships(&self, construct_id: &str) -> Vec<String> {
        let mut relationships = Vec::new();
        let has_source = self.make_term("sn:hasSource");
        let has_target = self.make_term("sn:hasTarget");

        for triple in self.graph.triples() {
            if let Ok(triple) = triple {
                let object_str = self.term_to_string(triple.o());

                if object_str == construct_id {
                    if self.term_equals(triple.p(), &has_source) ||
                       self.term_equals(triple.p(), &has_target) {
                        relationships.push(self.term_to_string(triple.s()));
                    }
                }
            }
        }
        relationships
    }

    /// Get constructs associated with a character
    fn get_character_constructs(&self, character_id: &str) -> Vec<String> {
        let mut constructs = Vec::new();
        let subject_term = SimpleTerm::Iri(character_id.parse().unwrap_or_else(|_| "".parse().unwrap()));
        let has_construct = self.make_term("sn:hasConstruct");

        for triple in self.graph.triples() {
            if let Ok(triple) = triple {
                if self.term_equals(triple.s(), &subject_term) &&
                   self.term_equals(triple.p(), &has_construct) {
                    constructs.push(self.term_to_string(triple.o()));
                }
            }
        }
        constructs
    }

    /// Create a SimpleTerm from a namespaced string (e.g., "sn:Construct")
    fn make_term(&self, namespaced: &str) -> SimpleTerm<'static> {
        if let Some((prefix, local)) = namespaced.split_once(':') {
            if let Some(namespace) = self.namespaces.get(prefix) {
                let iri = format!("{}{}", namespace, local);
                return SimpleTerm::Iri(iri.parse().unwrap_or_else(|_| "".parse().unwrap()));
            }
        }
        // Fallback: treat as full IRI
        SimpleTerm::Iri(namespaced.parse().unwrap_or_else(|_| "".parse().unwrap()))
    }

    /// Convert a Term to String
    /// Note: SimpleTerm in Sophia 0.8 doesn't have .value(), must convert manually
    fn term_to_string<T>(&self, term: &T) -> String
    where
        T: Term,
    {
        match SimpleTerm::from_term(term) {
            SimpleTerm::Iri(iri) => iri.to_string(),
            SimpleTerm::LiteralDatatype(lit, _) => lit.to_string(),
            SimpleTerm::LiteralLanguage(lit, _) => lit.to_string(),
            SimpleTerm::BlankNode(bn) => format!("_:{}", bn),
            _ => String::new(),
        }
    }

    /// Check if two terms are equal
    fn term_equals<T1, T2>(&self, term1: &T1, term2: &T2) -> bool
    where
        T1: Term,
        T2: Term,
    {
        SimpleTerm::from_term(term1) == SimpleTerm::from_term(term2)
    }

    /// Extract local name from IRI
    fn extract_local_name(&self, iri: &str) -> String {
        iri.split('#')
            .last()
            .or_else(|| iri.split('/').last())
            .unwrap_or(iri)
            .to_string()
    }
}

impl Default for SemanticProcessor {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_processor_creation() {
        let processor = SemanticProcessor::new();
        assert_eq!(processor.triple_count(), 0);
    }

    #[test]
    fn test_load_simple_turtle() {
        let mut processor = SemanticProcessor::new();
        let ttl = r#"
            @prefix sn: <https://sinople.org/ontology#> .
            @prefix rdfs: <https://www.w3.org/2000/01/rdf-schema#> .

            <https://example.org/test> a sn:Construct ;
                rdfs:label "Test Construct" .
        "#;

        assert!(processor.load_turtle(ttl).is_ok());
        assert!(processor.triple_count() > 0);
    }
}
