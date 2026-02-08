// SPDX-License-Identifier: AGPL-3.0-or-later
//! Application state and logic

use anyhow::Result;
use crossterm::event::{KeyCode, KeyEvent, KeyModifiers, MouseEvent};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::api::ApiClient;

/// Site health status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SiteStatus {
    Healthy,
    Warning,
    Critical,
    Unknown,
    Drifted,
    Syncing,
}

/// A managed site
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Site {
    pub id: String,
    pub domain: String,
    pub status: SiteStatus,
    pub last_sync: Option<chrono::DateTime<chrono::Utc>>,
    pub config_hash: Option<String>,
    pub response_time_ms: Option<u32>,
    pub ssl_expires: Option<chrono::DateTime<chrono::Utc>>,
    pub tags: Vec<String>,
    pub environment: String,
}

/// Active view in the TUI
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum View {
    Dashboard,
    SiteList,
    SiteDetail,
    Deployments,
    Secrets,
    Alerts,
    Logs,
    Help,
}

/// Application state
pub struct App {
    pub running: bool,
    pub view: View,
    pub sites: Vec<Site>,
    pub selected_site: usize,
    pub alerts: Vec<Alert>,
    pub pending_deployments: Vec<Deployment>,
    pub api_client: ApiClient,
    pub status_message: Option<String>,
    pub show_popup: bool,
    pub popup_content: String,
    pub scroll_offset: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Alert {
    pub id: String,
    pub site_id: String,
    pub severity: AlertSeverity,
    pub message: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub acknowledged: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AlertSeverity {
    Info,
    Warning,
    Critical,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Deployment {
    pub id: String,
    pub sites: Vec<String>,
    pub change_type: String,
    pub scheduled: Option<chrono::DateTime<chrono::Utc>>,
    pub status: DeploymentStatus,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum DeploymentStatus {
    Pending,
    InProgress,
    Completed,
    Failed,
    RolledBack,
}

impl App {
    pub async fn new(api_url: &str) -> Result<Self> {
        let api_client = ApiClient::new(api_url)?;

        // Fetch initial data
        let sites = api_client.get_sites().await.unwrap_or_default();
        let alerts = api_client.get_alerts().await.unwrap_or_default();
        let pending_deployments = api_client.get_pending_deployments().await.unwrap_or_default();

        Ok(Self {
            running: true,
            view: View::Dashboard,
            sites,
            selected_site: 0,
            alerts,
            pending_deployments,
            api_client,
            status_message: Some("Connected to control plane".to_string()),
            show_popup: false,
            popup_content: String::new(),
            scroll_offset: 0,
        })
    }

    /// Handle a key event, returns true if app should exit
    pub async fn handle_key(&mut self, key: KeyEvent) -> Result<bool> {
        // Global shortcuts
        match key.code {
            KeyCode::Char('q') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                return Ok(true);
            }
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                return Ok(true);
            }
            KeyCode::Esc => {
                if self.show_popup {
                    self.show_popup = false;
                } else if self.view != View::Dashboard {
                    self.view = View::Dashboard;
                } else {
                    return Ok(true);
                }
            }
            _ => {}
        }

        // View-specific handling
        match self.view {
            View::Dashboard => self.handle_dashboard_key(key).await?,
            View::SiteList => self.handle_site_list_key(key).await?,
            View::SiteDetail => self.handle_site_detail_key(key).await?,
            View::Deployments => self.handle_deployments_key(key).await?,
            View::Alerts => self.handle_alerts_key(key).await?,
            View::Help => self.handle_help_key(key)?,
            _ => {}
        }

        Ok(false)
    }

    async fn handle_dashboard_key(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Char('s') | KeyCode::Char('1') => self.view = View::SiteList,
            KeyCode::Char('d') | KeyCode::Char('2') => self.view = View::Deployments,
            KeyCode::Char('a') | KeyCode::Char('3') => self.view = View::Alerts,
            KeyCode::Char('l') | KeyCode::Char('4') => self.view = View::Logs,
            KeyCode::Char('?') | KeyCode::F(1) => self.view = View::Help,
            KeyCode::Char('r') => {
                self.status_message = Some("Refreshing...".to_string());
                self.refresh_data().await?;
                self.status_message = Some("Data refreshed".to_string());
            }
            _ => {}
        }
        Ok(())
    }

    async fn handle_site_list_key(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Up | KeyCode::Char('k') => {
                if self.selected_site > 0 {
                    self.selected_site -= 1;
                }
            }
            KeyCode::Down | KeyCode::Char('j') => {
                if self.selected_site < self.sites.len().saturating_sub(1) {
                    self.selected_site += 1;
                }
            }
            KeyCode::Enter => {
                self.view = View::SiteDetail;
            }
            KeyCode::Char('s') => {
                // Sync selected site
                if let Some(site) = self.sites.get(self.selected_site) {
                    self.status_message = Some(format!("Syncing {}...", site.domain));
                    self.api_client.sync_site(&site.id).await?;
                    self.status_message = Some(format!("Sync initiated for {}", site.domain));
                }
            }
            KeyCode::Char('/') => {
                // TODO: Search/filter
            }
            _ => {}
        }
        Ok(())
    }

