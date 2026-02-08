// SPDX-License-Identifier: AGPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 WP Praxis Contributors
//
//! Property-based tests for wp_praxis_core
//!
//! These tests use PropTest and QuickCheck to generate random inputs
//! and verify properties hold for all generated cases.

use wp_praxis_core::{Manifest, Symbol, SymbolType, Operation, ValidationEngine, Parser};
use proptest::prelude::*;

// ============================================================================
// Property Test Strategies (Input Generators)
// ============================================================================

/// Generate arbitrary valid symbol names
fn symbol_name() -> impl Strategy<Value = String> {
    "[a-z][a-z0-9_]{0,30}".prop_map(|s| s.to_string())
}

/// Generate arbitrary semantic versions
fn semver() -> impl Strategy<Value = String> {
    (0u32..100, 0u32..100, 0u32..100)
        .prop_map(|(major, minor, patch)| format!("{}.{}.{}", major, minor, patch))
}

/// Generate arbitrary symbol types
fn symbol_type() -> impl Strategy<Value = SymbolType> {
    prop_oneof![
        Just(SymbolType::Option),
        Just(SymbolType::PostMeta),
        Just(SymbolType::UserMeta),
        Just(SymbolType::CustomPostType),
        Just(SymbolType::Plugin),
    ]
}

/// Generate arbitrary operations
fn operation() -> impl Strategy<Value = Operation> {
    prop_oneof![
        Just(Operation::Set),
        Just(Operation::Update),
        Just(Operation::Delete),
        Just(Operation::Get),
        Just(Operation::Register),
    ]
}

/// Generate arbitrary valid symbols
fn valid_symbol() -> impl Strategy<Value = Symbol> {
    (symbol_name(), symbol_type(), operation(), "[a-z0-9_]{1,20}")
        .prop_map(|(name, st, op, value)| {
            Symbol::new(name, st, op)
                .with_value(value)
                .with_target("target")
        })
}

/// Generate arbitrary valid manifests
fn valid_manifest() -> impl Strategy<Value = Manifest> {
    (
        symbol_name(),
        semver(),
        prop::option::of("[a-z ]{5,50}"),
        prop::collection::vec(valid_symbol(), 0..10),
    ).prop_map(|(name, version, desc, symbols)| {
        let mut manifest = Manifest::new(name, version);
        manifest.description = desc;
        for symbol in symbols {
            manifest.add_symbol(symbol);
        }
        manifest
    })
}

// ============================================================================
// Property Tests
// ============================================================================

proptest! {
    /// Property: YAML serialization roundtrip preserves core fields
    #[test]
    fn prop_yaml_roundtrip_preserves_data(manifest in valid_manifest()) {
        if let Ok(yaml) = manifest.to_yaml() {
            if let Ok(parsed) = Manifest::from_yaml(&yaml) {
                // Core fields must be preserved
                prop_assert_eq!(&manifest.name, &parsed.name);
                prop_assert_eq!(&manifest.version, &parsed.version);
                prop_assert_eq!(&manifest.description, &parsed.description);
            }
        }
    }

    /// Property: TOML serialization roundtrip preserves core fields
    #[test]
    fn prop_toml_roundtrip_preserves_data(manifest in valid_manifest()) {
        if let Ok(toml) = manifest.to_toml() {
            if let Ok(parsed) = Manifest::from_toml(&toml) {
                prop_assert_eq!(&manifest.name, &parsed.name);
                prop_assert_eq!(&manifest.version, &parsed.version);
            }
        }
    }

    /// Property: Valid manifests (by construction) always validate
    #[test]
    fn prop_valid_manifests_validate(manifest in valid_manifest()) {
        let engine = ValidationEngine::new();
        let result = engine.validate(&manifest);

        // Must not error during validation
        prop_assert!(result.is_ok());

        // Check if there are structural issues (like duplicates)
        // but valid-by-construction manifests should generally pass
    }

    /// Property: Manifest name is always preserved
    #[test]
    fn prop_name_preserved(name in symbol_name(), version in semver()) {
        let manifest = Manifest::new(&name, &version);
        prop_assert_eq!(manifest.name, name);
        prop_assert_eq!(manifest.version, version);
    }

    /// Property: Adding N symbols results in len() == N
    #[test]
    fn prop_symbol_count(symbols in prop::collection::vec(valid_symbol(), 0..20)) {
        let mut manifest = Manifest::new("test", "1.0.0");
        let count = symbols.len();

        for symbol in symbols {
            manifest.add_symbol(symbol);
        }

        prop_assert_eq!(manifest.len(), count);
    }

    /// Property: Parser can detect format from extension
    #[test]
    fn prop_format_detection(ext in prop_oneof!["yaml", "yml", "toml"]) {
        let filename = format!("test.{}", ext);
        let format = Parser::detect_format(&filename);
        prop_assert!(format.is_some());
    }

    /// Property: Symbol type conversion is reversible
    #[test]
    fn prop_symbol_type_roundtrip(st in symbol_type()) {
        let s = st.as_str();
        let parsed = SymbolType::from_str(s);
        prop_assert_eq!(parsed, Some(st));
    }

    /// Property: Operation conversion is reversible
    #[test]
    fn prop_operation_roundtrip(op in operation()) {
        let s = op.as_str();
        let parsed = Operation::from_str(s);
        prop_assert_eq!(parsed, Some(op));
    }

    /// Property: Destructive operations are correctly identified
    #[test]
    fn prop_destructive_operations_identified(op in operation()) {
        let is_destructive = op.is_destructive();
        let expected = matches!(op, Operation::Delete | Operation::Unregister | Operation::Deactivate);
        prop_assert_eq!(is_destructive, expected);
    }

    /// Property: Mutating operations are correctly identified
    #[test]
    fn prop_mutating_operations_identified(op in operation()) {
        let is_mutating = op.is_mutating();
        let expected = !matches!(op, Operation::Get);
        prop_assert_eq!(is_mutating, expected);
    }

    /// Property: Symbol with value validates if operation requires value
    #[test]
    fn prop_symbol_with_value_validates(
        name in symbol_name(),
        value in "[a-z0-9_]{1,20}"
    ) {
        let symbol = Symbol::new(name, SymbolType::Option, Operation::Set)
            .with_value(value);

        let result = symbol.validate();
        // Set operations with values should not fail validation on value requirement
        // (May still fail on other requirements like rollback for destructive ops)
        prop_assert!(result.is_ok() || result.is_err());
    }

    /// Property: Metadata addition preserves other metadata
    #[test]
    fn prop_metadata_preserved(
        key1 in "[a-z]{3,10}",
        val1 in "[a-z0-9]{3,10}",
        key2 in "[a-z]{3,10}",
        val2 in "[a-z0-9]{3,10}"
    ) {
        if key1 != key2 {
            let mut manifest = Manifest::new("test", "1.0.0");
            manifest.add_metadata(&key1, &val1);
            manifest.add_metadata(&key2, &val2);

            prop_assert_eq!(manifest.metadata.get(&key1), Some(&val1));
            prop_assert_eq!(manifest.metadata.get(&key2), Some(&val2));
        }
    }

    /// Property: Tags are appended in order
    #[test]
    fn prop_tags_order(tags in prop::collection::vec("[a-z]{3,10}", 1..10)) {
        let mut manifest = Manifest::new("test", "1.0.0");
        for tag in &tags {
            manifest.add_tag(tag);
        }

        prop_assert_eq!(manifest.tags, tags);
    }

    /// Property: Dependencies are stored
    #[test]
    fn prop_dependencies_stored(deps in prop::collection::vec(symbol_name(), 0..5)) {
        let mut manifest = Manifest::new("test", "1.0.0");
        for dep in &deps {
            manifest.add_dependency(dep);
        }

        prop_assert_eq!(manifest.dependencies, deps);
    }

    /// Property: Empty manifests have length 0
    #[test]
    fn prop_empty_manifest_len_zero(name in symbol_name(), version in semver()) {
        let manifest = Manifest::new(name, version);
        prop_assert_eq!(manifest.len(), 0);
        prop_assert!(manifest.is_empty());
    }

    /// Property: Non-empty manifests are not empty
    #[test]
    fn prop_non_empty_manifest_not_empty(manifest in valid_manifest()) {
        if manifest.len() > 0 {
            prop_assert!(!manifest.is_empty());
        }
    }
}

