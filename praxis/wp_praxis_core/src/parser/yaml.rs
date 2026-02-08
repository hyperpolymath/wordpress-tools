// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Simple embedded YAML parser (offline-capable)
//!
//! This is a minimal YAML parser for common WP Praxis manifests.
//! It handles the subset of YAML we use most frequently without
//! requiring external dependencies.

use crate::{Manifest, Symbol, SymbolType, Operation, ParseError};

/// Parse YAML into a Manifest (embedded parser, zero dependencies)
pub fn parse_yaml(yaml: &str) -> Result<Manifest, ParseError> {
    let mut lines = yaml.lines().peekable();
    let mut manifest = Manifest::default();
    let mut current_section = Section::Root;
    let mut current_symbol: Option<Symbol> = None;
    let mut symbols: Vec<Symbol> = Vec::new();

    while let Some(line) = lines.next() {
        let trimmed = line.trim();

        // Skip comments and empty lines
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }

        // Detect indentation level
        let indent = line.len() - line.trim_start().len();

        // Check for list items with key-value
        if trimmed.starts_with("- ") && trimmed.contains(':') {
            // List item with inline key-value (e.g., "- name: test")
            let item_content = trimmed.trim_start_matches("- ");
            if let Some((key, value)) = split_key_value(item_content) {
                match current_section {
                    Section::Symbols if key == "name" => {
                        // Save previous symbol
                        if let Some(sym) = current_symbol.take() {
                            symbols.push(sym);
                        }
                        current_symbol = Some(Symbol::new(value, SymbolType::Option, Operation::Set));
                        current_section = Section::SymbolItem;
                    }
                    Section::Tags => {
                        manifest.add_tag(value);
                    }
                    Section::Dependencies => {
                        manifest.add_dependency(value);
                    }
                    _ => {}
                }
            }
        } else if let Some((key, value)) = split_key_value(trimmed) {
            // Regular key-value pairs
            match (indent, current_section) {
                (0, Section::Root) => {
                    // Top-level fields
                    match key {
                        "name" => manifest.name = value.to_string(),
                        "version" => manifest.version = value.to_string(),
                        "description" => manifest.description = Some(value.to_string()),
                        "author" => manifest.author = Some(value.to_string()),
                        "symbols" => current_section = Section::Symbols,
                        "metadata" => current_section = Section::Metadata,
                        "tags" => current_section = Section::Tags,
                        "dependencies" => current_section = Section::Dependencies,
                        _ => {}
                    }
                }
                (_, Section::SymbolItem) if indent >= 4 => {
                    // Symbol field within a list item
                    if let Some(ref mut sym) = current_symbol {
                        match key {
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
                            "name" => {} // Already handled
                            _ => {
                                sym.parameters.insert(key.to_string(), value.to_string());
                            }
                        }
                    }
                }
                (_, Section::Metadata) if indent >= 2 => {
                    manifest.add_metadata(key, value);
                }
                _ => {}
            }
        } else if trimmed.starts_with("- ") {
            // Plain list item
            let item = trimmed.trim_start_matches("- ").trim();
            match current_section {
                Section::Tags => {
                    manifest.add_tag(item);
                }
                Section::Dependencies => {
                    manifest.add_dependency(item);
                }
                _ => {}
            }
        } else if trimmed == "symbols:" {
            current_section = Section::Symbols;
        } else if trimmed == "metadata:" {
            current_section = Section::Metadata;
        } else if trimmed == "tags:" {
            current_section = Section::Tags;
        } else if trimmed == "dependencies:" {
            current_section = Section::Dependencies;
        }
    }

    // Add last symbol if exists
    if let Some(sym) = current_symbol {
        symbols.push(sym);
    }

    manifest.symbols = symbols;

    // Validate required fields
    if manifest.name.is_empty() {
        return Err(ParseError::MissingField("name".to_string()));
    }
    if manifest.version.is_empty() {
        return Err(ParseError::MissingField("version".to_string()));
    }

    Ok(manifest)
}

