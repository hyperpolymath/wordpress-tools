// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Network features (optional, feature-gated)
//!
//! Only available with `network` feature flag.
//! Enables fetching manifests from remote URLs.

#![cfg(feature = "network")]

use crate::{Manifest, ParseError};

/// Network client for fetching remote manifests
pub struct NetworkClient {
    // Future: HTTP client configuration
}

impl NetworkClient {
    /// Create a new network client
    pub fn new() -> Self {
        Self {}
    }

    /// Fetch a manifest from a URL
    pub async fn fetch_manifest(&self, _url: &str) -> Result<Manifest, ParseError> {
        // Placeholder - would use reqwest when fully implemented
        Err(ParseError::IoError("Network features not yet implemented".to_string()))
    }
}

impl Default for NetworkClient {
    fn default() -> Self {
        Self::new()
    }
}