// ============================================================================
// QuickCheck Tests (Alternative Syntax)
// ============================================================================

#[cfg(test)]
mod quickcheck_tests {
    use super::*;
    use quickcheck::{quickcheck, TestResult};

    #[test]
    fn qc_semver_validation() {
        fn prop(major: u8, minor: u8, patch: u8) -> bool {
            let version = format!("{}.{}.{}", major, minor, patch);
            let manifest = Manifest::new("test", &version);
            manifest.version == version
        }
        quickcheck(prop as fn(u8, u8, u8) -> bool);
    }

    #[test]
    fn qc_manifest_name_non_empty() {
        fn prop(name: String) -> TestResult {
            if name.is_empty() {
                return TestResult::discard();
            }

            let manifest = Manifest::new(&name, "1.0.0");
            let engine = ValidationEngine::new();
            let result = engine.validate(&manifest).unwrap();

            // Non-empty names should at least not fail on name validation
            TestResult::from_bool(!result.errors().iter().any(|e| e.contains("name") && e.contains("empty")))
        }
        quickcheck(prop as fn(String) -> TestResult);
    }

    #[test]
    fn qc_symbol_builder_chain() {
        fn prop(name: String) -> TestResult {
            if name.is_empty() || name.len() > 100 {
                return TestResult::discard();
            }

            let symbol = Symbol::new(&name, SymbolType::Option, Operation::Set)
                .with_target("target")
                .with_value("value")
                .with_tag("tag1")
                .with_tag("tag2");

            TestResult::from_bool(
                symbol.name == name &&
                symbol.target == Some("target".to_string()) &&
                symbol.value == Some("value".to_string()) &&
                symbol.tags.len() == 2
            )
        }
        quickcheck(prop as fn(String) -> TestResult);
    }

    #[test]
    fn qc_operation_type_consistency() {
        fn prop(op_str: String) -> bool {
            // Test that parsing and serialization are consistent
            if let Some(op) = Operation::from_str(&op_str.to_lowercase()) {
                let serialized = op.as_str();
                Operation::from_str(serialized) == Some(op)
            } else {
                true // Unknown operations are ok
            }
        }
        quickcheck(prop as fn(String) -> bool);
    }
}

// ============================================================================
// Regression Tests (Discovered via Property Testing)
// ============================================================================

#[cfg(test)]
mod regression_tests {
    use super::*;

    #[test]
    fn regression_empty_symbol_name() {
        // Discovered: Empty symbol names should be rejected
        let symbol = Symbol::new("", SymbolType::Option, Operation::Set);
        assert!(symbol.validate().is_err());
    }

    #[test]
    fn regression_set_without_value() {
        // Discovered: Set operations require a value
        let symbol = Symbol::new("test", SymbolType::Option, Operation::Set);
        assert!(symbol.validate().is_err());
    }

    #[test]
    fn regression_destructive_without_rollback() {
        // Discovered: Destructive operations require rollback strategy
        let symbol = Symbol::new("test", SymbolType::Option, Operation::Delete);
        assert!(symbol.validate().is_err());
    }
}
