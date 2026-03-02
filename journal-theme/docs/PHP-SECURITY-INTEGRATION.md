# PHP Security Integration with php-aegis and sanctify-php

This document describes the integration of Hyperpolymath's PHP security tools with the Sinople WordPress theme.

## Overview

Sinople integrates two complementary security tools:

1. **php-aegis**: Runtime PHP security library for input validation, output sanitization, and Turtle/RDF escaping
2. **sanctify-php**: Static analysis tool for PHP security hardening (CI/CD integration)

## php-aegis Integration

### Added Files

- `inc/aegis-integration.php` - WordPress-style function wrappers
- `inc/turtle-output.php` - RDF Turtle feed generation

### Features Used

| Feature | Sinople Use Case | Fallback |
|---------|------------------|----------|
| `Sanitizer::html()` | Template output | `esc_html()` |
| `Sanitizer::attr()` | Attribute escaping | `esc_attr()` |
| `Sanitizer::json()` | JSON-LD output | `wp_json_encode()` |
| `Validator::url()` | URL validation | `filter_var()` |
| `Validator::httpsUrl()` | HTTPS enforcement (RSR) | Manual check |
| `TurtleEscaper` | RDF/Turtle feed | Manual escaping |

### TurtleEscaper - Unique Value

The TurtleEscaper is particularly valuable for Sinople's semantic web focus. It provides:

- W3C-compliant string escaping for Turtle literals
- IRI validation and escaping per RFC 3987
- Language tag validation (BCP 47)
- Safe triple construction

This enables the new `/feed/turtle/` endpoint for RDF consumers.

### WordPress Function Wrappers

All php-aegis features are wrapped with WordPress-style functions that:
1. Check if php-aegis is available
2. Use php-aegis if loaded
3. Fall back to WordPress/PHP equivalents otherwise

Example:
```php
// Uses php-aegis if available, otherwise esc_html()
echo sinople_aegis_html($user_input);
```

## sanctify-php Integration

### CI Integration

The `.github/workflows/php-security.yml` workflow now includes:

1. **Basic grep-based scanning** (original)
2. **sanctify-php AST analysis** (new)
3. **php-aegis verification** (new)

### What sanctify-php Checks

- Missing `declare(strict_types=1)`
- Missing ABSPATH protection
- Unescaped output in echo statements
- Direct superglobal access without sanitization
- `wp_redirect()` without `exit`
- Missing text domains in i18n functions
- Direct database queries without `prepare()`

### Local Usage

```bash
# If sanctify is installed
sanctify analyze ./inc/
sanctify fix ./inc/  # Preview fixes
sanctify report ./ > security-report.json
```

## Compatibility Notes

### PHP Version

Both tools require **PHP 8.1+**, which matches Sinople's requirement.

### License Compatibility

| Tool | License | Sinople (GPL-3.0) |
|------|---------|-------------------|
| php-aegis | MIT | Compatible |
| sanctify-php | AGPL-3.0 | Compatible (build tool only) |

### WordPress Overlap

php-aegis COMPATIBILITY.md correctly notes that WordPress has built-in escaping. However, Sinople benefits from:

1. **TurtleEscaper** - Not available in WordPress
2. **Stricter validation** - `httpsUrl()` for RSR compliance
3. **Headers utilities** - Cleaner API with `removeInsecureHeaders()`

---

## Issues to Report to Upstream Repositories

### php-aegis Issues

#### 1. Missing php-aegis-compat Package
**File**: `COMPATIBILITY.md`
**Issue**: The document references `hyperpolymath/php-aegis-compat` for PHP 7.4+ support, but this package doesn't exist.
**Impact**: WordPress users on PHP 7.4/8.0 cannot use the library.
**Recommendation**: Either create the compat package or update documentation to clarify it's planned but not yet available.

#### 2. No Packagist Publication
**Issue**: php-aegis is not on Packagist, requiring VCS repository configuration in composer.json.
**Impact**: Harder installation, no version resolution through Packagist.
**Recommendation**: Publish to Packagist for standard Composer installation.

#### 3. WordPress Adapter Not Implemented
**File**: `COMPATIBILITY.md`
**Issue**: Describes WordPress mu-plugin adapter but it doesn't exist in the repo.
**Recommendation**: Either implement the adapter or mark as "proposed" in documentation.

#### 4. Missing Security Headers
**File**: `src/Headers.php`
**Issue**: Missing `Permissions-Policy` in `secure()` method despite having `permissionsPolicy()` helper.
**Recommendation**: Add default permissions policy to `secure()`.

### sanctify-php Issues

#### 1. Parser PHP 8.1+ Syntax
**Concern**: Verify parser handles all PHP 8.1+ features:
- Constructor property promotion
- Named arguments
- Match expressions
- Nullsafe operator (`?->`)
**Recommendation**: Add test cases for these syntax elements.

#### 2. UnsafeRedirect False Positives
**File**: `src/Sanctify/WordPress/Constraints.hs`
**Issue**: `UnsafeRedirect` check flags `wp_redirect()` without checking if `exit` is on the next line.
**Current**: Only checks same statement
**Expected**: Should check subsequent statement
**Example** (should not flag):
```php
wp_redirect($url);
exit;
```

#### 3. MissingTextDomain False Positives
**Issue**: May flag internal WordPress functions that don't need text domain.
**Example**: `__()` used with WordPress core text domain.
**Recommendation**: Add allowlist for core WordPress text domains.

#### 4. Guix Export Documentation
**Issue**: `sanctify export --guix` referenced but Guix configuration examples incomplete.
**Recommendation**: Add complete Guix container example in docs.

---

## Testing the Integration

### Verify php-aegis is loaded

```php
if (sinople_aegis_available()) {
    echo "php-aegis loaded";
} else {
    echo "Using fallbacks";
}
```

### Test Turtle output

Visit `/feed/turtle/` to see RDF output.

### Run sanctify locally

```bash
# Install (requires Haskell toolchain)
cd /tmp && git clone https://github.com/hyperpolymath/sanctify-php
cd sanctify-php && cabal install

# Analyze theme
sanctify analyze /path/to/sinople-theme
```

---

## Future Enhancements

1. **Structured RDFa Output**: Extend turtle-output.php to support RDFa attributes in HTML
2. **JSON-LD with php-aegis**: Use `Sanitizer::json()` for safer JSON-LD output
3. **Pre-commit Hook**: Add sanctify analysis to git pre-commit
4. **Editor Integration**: LSP support for sanctify-php in VS Code/Neovim

---

*Document created during php-aegis and sanctify-php integration into sinople-theme.*
*Last updated: 2025-12-27*
