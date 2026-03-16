// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// SafeNavigation.res — Accessible navigation using SafeDOM.
//
// Replaces navigation.js's DOM construction with proven-safe operations.
// The keyboard navigation and focus management logic stays in JS (it uses
// addEventListener, not innerHTML), but any DOM content injection goes
// through rescript-dom-mounter.
//
// The announceToScreenReader function is reimplemented here using
// SafeDOM.mountStringParsed instead of textContent assignment.

open SafeDOM

/// Create the ARIA live region for screen reader announcements.
/// Uses SafeDOM.mountWhenReady to ensure DOM is available.
let initLiveRegion = (): unit => {
  onDOMReady(() => {
    // Only create if it doesn't already exist
    switch Webapi.Dom.Document.getElementById(Webapi.Dom.document, "aria-live-region") {
    | Some(_) => () // Already exists
    | None => {
        let _ = mountStringParsed(
          "body",
          `<div id="aria-live-region" aria-live="polite" aria-atomic="true"
                class="screen-reader-text" style="position:absolute;width:1px;height:1px;
                padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);
                white-space:nowrap;border:0"></div>`,
        )
      }
    }
  })
}

/// Announce a message to screen readers.
/// Uses SafeDOM.remount for atomic content swap.
let announce = (message: string): unit => {
  let safeMessage = message
    ->String.replaceAll("<", "&lt;")
    ->String.replaceAll(">", "&gt;")

  let _ = remount("#aria-live-region", `<span>${safeMessage}</span>`)

  // Clear after 1 second so repeated announcements are read
  let _ = setTimeout(() => {
    let _ = unmount("#aria-live-region")
  }, 1000)
}
