// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Manifest parsing (offline-capable)
//!
//! Provides embedded parsers for YAML and TOML manifests.
//! Zero network dependencies - all parsing is done locally.

pub mod yaml;
pub mod toml;

use std::fmt;

/// Parser for manifest formats
pub struct Parser;

impl Parser {
    /// Parse a manifest from a string, auto-detecting format
    pub fn parse(input: &str) -> Result<crate::Manifest, ParseError> {
        // Try YAML first (more common)
        if let Ok(manifest) = yaml::parse_yaml(input) {
            return Ok(manifest);
        }

        // Try TOML
        if let Ok(manifest) = toml::parse_toml(input) {
            return Ok(manifest);
        }

        Err(ParseError::UnknownFormat)
    }

    /// Detect format from file extension
    pub fn detect_format(filename: &str) -> Option<Format> {
        let lower = filename.to_lowercase();
        if lower.ends_with(".yaml") || lower.ends_with(".yml") {
            Some(Format::Yaml)
        } else if lower.ends_with(".toml") {
            Some(Format::Toml)
        } else {
            None
        }
    }
}

/// Supported manifest formats
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Format {
    /// YAML format
    Yaml,
    /// TOML format
    Toml,
}

/// Parse error
#[derive(Debug, Clone, PartialEq)]
pub enum ParseError {
    /// Invalid YAML syntax
    InvalidYaml(String),
    /// Invalid TOML syntax
    InvalidToml(String),
    /// Missing required field
    MissingField(String),
    /// Invalid field value
    InvalidValue(String),
    /// Unknown format
    UnknownFormat,
    /// IO error
    IoError(String),
}

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidYaml(msg) => write!(f, "Invalid YAML: {}", msg),
            Self::InvalidToml(msg) => write!(f, "Invalid TOML: {}", msg),
            Self::MissingField(field) => write!(f, "Missing required field: {}", field),
            Self::InvalidValue(msg) => write!(f, "Invalid value: {}", msg),
            Self::UnknownFormat => write!(f, "Unknown manifest format"),
            Self::IoError(msg) => write!(f, "IO error: {}", msg),
        }
    }
}

impl std::error::Error for ParseError {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_format() {
        assert_eq!(Parser::detect_format("test.yaml"), Some(Format::Yaml));
        assert_eq!(Parser::detect_format("test.yml"), Some(Format::Yaml));
        assert_eq!(Parser::detect_format("test.toml"), Some(Format::Toml));
        assert_eq!(Parser::detect_format("test.txt"), None);
    }
}
