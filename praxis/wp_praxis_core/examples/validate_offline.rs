// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Example: Validate a manifest completely offline
//!
//! This demonstrates the zero-dependency validation capability.

use wp_praxis_core::{Manifest, Symbol, SymbolType, Operation, ValidationEngine};

fn main() {
    println!("WP Praxis Core - Offline Validation Example");
    println!("============================================\n");

    // Create a manifest programmatically (no file I/O required)
    let mut manifest = Manifest::new("example-workflow", "1.0.0");
    manifest.description = Some("Example WordPress workflow".to_string());
    manifest.author = Some("WP Praxis Team".to_string());
    manifest.add_tag("wordpress");
    manifest.add_tag("automation");

    // Add some symbols
    let symbol1 = Symbol::new("set_site_title", SymbolType::Option, Operation::Set)
        .with_target("blogname")
        .with_value("My Awesome Site")
        .with_tag("configuration");

    let symbol2 = Symbol::new("update_description", SymbolType::Option, Operation::Update)
        .with_target("blogdescription")
        .with_value("Just another WordPress site")
        .with_dependency("set_site_title"); // Depends on symbol1

    manifest.add_symbol(symbol1);
    manifest.add_symbol(symbol2);

    // Validate the manifest (completely offline)
    let engine = ValidationEngine::new();
    match engine.validate(&manifest) {
        Ok(result) => {
            if result.is_valid {
                println!("✓ Manifest is VALID");
                println!("  - Name: {}", manifest.name);
                println!("  - Version: {}", manifest.version);
                println!("  - Symbols: {}", manifest.len());
            } else {
                println!("✗ Manifest is INVALID");
                for error in result.errors() {
                    println!("  ERROR: {}", error);
                }
            }

            if !result.warnings().is_empty() {
                println!("\nWarnings:");
                for warning in result.warnings() {
                    println!("  WARN: {}", warning);
                }
            }
        }
        Err(e) => {
            eprintln!("Validation error: {}", e);
        }
    }

    // Serialize to YAML (offline)
    println!("\nGenerated YAML:");
    println!("===============");
    match manifest.to_yaml() {
        Ok(yaml) => println!("{}", yaml),
        Err(e) => eprintln!("Serialization error: {}", e),
    }

    // Serialize to TOML (offline)
    println!("\nGenerated TOML:");
    println!("===============");
    match manifest.to_toml() {
        Ok(toml) => println!("{}", toml),
        Err(e) => eprintln!("Serialization error: {}", e),
    }
}
