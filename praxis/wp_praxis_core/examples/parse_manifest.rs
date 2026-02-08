// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Example: Parse manifests from YAML and TOML
//!
//! Demonstrates offline parsing with embedded parsers.

use wp_praxis_core::{Manifest, ValidationEngine};

fn main() {
    println!("WP Praxis Core - Manifest Parsing Example");
    println!("==========================================\n");

    // Example YAML manifest
    let yaml_content = r#"
name: sample-workflow
version: 1.0.0
description: Sample WordPress workflow
author: WP Praxis Team
tags:
  - wordpress
  - automation
  - example

symbols:
  - name: set_site_title
    type: option
    operation: set
    target: blogname
    value: My Site Title

  - name: enable_comments
    type: option
    operation: update
    target: default_comment_status
    value: open

  - name: set_timezone
    type: option
    operation: set
    target: timezone_string
    value: America/New_York
"#;

    // Parse YAML
    println!("Parsing YAML manifest...");
    match Manifest::from_yaml(yaml_content) {
        Ok(manifest) => {
            println!("✓ Successfully parsed YAML");
            println!("  - Name: {}", manifest.name);
            println!("  - Version: {}", manifest.version);
            println!("  - Symbols: {}", manifest.len());

            // Validate
            let engine = ValidationEngine::new();
            if let Ok(result) = engine.validate(&manifest) {
                if result.is_valid {
                    println!("✓ Manifest is valid");
                } else {
                    println!("✗ Validation errors:");
                    for error in result.errors() {
                        println!("    - {}", error);
                    }
                }
            }
        }
        Err(e) => {
            eprintln!("✗ Failed to parse YAML: {}", e);
        }
    }

    println!("\n{}", "=".repeat(50));

    // Example TOML manifest
    let toml_content = r#"
name = "sample-workflow-toml"
version = "1.0.0"
description = "Sample WordPress workflow in TOML format"
author = "WP Praxis Team"
tags = ["wordpress", "automation", "toml"]

[[symbols]]
name = "set_site_title"
type = "option"
operation = "set"
target = "blogname"
value = "My TOML Site"

[[symbols]]
name = "disable_comments"
type = "option"
operation = "update"
target = "default_comment_status"
value = "closed"
"#;

    // Parse TOML
    println!("\nParsing TOML manifest...");
    match Manifest::from_toml(toml_content) {
        Ok(manifest) => {
            println!("✓ Successfully parsed TOML");
            println!("  - Name: {}", manifest.name);
            println!("  - Version: {}", manifest.version);
            println!("  - Symbols: {}", manifest.len());

            // Validate
            let engine = ValidationEngine::new();
            if let Ok(result) = engine.validate(&manifest) {
                if result.is_valid {
                    println!("✓ Manifest is valid");
                } else {
                    println!("✗ Validation errors:");
                    for error in result.errors() {
                        println!("    - {}", error);
                    }
                }
            }

            // Convert TOML to YAML
            println!("\nConverting TOML to YAML:");
            if let Ok(yaml) = manifest.to_yaml() {
                println!("{}", yaml);
            }
        }
        Err(e) => {
            eprintln!("✗ Failed to parse TOML: {}", e);
        }
    }
}
