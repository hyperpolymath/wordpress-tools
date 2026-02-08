// SPDX-License-Identifier: AGPL-3.0-or-later
//! TUI rendering

use ratatui::{
    prelude::*,
    widgets::{Block, Borders, Cell, Clear, Paragraph, Row, Table, Tabs, Wrap},
};

use crate::app::{App, SiteStatus, View};

pub fn draw(frame: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Length(3),  // Header/tabs
            Constraint::Min(0),     // Main content
            Constraint::Length(1),  // Status bar
        ])
        .split(frame.area());

    draw_header(frame, app, chunks[0]);
    draw_content(frame, app, chunks[1]);
    draw_status_bar(frame, app, chunks[2]);

    // Popup overlay
    if app.show_popup {
        draw_popup(frame, app);
    }
}

fn draw_header(frame: &mut Frame, app: &App, area: Rect) {
    let titles = vec!["Dashboard", "Sites", "Deployments", "Alerts", "Logs", "Help"];
    let selected = match app.view {
        View::Dashboard => 0,
        View::SiteList | View::SiteDetail => 1,
        View::Deployments => 2,
        View::Alerts => 3,
        View::Logs => 4,
        View::Help => 5,
        View::Secrets => 1,
    };

    let tabs = Tabs::new(titles)
        .block(Block::default().borders(Borders::BOTTOM).title(" SOCP "))
        .select(selected)
        .style(Style::default().fg(Color::White))
        .highlight_style(Style::default().fg(Color::Cyan).bold());

    frame.render_widget(tabs, area);
}

fn draw_content(frame: &mut Frame, app: &App, area: Rect) {
    match app.view {
        View::Dashboard => draw_dashboard(frame, app, area),
        View::SiteList => draw_site_list(frame, app, area),
        View::SiteDetail => draw_site_detail(frame, app, area),
        View::Deployments => draw_deployments(frame, app, area),
        View::Alerts => draw_alerts(frame, app, area),
        View::Help => draw_help(frame, area),
        _ => {}
    }
}

fn draw_dashboard(frame: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(50), Constraint::Percentage(50)])
        .split(area);

    let left_chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(7), Constraint::Min(0)])
        .split(chunks[0]);

    // Summary stats
    let stats_text = format!(
        "\n  Sites:  {} total\n  \x1b[32m●\x1b[0m Healthy: {}   \x1b[33m●\x1b[0m Warning: {}   \x1b[31m●\x1b[0m Critical: {}\n\n  Pending: {} deployments   Alerts: {}",
        app.sites.len(),
        app.healthy_sites(),
        app.warning_sites(),
        app.critical_sites(),
        app.pending_deployments.len(),
        app.unacknowledged_alerts(),
    );

    let stats = Paragraph::new(stats_text)
        .block(Block::default().borders(Borders::ALL).title(" Overview "));
    frame.render_widget(stats, left_chunks[0]);

    // Recent activity
    let activity = Paragraph::new("\n  Coming soon...")
        .block(Block::default().borders(Borders::ALL).title(" Recent Activity "));
    frame.render_widget(activity, left_chunks[1]);

    // Sites needing attention
    let attention_sites: Vec<&_> = app.sites.iter()
        .filter(|s| s.status != SiteStatus::Healthy)
        .take(10)
        .collect();

    let attention_text = if attention_sites.is_empty() {
        "\n  All sites healthy!".to_string()
    } else {
        attention_sites.iter()
            .map(|s| format!("  {} - {:?}", s.domain, s.status))
            .collect::<Vec<_>>()
            .join("\n")
    };

    let attention = Paragraph::new(format!("\n{}", attention_text))
        .block(Block::default().borders(Borders::ALL).title(" Needs Attention "));
    frame.render_widget(attention, chunks[1]);
}

fn draw_site_list(frame: &mut Frame, app: &App, area: Rect) {
    let header = Row::new(vec![
        Cell::from("Status"),
        Cell::from("Domain"),
        Cell::from("Environment"),
        Cell::from("Last Sync"),
        Cell::from("Response"),
    ]).style(Style::default().bold());

    let rows: Vec<Row> = app.sites.iter().enumerate().map(|(i, site)| {
        let status_style = match site.status {
            SiteStatus::Healthy => Style::default().fg(Color::Green),
            SiteStatus::Warning => Style::default().fg(Color::Yellow),
            SiteStatus::Critical => Style::default().fg(Color::Red),
            SiteStatus::Drifted => Style::default().fg(Color::Magenta),
            SiteStatus::Syncing => Style::default().fg(Color::Cyan),
            SiteStatus::Unknown => Style::default().fg(Color::Gray),
        };

        let status_icon = match site.status {
            SiteStatus::Healthy => "●",
            SiteStatus::Warning => "◐",
            SiteStatus::Critical => "○",
            SiteStatus::Drifted => "◑",
            SiteStatus::Syncing => "◌",
            SiteStatus::Unknown => "?",
        };

        let last_sync = site.last_sync
            .map(|t| t.format("%Y-%m-%d %H:%M").to_string())
            .unwrap_or_else(|| "Never".to_string());

        let response = site.response_time_ms
            .map(|t| format!("{}ms", t))
            .unwrap_or_else(|| "-".to_string());

        let row_style = if i == app.selected_site {
            Style::default().bg(Color::DarkGray)
        } else {
            Style::default()
        };

        Row::new(vec![
            Cell::from(status_icon).style(status_style),
            Cell::from(site.domain.clone()),
            Cell::from(site.environment.clone()),
            Cell::from(last_sync),
            Cell::from(response),
        ]).style(row_style)
    }).collect();

    let table = Table::new(rows, [
        Constraint::Length(8),
        Constraint::Min(30),
        Constraint::Length(12),
        Constraint::Length(18),
        Constraint::Length(10),
    ])
    .header(header)
    .block(Block::default().borders(Borders::ALL).title(" Sites (j/k to navigate, Enter to select) "));

    frame.render_widget(table, area);
}

