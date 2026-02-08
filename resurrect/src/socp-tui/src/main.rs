// SPDX-License-Identifier: AGPL-3.0-or-later
//! SOCP TUI - Site Operations Control Plane Terminal Interface
//!
//! A ncurses-style dashboard for managing multiple web sites
//! through a centralized, security-hardened control plane.

mod app;
mod api;
mod ui;
mod config;
mod events;

use anyhow::Result;
use clap::Parser;
use crossterm::{
    event::{DisableMouseCapture, EnableMouseCapture},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::prelude::*;
use std::io;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::app::App;
use crate::events::EventHandler;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Control plane API endpoint
    #[arg(short, long, env = "SOCP_API_URL")]
    api_url: Option<String>,

    /// Path to configuration file
    #[arg(short, long)]
    config: Option<String>,

    /// Enable debug logging
    #[arg(short, long)]
    debug: bool,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    // Initialize logging
    let log_level = if args.debug { "debug" } else { "info" };
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env()
            .unwrap_or_else(|_| log_level.into()))
        .with(tracing_subscriber::fmt::layer().with_target(false))
        .init();

    // Load configuration
    let config = config::load_config(args.config.as_deref())?;
    let api_url = args.api_url.or(config.api_url).unwrap_or_else(|| {
        "https://[::1]:8443".to_string()
    });

    // Initialize terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app state
    let mut app = App::new(&api_url).await?;
    let event_handler = EventHandler::new(250);

    // Main loop
    let result = run_app(&mut terminal, &mut app, &event_handler).await;

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(e) = result {
        eprintln!("Error: {e:?}");
        std::process::exit(1);
    }

    Ok(())
}

async fn run_app<B: Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
    event_handler: &EventHandler,
) -> Result<()> {
    loop {
        terminal.draw(|frame| ui::draw(frame, app))?;

        match event_handler.next().await? {
            events::Event::Tick => {
                app.tick().await?;
            }
            events::Event::Key(key) => {
                if app.handle_key(key).await? {
                    return Ok(());
                }
            }
            events::Event::Mouse(mouse) => {
                app.handle_mouse(mouse)?;
            }
            events::Event::Resize(width, height) => {
                app.handle_resize(width, height)?;
            }
        }
    }
}
