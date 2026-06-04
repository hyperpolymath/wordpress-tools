<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
// SPDX-License-Identifier: MPL-2.0

# Sinople Theme — Dogfooding Lessons

Learnings from deploying sinople to joshua.jewell.nexus, jonathan.jewell.nexus,
and nuj-lcb.org.uk on Verpex shared hosting (LiteSpeed + cPanel, March 2026).

## Deployment Environment

| Property | Value |
|----------|-------|
| Web Server | LiteSpeed (native, not OLS) |
| PHP | 8.2.29 via LSAPI |
| OPcache | Enabled |
| Redis/Memcached | Not available (shared hosting) |
| APCu | Not available |
| Imagick | Not available |
| CDN | Cloudflare (proxied, Full Strict SSL) |

## Corrective (Bugs Found)

### C1: mu-plugin WP_DEBUG conflict (CRITICAL)
**Problem:** First-run mu-plugin tried to `define('WP_DEBUG', ...)` which conflicts
with wp-config.php's existing definition, causing a fatal error that blocks the
WordPress installer entirely.

**Fix:** Never define constants in mu-plugins that wp-config.php already defines.
Use `defined()` guard or simply don't touch WP_DEBUG in plugins.

**Action:** Add a guard to any generated mu-plugin code:
```php
if (!defined('WP_DEBUG')) { define('WP_DEBUG', false); }
```

### C2: Self-signed SSL blocks Cloudflare Strict mode
**Problem:** New cPanel accounts get self-signed SSL certs. Cloudflare's Full
(Strict) mode rejects these, returning 526/suspended errors. AutoSSL takes
~24 hours to issue Let's Encrypt certs.

**Fix:** Temporarily set Cloudflare SSL to "Full" (not strict) for new domains.
Switch back to "Strict" after AutoSSL completes.

**Action:** Document this in the deployment runbook. Consider adding a Cloudflare
API check to the deployment script that monitors AutoSSL status and switches
SSL mode automatically.

### C3: cPanel package limits block subdomain creation
**Problem:** Default `experien_minimal` package had MAXSUB=1 and MAXSQL=1,
blocking creation of multiple subdomains/databases on the same account.

**Fix:** Updated package to MAXSUB=10, MAXSQL=10 via WHM API, then reapplied
to the account with `changepackage`.

**Action:** Set higher defaults in the package from the start. Add these limits
to the deployment checklist.

## Adaptive (Environment Differences)

### A1: LiteSpeed vs Apache vs nginx
The theme README says "Apache/nginx + PHP-FPM" but the Verpex shared hosting
runs **LiteSpeed** with LSAPI. LiteSpeed Cache plugin works natively (not via
.htaccess rewrite rules as with Apache). This is actually better performance
but the documentation should reflect this.

**Action:** Update CLAUDE.md deployment mode to mention LiteSpeed as a supported
(and preferred) web server. LiteSpeed Cache plugin should be listed as a
recommended plugin for LiteSpeed deployments.

### A2: No object cache on shared hosting
Redis/Memcached are unavailable on shared hosting. LiteSpeed Cache's object
cache mode falls back to file-based. This is adequate for personal sites but
the documentation should note the performance difference.

**Action:** Add a "Hosting Requirements" section to README distinguishing
"recommended" (Redis, PHP 8.3+, Imagick) from "minimum" (PHP 8.1+, OPcache).

### A3: PHP 8.2 vs 8.4
Server runs PHP 8.2.29 (fine) but MultiPHP feature is disabled on the reseller.
The theme's functions.php doesn't use any PHP 8.3+ features so this is safe,
but we should note minimum PHP version explicitly.

**Action:** Add `Requires PHP: 8.1` to style.css theme header.

### A4: Cloudflare performance stack
The full performance stack in production is:
1. LiteSpeed Cache (page cache, CSS/JS combine, WebP, lazy load)
2. Cloudflare (Brotli, minify, Rocket Loader, Early Hints, HTTP/3, aggressive caching)
3. OPcache (bytecode cache)

This three-layer approach delivers ~106ms TTFB on a shared host. Document this
as the recommended production stack.

## Perfective (Improvements)

### P1: Theme file count
The deployed sinople in lcb-website has 51 PHP files. The minimal version
created for jewell.nexus sites has 9 files and still looks correct. Consider
which of the 42 additional files are actually needed vs. aspirational.

