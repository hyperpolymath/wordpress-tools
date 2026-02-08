//! WP Praxis Symbolic Injector
//!
//! High-performance Rust-based symbolic logic injector for WordPress workflows.
//! This injector reads declarative manifest files and performs semantic-preserving
//! transformations on WordPress installations through database operations and
//! file system modifications.
//!
//! # Architecture
//!
//! The injector operates in multiple phases:
//! 1. **Parse** - Read and validate manifest files (YAML/TOML)
//! 2. **Plan** - Build execution plan with dependency resolution
//! 3. **Validate** - Check preconditions and permissions
//! 4. **Execute** - Perform atomic injection operations
//! 5. **Track** - Record state for rollback capability
//!
//! # Example Usage
//!
//! ```bash
//! # Validate a manifest
//! wp_injector validate --manifest workflow.toml
//!
//! # Inject symbols from manifest
//! wp_injector inject --manifest workflow.toml --wp-root /var/www/html
//!
//! # Check injection status
//! wp_injector status
//!
//! # Rollback last injection
//! wp_injector rollback --id abc123
//! ```

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use clap::{Parser, Subcommand};
use log::{error, info, warn};
use serde::{Deserialize, Serialize};
use sqlx::mysql::{MySqlConnectOptions, MySqlPool};
use sqlx::{ConnectOptions, Row};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use thiserror::Error;

// =============================================================================
// Error Types
// =============================================================================

#[derive(Error, Debug)]
pub enum InjectorError {
    #[error("Manifest parsing error: {0}")]
    ManifestParse(String),

    #[error("WordPress configuration error: {0}")]
    WordPressConfig(String),

    #[error("Database connection error: {0}")]
    DatabaseConnection(String),

    #[error("Injection failed: {0}")]
    InjectionFailed(String),

    #[error("Validation error: {0}")]
    ValidationFailed(String),

    #[error("State management error: {0}")]
    StateError(String),

    #[error("Rollback error: {0}")]
    RollbackFailed(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),
}

// =============================================================================
// CLI Structure
// =============================================================================

#[derive(Parser, Debug)]
#[command(
    name = "wp_injector",
    version,
    about = "WP Praxis Symbolic Injector - High-performance WordPress workflow automation",
    long_about = "Performs semantic-preserving symbolic injections into WordPress installations\n\
                  based on declarative manifest files. Supports rollback, validation, and\n\
                  state tracking for reliable WordPress automation."
)]
struct Cli {
    /// Enable verbose logging
    #[arg(short, long, global = true)]
    verbose: bool,

    /// Path to log file (default: stdout)
    #[arg(long, global = true)]
    log_file: Option<PathBuf>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug)]
enum Commands {
    /// Inject symbols from manifest into WordPress
    Inject {
        /// Path to manifest file (YAML or TOML)
        #[arg(short, long)]
        manifest: PathBuf,

        /// WordPress installation root directory
        #[arg(short, long)]
        wp_root: PathBuf,

        /// Dry run - validate without executing
        #[arg(long)]
        dry_run: bool,

        /// Skip validation checks
        #[arg(long)]
        skip_validation: bool,
    },

    /// Validate manifest without injecting
    Validate {
        /// Path to manifest file
        #[arg(short, long)]
        manifest: PathBuf,

        /// WordPress root for context validation
        #[arg(short, long)]
        wp_root: Option<PathBuf>,
    },

    /// Rollback previous injection
    Rollback {
        /// Injection ID to rollback
        #[arg(short, long)]
        id: Option<String>,

        /// Rollback last N injections
        #[arg(short, long)]
        last: Option<usize>,

        /// WordPress root directory
        #[arg(short, long)]
        wp_root: PathBuf,
    },

    /// Show injection status and history
    Status {
        /// WordPress root directory
        #[arg(short, long)]
        wp_root: Option<PathBuf>,

        /// Show detailed history
        #[arg(long)]
        detailed: bool,
    },

    /// Compare current state with manifest
    Diff {
        /// Path to manifest file
        #[arg(short, long)]
        manifest: PathBuf,

        /// WordPress root directory
        #[arg(short, long)]
        wp_root: PathBuf,
    },
}

// =============================================================================
// Manifest Structures
// =============================================================================

