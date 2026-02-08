// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Simple embedded TOML parser (offline-capable)
//!
//! This is a minimal TOML parser for common WP Praxis manifests.

use crate::{Manifest, Symbol, SymbolType, Operation, ParseError};

/// Parse TOML into a Manifest (embedded parser)
pub fn parse_toml(toml: &str) -> Result<Manifest, ParseError> {
    let mut manifest = Manifest::default();
    let mut lines = toml.lines().peekable();
    let mut current_section = Section::Root;
    let mut current_symbol: Option<Symbol> = None;
    let mut symbols: Vec<Symbol> = Vec::new();

    while let Some(line) = lines.next() {
        let trimmed = line.trim();

        // Skip comments and empty lines
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }

        // Section headers
        if trimmed.starts_with("[[") && trimmed.ends_with("]]") {
            let section_name = trimmed.trim_matches('[').trim_matches(']').trim();
            if section_name == "symbols" {
                // Save previous symbol
                if let Some(sym) = current_symbol.take() {
                    symbols.push(sym);
                }
                current_section = Section::Symbols;
                current_symbol = Some(Symbol::new("", SymbolType::Option, Operation::Set));
            }
        } else if trimmed.starts_with('[') && trimmed.ends_with(']') {
            let section_name = trimmed.trim_matches('[').trim_matches(']').trim();
            current_section = match section_name {
                "metadata" => Section::Metadata,
                _ => Section::Root,
            };
        } else if let Some((key, value)) = split_toml_key_value(trimmed) {
            // Key-value pairs
            match current_section {
                Section::Root => {
                    match key {
                        "name" => manifest.name = value.to_string(),
                        "version" => manifest.version = value.to_string(),
                        "description" => manifest.description = Some(value.to_string()),
                        "author" => manifest.author = Some(value.to_string()),
                        "tags" => {
                            if let Some(tags) = parse_toml_array(value) {
                                manifest.tags = tags;
                            }
                        }
                        "dependencies" => {
                            if let Some(deps) = parse_toml_array(value) {
                                manifest.dependencies = deps;
                            }
                        }
                        _ => {}
                    }
                }
                Section::Symbols => {
                    if let Some(ref mut sym) = current_symbol {
                        match key {
                            "name" => sym.name = value.to_string(),
                            "type" => {
                                if let Some(st) = SymbolType::from_str(value) {
                                    sym.symbol_type = st;
                                }
                            }
                            "operation" => {
                                if let Some(op) = Operation::from_str(value) {
                                    sym.operation = op;
                                }
                            }
                            "target" => sym.target = Some(value.to_string()),
                            "value" => sym.value = Some(value.to_string()),
                            "context" => sym.context = Some(value.to_string()),
                            "tags" => {
                                if let Some(tags) = parse_toml_array(value) {
                                    sym.tags = tags;
                                }
                            }
                            "dependencies" => {
                                if let Some(deps) = parse_toml_array(value) {
                                    sym.dependencies = deps;
                                }
                            }
                            _ => {
                                sym.parameters.insert(key.to_string(), value.to_string());
                            }
                        }
                    }
                }
                Section::Metadata => {
                    manifest.add_metadata(key, value);
                }
            }
        }
    }

    // Add last symbol if exists
    if let Some(sym) = current_symbol {
        symbols.push(sym);
    }

    manifest.symbols = symbols;

    // Validate
    if manifest.name.is_empty() {
        return Err(ParseError::MissingField("name".to_string()));
    }
    if manifest.version.is_empty() {
        return Err(ParseError::MissingField("version".to_string()));
    }

    Ok(manifest)
}

