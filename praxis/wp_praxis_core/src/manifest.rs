// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Manifest data structures
//!
//! Represents a WP Praxis symbolic workflow manifest.
//! Supports YAML and TOML formats with embedded parsing (no network).

use crate::symbol::Symbol;
use std::collections::HashMap;

/// A WP Praxis manifest representing a symbolic workflow
#[derive(Debug, Clone, PartialEq)]
pub struct Manifest {
    /// Manifest name
    pub name: String,

    /// Manifest version (semantic versioning)
    pub version: String,

    /// Optional description
    pub description: Option<String>,

    /// Optional author
    pub author: Option<String>,

    /// Symbols defined in this manifest
    pub symbols: Vec<Symbol>,

    /// Optional metadata
    pub metadata: HashMap<String, String>,

    /// Optional tags for categorization
    pub tags: Vec<String>,

    /// Optional dependencies on other manifests
    pub dependencies: Vec<String>,
}

impl Manifest {
    /// Create a new manifest with the given name and version
    pub fn new(name: impl Into<String>, version: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            version: version.into(),
            description: None,
            author: None,
            symbols: Vec::new(),
            metadata: HashMap::new(),
            tags: Vec::new(),
            dependencies: Vec::new(),
        }
    }

    /// Parse a manifest from YAML string (offline, embedded parser)
    pub fn from_yaml(yaml: &str) -> Result<Self, crate::ParseError> {
        crate::parser::yaml::parse_yaml(yaml)
    }

    /// Parse a manifest from TOML string (offline, embedded parser)
    pub fn from_toml(toml: &str) -> Result<Self, crate::ParseError> {
        crate::parser::toml::parse_toml(toml)
    }

    /// Serialize manifest to YAML string
    pub fn to_yaml(&self) -> Result<String, crate::ParseError> {
        crate::parser::yaml::serialize_yaml(self)
    }

    /// Serialize manifest to TOML string
    pub fn to_toml(&self) -> Result<String, crate::ParseError> {
        crate::parser::toml::serialize_toml(self)
    }

    /// Add a symbol to the manifest
    pub fn add_symbol(&mut self, symbol: Symbol) {
        self.symbols.push(symbol);
    }

    /// Get all symbols of a specific type
    pub fn symbols_by_type(&self, symbol_type: crate::symbol::SymbolType) -> Vec<&Symbol> {
        self.symbols
            .iter()
            .filter(|s| s.symbol_type == symbol_type)
            .collect()
    }

    /// Get a symbol by name
    pub fn get_symbol(&self, name: &str) -> Option<&Symbol> {
        self.symbols.iter().find(|s| s.name == name)
    }

    /// Check if manifest has any symbols
    pub fn is_empty(&self) -> bool {
        self.symbols.is_empty()
    }

    /// Get the number of symbols
    pub fn len(&self) -> usize {
        self.symbols.len()
    }

    /// Add metadata
    pub fn add_metadata(&mut self, key: impl Into<String>, value: impl Into<String>) {
        self.metadata.insert(key.into(), value.into());
    }

    /// Add a tag
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        self.tags.push(tag.into());
    }

    /// Add a dependency
    pub fn add_dependency(&mut self, dep: impl Into<String>) {
        self.dependencies.push(dep.into());
    }
}

impl Default for Manifest {
    fn default() -> Self {
        Self::new("untitled", "0.0.0")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::symbol::{Operation, SymbolType};

    #[test]
    fn test_new_manifest() {
        let manifest = Manifest::new("test", "1.0.0");
        assert_eq!(manifest.name, "test");
        assert_eq!(manifest.version, "1.0.0");
        assert!(manifest.is_empty());
    }

    #[test]
    fn test_add_symbol() {
        let mut manifest = Manifest::new("test", "1.0.0");
        let symbol = Symbol::new("test_symbol", SymbolType::Option, Operation::Set);
        manifest.add_symbol(symbol);
        assert_eq!(manifest.len(), 1);
    }

    #[test]
    fn test_metadata() {
        let mut manifest = Manifest::new("test", "1.0.0");
        manifest.add_metadata("key", "value");
        assert_eq!(manifest.metadata.get("key"), Some(&"value".to_string()));
    }

    #[test]
    fn test_tags() {
        let mut manifest = Manifest::new("test", "1.0.0");
        manifest.add_tag("wordpress");
        manifest.add_tag("automation");
        assert_eq!(manifest.tags.len(), 2);
    }
}
