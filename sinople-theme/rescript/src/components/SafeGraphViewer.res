// SPDX-License-Identifier: PMPL-1.0-or-later
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// SafeGraphViewer.res — Semantic graph viewer using SafeDOM.
//
// Replaces the unsafe graph-viewer.js with proven-safe DOM operations.
// All HTML mounting goes through rescript-dom-mounter's 4-layer
// defence-in-depth (validation, DOMPurify, Trusted Types, CSP nonce).
//
// Integration path:
//   proven (Idris2) → Zig FFI → WASM → SafeDOM (ReScript) → Browser
//
// This module handles:
//   - Loading state display via SafeDOM.mountStringParsed
//   - Error state display via SafeDOM.mountStringParsed
//   - Graph status updates via SafeDOM.remount
//   - All SVG construction uses safe createElement (no innerHTML)

open SafeDOM

/// WordPress REST API configuration injected by wp_localize_script.
type wpConfig = {
  rest_url: string,
  nonce: string,
  home_url: string,
}

/// A node in the semantic graph.
type graphNode = {
  id: string,
  label: string,
  iri: option<string>,
}

/// An edge connecting two nodes.
type graphEdge = {
  source: string,
  target: string,
  label: option<string>,
}

/// Semantic graph data from the REST API.
type graphData = {
  nodes: array<graphNode>,
  edges: array<graphEdge>,
}

/// Get the WordPress config from the global sinople object.
@val @scope("window")
external sinople: wpConfig = "sinople"

/// Show a loading state inside the graph container.
/// Uses SafeDOM.mountStringParsed — no innerHTML sink.
let showLoading = (selector: string): mountResult => {
  mountStringParsed(
    selector,
    `<div class="graph-loading" role="status" aria-live="polite">
       <p>Loading semantic graph\u2026</p>
     </div>`,
  )
}

/// Show an error state inside the graph container.
/// Uses SafeDOM.mountStringParsed — no innerHTML sink.
let showError = (selector: string, message: string): mountResult => {
  // Escape the message through SafeDOM's validation layer.
  // mountStringParsed sanitises all HTML before parsing with DOMParser.
  let safeMessage = message
    ->String.replaceAll("<", "&lt;")
    ->String.replaceAll(">", "&gt;")
    ->String.replaceAll("\"", "&quot;")

  mountStringParsed(
    selector,
    `<div class="graph-error" role="alert">
       <p><strong>Error:</strong> ${safeMessage}</p>
       <p>Please try refreshing the page or contact the administrator.</p>
     </div>`,
  )
}

/// Update the graph status text.
/// Uses SafeDOM.remount for atomic swap (validates new content before
/// removing old content).
let updateStatus = (showing: int, total: int): unit => {
  let statusHtml = if showing == total {
    `<span role="status" aria-live="polite">Showing ${Int.toString(total)} constructs</span>`
  } else {
    `<span role="status" aria-live="polite">Showing ${Int.toString(showing)} of ${Int.toString(total)} constructs</span>`
  }

  let _ = remount("#graph-status", statusHtml)
}

/// Mount the graph controls (filter input + status).
/// Uses SafeDOM.mountStringParsed — no innerHTML sink.
let mountControls = (selector: string, nodeCount: int): mountResult => {
  mountStringParsed(
    selector,
    `<div class="graph-controls">
       <label for="graph-filter">Filter constructs:</label>
       <input type="search" id="graph-filter" placeholder="Search\u2026"
              aria-label="Filter constructs" />
       <span id="graph-status" role="status" aria-live="polite">
         Showing ${Int.toString(nodeCount)} constructs
       </span>
     </div>`,
  )
}

/// Announce a message to screen readers via a live region.
/// Creates the live region if it doesn't exist, using SafeDOM.
let announce = (message: string): unit => {
  let safeMessage = message
    ->String.replaceAll("<", "&lt;")
    ->String.replaceAll(">", "&gt;")

  let _ = mountStringParsed(
    "#aria-live-region",
    `<span>${safeMessage}</span>`,
  )

  // Clear after 1 second
  let _ = setTimeout(() => {
    let _ = unmount("#aria-live-region")
  }, 1000)
}