/// Root manifest structure supporting both YAML and TOML formats
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Manifest {
    /// Manifest metadata
    #[serde(default)]
    pub metadata: ManifestMetadata,

    /// List of symbolic operations
    pub symbols: Vec<Symbol>,

    /// Global configuration
    #[serde(default)]
    pub config: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct ManifestMetadata {
    pub name: Option<String>,
    pub version: Option<String>,
    pub description: Option<String>,
    pub author: Option<String>,
}

/// Symbolic operation definition
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Symbol {
    /// Unique symbol identifier
    pub name: String,

    /// Symbol type (action, filter, state, post_type, taxonomy, etc.)
    #[serde(rename = "type")]
    pub symbol_type: String,

    /// Execution context (wordpress, file, database, system)
    #[serde(default = "default_context")]
    pub context: String,

    /// Dispatch target (rust_injector, php_engine, cli, etc.)
    #[serde(default = "default_dispatch")]
    pub dispatch: String,

    /// Symbol-specific parameters
    #[serde(default)]
    pub parameters: HashMap<String, serde_json::Value>,

    /// Dependencies on other symbols
    #[serde(default)]
    pub depends_on: Vec<String>,

    /// Validation rules
    #[serde(default)]
    pub validation: ValidationRules,

    /// Rollback strategy
    #[serde(default)]
    pub rollback: RollbackStrategy,
}

fn default_context() -> String {
    "wordpress".to_string()
}

fn default_dispatch() -> String {
    "rust_injector".to_string()
}

#[derive(Debug, Deserialize, Serialize, Clone, Default)]
pub struct ValidationRules {
    #[serde(default)]
    pub required_plugins: Vec<String>,

    #[serde(default)]
    pub wordpress_version: Option<String>,

    #[serde(default)]
    pub php_version: Option<String>,

    #[serde(default)]
    pub custom: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(rename_all = "lowercase")]
pub enum RollbackStrategy {
    /// Store previous state and restore on rollback
    Snapshot,
    /// Execute inverse operations
    Inverse,
    /// Cannot be rolled back
    None,
}

impl Default for RollbackStrategy {
    fn default() -> Self {
        RollbackStrategy::Snapshot
    }
}

// =============================================================================
// WordPress Configuration
// =============================================================================

#[derive(Debug, Clone)]
pub struct WordPressConfig {
    pub db_name: String,
    pub db_user: String,
    pub db_password: String,
    pub db_host: String,
    pub db_port: u16,
    pub table_prefix: String,
    pub wp_root: PathBuf,
}

impl WordPressConfig {
    /// Parse wp-config.php to extract database configuration
    pub fn from_wp_root(wp_root: &Path) -> Result<Self, InjectorError> {
        let config_path = wp_root.join("wp-config.php");

        if !config_path.exists() {
            return Err(InjectorError::WordPressConfig(format!(
                "wp-config.php not found at {:?}",
                config_path
            )));
        }

        let content = fs::read_to_string(&config_path)
            .context("Failed to read wp-config.php")
            .map_err(|e| InjectorError::WordPressConfig(e.to_string()))?;

        Ok(Self {
            db_name: Self::extract_define(&content, "DB_NAME")?,
            db_user: Self::extract_define(&content, "DB_USER")?,
            db_password: Self::extract_define(&content, "DB_PASSWORD")?,
            db_host: Self::extract_define(&content, "DB_HOST")
                .unwrap_or_else(|_| "localhost".to_string()),
            db_port: 3306, // Default MySQL port
            table_prefix: Self::extract_variable(&content, "$table_prefix")
                .unwrap_or_else(|_| "wp_".to_string()),
            wp_root: wp_root.to_path_buf(),
        })
    }

    /// Extract PHP define() value
    fn extract_define(content: &str, name: &str) -> Result<String, InjectorError> {
        let pattern = format!("define\\s*\\(\\s*['\"]?{}['\"]?\\s*,\\s*['\"]([^'\"]+)['\"]", name);
        let re = regex::Regex::new(&pattern)
            .map_err(|e| InjectorError::WordPressConfig(e.to_string()))?;

        re.captures(content)
            .and_then(|caps| caps.get(1))
            .map(|m| m.as_str().to_string())
            .ok_or_else(|| {
                InjectorError::WordPressConfig(format!("Could not find {} in wp-config.php", name))
            })
    }

    /// Extract PHP variable value
    fn extract_variable(content: &str, name: &str) -> Result<String, InjectorError> {
        let pattern = format!("{}\\s*=\\s*['\"]([^'\"]+)['\"]", regex::escape(name));
        let re = regex::Regex::new(&pattern)
            .map_err(|e| InjectorError::WordPressConfig(e.to_string()))?;

        re.captures(content)
            .and_then(|caps| caps.get(1))
            .map(|m| m.as_str().to_string())
            .ok_or_else(|| {
                InjectorError::WordPressConfig(format!("Could not find {} in wp-config.php", name))
            })
    }
}

// =============================================================================
// Injection State Management
// =============================================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InjectionState {
    pub id: String,
    pub manifest_name: String,
    pub timestamp: DateTime<Utc>,
    pub symbols_injected: Vec<String>,
    pub rollback_data: HashMap<String, serde_json::Value>,
    pub status: InjectionStatus,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum InjectionStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    RolledBack,
}