    async fn handle_site_detail_key(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Backspace | KeyCode::Char('b') => {
                self.view = View::SiteList;
            }
            KeyCode::Char('s') => {
                // Sync this site
                if let Some(site) = self.sites.get(self.selected_site) {
                    self.status_message = Some(format!("Syncing {}...", site.domain));
                    self.api_client.sync_site(&site.id).await?;
                }
            }
            KeyCode::Char('c') => {
                // Show config diff
                if let Some(site) = self.sites.get(self.selected_site) {
                    let diff = self.api_client.get_config_diff(&site.id).await?;
                    self.popup_content = diff;
                    self.show_popup = true;
                }
            }
            KeyCode::Up | KeyCode::Char('k') => {
                self.scroll_offset = self.scroll_offset.saturating_sub(1);
            }
            KeyCode::Down | KeyCode::Char('j') => {
                self.scroll_offset += 1;
            }
            _ => {}
        }
        Ok(())
    }

    async fn handle_deployments_key(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Char('a') => {
                // Approve selected deployment
            }
            KeyCode::Char('r') => {
                // Reject/cancel selected deployment
            }
            _ => {}
        }
        Ok(())
    }

    async fn handle_alerts_key(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Char('a') => {
                // Acknowledge selected alert
            }
            KeyCode::Char('d') => {
                // Dismiss selected alert
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_help_key(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Char('q') | KeyCode::Esc => {
                self.view = View::Dashboard;
            }
            _ => {}
        }
        Ok(())
    }

    pub fn handle_mouse(&mut self, _mouse: MouseEvent) -> Result<()> {
        // TODO: Mouse support
        Ok(())
    }

    pub fn handle_resize(&mut self, _width: u16, _height: u16) -> Result<()> {
        // Terminal resize handled by ratatui automatically
        Ok(())
    }

    pub async fn tick(&mut self) -> Result<()> {
        // Periodic data refresh (every 30 ticks = ~7.5 seconds at 250ms interval)
        // TODO: Implement efficient polling or WebSocket updates
        Ok(())
    }

    async fn refresh_data(&mut self) -> Result<()> {
        self.sites = self.api_client.get_sites().await?;
        self.alerts = self.api_client.get_alerts().await?;
        self.pending_deployments = self.api_client.get_pending_deployments().await?;
        Ok(())
    }

    pub fn healthy_sites(&self) -> usize {
        self.sites.iter().filter(|s| s.status == SiteStatus::Healthy).count()
    }

    pub fn warning_sites(&self) -> usize {
        self.sites.iter().filter(|s| s.status == SiteStatus::Warning).count()
    }

    pub fn critical_sites(&self) -> usize {
        self.sites.iter().filter(|s| s.status == SiteStatus::Critical).count()
    }

    pub fn unacknowledged_alerts(&self) -> usize {
        self.alerts.iter().filter(|a| !a.acknowledged).count()
    }
}
