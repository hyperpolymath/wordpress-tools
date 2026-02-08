// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Symbol data structures and types
//!
//! Represents symbolic operations in WP Praxis workflows.

use std::collections::HashMap;

/// Type of symbol
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SymbolType {
    /// WordPress option
    Option,
    /// WordPress post meta
    PostMeta,
    /// WordPress user meta
    UserMeta,
    /// WordPress term meta
    TermMeta,
    /// Custom post type
    CustomPostType,
    /// Taxonomy
    Taxonomy,
    /// Plugin activation
    Plugin,
    /// Theme modification
    Theme,
    /// Database query
    Query,
    /// Custom action
    Action,
    /// Custom filter
    Filter,
}

impl SymbolType {
    /// Parse from string
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "option" => Some(Self::Option),
            "postmeta" | "post_meta" => Some(Self::PostMeta),
            "usermeta" | "user_meta" => Some(Self::UserMeta),
            "termmeta" | "term_meta" => Some(Self::TermMeta),
            "customposttype" | "custom_post_type" | "cpt" => Some(Self::CustomPostType),
            "taxonomy" | "tax" => Some(Self::Taxonomy),
            "plugin" => Some(Self::Plugin),
            "theme" => Some(Self::Theme),
            "query" => Some(Self::Query),
            "action" => Some(Self::Action),
            "filter" => Some(Self::Filter),
            _ => None,
        }
    }

    /// Convert to string
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Option => "option",
            Self::PostMeta => "post_meta",
            Self::UserMeta => "user_meta",
            Self::TermMeta => "term_meta",
            Self::CustomPostType => "custom_post_type",
            Self::Taxonomy => "taxonomy",
            Self::Plugin => "plugin",
            Self::Theme => "theme",
            Self::Query => "query",
            Self::Action => "action",
            Self::Filter => "filter",
        }
    }
}

/// Operation to perform on a symbol
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Operation {
    /// Set/create
    Set,
    /// Update/modify
    Update,
    /// Delete/remove
    Delete,
    /// Get/query
    Get,
    /// Register
    Register,
    /// Unregister
    Unregister,
    /// Activate
    Activate,
    /// Deactivate
    Deactivate,
}

impl Operation {
    /// Parse from string
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "set" | "create" => Some(Self::Set),
            "update" | "modify" => Some(Self::Update),
            "delete" | "remove" => Some(Self::Delete),
            "get" | "query" | "read" => Some(Self::Get),
            "register" => Some(Self::Register),
            "unregister" => Some(Self::Unregister),
            "activate" | "enable" => Some(Self::Activate),
            "deactivate" | "disable" => Some(Self::Deactivate),
            _ => None,
        }
    }

    /// Convert to string
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Set => "set",
            Self::Update => "update",
            Self::Delete => "delete",
            Self::Get => "get",
            Self::Register => "register",
            Self::Unregister => "unregister",
            Self::Activate => "activate",
            Self::Deactivate => "deactivate",
        }
    }

    /// Check if operation is destructive (requires rollback support)
    pub fn is_destructive(&self) -> bool {
        matches!(self, Self::Delete | Self::Unregister | Self::Deactivate)
    }

    /// Check if operation modifies state
    pub fn is_mutating(&self) -> bool {
        !matches!(self, Self::Get)
    }
}

/// A symbolic operation in a WP Praxis workflow
#[derive(Debug, Clone, PartialEq)]
pub struct Symbol {
    /// Symbol name (unique identifier)
    pub name: String,

    /// Type of symbol
    pub symbol_type: SymbolType,

    /// Operation to perform
    pub operation: Operation,

    /// Optional target (e.g., option name, post ID)
    pub target: Option<String>,

    /// Optional value (for set/update operations)
    pub value: Option<String>,

    /// Optional context/scope
    pub context: Option<String>,

    /// Optional parameters
    pub parameters: HashMap<String, String>,

    /// Optional tags
    pub tags: Vec<String>,

    /// Optional dependencies on other symbols
    pub dependencies: Vec<String>,

    /// Optional rollback strategy
    pub rollback: Option<RollbackStrategy>,
}