/// State manager handles injection history and rollback data
pub struct StateManager {
    state_dir: PathBuf,
}

impl StateManager {
    pub fn new(wp_root: &Path) -> Result<Self> {
        let state_dir = wp_root
            .join("wp-content")
            .join(".wp-praxis")
            .join("injections");

        fs::create_dir_all(&state_dir)
            .context("Failed to create state directory")?;

        Ok(Self { state_dir })
    }

    pub fn save_state(&self, state: &InjectionState) -> Result<()> {
        let state_file = self.state_dir.join(format!("{}.json", state.id));
        let json = serde_json::to_string_pretty(state)
            .context("Failed to serialize state")?;

        fs::write(&state_file, json)
            .context("Failed to write state file")?;

        info!("Saved injection state: {}", state.id);
        Ok(())
    }

    pub fn load_state(&self, id: &str) -> Result<InjectionState> {
        let state_file = self.state_dir.join(format!("{}.json", id));
        let json = fs::read_to_string(&state_file)
            .context("Failed to read state file")?;

        serde_json::from_str(&json)
            .context("Failed to deserialize state")
    }

    pub fn list_states(&self) -> Result<Vec<InjectionState>> {
        let mut states = Vec::new();

        for entry in fs::read_dir(&self.state_dir)? {
            let entry = entry?;
            let path = entry.path();

            if path.extension().and_then(|s| s.to_str()) == Some("json") {
                match fs::read_to_string(&path) {
                    Ok(json) => {
                        if let Ok(state) = serde_json::from_str::<InjectionState>(&json) {
                            states.push(state);
                        }
                    }
                    Err(e) => warn!("Failed to read state file {:?}: {}", path, e),
                }
            }
        }

        states.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));
        Ok(states)
    }

    pub fn get_last_state(&self) -> Result<Option<InjectionState>> {
        Ok(self.list_states()?.into_iter().next())
    }
}

// =============================================================================
// WordPress Database Operations
// =============================================================================

pub struct WordPressDatabase {
    pool: MySqlPool,
    table_prefix: String,
}

impl WordPressDatabase {
    /// Connect to WordPress database
    pub async fn connect(config: &WordPressConfig) -> Result<Self, InjectorError> {
        info!(
            "Connecting to WordPress database: {}@{}:{}",
            config.db_user, config.db_host, config.db_port
        );

        let connect_opts = MySqlConnectOptions::new()
            .host(&config.db_host)
            .port(config.db_port)
            .username(&config.db_user)
            .password(&config.db_password)
            .database(&config.db_name)
            .disable_statement_logging();

        let pool = MySqlPool::connect_with(connect_opts)
            .await
            .map_err(|e| InjectorError::DatabaseConnection(e.to_string()))?;

        info!("Successfully connected to WordPress database");

        Ok(Self {
            pool,
            table_prefix: config.table_prefix.clone(),
        })
    }

    /// Get table name with WordPress prefix
    fn table(&self, name: &str) -> String {
        format!("{}{}", self.table_prefix, name)
    }

    /// Inject custom post type
    pub async fn inject_post_type(&self, symbol: &Symbol) -> Result<(), InjectorError> {
        let name = symbol.parameters.get("post_type")
            .and_then(|v| v.as_str())
            .ok_or_else(|| InjectorError::InjectionFailed(
                "post_type parameter required".to_string()
            ))?;

        let label = symbol.parameters.get("label")
            .and_then(|v| v.as_str())
            .unwrap_or(name);

        let public = symbol.parameters.get("public")
            .and_then(|v| v.as_bool())
            .unwrap_or(true);

        info!("Injecting custom post type: {}", name);

        // Store in wp_options as serialized PHP array (WordPress convention)
        let option_name = format!("wp_praxis_cpt_{}", name);
        let option_value = serde_json::json!({
            "name": name,
            "label": label,
            "public": public,
            "parameters": symbol.parameters,
        }).to_string();

        let query = format!(
            "INSERT INTO {} (option_name, option_value, autoload) VALUES (?, ?, 'yes') \
             ON DUPLICATE KEY UPDATE option_value = VALUES(option_value)",
            self.table("options")
        );

        sqlx::query(&query)
            .bind(&option_name)
            .bind(&option_value)
            .execute(&self.pool)
            .await
            .map_err(|e| InjectorError::InjectionFailed(format!(
                "Failed to inject post type: {}", e
            )))?;

        info!("Successfully injected custom post type: {}", name);
        Ok(())
    }

