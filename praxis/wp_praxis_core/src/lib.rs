// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors

//! WP Praxis Core — High-Assurance Symbolic Workflows.
//!
//! This crate provides the foundational engine for "Praxis" — a system 
//! for managing WordPress site logic through formally verified manifests.
//!
//! FEATURES:
//! - **Offline-First**: Zero network dependencies in the default configuration.
//! - **Formal Verification**: Critical logic paths are verified using `Kani`.
//! - **Modularity**: Support for optional `network` and `full-stack` (SQLx) backends.
//!
//! ARCHITECTURE:
//! 1. `manifest`: Definitive schema for site logic.
//! 2. `parser`: Ingests Nickel/YAML specifications.
//! 3. `symbol`: Represents atomic logic operations (Set, Option, Toggle).
//! 4. `validation`: Deterministic engine for ensuring manifest correctness.

#![deny(unsafe_code)]
#![warn(missing_docs)]

#![forbid(unsafe_code)]
pub mod manifest;
pub mod parser;
pub mod symbol;
pub mod validation;

// OPTIONAL MODULES: Enabled via feature gates for specific deployment environments.
#[cfg(feature = "network")]
pub mod network;

#[cfg(feature = "full-stack")]
pub mod database;

// KANI VERIFICATION: Formal proofs for correctness and safety.
#[cfg(kani)]
pub mod verification;

// RE-EXPORTS: Canonical types for consuming applications.
pub use manifest::Manifest;
pub use parser::{Parser, ParseError};
pub use symbol::{Symbol, SymbolType, Operation};
pub use validation::{ValidationEngine, ValidationResult};

/// The semantic version of the Praxis Core library.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
