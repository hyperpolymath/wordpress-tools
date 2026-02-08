// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Validation engine for manifests and symbols
//!
//! Validates semantic correctness of WP Praxis workflows.

use crate::Manifest;
use std::collections::{HashMap, HashSet};

/// Validation engine for manifests
pub struct ValidationEngine {
    /// Strict mode (fail on warnings)
    strict: bool,
}

impl ValidationEngine {
    /// Create a new validation engine
    pub fn new() -> Self {
        Self { strict: false }
    }

    /// Create a validation engine in strict mode
    pub fn strict() -> Self {
        Self { strict: true }
    }

    /// Validate a manifest
    pub fn validate(&self, manifest: &Manifest) -> Result<ValidationResult, ValidationError> {
        let mut result = ValidationResult {
            is_valid: true,
            errors: Vec::new(),
            warnings: Vec::new(),
        };

        // Validate manifest structure
        if manifest.name.is_empty() {
            result.add_error("Manifest name cannot be empty");
        }

        if manifest.version.is_empty() {
            result.add_error("Manifest version cannot be empty");
        } else if !is_valid_semver(&manifest.version) {
            result.add_warning("Manifest version should follow semantic versioning");
        }

        if manifest.symbols.is_empty() {
            result.add_warning("Manifest contains no symbols");
        }

        // Validate symbols
        for symbol in &manifest.symbols {
            if let Err(e) = symbol.validate() {
                result.add_error(&format!("Symbol '{}': {}", symbol.name, e));
            }
        }

        // Check for duplicate symbol names
        let mut seen_names: HashSet<String> = HashSet::new();
        for symbol in &manifest.symbols {
            if !seen_names.insert(symbol.name.clone()) {
                result.add_error(&format!("Duplicate symbol name: {}", symbol.name));
            }
        }

        // Validate dependencies
        if let Err(e) = self.validate_dependencies(manifest) {
            result.add_error(&format!("Dependency validation failed: {}", e));
        }

        // In strict mode, warnings become errors
        if self.strict && !result.warnings.is_empty() {
            result.is_valid = false;
        }

        // Mark as invalid if errors exist
        if !result.errors.is_empty() {
            result.is_valid = false;
        }

        Ok(result)
    }

    /// Validate symbol dependencies (DAG check)
    fn validate_dependencies(&self, manifest: &Manifest) -> Result<(), String> {
        let mut graph: HashMap<String, Vec<String>> = HashMap::new();

        // Build dependency graph
        for symbol in &manifest.symbols {
            graph.insert(symbol.name.clone(), symbol.dependencies.clone());
        }

        // Check for cycles using DFS
        let mut visited: HashSet<String> = HashSet::new();
        let mut rec_stack: HashSet<String> = HashSet::new();

        for symbol in &manifest.symbols {
            if !visited.contains(&symbol.name) {
                if self.has_cycle(&symbol.name, &graph, &mut visited, &mut rec_stack) {
                    return Err(format!("Circular dependency detected involving '{}'", symbol.name));
                }
            }
        }

        // Check for missing dependencies
        for symbol in &manifest.symbols {
            for dep in &symbol.dependencies {
                if !graph.contains_key(dep) {
                    return Err(format!("Symbol '{}' depends on non-existent symbol '{}'", symbol.name, dep));
                }
            }
        }

        Ok(())
    }

    /// Check for cycles in dependency graph using DFS
    fn has_cycle(
        &self,
        node: &str,
        graph: &HashMap<String, Vec<String>>,
        visited: &mut HashSet<String>,
        rec_stack: &mut HashSet<String>,
    ) -> bool {
        visited.insert(node.to_string());
        rec_stack.insert(node.to_string());

        if let Some(neighbors) = graph.get(node) {
            for neighbor in neighbors {
                if !visited.contains(neighbor) {
                    if self.has_cycle(neighbor, graph, visited, rec_stack) {
                        return true;
                    }
                } else if rec_stack.contains(neighbor) {
                    return true; // Back edge found - cycle detected
                }
            }
        }

        rec_stack.remove(node);
        false
    }
}

impl Default for ValidationEngine {
    fn default() -> Self {
        Self::new()
    }
}

/// Result of validation
#[derive(Debug, Clone, PartialEq)]
pub struct ValidationResult {
    /// Whether the manifest is valid
    pub is_valid: bool,
    /// Validation errors (critical issues)
    pub errors: Vec<String>,
    /// Validation warnings (non-critical issues)
    pub warnings: Vec<String>,
}