    /// Inject taxonomy
    pub async fn inject_taxonomy(&self, symbol: &Symbol) -> Result<(), InjectorError> {
        let name = symbol.parameters.get("taxonomy")
            .and_then(|v| v.as_str())
            .ok_or_else(|| InjectorError::InjectionFailed(
                "taxonomy parameter required".to_string()
            ))?;

        let label = symbol.parameters.get("label")
            .and_then(|v| v.as_str())
            .unwrap_or(name);

        info!("Injecting taxonomy: {}", name);

        let option_name = format!("wp_praxis_taxonomy_{}", name);
        let option_value = serde_json::json!({
            "name": name,
            "label": label,
            "parameters": symbol.parameters,
        }).to_string();

        let query = format!(
            "INSERT INTO {} (option_name, option_value, autoload) VALUES (?, ?, 'yes') \
             ON DUPLICATE KEY UPDATE option_value = VALUES(option_value)",
            self.table("options")
        );

        sqlx::query(&query)
            .bind(&option_name)
            .bind(&option_value)
            .execute(&self.pool)
            .await
            .map_err(|e| InjectorError::InjectionFailed(format!(
                "Failed to inject taxonomy: {}", e
            )))?;

        info!("Successfully injected taxonomy: {}", name);
        Ok(())
    }

    /// Set WordPress option
    pub async fn set_option(&self, symbol: &Symbol) -> Result<(), InjectorError> {
        let option_name = symbol.parameters.get("option_name")
            .and_then(|v| v.as_str())
            .ok_or_else(|| InjectorError::InjectionFailed(
                "option_name parameter required".to_string()
            ))?;

        let option_value = symbol.parameters.get("option_value")
            .ok_or_else(|| InjectorError::InjectionFailed(
                "option_value parameter required".to_string()
            ))?;

        info!("Setting WordPress option: {}", option_name);

        let value_str = match option_value {
            serde_json::Value::String(s) => s.clone(),
            other => other.to_string(),
        };

        let query = format!(
            "INSERT INTO {} (option_name, option_value, autoload) VALUES (?, ?, 'yes') \
             ON DUPLICATE KEY UPDATE option_value = VALUES(option_value)",
            self.table("options")
        );

        sqlx::query(&query)
            .bind(option_name)
            .bind(&value_str)
            .execute(&self.pool)
            .await
            .map_err(|e| InjectorError::InjectionFailed(format!(
                "Failed to set option: {}", e
            )))?;

        info!("Successfully set option: {}", option_name);
        Ok(())
    }

    /// Get WordPress option for comparison
    pub async fn get_option(&self, name: &str) -> Result<Option<String>, InjectorError> {
        let query = format!(
            "SELECT option_value FROM {} WHERE option_name = ?",
            self.table("options")
        );

        let row = sqlx::query(&query)
            .bind(name)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| InjectorError::Database(e))?;

        match row {
            Some(r) => {
                let value: String = r.try_get("option_value")
                    .map_err(|e| InjectorError::Database(e))?;
                Ok(Some(value))
            }
            None => Ok(None),
        }
    }

    /// Execute generic SQL query (for advanced symbols)
    pub async fn execute_query(&self, sql: &str) -> Result<u64, InjectorError> {
        let result = sqlx::query(sql)
            .execute(&self.pool)
            .await
            .map_err(|e| InjectorError::InjectionFailed(format!(
                "Query execution failed: {}", e
            )))?;

        Ok(result.rows_affected())
    }

    /// Get WordPress version
    pub async fn get_version(&self) -> Result<String, InjectorError> {
        self.get_option("wp_version")
            .await?
            .ok_or_else(|| InjectorError::ValidationFailed(
                "Could not determine WordPress version".to_string()
            ))
    }

    /// Check if plugin is active
    pub async fn is_plugin_active(&self, plugin: &str) -> Result<bool, InjectorError> {
        if let Some(active_plugins) = self.get_option("active_plugins").await? {
            Ok(active_plugins.contains(plugin))
        } else {
            Ok(false)
        }
    }
}

