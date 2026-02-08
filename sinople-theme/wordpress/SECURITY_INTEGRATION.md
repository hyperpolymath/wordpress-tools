# Security Integration Report

## Overview

This document captures the integration of `php-aegis` and `sanctify-php` security tools into the Sinople WordPress theme, including issues discovered and recommendations for upstream repositories.

## Integration Summary

### php-aegis Integration

**Status**: Successfully integrated

**Components Used**:
- `Validator` - Input validation for URLs, emails, etc.
- `Sanitizer` - Output sanitization (HTML, JS, CSS contexts)
- `Headers` - HTTP security headers (CSP, HSTS, X-Frame-Options, etc.)
- `TurtleEscaper` - W3C-compliant RDF Turtle escaping (critical for this semantic web theme)

**Location**: `wordpress/vendor/php-aegis/`

### sanctify-php Analysis

**Status**: Analyzed (Haskell static analysis tool - not embedded in PHP)

**Recommendations Applied**:
- Added `declare(strict_types=1)` to all PHP files
- Improved type hints on function signatures
- Added return type declarations where applicable

---

## Issues for php-aegis Repository

### Issue 1: WordPress-specific Validator Methods Needed

**Severity**: Enhancement

**Description**: When integrating with WordPress, common validation patterns are needed that could be added to php-aegis:

```php
// Suggested additions to Validator class:
public static function wpNonce(string $nonce, string $action): bool;
public static function wpCapability(string $capability): bool;
public static function wpPostId(mixed $id): bool;
```

**Workaround Used**: Used WordPress native functions (`wp_verify_nonce`, `current_user_can`, `absint`)

---

### Issue 2: TurtleEscaper Language Tag Case Sensitivity

**Severity**: Minor

**Description**: `TurtleEscaper::languageTag()` normalizes to lowercase, but BCP 47 recommends preserving case for readability (e.g., `en-US` not `en-us`).

**Location**: `src/TurtleEscaper.php:123`

**Recommendation**: Consider making lowercase normalization optional or documenting the behavior.

---

### Issue 3: Headers Class WordPress Compatibility

**Severity**: Documentation

**Description**: When using `Headers::secure()` in WordPress:
1. Must check `is_admin()` and `wp_doing_ajax()` to avoid breaking admin
2. Must check `headers_sent()` before setting headers
3. CSP `'unsafe-inline'` and `'unsafe-eval'` are required for WordPress admin

**Recommendation**: Add WordPress integration example to documentation:

```php
function my_theme_security_headers(): void {
    if ( is_admin() || wp_doing_ajax() || headers_sent() ) {
        return;
    }
    // Then use Headers class...
}
add_action( 'send_headers', 'my_theme_security_headers' );
```

---

### Issue 4: Missing SPDX Header Validation

**Severity**: Enhancement

**Description**: For projects requiring SPDX license headers, a validator method would be useful:

```php
public static function spdxIdentifier(string $identifier): bool;
```

---

## Issues for sanctify-php Repository

### Issue 1: WordPress Hook Detection

**Severity**: Enhancement

**Description**: When analyzing WordPress themes/plugins, sanctify-php should recognize WordPress-specific patterns:

1. **Hook callbacks**: Functions passed to `add_action()` and `add_filter()` may have parameters injected by WordPress
2. **Template tags**: Functions like `the_title()`, `the_content()` auto-escape in certain contexts
3. **Nonce verification**: `wp_verify_nonce()` + `wp_nonce_field()` patterns

**Example false positive scenario**:
```php
// sanctify-php might flag this as missing sanitization
// but WordPress escapes template tag output
function my_callback() {
    the_title(); // Auto-escaped by WordPress
}
```

---

### Issue 2: RDF Turtle Output Context

**Severity**: Feature Request

**Description**: sanctify-php should recognize RDF Turtle as an output context distinct from HTML/SQL.

**Current behavior**: `addslashes()` in RDF contexts is flagged as SQL-related (correct to flag, but for wrong reason)

