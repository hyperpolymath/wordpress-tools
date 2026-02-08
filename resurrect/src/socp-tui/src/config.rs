// SPDX-License-Identifier: AGPL-3.0-or-later
//! Configuration loading

use anyhow::Result;
use serde::Deserialize;
use std::path::Path;

#[derive(Debug, Deserialize, Default)]
pub struct Config {
    pub api_url: Option<String>,
    pub refresh_interval_secs: Option<u64>,
    pub theme: Option<String>,
}

pub fn load_config(path: Option<&str>) -> Result<Config> {
    let config_path = path.map(|p| Path::new(p).to_path_buf()).or_else(|| {
        directories::ProjectDirs::from("sh", "rhodium", "socp-tui").map(|dirs| {
            dirs.config_dir().join("config.toml")
        })
    });

    match config_path {
        Some(path) if path.exists() => {
            let contents = std::fs::read_to_string(&path)?;
            Ok(toml::from_str(&contents)?)
        }
        _ => Ok(Config::default()),
    }
}
