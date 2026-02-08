# Security Integration Report

Integration of `php-aegis` and `sanctify-php` into `wp-sinople-theme`.

## Summary

| Aspect | Status |
|--------|--------|
| php-aegis integration | Partial - wrapper created |
| sanctify-php integration | Planned - requires Haskell build |
| Security fixes applied | 6 fixes |
| Files hardened | 9 PHP files |

## What Was Done

### 1. Composer Integration

Created `wordpress/composer.json` with:
- `hyperpolymath/php-aegis` as dependency
- PHPStan and PHP-CS-Fixer for dev

```bash
cd wordpress && composer install
```

### 2. Security Wrapper Module

Created `wordpress/inc/security.php` providing:

| Function | Purpose |
|----------|---------|
| `sinople_security()` | Get singleton security instance |
| `Sinople_Security::sanitize_html()` | XSS prevention (wraps php-aegis) |
| `Sinople_Security::validate_email()` | Email validation (wraps php-aegis) |
| `Sinople_Security::validate_url()` | URL validation (wraps php-aegis) |
| `Sinople_Security::escape_turtle_string()` | RDF Turtle literal escaping |
| `Sinople_Security::escape_turtle_iri()` | RDF Turtle IRI escaping |
| `Sinople_Security::is_safe_turtle_literal()` | Turtle injection detection |
| `Sinople_Security::sanitize_micropub_content()` | Micropub content sanitization |
| `Sinople_Security::verify_indieauth_token()` | IndieAuth token verification |
| `Sinople_Security::add_security_headers()` | HTTP security headers |

### 3. Security Fixes Applied

#### 3.1 RDF Turtle Injection (semantic.php)

**Before:** Used `addslashes()` for Turtle escaping - incorrect and vulnerable.

**After:** Proper Turtle string escaping per W3C spec with:
- Backslash/quote escaping
- Control character filtering
- IRI percent-encoding
- Type value whitelisting

#### 3.2 Micropub Content Injection (indieweb.php)

**Before:** `$data['content']` used directly without sanitization.

**After:**
- Full content sanitization via `sanitize_micropub_content()`
- HTML content uses `wp_kses_post()`
- Text content uses `sanitize_textarea_field()`
- Array/object content structures handled properly
- Categories sanitized and validated

#### 3.3 IndieAuth Token Verification (indieweb.php)

**Before:** Token permission callback returned `true` without verification.

**After:**
- Full IndieAuth token verification against endpoint
- Scope checking (requires `create` or `post`)
- Site URL validation
- GET requests for config allowed without auth

#### 3.4 Strict Types (all PHP files)

Added `declare(strict_types=1)` to:
- `functions.php`
- `inc/security.php`
- `inc/semantic.php`
- `inc/indieweb.php`
- `inc/custom-post-types.php`
- `inc/customizer.php`
- `inc/taxonomies.php`
- `inc/widgets.php`
- `inc/accessibility.php`

#### 3.5 Security Headers

Added automatic HTTP security headers:
- Content-Security-Policy
- X-Content-Type-Options: nosniff
- X-XSS-Protection: 1; mode=block
- X-Frame-Options: SAMEORIGIN
- Referrer-Policy: strict-origin-when-cross-origin
- Permissions-Policy

---

## Issues for Upstream Repositories

### php-aegis Issues

#### Issue 1: Minimal Feature Set

**Problem:** php-aegis only provides basic `html()`, `stripTags()`, `email()`, and `url()` functions. WordPress already has equivalents (`esc_html()`, `strip_tags()`, `is_email()`, `filter_var()`).

**Recommendation:** Expand php-aegis to provide value beyond built-in functions:

```php
// Suggested additions for php-aegis
class Sanitizer {
    // Existing
    public function html(string $input): string;
    public function stripTags(string $input): string;

    // NEW: Context-aware escaping
    public function forAttribute(string $input): string;
    public function forUrl(string $input): string;
    public function forJavaScript(string $input): string;
    public function forCss(string $input): string;

    // NEW: Format-specific escaping
    public function forJson(string $input): string;
    public function forSql(string $input, string $driver = 'mysql'): string;
    public function forRdfTurtle(string $input): string;  // <-- Added for Sinople
    public function forXml(string $input): string;

    // NEW: Framework adapters
    public function wordPress(): WordPressSanitizer;
    public function laravel(): LaravelSanitizer;
}

class Validator {
    // Existing
    public function email(string $email): bool;
    public function url(string $url): bool;

    // NEW: Additional validators
    public function uuid(string $uuid): bool;
    public function slug(string $slug): bool;
    public function iri(string $iri): bool;  // <-- For RDF
    public function jwt(string $token): bool;
    public function alphanumeric(string $input): bool;

    // NEW: Configurable validators
    public function matches(string $input, string $pattern): bool;
    public function inList(string $input, array $allowed): bool;
}
```

#### Issue 2: No PHP 8.1+ Type Declarations

**Problem:** php-aegis requires PHP 8.1+ but doesn't use union types, enums, or other PHP 8.1 features.