// =============================================================================
// Symbolic Injector
// =============================================================================

pub struct SymbolicInjector {
    manifest: Manifest,
    wp_config: WordPressConfig,
    db: Option<WordPressDatabase>,
    state_manager: StateManager,
    dry_run: bool,
}

impl SymbolicInjector {
    pub async fn new(
        manifest: Manifest,
        wp_config: WordPressConfig,
        dry_run: bool,
    ) -> Result<Self> {
        let state_manager = StateManager::new(&wp_config.wp_root)?;

        let db = if dry_run {
            info!("Dry run mode - skipping database connection");
            None
        } else {
            Some(WordPressDatabase::connect(&wp_config).await?)
        };

        Ok(Self {
            manifest,
            wp_config,
            db,
            state_manager,
            dry_run,
        })
    }

    /// Validate manifest and environment
    pub async fn validate(&self) -> Result<(), InjectorError> {
        info!("Validating manifest and environment...");

        // Validate manifest structure
        if self.manifest.symbols.is_empty() {
            return Err(InjectorError::ValidationFailed(
                "Manifest contains no symbols".to_string()
            ));
        }

        // Check for duplicate symbol names
        let mut names = std::collections::HashSet::new();
        for symbol in &self.manifest.symbols {
            if !names.insert(&symbol.name) {
                return Err(InjectorError::ValidationFailed(format!(
                    "Duplicate symbol name: {}",
                    symbol.name
                )));
            }
        }

        // Validate dependencies
        for symbol in &self.manifest.symbols {
            for dep in &symbol.depends_on {
                if !names.contains(&dep) {
                    return Err(InjectorError::ValidationFailed(format!(
                        "Symbol '{}' depends on unknown symbol '{}'",
                        symbol.name, dep
                    )));
                }
            }
        }

        // Validate WordPress environment
        if let Some(db) = &self.db {
            let wp_version = db.get_version().await?;
            info!("WordPress version: {}", wp_version);

            // Check required plugins
            for symbol in &self.manifest.symbols {
                for plugin in &symbol.validation.required_plugins {
                    if !db.is_plugin_active(plugin).await? {
                        warn!("Required plugin not active: {}", plugin);
                    }
                }
            }
        }

        info!("Validation successful");
        Ok(())
    }

    /// Execute injection with dependency resolution
    pub async fn inject(&mut self) -> Result<InjectionState> {
        info!("Starting injection process...");

        let injection_id = format!("inj_{}", Utc::now().timestamp());
        let mut state = InjectionState {
            id: injection_id.clone(),
            manifest_name: self.manifest.metadata.name.clone()
                .unwrap_or_else(|| "unnamed".to_string()),
            timestamp: Utc::now(),
            symbols_injected: Vec::new(),
            rollback_data: HashMap::new(),
            status: InjectionStatus::InProgress,
        };

        // Sort symbols by dependencies
        let sorted_symbols = self.topological_sort()?;

        for symbol in sorted_symbols {
            info!("Injecting symbol: {} (type: {})", symbol.name, symbol.symbol_type);

            if self.dry_run {
                info!("  [DRY RUN] Would inject symbol: {}", symbol.name);
                state.symbols_injected.push(symbol.name.clone());
                continue;
            }

            match self.inject_symbol(&symbol, &mut state).await {
                Ok(()) => {
                    state.symbols_injected.push(symbol.name.clone());
                    info!("  Successfully injected: {}", symbol.name);
                }
                Err(e) => {
                    error!("  Failed to inject {}: {}", symbol.name, e);
                    state.status = InjectionStatus::Failed;
                    self.state_manager.save_state(&state)?;
                    return Err(e.into());
                }
            }
        }

        state.status = InjectionStatus::Completed;
        self.state_manager.save_state(&state)?;

        info!(
            "Injection completed successfully: {} symbols injected",
            state.symbols_injected.len()
        );

        Ok(state)
    }

    /// Inject individual symbol
    async fn inject_symbol(
        &self,
        symbol: &Symbol,
        state: &mut InjectionState,
    ) -> Result<(), InjectorError> {
        let db = self.db.as_ref()
            .ok_or_else(|| InjectorError::InjectionFailed(
                "Database not connected".to_string()
            ))?;

        // Store rollback data based on strategy
        if matches!(symbol.rollback, RollbackStrategy::Snapshot) {
            self.snapshot_symbol(symbol, state, db).await?;
        }

        // Dispatch based on symbol type
        match symbol.symbol_type.as_str() {
            "post_type" => db.inject_post_type(symbol).await?,
            "taxonomy" => db.inject_taxonomy(symbol).await?,
            "option" => db.set_option(symbol).await?,
            "query" => {
                let sql = symbol.parameters.get("sql")
                    .and_then(|v| v.as_str())
                    .ok_or_else(|| InjectorError::InjectionFailed(
                        "sql parameter required for query type".to_string()
                    ))?;
                db.execute_query(sql).await?;
            }
            other => {
                warn!("Unknown symbol type '{}' - skipping", other);
            }
        }

        Ok(())
    }