/// Serialize a Manifest to YAML
pub fn serialize_yaml(manifest: &Manifest) -> Result<String, ParseError> {
    let mut output = String::new();

    output.push_str(&format!("name: {}\n", manifest.name));
    output.push_str(&format!("version: {}\n", manifest.version));

    if let Some(desc) = &manifest.description {
        output.push_str(&format!("description: {}\n", desc));
    }

    if let Some(author) = &manifest.author {
        output.push_str(&format!("author: {}\n", author));
    }

    if !manifest.tags.is_empty() {
        output.push_str("tags:\n");
        for tag in &manifest.tags {
            output.push_str(&format!("  - {}\n", tag));
        }
    }

    if !manifest.dependencies.is_empty() {
        output.push_str("dependencies:\n");
        for dep in &manifest.dependencies {
            output.push_str(&format!("  - {}\n", dep));
        }
    }

    if !manifest.metadata.is_empty() {
        output.push_str("metadata:\n");
        for (key, value) in &manifest.metadata {
            output.push_str(&format!("  {}: {}\n", key, value));
        }
    }

    if !manifest.symbols.is_empty() {
        output.push_str("symbols:\n");
        for symbol in &manifest.symbols {
            output.push_str(&format!("  - name: {}\n", symbol.name));
            output.push_str(&format!("    type: {}\n", symbol.symbol_type.as_str()));
            output.push_str(&format!("    operation: {}\n", symbol.operation.as_str()));

            if let Some(target) = &symbol.target {
                output.push_str(&format!("    target: {}\n", target));
            }
            if let Some(value) = &symbol.value {
                output.push_str(&format!("    value: {}\n", value));
            }
            if let Some(context) = &symbol.context {
                output.push_str(&format!("    context: {}\n", context));
            }

            for (key, value) in &symbol.parameters {
                output.push_str(&format!("    {}: {}\n", key, value));
            }
        }
    }

    Ok(output)
}

#[derive(Debug, Clone, Copy, PartialEq)]
enum Section {
    Root,
    Symbols,
    SymbolItem,
    Metadata,
    Tags,
    Dependencies,
}

fn split_key_value(line: &str) -> Option<(&str, &str)> {
    if let Some(pos) = line.find(':') {
        let key = line[..pos].trim();
        let value = line[pos + 1..].trim().trim_matches('"').trim_matches('\'');
        if !key.is_empty() {
            return Some((key, value));
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple_yaml() {
        let yaml = r#"
name: test
version: 1.0.0
description: Test manifest
symbols:
  - name: test_symbol
    type: option
    operation: set
    target: my_option
    value: test_value
"#;

        let manifest = parse_yaml(yaml).unwrap();
        assert_eq!(manifest.name, "test");
        assert_eq!(manifest.version, "1.0.0");
        assert_eq!(manifest.description, Some("Test manifest".to_string()));
        assert_eq!(manifest.symbols.len(), 1);
        assert_eq!(manifest.symbols[0].name, "test_symbol");
    }

    #[test]
    fn test_serialize_yaml() {
        let mut manifest = Manifest::new("test", "1.0.0");
        manifest.description = Some("Test".to_string());
        let symbol = Symbol::new("test_symbol", SymbolType::Option, Operation::Set)
            .with_target("my_option")
            .with_value("test_value");
        manifest.add_symbol(symbol);

        let yaml = serialize_yaml(&manifest).unwrap();
        assert!(yaml.contains("name: test"));
        assert!(yaml.contains("version: 1.0.0"));
        assert!(yaml.contains("test_symbol"));
    }

    #[test]
    fn test_roundtrip() {
        let original = r#"name: test
version: 1.0.0
symbols:
  - name: test_symbol
    type: option
    operation: set
"#;

        let manifest = parse_yaml(original).unwrap();
        let serialized = serialize_yaml(&manifest).unwrap();
        let reparsed = parse_yaml(&serialized).unwrap();

        assert_eq!(manifest.name, reparsed.name);
        assert_eq!(manifest.version, reparsed.version);
    }
}