fn draw_site_detail(frame: &mut Frame, app: &App, area: Rect) {
    let site = match app.sites.get(app.selected_site) {
        Some(s) => s,
        None => {
            let para = Paragraph::new("No site selected")
                .block(Block::default().borders(Borders::ALL).title(" Site Detail "));
            frame.render_widget(para, area);
            return;
        }
    };

    let detail_text = format!(
        r#"
  Domain:      {}
  Status:      {:?}
  Environment: {}
  Tags:        {}

  Last Sync:   {}
  Config Hash: {}

  Response:    {}
  SSL Expires: {}

  [s] Sync  [c] Config Diff  [b] Back
"#,
        site.domain,
        site.status,
        site.environment,
        site.tags.join(", "),
        site.last_sync.map(|t| t.to_string()).unwrap_or_else(|| "Never".to_string()),
        site.config_hash.as_deref().unwrap_or("N/A"),
        site.response_time_ms.map(|t| format!("{}ms", t)).unwrap_or_else(|| "N/A".to_string()),
        site.ssl_expires.map(|t| t.format("%Y-%m-%d").to_string()).unwrap_or_else(|| "N/A".to_string()),
    );

    let detail = Paragraph::new(detail_text)
        .block(Block::default().borders(Borders::ALL).title(format!(" {} ", site.domain)));
    frame.render_widget(detail, area);
}

fn draw_deployments(frame: &mut Frame, app: &App, area: Rect) {
    let text = if app.pending_deployments.is_empty() {
        "\n  No pending deployments".to_string()
    } else {
        app.pending_deployments.iter()
            .map(|d| format!("  {} - {} - {:?}", d.id, d.change_type, d.status))
            .collect::<Vec<_>>()
            .join("\n")
    };

    let para = Paragraph::new(format!("\n{}", text))
        .block(Block::default().borders(Borders::ALL).title(" Pending Deployments "));
    frame.render_widget(para, area);
}

fn draw_alerts(frame: &mut Frame, app: &App, area: Rect) {
    let text = if app.alerts.is_empty() {
        "\n  No alerts".to_string()
    } else {
        app.alerts.iter()
            .map(|a| {
                let ack = if a.acknowledged { "✓" } else { " " };
                format!("  [{}] {:?} - {} - {}", ack, a.severity, a.site_id, a.message)
            })
            .collect::<Vec<_>>()
            .join("\n")
    };

    let para = Paragraph::new(format!("\n{}", text))
        .block(Block::default().borders(Borders::ALL).title(" Alerts ([a] Acknowledge, [d] Dismiss) "));
    frame.render_widget(para, area);
}

fn draw_help(frame: &mut Frame, area: Rect) {
    let help_text = r#"
  SOCP - Site Operations Control Plane

  NAVIGATION
    Tab / 1-5     Switch views
    j / ↓         Move down
    k / ↑         Move up
    Enter         Select / Open
    Esc / b       Back / Close
    Ctrl+Q        Quit

  DASHBOARD
    s             Sites view
    d             Deployments view
    a             Alerts view
    l             Logs view
    r             Refresh data

  SITES
    s             Sync selected site
    c             Show config diff
    /             Search/filter

  DEPLOYMENTS
    a             Approve deployment
    r             Reject deployment

  ALERTS
    a             Acknowledge alert
    d             Dismiss alert
"#;

    let para = Paragraph::new(help_text)
        .block(Block::default().borders(Borders::ALL).title(" Help "))
        .wrap(Wrap { trim: false });
    frame.render_widget(para, area);
}

fn draw_status_bar(frame: &mut Frame, app: &App, area: Rect) {
    let status = app.status_message.as_deref().unwrap_or("Ready");
    let para = Paragraph::new(format!(" {} ", status))
        .style(Style::default().bg(Color::DarkGray).fg(Color::White));
    frame.render_widget(para, area);
}

fn draw_popup(frame: &mut Frame, app: &App) {
    let area = centered_rect(80, 80, frame.area());

    frame.render_widget(Clear, area);

    let popup = Paragraph::new(app.popup_content.clone())
        .block(Block::default().borders(Borders::ALL).title(" Config Diff (Esc to close) "))
        .wrap(Wrap { trim: false });
    frame.render_widget(popup, area);
}

fn centered_rect(percent_x: u16, percent_y: u16, area: Rect) -> Rect {
    let popup_layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage((100 - percent_y) / 2),
            Constraint::Percentage(percent_y),
            Constraint::Percentage((100 - percent_y) / 2),
        ])
        .split(area);

    Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .split(popup_layout[1])[1]
}