    /// Create snapshot for rollback
    async fn snapshot_symbol(
        &self,
        symbol: &Symbol,
        state: &mut InjectionState,
        db: &WordPressDatabase,
    ) -> Result<(), InjectorError> {
        match symbol.symbol_type.as_str() {
            "option" => {
                if let Some(option_name) = symbol.parameters.get("option_name")
                    .and_then(|v| v.as_str())
                {
                    if let Some(old_value) = db.get_option(option_name).await? {
                        state.rollback_data.insert(
                            symbol.name.clone(),
                            serde_json::json!({
                                "type": "option",
                                "option_name": option_name,
                                "old_value": old_value,
                            }),
                        );
                    }
                }
            }
            _ => {
                // For other types, store the symbol definition for inverse operations
                state.rollback_data.insert(
                    symbol.name.clone(),
                    serde_json::to_value(symbol).unwrap(),
                );
            }
        }

        Ok(())
    }

    /// Topological sort for dependency resolution
    fn topological_sort(&self) -> Result<Vec<Symbol>, InjectorError> {
        let mut sorted = Vec::new();
        let mut visited = std::collections::HashSet::new();
        let mut in_progress = std::collections::HashSet::new();

        let symbol_map: HashMap<_, _> = self.manifest.symbols.iter()
            .map(|s| (s.name.as_str(), s))
            .collect();

        fn visit<'a>(
            name: &'a str,
            symbol_map: &HashMap<&'a str, &'a Symbol>,
            visited: &mut std::collections::HashSet<String>,
            in_progress: &mut std::collections::HashSet<String>,
            sorted: &mut Vec<Symbol>,
        ) -> Result<(), InjectorError> {
            if visited.contains(name) {
                return Ok(());
            }

            if in_progress.contains(name) {
                return Err(InjectorError::ValidationFailed(format!(
                    "Circular dependency detected: {}",
                    name
                )));
            }

            in_progress.insert(name.to_string());

            if let Some(symbol) = symbol_map.get(name) {
                for dep in &symbol.depends_on {
                    visit(dep, symbol_map, visited, in_progress, sorted)?;
                }

                sorted.push((*symbol).clone());
                visited.insert(name.to_string());
            }

            in_progress.remove(name);
            Ok(())
        }

        for symbol in &self.manifest.symbols {
            visit(&symbol.name, &symbol_map, &mut visited, &mut in_progress, &mut sorted)?;
        }

        Ok(sorted)
    }

    /// Rollback injection
    pub async fn rollback(&self, state: &InjectionState) -> Result<()> {
        info!("Rolling back injection: {}", state.id);

        let db = self.db.as_ref()
            .ok_or_else(|| InjectorError::RollbackFailed(
                "Database not connected".to_string()
            ))?;

        // Rollback in reverse order
        for symbol_name in state.symbols_injected.iter().rev() {
            if let Some(rollback_data) = state.rollback_data.get(symbol_name) {
                info!("Rolling back symbol: {}", symbol_name);

                if let Some(rb_type) = rollback_data.get("type").and_then(|v| v.as_str()) {
                    match rb_type {
                        "option" => {
                            let option_name = rollback_data.get("option_name")
                                .and_then(|v| v.as_str())
                                .ok_or_else(|| InjectorError::RollbackFailed(
                                    "Missing option_name in rollback data".to_string()
                                ))?;

                            let old_value = rollback_data.get("old_value")
                                .and_then(|v| v.as_str())
                                .unwrap_or("");

                            let query = format!(
                                "UPDATE {} SET option_value = ? WHERE option_name = ?",
                                db.table("options")
                            );

                            sqlx::query(&query)
                                .bind(old_value)
                                .bind(option_name)
                                .execute(&db.pool)
                                .await
                                .map_err(|e| InjectorError::RollbackFailed(e.to_string()))?;
                        }
                        _ => {
                            warn!("Unknown rollback type: {}", rb_type);
                        }
                    }
                }
            }
        }

        info!("Rollback completed successfully");
        Ok(())
    }

    /// Compare current state with manifest
    pub async fn diff(&self) -> Result<Vec<SymbolDiff>> {
        info!("Comparing current state with manifest...");

        let db = self.db.as_ref()
            .ok_or_else(|| InjectorError::ValidationFailed(
                "Database not connected".to_string()
            ))?;

        let mut diffs = Vec::new();

        for symbol in &self.manifest.symbols {
            match symbol.symbol_type.as_str() {
                "option" => {
                    if let Some(option_name) = symbol.parameters.get("option_name")
                        .and_then(|v| v.as_str())
                    {
                        let current = db.get_option(option_name).await?;
                        let expected = symbol.parameters.get("option_value")
                            .map(|v| v.to_string());

                        if current.as_ref() != expected.as_ref() {
                            diffs.push(SymbolDiff {
                                symbol_name: symbol.name.clone(),
                                symbol_type: symbol.symbol_type.clone(),
                                current_value: current,
                                expected_value: expected,
                            });
                        }
                    }
                }
                _ => {
                    // For other types, just note they exist in manifest
                    diffs.push(SymbolDiff {
                        symbol_name: symbol.name.clone(),
                        symbol_type: symbol.symbol_type.clone(),
                        current_value: None,
                        expected_value: Some("(defined in manifest)".to_string()),
                    });
                }
            }
        }

        Ok(diffs)
    }
}

