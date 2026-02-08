// SPDX-License-Identifier: AGPL-3.0-or-later
//! Event handling for the TUI

use anyhow::Result;
use crossterm::event::{self, Event as CrosstermEvent, KeyEvent, MouseEvent};
use std::time::Duration;
use tokio::sync::mpsc;

#[derive(Debug)]
pub enum Event {
    Tick,
    Key(KeyEvent),
    Mouse(MouseEvent),
    Resize(u16, u16),
}

pub struct EventHandler {
    rx: mpsc::UnboundedReceiver<Event>,
    _tx: mpsc::UnboundedSender<Event>,
}

impl EventHandler {
    pub fn new(tick_rate_ms: u64) -> Self {
        let (tx, rx) = mpsc::unbounded_channel();
        let tick_rate = Duration::from_millis(tick_rate_ms);

        let tx_clone = tx.clone();
        tokio::spawn(async move {
            loop {
                if event::poll(tick_rate).unwrap_or(false) {
                    if let Ok(evt) = event::read() {
                        let event = match evt {
                            CrosstermEvent::Key(key) => Event::Key(key),
                            CrosstermEvent::Mouse(mouse) => Event::Mouse(mouse),
                            CrosstermEvent::Resize(w, h) => Event::Resize(w, h),
                            _ => continue,
                        };
                        if tx_clone.send(event).is_err() {
                            break;
                        }
                    }
                } else {
                    if tx_clone.send(Event::Tick).is_err() {
                        break;
                    }
                }
            }
        });

        Self { rx, _tx: tx }
    }

    pub async fn next(&self) -> Result<Event> {
        // Safety: We keep _tx alive so the channel never closes
        Ok(self.rx.recv().await.expect("Event channel closed"))
    }
}