**Recommended enhancement**:
- Detect Turtle format output (Content-Type: text/turtle)
- Flag `addslashes()` as incorrect for Turtle (should use Turtle-specific escaping)
- Suggest using `TurtleEscaper` or similar library

---

### Issue 3: WordPress REST API Patterns

**Severity**: Enhancement

**Description**: WordPress REST API has built-in sanitization via `sanitize_callback` and `validate_callback` in route args. These should be recognized:

```php
register_rest_route('namespace', '/route', [
    'args' => [
        'param' => [
            'sanitize_callback' => 'sanitize_text_field', // Safe
            'validate_callback' => function($v) { return is_numeric($v); }
        ]
    ]
]);
```

---

## Security Improvements Applied

### CRITICAL Fixes

1. **RDF Turtle Injection Prevention** (`inc/semantic.php`)
   - **Before**: Used `addslashes()` for Turtle string escaping (SQL escaping, not Turtle)
   - **After**: Uses `TurtleEscaper::literal()` and `TurtleEscaper::iri()` for W3C-compliant escaping
   - **Impact**: Prevents RDF injection attacks in semantic web output

2. **IRI Validation** (`inc/semantic.php`)
   - **Before**: Direct IRI interpolation without validation
   - **After**: Uses `Validator::url()` + `TurtleEscaper::iri()` with error handling
   - **Impact**: Prevents malformed/malicious IRIs in RDF output

### HIGH Fixes

3. **URL Origin Validation** (`inc/indieweb.php`)
   - **Before**: Used `strpos()` which could be bypassed with query strings
   - **After**: Uses `parse_url()` with proper host/scheme/port comparison
   - **Impact**: Prevents Webmention target manipulation attacks

4. **Input Sanitization for Micropub** (`inc/indieweb.php`)
   - **Before**: Direct use of `$data['name']` and `$data['content']`
   - **After**: Uses `sanitize_text_field()` and `wp_kses_post()`
   - **Impact**: Prevents XSS via Micropub content injection

### MEDIUM Fixes

5. **HTTP Security Headers** (`functions.php`)
   - Added comprehensive security headers via `PhpAegis\Headers`
   - CSP, HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy
   - **Impact**: Defense in depth against XSS, clickjacking, MIME sniffing

6. **Rate Limiting for Webmentions** (`inc/indieweb.php`)
   - Added 1-minute rate limit per source URL
   - **Impact**: Prevents Webmention spam/flooding

7. **Strict Types Enforcement**
   - Added `declare(strict_types=1)` to all PHP files
   - **Impact**: Catches type errors early, prevents type juggling attacks

---

## Testing Recommendations

1. **RDF Output Validation**
   - Verify Turtle output parses correctly with RDF validator
   - Test with special characters: `"quotes"`, `\backslash`, `newlines\n`, unicode
   - Verify IRI escaping handles all RFC 3987 disallowed characters

2. **Security Headers**
   - Use securityheaders.com to verify headers are set correctly
   - Test that admin panel still functions with CSP
   - Verify HSTS only sets on HTTPS

3. **Webmention/Micropub**
   - Test URL validation with edge cases (query strings, fragments, non-standard ports)
   - Verify rate limiting blocks rapid requests
   - Test Micropub with various content types

---

## Future Recommendations

1. **Implement IndieAuth Token Verification**
   - Current Micropub auth is placeholder only
   - Must verify tokens with IndieAuth token endpoint before production

2. **Add CSP Nonces for Inline Scripts**
   - Current CSP uses `'unsafe-inline'` for WordPress compatibility
   - Consider nonce-based approach for stricter security

3. **WASM Content Security**
   - Add specific CSP rules for WASM module loading
   - Consider Subresource Integrity (SRI) for WASM files

4. **Automated Security Scanning**
   - Integrate sanctify-php into CI/CD pipeline
   - Run PHPStan with strict rules
   - Add security-focused test suite

---

## Version Information

- **php-aegis**: Integrated from hyperpolymath/php-aegis
- **sanctify-php**: Analysis tool from hyperpolymath/sanctify-php
- **Integration Date**: 2025-12-27
- **WordPress Minimum**: 6.0+ (PHP 8.1+)