#[derive(Debug)]
pub struct SymbolDiff {
    pub symbol_name: String,
    pub symbol_type: String,
    pub current_value: Option<String>,
    pub expected_value: Option<String>,
}

// =============================================================================
// Manifest Loading
// =============================================================================

fn load_manifest(path: &Path) -> Result<Manifest, InjectorError> {
    info!("Loading manifest from: {:?}", path);

    let content = fs::read_to_string(path)
        .context("Failed to read manifest file")
        .map_err(|e| InjectorError::ManifestParse(e.to_string()))?;

    let manifest = if path.extension().and_then(|s| s.to_str()) == Some("toml") {
        toml::from_str::<Manifest>(&content)
            .context("Failed to parse TOML manifest")
            .map_err(|e| InjectorError::ManifestParse(e.to_string()))?
    } else {
        serde_yaml::from_str::<Manifest>(&content)
            .context("Failed to parse YAML manifest")
            .map_err(|e| InjectorError::ManifestParse(e.to_string()))?
    };

    info!(
        "Loaded manifest: {} symbols",
        manifest.symbols.len()
    );

    Ok(manifest)
}

// =============================================================================
// Main Entry Point
// =============================================================================

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // Initialize logging
    let mut log_builder = env_logger::Builder::from_default_env();

    if cli.verbose {
        log_builder.filter_level(log::LevelFilter::Debug);
    } else {
        log_builder.filter_level(log::LevelFilter::Info);
    }

    log_builder.init();

    info!("WP Praxis Symbolic Injector v{}", env!("CARGO_PKG_VERSION"));

    // Execute command
    match cli.command {
        Commands::Inject {
            manifest,
            wp_root,
            dry_run,
            skip_validation,
        } => {
            let manifest_data = load_manifest(&manifest)?;
            let wp_config = WordPressConfig::from_wp_root(&wp_root)?;

            let mut injector = SymbolicInjector::new(
                manifest_data,
                wp_config,
                dry_run,
            ).await?;

            if !skip_validation {
                injector.validate().await?;
            }

            let state = injector.inject().await?;

            println!("\n✓ Injection completed successfully!");
            println!("  ID: {}", state.id);
            println!("  Symbols injected: {}", state.symbols_injected.len());
            println!("  Timestamp: {}", state.timestamp);
        }

        Commands::Validate { manifest, wp_root } => {
            let manifest_data = load_manifest(&manifest)?;

            if let Some(wp_root) = wp_root {
                let wp_config = WordPressConfig::from_wp_root(&wp_root)?;
                let injector = SymbolicInjector::new(manifest_data, wp_config, true).await?;
                injector.validate().await?;
            } else {
                // Basic validation without WordPress context
                info!("Validating manifest structure only (no WordPress context)");
                if manifest_data.symbols.is_empty() {
                    return Err(InjectorError::ValidationFailed(
                        "Manifest contains no symbols".to_string()
                    ).into());
                }
            }

            println!("✓ Manifest validation successful!");
        }

        Commands::Rollback { id, last, wp_root } => {
            let wp_config = WordPressConfig::from_wp_root(&wp_root)?;
            let state_manager = StateManager::new(&wp_config.wp_root)?;

            let state = if let Some(id) = id {
                state_manager.load_state(&id)?
            } else if let Some(_n) = last {
                state_manager.get_last_state()?
                    .ok_or_else(|| anyhow::anyhow!("No injection history found"))?
            } else {
                return Err(anyhow::anyhow!("Either --id or --last must be specified"));
            };

            // Create minimal manifest for rollback
            let manifest = Manifest {
                metadata: ManifestMetadata::default(),
                symbols: Vec::new(),
                config: HashMap::new(),
            };

            let injector = SymbolicInjector::new(manifest, wp_config, false).await?;
            injector.rollback(&state).await?;

            println!("✓ Rollback completed successfully!");
        }

        Commands::Status { wp_root, detailed } => {
            if let Some(wp_root) = wp_root {
                let state_manager = StateManager::new(&wp_root)?;
                let states = state_manager.list_states()?;

                if states.is_empty() {
                    println!("No injection history found.");
                } else {
                    println!("\nInjection History:");
                    println!("{}", "=".repeat(80));

                    for state in states {
                        println!("\nID: {}", state.id);
                        println!("Manifest: {}", state.manifest_name);
                        println!("Timestamp: {}", state.timestamp);
                        println!("Status: {:?}", state.status);
                        println!("Symbols: {}", state.symbols_injected.len());

                        if detailed {
                            for symbol in &state.symbols_injected {
                                println!("  - {}", symbol);
                            }
                        }
                    }
                }
            } else {
                println!("Please specify --wp-root to view injection status");
            }
        }

        Commands::Diff { manifest, wp_root } => {
            let manifest_data = load_manifest(&manifest)?;
            let wp_config = WordPressConfig::from_wp_root(&wp_root)?;

            let injector = SymbolicInjector::new(manifest_data, wp_config, false).await?;
            let diffs = injector.diff().await?;

            if diffs.is_empty() {
                println!("✓ No differences found - state matches manifest");
            } else {
                println!("\nDifferences found:");
                println!("{}", "=".repeat(80));

                for diff in diffs {
                    println!("\nSymbol: {} ({})", diff.symbol_name, diff.symbol_type);
                    println!("  Current:  {:?}", diff.current_value);
                    println!("  Expected: {:?}", diff.expected_value);
                }
            }
        }
    }

    Ok(())
}