/// Serialize a Manifest to TOML
pub fn serialize_toml(manifest: &Manifest) -> Result<String, ParseError> {
    let mut output = String::new();

    output.push_str(&format!("name = \"{}\"\n", manifest.name));
    output.push_str(&format!("version = \"{}\"\n", manifest.version));

    if let Some(desc) = &manifest.description {
        output.push_str(&format!("description = \"{}\"\n", desc));
    }

    if let Some(author) = &manifest.author {
        output.push_str(&format!("author = \"{}\"\n", author));
    }

    if !manifest.tags.is_empty() {
        output.push_str(&format!("tags = [{}]\n",
            manifest.tags.iter().map(|t| format!("\"{}\"", t)).collect::<Vec<_>>().join(", ")));
    }

    if !manifest.dependencies.is_empty() {
        output.push_str(&format!("dependencies = [{}]\n",
            manifest.dependencies.iter().map(|d| format!("\"{}\"", d)).collect::<Vec<_>>().join(", ")));
    }

    if !manifest.metadata.is_empty() {
        output.push_str("\n[metadata]\n");
        for (key, value) in &manifest.metadata {
            output.push_str(&format!("{} = \"{}\"\n", key, value));
        }
    }

    for symbol in &manifest.symbols {
        output.push_str("\n[[symbols]]\n");
        output.push_str(&format!("name = \"{}\"\n", symbol.name));
        output.push_str(&format!("type = \"{}\"\n", symbol.symbol_type.as_str()));
        output.push_str(&format!("operation = \"{}\"\n", symbol.operation.as_str()));

        if let Some(target) = &symbol.target {
            output.push_str(&format!("target = \"{}\"\n", target));
        }
        if let Some(value) = &symbol.value {
            output.push_str(&format!("value = \"{}\"\n", value));
        }
        if let Some(context) = &symbol.context {
            output.push_str(&format!("context = \"{}\"\n", context));
        }

        if !symbol.tags.is_empty() {
            output.push_str(&format!("tags = [{}]\n",
                symbol.tags.iter().map(|t| format!("\"{}\"", t)).collect::<Vec<_>>().join(", ")));
        }

        for (key, value) in &symbol.parameters {
            output.push_str(&format!("{} = \"{}\"\n", key, value));
        }
    }

    Ok(output)
}

#[derive(Debug, Clone, Copy, PartialEq)]
enum Section {
    Root,
    Symbols,
    Metadata,
}

fn split_toml_key_value(line: &str) -> Option<(&str, &str)> {
    if let Some(pos) = line.find('=') {
        let key = line[..pos].trim();
        let value = line[pos + 1..].trim().trim_matches('"').trim_matches('\'');
        if !key.is_empty() {
            return Some((key, value));
        }
    }
    None
}

fn parse_toml_array(value: &str) -> Option<Vec<String>> {
    if value.starts_with('[') && value.ends_with(']') {
        let content = value.trim_matches('[').trim_matches(']');
        let items: Vec<String> = content
            .split(',')
            .map(|s| s.trim().trim_matches('"').trim_matches('\'').to_string())
            .filter(|s| !s.is_empty())
            .collect();
        Some(items)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_toml() {
        let toml = r#"
name = "test"
version = "1.0.0"
description = "Test manifest"
tags = ["wordpress", "automation"]

[[symbols]]
name = "test_symbol"
type = "option"
operation = "set"
target = "my_option"
value = "test_value"
"#;

        let manifest = parse_toml(toml).unwrap();
        assert_eq!(manifest.name, "test");
        assert_eq!(manifest.version, "1.0.0");
        assert_eq!(manifest.symbols.len(), 1);
        assert_eq!(manifest.symbols[0].name, "test_symbol");
        assert_eq!(manifest.tags.len(), 2);
    }

    #[test]
    fn test_serialize_toml() {
        let mut manifest = Manifest::new("test", "1.0.0");
        manifest.description = Some("Test".to_string());
        let symbol = Symbol::new("test_symbol", SymbolType::Option, Operation::Set)
            .with_target("my_option")
            .with_value("test_value");
        manifest.add_symbol(symbol);

        let toml = serialize_toml(&manifest).unwrap();
        assert!(toml.contains("name = \"test\""));
        assert!(toml.contains("version = \"1.0.0\""));
        assert!(toml.contains("test_symbol"));
    }

    #[test]
    fn test_parse_toml_array() {
        let array = "[\"tag1\", \"tag2\", \"tag3\"]";
        let result = parse_toml_array(array).unwrap();
        assert_eq!(result.len(), 3);
        assert_eq!(result[0], "tag1");
    }
}