impl ValidationResult {
    /// Add an error
    fn add_error(&mut self, msg: &str) {
        self.errors.push(msg.to_string());
        self.is_valid = false;
    }

    /// Add a warning
    fn add_warning(&mut self, msg: &str) {
        self.warnings.push(msg.to_string());
    }

    /// Check if validation passed
    pub fn is_ok(&self) -> bool {
        self.is_valid
    }

    /// Get all errors
    pub fn errors(&self) -> &[String] {
        &self.errors
    }

    /// Get all warnings
    pub fn warnings(&self) -> &[String] {
        &self.warnings
    }
}

/// Validation error
#[derive(Debug, Clone, PartialEq)]
pub enum ValidationError {
    /// Internal validation error
    Internal(String),
}

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Internal(msg) => write!(f, "Validation error: {}", msg),
        }
    }
}

impl std::error::Error for ValidationError {}

/// Check if a version string follows semantic versioning
fn is_valid_semver(version: &str) -> bool {
    let parts: Vec<&str> = version.split('.').collect();
    if parts.len() != 3 {
        return false;
    }
    parts.iter().all(|p| p.parse::<u32>().is_ok())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{Symbol, SymbolType, Operation};

    #[test]
    fn test_validate_valid_manifest() {
        let mut manifest = Manifest::new("test", "1.0.0");
        let symbol = Symbol::new("test_symbol", SymbolType::Option, Operation::Set)
            .with_value("value");
        manifest.add_symbol(symbol);

        let engine = ValidationEngine::new();
        let result = engine.validate(&manifest).unwrap();
        assert!(result.is_valid);
        assert!(result.errors.is_empty());
    }

    #[test]
    fn test_validate_empty_name() {
        let manifest = Manifest::new("", "1.0.0");
        let engine = ValidationEngine::new();
        let result = engine.validate(&manifest).unwrap();
        assert!(!result.is_valid);
        assert!(!result.errors.is_empty());
    }

    #[test]
    fn test_validate_duplicate_symbols() {
        let mut manifest = Manifest::new("test", "1.0.0");
        let symbol1 = Symbol::new("duplicate", SymbolType::Option, Operation::Set)
            .with_value("value1");
        let symbol2 = Symbol::new("duplicate", SymbolType::Option, Operation::Set)
            .with_value("value2");
        manifest.add_symbol(symbol1);
        manifest.add_symbol(symbol2);

        let engine = ValidationEngine::new();
        let result = engine.validate(&manifest).unwrap();
        assert!(!result.is_valid);
        assert!(result.errors.iter().any(|e| e.contains("Duplicate")));
    }

    #[test]
    fn test_validate_circular_dependency() {
        let mut manifest = Manifest::new("test", "1.0.0");
        let symbol1 = Symbol::new("symbol1", SymbolType::Option, Operation::Set)
            .with_value("value")
            .with_dependency("symbol2");
        let symbol2 = Symbol::new("symbol2", SymbolType::Option, Operation::Set)
            .with_value("value")
            .with_dependency("symbol1");
        manifest.add_symbol(symbol1);
        manifest.add_symbol(symbol2);

        let engine = ValidationEngine::new();
        let result = engine.validate(&manifest).unwrap();
        assert!(!result.is_valid);
        assert!(result.errors.iter().any(|e| e.contains("Circular dependency")));
    }

    #[test]
    fn test_validate_missing_dependency() {
        let mut manifest = Manifest::new("test", "1.0.0");
        let symbol = Symbol::new("symbol1", SymbolType::Option, Operation::Set)
            .with_value("value")
            .with_dependency("nonexistent");
        manifest.add_symbol(symbol);

        let engine = ValidationEngine::new();
        let result = engine.validate(&manifest).unwrap();
        assert!(!result.is_valid);
        assert!(result.errors.iter().any(|e| e.contains("non-existent")));
    }

    #[test]
    fn test_semver_validation() {
        assert!(is_valid_semver("1.0.0"));
        assert!(is_valid_semver("0.1.0"));
        assert!(is_valid_semver("10.20.30"));
        assert!(!is_valid_semver("1.0"));
        assert!(!is_valid_semver("1.0.0.0"));
        assert!(!is_valid_semver("v1.0.0"));
    }
}
