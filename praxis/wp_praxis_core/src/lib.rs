// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! WP Praxis Core - Offline-capable symbolic workflow library
//!
//! This crate provides zero-dependency manifest parsing and validation
//! for WP Praxis symbolic workflows. It is designed to work completely
//! offline with no network dependencies in default configuration.
//!
//! # Features
//!
//! - `offline` (default): Zero network dependencies, embedded parsing
//! - `network`: Enable network features (HTTP clients, remote manifests)
//! - `full-stack`: Enable database features (SQLx, migrations)
//!
//! # Examples
//!
//! ```rust
//! use wp_praxis_core::{Manifest, ValidationEngine};
//!
//! // Parse a manifest from YAML string (fully offline)
//! let yaml = r#"
//! name: example
//! version: "1.0.0"
//! symbols:
//!   - name: test_symbol
//!     type: option
//!     operation: set
//! "#;
//!
//! let manifest = Manifest::from_yaml(yaml).unwrap();
//! let engine = ValidationEngine::new();
//! let result = engine.validate(&manifest).unwrap();
//! assert!(result.is_valid);
//! ```

#![deny(unsafe_code)]
#![warn(missing_docs)]
#![warn(clippy::all)]

pub mod manifest;
pub mod parser;
pub mod symbol;
pub mod validation;

#[cfg(feature = "network")]
pub mod network;

#[cfg(feature = "full-stack")]
pub mod database;

#[cfg(kani)]
pub mod verification;

// Re-exports for convenience
pub use manifest::Manifest;
pub use parser::{Parser, ParseError};
pub use symbol::{Symbol, SymbolType, Operation};
pub use validation::{ValidationEngine, ValidationResult, ValidationError};

#[cfg(feature = "network")]
pub use network::NetworkClient;

#[cfg(feature = "full-stack")]
pub use database::Database;

/// WP Praxis Core version
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Check if offline mode is enabled (default)
pub const fn is_offline() -> bool {
    cfg!(feature = "offline") && !cfg!(feature = "network")
}

/// Check if network features are enabled
pub const fn has_network() -> bool {
    cfg!(feature = "network")
}

/// Check if full-stack features are enabled
pub const fn has_full_stack() -> bool {
    cfg!(feature = "full-stack")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_version() {
        assert!(!VERSION.is_empty());
    }

    #[test]
    fn test_feature_flags() {
        // In default mode, should be offline-only
        #[cfg(all(feature = "offline", not(feature = "network")))]
        {
            assert!(is_offline());
            assert!(!has_network());
        }
    }
}
