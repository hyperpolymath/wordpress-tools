// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Database features (optional, feature-gated)
//!
//! Only available with `full-stack` feature flag.
//! Enables persisting manifests to SQLite/MySQL databases.

#![cfg(feature = "full-stack")]

use crate::{Manifest, ParseError};

/// Database client for persisting manifests
pub struct Database {
    // Future: SQLx connection pool
}

impl Database {
    /// Create a new database client
    pub fn new() -> Self {
        Self {}
    }

    /// Save a manifest to the database
    pub async fn save_manifest(&self, _manifest: &Manifest) -> Result<(), ParseError> {
        // Placeholder - would use sqlx when fully implemented
        Err(ParseError::IoError("Database features not yet implemented".to_string()))
    }

    /// Load a manifest from the database
    pub async fn load_manifest(&self, _id: &str) -> Result<Manifest, ParseError> {
        // Placeholder - would use sqlx when fully implemented
        Err(ParseError::IoError("Database features not yet implemented".to_string()))
    }
}

impl Default for Database {
    fn default() -> Self {
        Self::new()
    }
}