**Recommendation:** Add return type declarations, use enums for escaping contexts:

```php
enum EscapeContext: string {
    case HTML = 'html';
    case ATTRIBUTE = 'attr';
    case URL = 'url';
    case JS = 'js';
    case CSS = 'css';
}

public function escape(string $input, EscapeContext $context): string;
```

#### Issue 3: Missing SPDX License Header

**Problem:** PHP files lack SPDX license headers per Hyperpolymath standard.

**Fix:** Add to all source files:
```php
<?php
// SPDX-License-Identifier: PMPL-1.0-or-later
```

---

### sanctify-php Issues

#### Issue 1: Haskell Build Dependency

**Problem:** Requires GHC and Cabal, which aren't commonly installed. Cannot easily integrate into PHP/WordPress CI pipelines.

**Recommendation:**
1. Provide pre-built binaries for common platforms (Linux x86_64, macOS arm64)
2. Add Docker container: `hyperpolymath/sanctify-php`
3. Create GitHub Action for easy CI integration

```yaml
# Suggested GitHub Action
- uses: hyperpolymath/sanctify-php-action@v1
  with:
    path: ./wordpress/
    fix: true
    report: sarif
```

#### Issue 2: Incomplete PHP Parser

**Problem:** Parser may not handle all PHP 8.x syntax (attributes, named arguments, match expressions, enums, etc.).

**Recommendation:** Add tests for PHP 8.x features:
- `#[Attribute]` syntax
- Named arguments: `fn(param: value)`
- Match expressions
- Enums
- Constructor property promotion
- Union/intersection types
- `readonly` properties

#### Issue 3: WordPress Detection Heuristics

**Problem:** `isWordPressCode` only checks for `wp_` prefixes and hook functions. May miss WordPress code that uses different patterns.

**Recommendation:** Improve detection:
```haskell
isWordPressCode file =
    hasAbspathCheck file ||
    hasWordPressPrefix file ||
    usesWordPressHooks file ||
    hasWordPressComments file ||  -- Check for "@package WordPress" etc.
    importsWordPressNamespace file
```

#### Issue 4: RDF/Turtle Awareness

**Problem:** No awareness of RDF/Turtle output contexts. The theme's RDF endpoints could be missed.

**Recommendation:** Add RDF-specific checks:
```haskell
data WpIssueType
    = ...
    | UnsafeTurtleOutput     -- NEW: RDF Turtle injection risk
    | UnsafeJsonLdOutput     -- NEW: JSON-LD injection risk
```

Check for patterns like:
- String interpolation in Turtle output
- Using `addslashes()` for Turtle (wrong escaping)
- Unvalidated IRIs

#### Issue 5: Missing Integration Docs

**Problem:** No documentation on how to integrate with specific WordPress themes/plugins.

**Recommendation:** Add integration guide with:
- Composer integration (as dev dependency)
- Pre-commit hook setup
- CI/CD pipeline examples
- WordPress-specific configuration

---

## Recommendations for This Theme

### Immediate (Already Done)

- [x] Add `declare(strict_types=1)` to all PHP files
- [x] Fix Turtle escaping in semantic.php
- [x] Fix Micropub sanitization in indieweb.php
- [x] Add IndieAuth token verification
- [x] Add security headers

### Short-term

1. **Install Composer dependencies**
   ```bash
   cd wordpress && composer install
   ```

2. **Run sanctify-php analysis** (when built)
   ```bash
   sanctify analyze ./wordpress/
   ```

3. **Add PHPStan CI check**
   ```bash
   composer analyze
   ```

### Long-term

1. **Rate Limiting**: Add rate limiting to REST endpoints (webmention, micropub, semantic-graph)

2. **Input Validation**: Add JSON Schema validation for Micropub requests

3. **Audit Logging**: Log security-relevant events (failed auth, rate limit hits)

4. **CSP Nonces**: Generate nonces for inline scripts to strengthen CSP

---

## Files Changed

```
wordpress/
├── composer.json                    # NEW: Composer config with php-aegis
├── functions.php                    # MODIFIED: Added strict_types, security include
├── inc/
│   ├── security.php                 # NEW: Security wrapper module
│   ├── semantic.php                 # MODIFIED: Fixed Turtle escaping
│   ├── indieweb.php                 # MODIFIED: Fixed auth and sanitization
│   ├── custom-post-types.php        # MODIFIED: Added strict_types
│   ├── customizer.php               # MODIFIED: Added strict_types
│   ├── taxonomies.php               # MODIFIED: Added strict_types
│   ├── widgets.php                  # MODIFIED: Added strict_types
│   └── accessibility.php            # MODIFIED: Added strict_types
```

---

## Testing

```bash
# Syntax check all PHP files
find wordpress -name "*.php" -exec php -l {} \;

# Run PHPStan (after composer install)
cd wordpress && composer analyze

# Test theme loads correctly
wp theme activate sinople  # (in WordPress environment)
```

---

*Report generated: 2025-12-27*
*Integration: php-aegis + sanctify-php into wp-sinople-theme*