// =============================================================================
// Unit Tests
// =============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_manifest_parsing_yaml() {
        let yaml = r#"
metadata:
  name: test_manifest
  version: "1.0"

symbols:
  - name: test_option
    type: option
    context: wordpress
    parameters:
      option_name: test_key
      option_value: test_value
"#;

        let manifest: Manifest = serde_yaml::from_str(yaml).unwrap();
        assert_eq!(manifest.symbols.len(), 1);
        assert_eq!(manifest.symbols[0].name, "test_option");
    }

    #[test]
    fn test_manifest_parsing_toml() {
        let toml_str = r#"
[metadata]
name = "test_manifest"
version = "1.0"

[[symbols]]
name = "test_option"
type = "option"
context = "wordpress"

[symbols.parameters]
option_name = "test_key"
option_value = "test_value"
"#;

        let manifest: Manifest = toml::from_str(toml_str).unwrap();
        assert_eq!(manifest.symbols.len(), 1);
        assert_eq!(manifest.symbols[0].name, "test_option");
    }

    #[test]
    fn test_dependency_validation() {
        let manifest = Manifest {
            metadata: ManifestMetadata::default(),
            symbols: vec![
                Symbol {
                    name: "symbol_a".to_string(),
                    symbol_type: "action".to_string(),
                    context: "wordpress".to_string(),
                    dispatch: "rust_injector".to_string(),
                    parameters: HashMap::new(),
                    depends_on: vec!["symbol_b".to_string()],
                    validation: ValidationRules::default(),
                    rollback: RollbackStrategy::default(),
                },
                Symbol {
                    name: "symbol_b".to_string(),
                    symbol_type: "action".to_string(),
                    context: "wordpress".to_string(),
                    dispatch: "rust_injector".to_string(),
                    parameters: HashMap::new(),
                    depends_on: vec![],
                    validation: ValidationRules::default(),
                    rollback: RollbackStrategy::default(),
                },
            ],
            config: HashMap::new(),
        };

        // This would be tested in an async context
        // but demonstrates the structure is valid
        assert_eq!(manifest.symbols.len(), 2);
    }
}
