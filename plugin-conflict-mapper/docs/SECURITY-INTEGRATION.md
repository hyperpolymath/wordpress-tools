# Security Libraries Integration Report

## Overview

This document details the integration of `php-aegis` and `sanctify-php` security libraries into the WP Plugin Conflict Mapper project.

## Libraries Integrated

### php-aegis ✅ Fully Integrated

- **Type**: PHP runtime library (composer dependency)
- **Purpose**: Input validation and sanitization
- **PHP Requirement**: 8.1+ (we require 8.2+)
- **License**: MIT
- **Status**: **Direct dependency via composer**

**Features Used**:
- `PhpAegis\Validator::email()` - Email validation
- `PhpAegis\Validator::url()` - URL validation
- `PhpAegis\Sanitizer::html()` - XSS prevention via htmlspecialchars
- `PhpAegis\Sanitizer::stripTags()` - Tag removal

### sanctify-php ⚙️ Development Workflow

- **Type**: Haskell static analysis tool
- **Purpose**: PHP code transformation and security analysis
- **License**: AGPL-3.0-or-later
- **Status**: **Added to CI/development workflow**

**Features**:
- Adds `declare(strict_types=1)` declarations
- Detects SQL injection, XSS, CSRF, command injection
- WordPress-specific checks (ABSPATH, escaping, nonces, capabilities)
- Taint tracking analysis
- Generates SARIF/JSON/HTML reports

---

## PHP Version Requirements

| Component | Minimum PHP | Notes |
|-----------|-------------|-------|
| Plugin | 8.2 | Modern PHP for security and performance |
| php-aegis | 8.1 | Satisfied by plugin requirement |
| WordPress | 6.4+ | Required for PHP 8.2 support |

### PHP Version Policy

**Hard Floor: PHP 8.0+** - We do not support PHP 7.x under any circumstances.

**Rationale**: If you're running PHP < 8.0, you have far more serious security problems than this plugin can address. PHP 7.4 has been end-of-life since November 2022. Continuing to run EOL PHP versions exposes your site to unpatched vulnerabilities. Upgrading PHP is the single most impactful security improvement you can make - this plugin should not be used as a band-aid for staying on insecure infrastructure.

**Actual Requirement: PHP 8.2+**

| PHP Version | Status | Our Support |
|-------------|--------|-------------|
| 7.4 | EOL Nov 2022 | ❌ Never |
| 8.0 | EOL Nov 2023 | ❌ No (below floor) |
| 8.1 | Security-only | ❌ No (php-aegis minimum) |
| 8.2 | Active support | ✅ **Required** |
| 8.3 | Active support | ✅ Supported |
| 8.4 | Latest stable | ✅ Supported |

**Why 8.2 specifically?**
- Active support until December 2025
- Enables `mixed` type, `never` return type, `match` expressions
- Direct php-aegis integration (requires 8.1+)
- Stable and widely deployed

### WordPress Version Policy

**Hard Floor: WordPress 6.0+** - We do not support WordPress 5.x under any circumstances.

**Rationale**: WordPress 5.x was designed for PHP 7.x and lacks modern security APIs, block editor maturity, and performance improvements present in 6.x. If you're running WordPress < 6.0, you're missing critical security patches and should upgrade immediately. Running outdated WordPress is one of the primary vectors for site compromise - this plugin cannot protect you from that fundamental vulnerability.

**Actual Requirement: WordPress 6.4+**

| WordPress Version | PHP Support | Our Support |
|-------------------|-------------|-------------|
| 5.x | PHP 7.4+ | ❌ Never |
| 6.0-6.3 | PHP 8.0+ | ❌ No (below floor) |
| 6.4 | PHP 8.2+ | ✅ **Minimum** |
| 6.5+ | PHP 8.3+ | ✅ Supported |

**Why 6.4 specifically?**
- First version with full PHP 8.2 support
- Improved security headers and CSP support
- Modern block editor with security fixes
- Active security updates

---

## Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    WPCM_Security Class                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────┐    ┌──────────────────────────────┐  │
│  │   php-aegis          │    │   WordPress Functions        │  │
│  │   ─────────          │    │   ───────────────────        │  │
│  │   Validator::email() │    │   sanitize_text_field()      │  │
│  │   Validator::url()   │    │   sanitize_key()             │  │
│  │   Sanitizer::html()  │    │   wp_verify_nonce()          │  │
│  │   Sanitizer::strip() │    │   current_user_can()         │  │
│  └──────────────────────┘    │   esc_html(), esc_attr()     │  │
│                              └──────────────────────────────┘  │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    Unified WordPress API                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Class Usage

### Validation (via php-aegis)

```php
use WPCM_Security;

// Email validation
if (!WPCM_Security::validate_email($email)) {
    wp_die('Invalid email');
}

// URL validation
if (!WPCM_Security::validate_url($url)) {
    wp_die('Invalid URL');
}
```

### Sanitization (php-aegis + WordPress)

```php
// HTML sanitization (php-aegis)
$safe_html = WPCM_Security::sanitize_html($user_input);

// Text field (WordPress)
$text = WPCM_Security::sanitize_text($input);

// Parameter helpers
$id = WPCM_Security::get_post_param('id', 'int', 0);
$email = WPCM_Security::get_get_param('email', 'email', '');
```

### Security Verification

