// Unit tests for WP Praxis Injector

use wp_injector::*;
use std::collections::HashMap;

#[cfg(test)]
mod symbol_tests {
    use super::*;

    #[test]
    fn test_create_action_symbol() {
        let symbol = Symbol {
            name: "test_action".to_string(),
            symbol_type: SymbolType::Action,
            context: "wordpress".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        assert_eq!(symbol.name, "test_action");
        assert_eq!(symbol.symbol_type, SymbolType::Action);
        assert_eq!(symbol.context, "wordpress");
    }

    #[test]
    fn test_create_query_symbol() {
        let symbol = Symbol {
            name: "test_query".to_string(),
            symbol_type: SymbolType::Query,
            context: "database".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        assert_eq!(symbol.symbol_type, SymbolType::Query);
    }

    #[test]
    fn test_symbol_with_parameters() {
        let mut params = HashMap::new();
        params.insert("key1".to_string(), "value1".to_string());
        params.insert("key2".to_string(), "value2".to_string());

        let symbol = Symbol {
            name: "parameterized_symbol".to_string(),
            symbol_type: SymbolType::Transform,
            context: "data".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: params,
        };

        assert_eq!(symbol.parameters.len(), 2);
        assert_eq!(symbol.parameters.get("key1"), Some(&"value1".to_string()));
    }

    #[test]
    fn test_symbol_serialization() {
        let symbol = Symbol {
            name: "serialize_test".to_string(),
            symbol_type: SymbolType::Action,
            context: "test".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        let json = serde_json::to_string(&symbol).unwrap();
        assert!(json.contains("serialize_test"));
        assert!(json.contains("action"));
    }

    #[test]
    fn test_symbol_deserialization() {
        let json = r#"{
            "name": "deserialize_test",
            "symbol_type": "action",
            "context": "test",
            "dispatch": "rust_injector",
            "parameters": {}
        }"#;

        let symbol: Symbol = serde_json::from_str(json).unwrap();
        assert_eq!(symbol.name, "deserialize_test");
        assert_eq!(symbol.symbol_type, SymbolType::Action);
    }

    #[test]
    fn test_symbol_clone() {
        let symbol = Symbol {
            name: "clone_test".to_string(),
            symbol_type: SymbolType::Validator,
            context: "validation".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        let cloned = symbol.clone();
        assert_eq!(symbol.name, cloned.name);
        assert_eq!(symbol.symbol_type, cloned.symbol_type);
    }
}

#[cfg(test)]
mod injector_tests {
    use super::*;
    use wp_injector::injector::*;

    #[test]
    fn test_inject_valid_symbol() {
        let symbol = Symbol {
            name: "valid_symbol".to_string(),
            symbol_type: SymbolType::Action,
            context: "wordpress".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        let config = InjectorConfig::default();
        let result = inject_symbol(&symbol, &config);

        assert!(result.is_ok());
        let injection_result = result.unwrap();
        assert!(injection_result.success);
        assert_eq!(injection_result.symbol_name, "valid_symbol");
    }

    #[test]
    fn test_inject_symbol_with_empty_name() {
        let symbol = Symbol {
            name: "".to_string(),
            symbol_type: SymbolType::Action,
            context: "wordpress".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        let config = InjectorConfig::default();
        let result = inject_symbol(&symbol, &config);

        assert!(result.is_err());
        assert_eq!(result.err().unwrap(), "Symbol name cannot be empty");
    }

    #[test]
    fn test_inject_symbol_with_empty_context() {
        let symbol = Symbol {
            name: "test".to_string(),
            symbol_type: SymbolType::Action,
            context: "".to_string(),
            dispatch: "rust_injector".to_string(),
            parameters: HashMap::new(),
        };

        let config = InjectorConfig::default();
        let result = inject_symbol(&symbol, &config);

        assert!(result.is_err());
        assert!(result.err().unwrap().contains("context"));
    }

    #[test]
    fn test_inject_symbol_with_empty_dispatch() {
        let symbol = Symbol {
            name: "test".to_string(),
            symbol_type: SymbolType::Action,
            context: "wordpress".to_string(),
            dispatch: "".to_string(),
            parameters: HashMap::new(),
        };

        let config = InjectorConfig::default();
        let result = inject_symbol(&symbol, &config);

        assert!(result.is_err());
        assert!(result.err().unwrap().contains("dispatch"));
    }

    #[test]
    fn test_inject_symbol_unknown_dispatch() {
        let symbol = Symbol {
            name: "test".to_string(),
            symbol_type: SymbolType::Action,
            context: "wordpress".to_string(),
            dispatch: "unknown_executor".to_string(),
            parameters: HashMap::new(),
        };

        let config = InjectorConfig::default();
        let result = inject_symbol(&symbol, &config);

        assert!(result.is_err());
        assert!(result.err().unwrap().contains("Unknown dispatch type"));
    }

    #[test]
    fn test_inject_php_symbol() {
        let symbol = Symbol {
            name: "php_symbol".to_string(),
            symbol_type: SymbolType::Action,
            context: "wordpress".to_string(),
            dispatch: "php_engine".to_string(),
            parameters: HashMap::new(),
        };

        let config = InjectorConfig::default();
        let result = inject_symbol(&symbol, &config);

        assert!(result.is_ok());
        let injection_result = result.unwrap();
        assert!(injection_result.message.contains("PHP"));
    }
}

#[cfg(test)]
mod config_tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = InjectorConfig::default();
        assert_eq!(config.target, "wordpress");
        assert_eq!(config.mode, "safe");
        assert!(config.cache_enabled);
        assert_eq!(config.max_concurrent, 5);
    }

    #[test]
    fn test_custom_config_deserialization() {
        let json = r#"{
            "target": "custom_target",
            "mode": "aggressive",
            "cache_enabled": false,
            "max_concurrent": 10
        }"#;

        let config: InjectorConfig = serde_json::from_str(json).unwrap();
        assert_eq!(config.target, "custom_target");
        assert_eq!(config.mode, "aggressive");
        assert!(!config.cache_enabled);
        assert_eq!(config.max_concurrent, 10);
    }
}

#[cfg(test)]
mod manifest_tests {
    use super::*;
    use wp_injector::manifest::*;

    #[test]
    fn test_parse_yaml_manifest() {
        let yaml = r#"
name: test_manifest
version: 1.0.0
symbols:
  - name: test_symbol
    symbol_type: action
    context: wordpress
    dispatch: rust_injector
    parameters: {}
"#;

        let manifest = parse_yaml(yaml);
        assert!(manifest.is_ok());

        let m = manifest.unwrap();
        assert_eq!(m.name, "test_manifest");
        assert_eq!(m.version, "1.0.0");
        assert_eq!(m.symbols.len(), 1);
    }

    #[test]
    fn test_parse_toml_manifest() {
        let toml = r#"
name = "test_manifest"
version = "1.0.0"

[[symbols]]
name = "test_symbol"
symbol_type = "action"
context = "wordpress"
dispatch = "rust_injector"

[symbols.parameters]
"#;

        let manifest = parse_toml(toml);
        assert!(manifest.is_ok());

        let m = manifest.unwrap();
        assert_eq!(m.name, "test_manifest");
    }

    #[test]
    fn test_parse_invalid_yaml() {
        let invalid_yaml = "invalid: yaml: content:";
        let result = parse_yaml(invalid_yaml);
        assert!(result.is_err());
    }

    #[test]
    fn test_parse_invalid_toml() {
        let invalid_toml = "invalid toml [[[";
        let result = parse_toml(invalid_toml);
        assert!(result.is_err());
    }

    #[test]
    fn test_manifest_with_multiple_symbols() {
        let yaml = r#"
name: multi_symbol
version: 1.0.0
symbols:
  - name: symbol1
    symbol_type: action
    context: wordpress
    dispatch: rust_injector
    parameters: {}
  - name: symbol2
    symbol_type: query
    context: database
    dispatch: php_engine
    parameters: {}
  - name: symbol3
    symbol_type: transform
    context: data
    dispatch: rust_injector
    parameters: {}
"#;

        let manifest = parse_yaml(yaml).unwrap();
        assert_eq!(manifest.symbols.len(), 3);
        assert_eq!(manifest.symbols[0].name, "symbol1");
        assert_eq!(manifest.symbols[1].symbol_type, SymbolType::Query);
        assert_eq!(manifest.symbols[2].dispatch, "rust_injector");
    }
}

#[cfg(test)]
mod integration_tests {
    use super::*;
    use wp_injector::injector::*;
    use wp_injector::manifest::*;

    #[test]
    fn test_full_manifest_injection_workflow() {
        let yaml = r#"
name: workflow_test
version: 1.0.0
symbols:
  - name: init_action
    symbol_type: action
    context: wordpress
    dispatch: rust_injector
    parameters: {}
  - name: process_query
    symbol_type: query
    context: database
    dispatch: php_engine
    parameters: {}
"#;

        let manifest = parse_yaml(yaml).unwrap();
        let config = InjectorConfig::default();

        for symbol in &manifest.symbols {
            let result = inject_symbol(symbol, &config);
            assert!(result.is_ok());
        }
    }

    #[test]
    fn test_symbol_type_all_variants() {
        let types = vec![
            SymbolType::Action,
            SymbolType::Query,
            SymbolType::Transform,
            SymbolType::Validator,
        ];

        let config = InjectorConfig::default();

        for (i, symbol_type) in types.iter().enumerate() {
            let symbol = Symbol {
                name: format!("symbol_{}", i),
                symbol_type: symbol_type.clone(),
                context: "test".to_string(),
                dispatch: "rust_injector".to_string(),
                parameters: HashMap::new(),
            };

            let result = inject_symbol(&symbol, &config);
            assert!(result.is_ok());
        }
    }
}