/// Rollback strategy for destructive operations
#[derive(Debug, Clone, PartialEq)]
pub enum RollbackStrategy {
    /// No rollback
    None,
    /// Store previous value
    StorePrevious,
    /// Create backup
    Backup,
    /// Custom rollback logic
    Custom(String),
}

impl Symbol {
    /// Create a new symbol
    pub fn new(
        name: impl Into<String>,
        symbol_type: SymbolType,
        operation: Operation,
    ) -> Self {
        Self {
            name: name.into(),
            symbol_type,
            operation,
            target: None,
            value: None,
            context: None,
            parameters: HashMap::new(),
            tags: Vec::new(),
            dependencies: Vec::new(),
            rollback: None,
        }
    }

    /// Set the target
    pub fn with_target(mut self, target: impl Into<String>) -> Self {
        self.target = Some(target.into());
        self
    }

    /// Set the value
    pub fn with_value(mut self, value: impl Into<String>) -> Self {
        self.value = Some(value.into());
        self
    }

    /// Set the context
    pub fn with_context(mut self, context: impl Into<String>) -> Self {
        self.context = Some(context.into());
        self
    }

    /// Add a parameter
    pub fn with_parameter(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.parameters.insert(key.into(), value.into());
        self
    }

    /// Add a tag
    pub fn with_tag(mut self, tag: impl Into<String>) -> Self {
        self.tags.push(tag.into());
        self
    }

    /// Add a dependency
    pub fn with_dependency(mut self, dep: impl Into<String>) -> Self {
        self.dependencies.push(dep.into());
        self
    }

    /// Set rollback strategy
    pub fn with_rollback(mut self, rollback: RollbackStrategy) -> Self {
        self.rollback = Some(rollback);
        self
    }

    /// Check if symbol requires rollback support
    pub fn needs_rollback(&self) -> bool {
        self.operation.is_destructive() && self.rollback != Some(RollbackStrategy::None)
    }

    /// Validate symbol consistency
    pub fn validate(&self) -> Result<(), String> {
        // Name must not be empty
        if self.name.is_empty() {
            return Err("Symbol name cannot be empty".to_string());
        }

        // Set/Update operations require a value
        if matches!(self.operation, Operation::Set | Operation::Update) && self.value.is_none() {
            return Err(format!("Symbol '{}' requires a value for {:?} operation", self.name, self.operation));
        }

        // Destructive operations should have rollback strategy
        if self.operation.is_destructive() && self.rollback.is_none() {
            return Err(format!("Symbol '{}' is destructive but has no rollback strategy", self.name));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_symbol_type_from_str() {
        assert_eq!(SymbolType::from_str("option"), Some(SymbolType::Option));
        assert_eq!(SymbolType::from_str("post_meta"), Some(SymbolType::PostMeta));
        assert_eq!(SymbolType::from_str("invalid"), None);
    }

    #[test]
    fn test_operation_from_str() {
        assert_eq!(Operation::from_str("set"), Some(Operation::Set));
        assert_eq!(Operation::from_str("delete"), Some(Operation::Delete));
        assert!(Operation::Delete.is_destructive());
        assert!(Operation::Set.is_mutating());
        assert!(!Operation::Get.is_mutating());
    }

    #[test]
    fn test_symbol_builder() {
        let symbol = Symbol::new("test", SymbolType::Option, Operation::Set)
            .with_target("my_option")
            .with_value("test_value")
            .with_tag("wordpress");

        assert_eq!(symbol.name, "test");
        assert_eq!(symbol.target, Some("my_option".to_string()));
        assert_eq!(symbol.value, Some("test_value".to_string()));
        assert_eq!(symbol.tags.len(), 1);
    }

    #[test]
    fn test_symbol_validation() {
        let valid_symbol = Symbol::new("test", SymbolType::Option, Operation::Set)
            .with_value("value");
        assert!(valid_symbol.validate().is_ok());

        let invalid_symbol = Symbol::new("test", SymbolType::Option, Operation::Set);
        assert!(invalid_symbol.validate().is_err());

        let destructive_symbol = Symbol::new("test", SymbolType::Option, Operation::Delete);
        assert!(destructive_symbol.validate().is_err()); // No rollback strategy
    }
}
