// SPDX-License-Identifier: AGPL-3.0-or-later
//! API client for communicating with the SOCP control plane

use anyhow::Result;
use reqwest::Client;

use crate::app::{Alert, Deployment, Site};

pub struct ApiClient {
    client: Client,
    base_url: String,
}

impl ApiClient {
    pub fn new(base_url: &str) -> Result<Self> {
        let client = Client::builder()
            .danger_accept_invalid_certs(false) // Always verify certs
            .build()?;

        Ok(Self {
            client,
            base_url: base_url.trim_end_matches('/').to_string(),
        })
    }

    pub async fn get_sites(&self) -> Result<Vec<Site>> {
        // TODO: Implement actual API call
        // For now, return mock data for testing the TUI
        Ok(vec![
            Site {
                id: "site-1".to_string(),
                domain: "example.com".to_string(),
                status: crate::app::SiteStatus::Healthy,
                last_sync: Some(chrono::Utc::now()),
                config_hash: Some("sha256:abc123".to_string()),
                response_time_ms: Some(145),
                ssl_expires: Some(chrono::Utc::now() + chrono::Duration::days(60)),
                tags: vec!["production".to_string(), "wordpress".to_string()],
                environment: "production".to_string(),
            },
            Site {
                id: "site-2".to_string(),
                domain: "blog.example.com".to_string(),
                status: crate::app::SiteStatus::Warning,
                last_sync: Some(chrono::Utc::now() - chrono::Duration::hours(2)),
                config_hash: Some("sha256:def456".to_string()),
                response_time_ms: Some(523),
                ssl_expires: Some(chrono::Utc::now() + chrono::Duration::days(15)),
                tags: vec!["production".to_string(), "wordpress".to_string()],
                environment: "production".to_string(),
            },
            Site {
                id: "site-3".to_string(),
                domain: "staging.example.com".to_string(),
                status: crate::app::SiteStatus::Drifted,
                last_sync: Some(chrono::Utc::now() - chrono::Duration::days(1)),
                config_hash: Some("sha256:ghi789".to_string()),
                response_time_ms: Some(89),
                ssl_expires: Some(chrono::Utc::now() + chrono::Duration::days(90)),
                tags: vec!["staging".to_string()],
                environment: "staging".to_string(),
            },
        ])
    }

    pub async fn get_alerts(&self) -> Result<Vec<Alert>> {
        // TODO: Implement actual API call
        Ok(vec![
            Alert {
                id: "alert-1".to_string(),
                site_id: "site-2".to_string(),
                severity: crate::app::AlertSeverity::Warning,
                message: "SSL certificate expires in 15 days".to_string(),
                timestamp: chrono::Utc::now(),
                acknowledged: false,
            },
            Alert {
                id: "alert-2".to_string(),
                site_id: "site-2".to_string(),
                severity: crate::app::AlertSeverity::Warning,
                message: "Response time > 500ms".to_string(),
                timestamp: chrono::Utc::now() - chrono::Duration::hours(1),
                acknowledged: false,
            },
        ])
    }

    pub async fn get_pending_deployments(&self) -> Result<Vec<Deployment>> {
        // TODO: Implement actual API call
        Ok(vec![
            Deployment {
                id: "deploy-1".to_string(),
                sites: vec!["site-1".to_string(), "site-2".to_string()],
                change_type: "security-headers-update".to_string(),
                scheduled: Some(chrono::Utc::now() + chrono::Duration::hours(6)),
                status: crate::app::DeploymentStatus::Pending,
            },
        ])
    }

    pub async fn sync_site(&self, site_id: &str) -> Result<()> {
        // TODO: Implement actual API call
        tracing::info!("Syncing site: {}", site_id);
        Ok(())
    }

    pub async fn get_config_diff(&self, site_id: &str) -> Result<String> {
        // TODO: Implement actual API call
        Ok(format!(
            r#"--- a/sites/{}/config.ncl
+++ b/sites/{}/config.ncl
@@ -15,7 +15,7 @@
   security = {{
     headers = {{
-      x_frame_options = 'SAMEORIGIN,
+      x_frame_options = 'DENY,
       content_security_policy = "default-src 'self'",
     }},
   }},
"#,
            site_id, site_id
        ))
    }
}
