# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Security Philosophy

The Sinople WordPress theme follows a **defense-in-depth** approach with multiple security layers:

1. **Memory Safety**: Rust WASM module (zero `unsafe` blocks)
2. **Type Safety**: ReScript bindings (sound type system)
3. **Input Sanitization**: All WordPress inputs sanitized
4. **Output Escaping**: All outputs escaped (XSS prevention)
5. **CSRF Protection**: Nonces for all form submissions
6. **Capability Checks**: WordPress role-based access control
7. **SQL Injection Prevention**: WordPress prepared statements
8. **Content Security Policy**: Recommended CSP headers
9. **Offline-First**: Minimal attack surface (local WordPress)
10. **Dependency Auditing**: Minimal dependencies, vetted sources

## Reporting a Vulnerability

**DO NOT** open a public GitHub issue for security vulnerabilities.

### Preferred Method: Security Advisory

Use GitHub's [Security Advisories](https://github.com/Hyperpolymath/wp-sinople-theme/security/advisories/new) to privately report vulnerabilities.

### Alternative Method: Email

Email security reports to: **security@sinople.org** (or maintainer email if unavailable)

Use PGP encryption for sensitive disclosures (key available at `.well-known/security.txt`).

### What to Include

Please provide:

1. **Type of vulnerability** (XSS, CSRF, injection, etc.)
2. **Affected component** (WASM, PHP, ReScript, JavaScript, etc.)
3. **Affected versions** (1.0.0, 1.0.1, etc.)
4. **Steps to reproduce** (detailed, with code samples if possible)
5. **Proof of concept** (if applicable, responsibly disclosed)
6. **Suggested fix** (optional, but appreciated)
7. **Impact assessment** (low, medium, high, critical)

### Response Timeline

- **24 hours**: Acknowledgment of report
- **72 hours**: Initial assessment and severity classification
- **7 days**: Patch development (for high/critical issues)
- **14 days**: Coordinated disclosure and release
- **30 days**: Public disclosure (if fix is available)

### Disclosure Policy

We follow **coordinated disclosure**:

1. You report vulnerability privately
2. We acknowledge and investigate
3. We develop and test a patch
4. We coordinate release timing with you
5. We release patch and credit you (if desired)
6. Public disclosure after users have time to update

### Security Advisories

All security issues will be documented in:

- GitHub Security Advisories
- CHANGELOG.md (with CVE if applicable)
- Release notes

### Bug Bounty

We currently **do not** have a bug bounty program, but we:

- Credit all security researchers (with permission)
- List contributors in SECURITY.md
- Provide attribution in release notes
- Recommend researchers for recognition in wider community

## Security Best Practices for Users

### WordPress Configuration

1. **Keep WordPress updated** (6.0+ required)
2. **Use HTTPS** (required for WASM/Service Workers)
3. **Enable automatic updates** for security patches
4. **Use strong passwords** (16+ characters, unique)
5. **Enable two-factor authentication** (2FA)
6. **Limit login attempts** (use fail2ban or similar)
7. **Disable XML-RPC** (if not needed)
8. **Use security headers**:
   ```
   Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval'
   X-Content-Type-Options: nosniff
   X-Frame-Options: SAMEORIGIN
   X-XSS-Protection: 1; mode=block
   Referrer-Policy: strict-origin-when-cross-origin
   ```

### Theme Configuration

1. **Validate RDF input** (malicious Turtle files)
2. **Sanitize construct/entanglement data**
3. **Limit file uploads** (if accepting ontologies)
4. **Use Content Security Policy** (restrict inline scripts)
5. **Enable WASM sandboxing** (browser default)

### Server Configuration

1. **Disable directory listing**
2. **Protect wp-config.php** (move outside web root)
3. **Use Web Application Firewall** (ModSecurity, Cloudflare)
4. **Enable fail2ban** (brute force protection)
5. **Regular backups** (automated, off-site)
6. **Monitor logs** (access, error, security logs)

## Known Security Considerations

### WASM Module

- **Sandboxed**: Runs in browser sandbox (no file system access)
- **Memory-safe**: Rust ownership model prevents buffer overflows
- **No network**: WASM module makes no network calls
- **Deterministic**: Same input always produces same output

### WordPress Integration

- **REST API exposure**: Semantic graph API is public (read-only)
- **Custom post types**: Respect WordPress capability checks
- **Meta data**: Sanitized on input, escaped on output
- **Nonces**: All forms use WordPress nonces (CSRF protection)

### IndieWeb Endpoints

- **Webmention**: Validates source/target before processing
- **Micropub**: Requires IndieAuth token (OAuth 2.0)
- **Microformats**: No JavaScript execution risk (passive markup)

### JavaScript

- **No `eval()`**: No dynamic code execution
- **No `innerHTML`**: Use `textContent` or DOM APIs
- **CSP-compliant**: No inline scripts (all external files)
- **XSS prevention**: All user input escaped before display

## Security Checklist for Contributions

Before submitting code:

- [ ] All user input is sanitized (`sanitize_text_field()`, `sanitize_email()`, etc.)
- [ ] All output is escaped (`esc_html()`, `esc_attr()`, `esc_url()`, etc.)
- [ ] SQL queries use prepared statements (WordPress `$wpdb->prepare()`)
- [ ] Forms include nonces (`wp_nonce_field()`, `wp_verify_nonce()`)
- [ ] Capability checks before privileged operations (`current_user_can()`)
- [ ] No hardcoded credentials or secrets
- [ ] No `eval()` or dynamic code execution
- [ ] No `unsafe` blocks in Rust code
- [ ] Dependencies are from trusted sources
- [ ] Code has been tested for XSS, CSRF, SQL injection

## Security Hall of Fame

We thank the following security researchers for responsibly disclosing vulnerabilities:

*(None yet - be the first!)*

## Contact

- **Security Email**: security@sinople.org
- **PGP Key**: See `.well-known/security.txt`
- **Security Advisories**: https://github.com/Hyperpolymath/wp-sinople-theme/security/advisories

---

**Last Updated**: 2025-11-22
**Policy Version**: 1.0.0