**Core files (9):** style.css, functions.php, header.php, footer.php, index.php,
single.php, page.php, 404.php, sidebar.php

**Nice-to-have:** archive.php, search.php, comments.php, template-parts/*,
inc/custom-post-types.php, inc/semantic.php, inc/indieweb.php

**Only needed for semantic features:** single-construct.php,
single-entanglement.php, inc/taxonomies.php, WASM modules

**Action:** Create a "sinople-lite" variant that ships only the 9 core files
plus archive.php and search.php. The full semantic/IndieWeb/WASM stack remains
in sinople-full.

### P2: Automated deployment script
The deployment process requires 6 separate cPanel API calls (create subdomain,
create database, create user, grant privileges, upload WordPress, configure).
This should be a single `just deploy-wordpress <domain>` recipe.

**Action:** Create `scripts/deploy-wordpress.sh` that automates the full flow
via WHM API. Include Cloudflare DNS record creation.

### P3: Security hardening defaults
The following settings should be baked into the theme's functions.php rather
than requiring manual configuration:
- Disable file editor (`DISALLOW_FILE_EDIT`)
- Disable XML-RPC (unless needed)
- Disable pingbacks and trackbacks
- Close comments by default
- Remove WordPress version from headers

**Action:** Add these to functions.php as opt-out (enabled by default, can be
disabled via theme customizer).

### P4: LiteSpeed Cache optimal defaults
Document the optimal LiteSpeed Cache settings as a deployable configuration:
- Page cache: on
- Browser cache: on
- Mobile cache: on (separate)
- CSS/JS minify + combine: on
- Google Fonts async: on
- Image lazy load: on
- WebP replace: on
- Crawler: on
- Public TTL: 7 days
- Feed TTL: 1 hour

**Action:** Create `config/litespeed-cache.json` with these defaults that can
be imported via the LiteSpeed Cache plugin's import feature.

### P5: Cloudflare baseline settings
Document and script the Cloudflare security + performance baseline:

**Security:** SSL strict, TLS 1.2 min, Always HTTPS, HSTS (1yr, subdomains),
TLS 1.3 0-RTT, security level high, browser integrity check, email obfuscation,
hotlink protection.

**Performance:** Brotli, auto minify (CSS+JS+HTML), Early Hints, HTTP/3,
Rocket Loader, aggressive caching, respect origin cache headers.

**Action:** Create `scripts/cloudflare-baseline.sh` that applies these settings
to any zone via the Cloudflare API.

### P6: Replace innerHTML with rescript-dom-mounter (CRITICAL)
panic-attack flagged innerHTML usage in graph-viewer.js and navigation.js as
HIGH severity. The correct fix is NOT to replace innerHTML with createElement
(that's just a different unsafe API). The correct fix is to use
**rescript-dom-mounter** (`hyperpolymath/rescript-dom-mounter`) which provides:

- 4-layer defence-in-depth (validation, DOMPurify, Trusted Types, CSP nonce)
- `mountStringParsed` — DOMParser-based mounting with NO innerHTML sink
- Compile-time guarantees via opaque `validSelector` and `validHtml` types
- Formal verification of mount correctness via Idris2 ABI proofs

**Action:** Add rescript-dom-mounter as a dependency. Rewrite graph-viewer.js
and navigation.js in ReScript using SafeDOM.mountStringParsed. Remove all raw
innerHTML/document.write calls from the theme's JS. This is the whole point of
the library — eat your own dogfood.

```rescript
// Before (UNSAFE):
// element.innerHTML = graphHtml

// After (PROVEN SAFE):
open SafeDOM
let _ = mountStringParsed("#graph-container", graphHtml)
```

## Performance Benchmarks (2026-03-16)

| Site | TTFB | Total | Size | Notes |
|------|------|-------|------|-------|
| joshua.jewell.nexus | 106ms | 107ms | 3.1KB | Fresh install, no content |
| jonathan.jewell.nexus | 116ms | 116ms | 3.1KB | Fresh install, no content |
| nuj-lcb.org.uk | 150ms | 151ms | 1.0KB | Redirect (suspended?) |

Benchmark conditions: curl via Cloudflare, HTTP/1.1, single request (no warm cache).
LiteSpeed Cache crawler has not run yet — expect faster responses after crawl.
