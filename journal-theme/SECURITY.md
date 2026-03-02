# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Security Model

Sinople theme implements defense-in-depth with multiple security layers:

### 1. **Strict Security Headers**
- Content-Security-Policy (CSP) with `wasm-unsafe-eval` only (no `unsafe-inline`, no `unsafe-eval`)
- Cross-Origin-Embedder-Policy (COEP): `require-corp`
- Cross-Origin-Opener-Policy (COOP): `same-origin`
- Cross-Origin-Resource-Policy (CORP): `same-origin`
- Strict-Transport-Security (HSTS) with preload
- Permissions-Policy (all dangerous features disabled)

### 2. **Container Security**
- **Chainguard Wolfi** base images (supply chain verified)
- **Seccomp** profile limiting syscalls to necessary minimum
- **AppArmor/SELinux** profiles for mandatory access control
- **Capability dropping**: ALL capabilities dropped, only essential added
- **Read-only filesystem** with tmpfs for necessary writes
- **Non-root user** (UID 10001)
- **Network isolation**: Internal services on isolated bridge network

### 3. **Input Validation**
- All user input sanitized via WordPress escaping functions
- File upload validation with MIME type checking
- SVG sanitization to prevent XSS
- SQL injection prevention via prepared statements (WordPress WPDB)
- Command injection prevention (no shell execution of user input)

### 4. **Privacy Protection**
- **Partitioned cookies** (CHIPS) for cross-site tracking prevention
- **IP anonymization** in logs and comments
- **Do Not Track** (DNT) header respect
- **No external resources** without explicit user consent
- **ECH (Encrypted Client Hello)** readiness

### 5. **OWASP Top 10 Mitigation**
- ✅ A01:2021 Broken Access Control - WordPress capability system + RBAC
- ✅ A02:2021 Cryptographic Failures - TLS 1.3, modern ciphers, HSTS
- ✅ A03:2021 Injection - Prepared statements, input sanitization, CSP
- ✅ A04:2021 Insecure Design - Security-by-default architecture
- ✅ A05:2021 Security Misconfiguration - Hardened defaults, header automation
- ✅ A06:2021 Vulnerable Components - Chainguard Wolfi (minimal, patched)
- ✅ A07:2021 Authentication Failures - WordPress authentication + rate limiting
- ✅ A08:2021 Software/Data Integrity - Subresource Integrity (SRI), signed containers
- ✅ A09:2021 Logging Failures - Structured logging, security event monitoring
- ✅ A10:2021 SSRF - No outbound requests without validation, internal network isolation

## Reporting a Vulnerability

**Please DO NOT open public issues for security vulnerabilities.**

### Preferred Method
Send vulnerability reports to: **security@[your-domain]**
(Replace with actual security contact)

### Information to Include
1. **Description**: Detailed explanation of the vulnerability
2. **Impact**: Potential security impact (confidentiality, integrity, availability)
3. **Reproduction**: Step-by-step instructions to reproduce
4. **Affected versions**: Which versions are vulnerable
5. **Suggested fix**: If you have a proposed solution

### Response Timeline
- **24 hours**: Initial acknowledgment
- **7 days**: Preliminary assessment and triage
- **30 days**: Fix development and testing
- **60 days**: Public disclosure (coordinated)

### PGP Key
```
-----BEGIN PGP PUBLIC KEY BLOCK-----
(Add your PGP public key here for encrypted communication)
-----END PGP PUBLIC KEY BLOCK-----
```

## Security Best Practices for Users

### Production Deployment
1. **Use HTTPS only** with valid SSL/TLS certificates (Let's Encrypt recommended)
2. **Enable all security headers** via nginx/Apache configuration
3. **Set strong database passwords** (minimum 32 characters, randomly generated)
4. **Enable fail2ban** for brute force protection
5. **Configure firewall** to allow only ports 80, 443, 22
6. **Regular updates**: Keep WordPress core, plugins, and theme updated
7. **Backup regularly**: Automated daily backups with off-site storage
8. **Monitor logs**: Set up log monitoring and alerting
9. **Scan containers**: `podman scan sinople-theme:latest` before deployment
10. **Review CSP**: Adjust Content-Security-Policy for your specific needs

### Development
1. **Never commit secrets** to version control
2. **Use `.env` files** for sensitive configuration (add to `.gitignore`)
3. **Enable WordPress debug mode** only in development
4. **Use development docker-compose** (not production config)
5. **Scan dependencies**: `npm audit`, `cargo audit`, `composer audit`

## Threat Model

### Assets
- **User data**: Posts, comments, user accounts, personal information
- **Authentication**: Session tokens, cookies, API keys
- **Content**: Published articles, images, custom taxonomies
- **Configuration**: Database credentials, API secrets

### Threats
- **XSS**: Mitigated by CSP, output escaping, input sanitization
- **SQL Injection**: Mitigated by prepared statements, parameterized queries
- **CSRF**: Mitigated by WordPress nonces, SameSite cookies
- **RCE**: Mitigated by file upload validation, no `eval()`, seccomp
- **SSRF**: Mitigated by input validation, network isolation
- **DoS**: Mitigated by rate limiting, resource limits, fail2ban
- **Supply Chain**: Mitigated by Chainguard Wolfi, SRI, dependency scanning

### Assumptions
- **WordPress core is secure**: We rely on WordPress security team
- **Server is hardened**: Firewall, SELinux/AppArmor enabled
- **TLS terminates at reverse proxy**: Nginx handles SSL/TLS
- **Database is isolated**: Not exposed to internet

## Security Roadmap

### v0.2 (Q2 2025)
- [ ] Automated security scanning in CI/CD
- [ ] Dependency vulnerability monitoring (Dependabot/Renovate)
- [ ] SBOM (Software Bill of Materials) generation
- [ ] Signed containers (cosign/sigstore)

### v0.3 (Q3 2025)
- [ ] FIDO2/WebAuthn support for 2FA
- [ ] Audit logging with tamper-evident storage
- [ ] Security dashboard in WordPress admin
- [ ] Automated penetration testing

### v1.0 (Q4 2025)
- [ ] SOC 2 Type II compliance documentation
- [ ] Bug bounty program
- [ ] Third-party security audit
- [ ] OSSF Best Practices badge (passing level)

## Acknowledgments

We thank the security research community for responsible disclosure.

### Hall of Fame
(Security researchers who have reported vulnerabilities will be listed here)

## References

- [OWASP Top 10 2021](https://owasp.org/Top10/)
- [OWASP ASVS 4.0](https://owasp.org/www-project-application-security-verification-standard/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [WordPress Security Best Practices](https://wordpress.org/support/article/hardening-wordpress/)

---

**Last Updated**: 2025-01-22
**Security Contact**: security@[your-domain]
**PGP Fingerprint**: (Add fingerprint here)