```php
// Combined nonce + capability check
if (!WPCM_Security::verify_ajax_request('my_action', 'nonce')) {
    WPCM_Security::send_unauthorized();
}
```

---

## sanctify-php Recommendations

For the sanctify-php upstream project:

1. **Pre-built Binaries** - Would greatly simplify CI integration
2. **GitHub Action** - Official action for easy workflow integration
3. **PHP Composer Plugin** - Wrapper to download and run sanctify-php

### Current CI Integration

```yaml
# .github/workflows/security-analysis.yml
# Sanctify-php is commented out pending binary availability
# See workflow file for integration template
```

---

## Files Modified

| File | Change |
|------|--------|
| `includes/class-wpcm-security.php` | Integrates php-aegis Validator/Sanitizer |
| `composer.json` | Added php-aegis dependency, PHP 8.2+ |
| `wp-plugin-conflict-mapper.php` | Updated PHP requirement to 8.2 |
| `.github/workflows/security-analysis.yml` | Security CI workflow |

---

## Version History

| Version | Date | Change |
|---------|------|--------|
| 1.1.0 | 2025-12-27 | Initial php-aegis integration (PHP 7.4 compat layer) |
| 1.2.0 | 2025-12-27 | Full php-aegis integration, PHP 8.2+ requirement |

---

## Integration Learning Report

This section documents lessons learned during the integration process, intended as feedback for the upstream `php-aegis` and `sanctify-php` projects.

### php-aegis Integration Findings

#### What Worked Well

1. **Simple, focused API** - The `Validator` and `Sanitizer` classes have a clean, minimal interface that's easy to understand and integrate.
2. **Zero dependencies** - No external dependencies means no version conflicts with WordPress or other plugins.
3. **PSR-12 compliance** - Code quality is high and follows modern PHP standards.
4. **Type safety** - Strict typing throughout helps catch bugs at development time.

#### Issues Encountered

| Issue | Severity | Description | Suggested Fix |
|-------|----------|-------------|---------------|
| PHP 8.1+ requirement | High | Many WordPress sites still run PHP 7.4/8.0. Initial integration required a compatibility shim. | Consider a `php-aegis-compat` package or conditional feature degradation |
| No WordPress adapter | Medium | WordPress uses snake_case; php-aegis uses camelCase. Required wrapper methods. | Provide optional WordPress adapter |
| Limited validator set | Low | Only email/url validation. Had to use native PHP for int/bool/ip validation. | Expand Validator class with more methods |

#### Recommendations for php-aegis

1. **Priority High**: Document PHP version requirement prominently in README
2. **Priority Medium**: Consider WordPress/Laravel/Symfony adapters
3. **Priority Low**: Add `Validator::int()`, `Validator::ip()`, `Validator::domain()` methods
4. **Priority Low**: Add `Sanitizer::sql()` for prepared statement escaping hints

### sanctify-php Integration Findings

#### What Worked Well

1. **WordPress-aware** - The `Sanctify.WordPress.Constraints` module understands WordPress-specific patterns (ABSPATH, nonces, capabilities).
2. **Comprehensive detection** - Covers OWASP top 10 vulnerabilities with taint tracking.
3. **SARIF output** - Standard format integrates with GitHub Security tab.

#### Issues Encountered

| Issue | Severity | Description | Suggested Fix |
|-------|----------|-------------|---------------|
| Haskell dependency | Critical | Requires full Haskell toolchain (GHC, Cabal). Most PHP developers don't have this. | Pre-built binaries for Linux/macOS/Windows |
| No CI integration | High | No GitHub Action available. Had to write custom workflow (currently commented out). | Official `sanctify-php-action` |
| Installation complexity | High | `cabal install` is unfamiliar to PHP ecosystem. | PHP Composer plugin that downloads binaries |
| No incremental analysis | Medium | Full codebase scan on every run. Slow for large projects. | Cache analysis results, only re-scan changed files |

#### Recommendations for sanctify-php

1. **Priority Critical**: Pre-built binaries (eliminate Haskell requirement for end users)
2. **Priority High**: GitHub Action for CI integration
3. **Priority High**: Composer plugin wrapper (`composer require --dev hyperpolymath/sanctify-php`)
4. **Priority Medium**: Incremental analysis mode for faster CI runs
5. **Priority Low**: VS Code extension for real-time feedback

### General Observations

#### The PHP Security Library Ecosystem Gap

There's a notable gap in the PHP ecosystem for security libraries that are:
- Modern (PHP 8.0+)
- WordPress-compatible
- Zero-dependency
- Well-documented

php-aegis fills part of this gap but could expand to become a more comprehensive solution.

#### Static Analysis Tool Adoption Barriers

The biggest barrier to sanctify-php adoption is the Haskell dependency. PHP developers expect:
- `composer require` installation
- No external runtime dependencies
- Sub-second startup time

Consider compiling to a standalone binary or WASM for browser-based analysis.

### Metrics

| Metric | Before | After |
|--------|--------|-------|
| Files with `strict_types` | 0 | 24 (100%) |
| Files with SPDX headers | 0 | 24 (100%) |
| Centralized security class | No | Yes |
| PHP version | 7.4+ | 8.2+ |
| WordPress version | 5.8+ | 6.4+ |
| External security deps | 0 | 1 (php-aegis) |
| CI security checks | 0 | 4 (PHPStan, WPCS, patterns, strict_types) |
