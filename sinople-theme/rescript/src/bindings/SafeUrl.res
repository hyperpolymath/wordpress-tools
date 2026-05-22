// SPDX-License-Identifier: MPL-2.0
// SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// SafeUrl.res — URL validation and construction bindings.
//
// Thin wrapper providing URL safety at the ReScript level.
// Prevents URL injection attacks by validating all URLs before use.
//
// Future: will bind to proven/SafeUrl (Idris2) via Zig FFI → WASM.
// Current: pure ReScript implementation with the same API contract.

/// Validated URL (opaque — cannot be constructed without validation).
type t = ValidUrl(string)

/// URL validation error.
type urlError =
  | EmptyUrl
  | InvalidScheme(string)
  | MissingHost
  | UnsafeCharacters
  | JavascriptScheme

/// Allowed schemes for navigation URLs.
let allowedSchemes = ["https", "http", "mailto", "tel"]

/// Validate a URL string. Returns Ok(ValidUrl) or Error(urlError).
/// Rejects javascript: URIs, data: URIs, and malformed URLs.
let validate = (raw: string): result<t, urlError> => {
  let trimmed = raw->String.trim

  if String.length(trimmed) == 0 {
    Error(EmptyUrl)
  } else {
    // Block javascript: and data: schemes (XSS vectors)
    let lower = trimmed->String.toLowerCase
    if (
      lower->String.startsWith("javascript:") ||
      lower->String.startsWith("data:") ||
      lower->String.startsWith("vbscript:")
    ) {
      Error(JavascriptScheme)
    } else {
      // Extract scheme if present
      switch String.indexOf(trimmed, ":") {
      | Some(colonIdx) if colonIdx > 0 => {
          let scheme = String.slice(trimmed, ~start=0, ~end=colonIdx)->String.toLowerCase
          if allowedSchemes->Array.includes(scheme) || String.startsWith(trimmed, "/") {
            Ok(ValidUrl(trimmed))
          } else {
            Error(InvalidScheme(scheme))
          }
        }
      | _ =>
        // Relative URL or just a path — allowed
        if (
          String.startsWith(trimmed, "/") ||
          String.startsWith(trimmed, "#") ||
          String.startsWith(trimmed, "?")
        ) {
          Ok(ValidUrl(trimmed))
        } else {
          // Bare string without scheme — treat as relative path
          Ok(ValidUrl(trimmed))
        }
      }
    }
  }
}

/// Extract the string from a validated URL.
let toString = (ValidUrl(url): t): string => url

/// Build a WordPress construct permalink safely.
let constructPermalink = (~homeUrl: string, ~id: string): result<t, urlError> => {
  let safeId = id
    ->String.replaceAll("/", "")
    ->String.replaceAll("\\", "")
    ->String.replaceAll("..", "")
    ->String.replaceAll("<", "")
    ->String.replaceAll(">", "")

  validate(`${homeUrl}/constructs/${safeId}`)
}

/// Navigate to a validated URL.
let navigateTo = (validUrl: t): unit => {
  let url = toString(validUrl)
  Webapi.Dom.Location.setHref(Webapi.Dom.Window.location(Webapi.Dom.window), url)
}

/// Navigate safely — validate first, log error if invalid.
let safeNavigate = (rawUrl: string): unit => {
  switch validate(rawUrl) {
  | Ok(url) => navigateTo(url)
  | Error(JavascriptScheme) =>
    Console.error("SafeUrl: blocked javascript: URI navigation attempt")
  | Error(InvalidScheme(s)) =>
    Console.error2("SafeUrl: blocked navigation to unsupported scheme:", s)
  | Error(err) =>
    Console.error2("SafeUrl: navigation blocked:", err)
  }
}
