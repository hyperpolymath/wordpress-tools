# Security Policy

## Supported Versions

We release security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |
| < 0.1   | :x:                |

## Security Features

WP Praxis implements multiple layers of security:

### 1. Input Validation & Sanitization

- **WordPress Integration**: All inputs sanitized with WordPress functions (`sanitize_text_field`, `wp_kses`)
- **Rust Injector**: Type-safe parsing, no SQL injection (prepared statements via SQLx)
- **Manifest Validation**: Schema validation before execution (LFE parser, YAML/TOML validation)
- **API Layer**: GraphQL input validation, JWT token verification

### 2. Authentication & Authorization

- **WordPress Plugin**:
  - Nonce verification on all AJAX requests
  - Capability checks (`manage_options`) for admin operations
  - WordPress role-based permissions
- **GraphQL API**: JWT token-based authentication
- **REST API**: Token authentication with permission checks
- **RBAC**: Role validation via `Validate-SymbolicRoles.ps1`

### 3. Memory Safety

- **Rust Components**: Zero `unsafe` blocks in production code, ownership model prevents memory issues
- **Type Safety**: Strong typing in Rust, TypeScript strict mode, Elixir specs

### 4. Database Security

- **SQL Injection Protection**:
  - Rust: SQLx with compile-time checked queries
  - PHP: WordPress $wpdb->prepare() for all queries
  - Elixir: Ecto parameterized queries
- **Database Credentials**: Parsed from wp-config.php (not committed), environment variables
- **Connection Security**: SSL/TLS for production database connections

### 5. Execution Safety

- **Sandbox Execution**: Swarm workers run in isolated processes
- **Rollback Support**: Transaction-like behavior with snapshot rollback
- **Audit Logging**: All operations logged with timestamps and user context
- **State Validation**: Pre-execution validation of symbolic operations

### 6. Network Security

- **CORS**: Configurable CORS policies for APIs
- **HTTPS**: Required for production deployments
- **Rate Limiting**: Planned for API endpoints
- **WebSocket Security**: WSS (secure WebSocket) for production

### 7. Secrets Management

- **No Hardcoded Secrets**: All credentials from environment variables or config files
- **Config Files Ignored**: `.env`, `wp-config.php`, credentials never committed
- **.htaccess Protection**: Uploaded manifests protected from direct access

### 8. Dependency Security

- **Minimal Dependencies**: Carefully vetted dependencies only
- **Regular Updates**: Dependabot configured for automatic security updates
- **Audit**: `cargo audit`, `npm audit`, `mix hex.audit` in CI/CD

## Reporting a Vulnerability

**DO NOT** open public GitHub issues for security vulnerabilities.

### How to Report

Send security reports to: **security@wp-praxis.dev**

Alternatively, use our security.txt (RFC 9116):
```
https://wp-praxis.dev/.well-known/security.txt
```

### What to Include

Please include:

1. **Description** of the vulnerability
2. **Steps to reproduce** (proof of concept)
3. **Impact assessment** (what can be compromised)
4. **Affected versions** (if known)
5. **Your contact information** (for follow-up)

### What to Expect

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - **Critical**: Patch within 24-48 hours
  - **High**: Patch within 1 week
  - **Medium**: Patch within 1 month
  - **Low**: Included in next regular release

### Disclosure Policy

We follow **Coordinated Disclosure**:

1. You report the issue privately
2. We acknowledge and investigate
3. We develop and test a fix
4. We release the fix and credit you (if desired)
5. Public disclosure 30 days after fix release

## Security Best Practices for Users

### For WordPress Plugin Users

1. **Keep Updated**: Always use the latest version
2. **Limit Access**: Only give admin access to trusted users
3. **Review Manifests**: Validate YAML/TOML before execution
4. **Use HTTPS**: Run WordPress on HTTPS
5. **Backup First**: Create baseline before major changes
6. **Monitor Logs**: Review audit logs regularly

### For Developers

1. **Code Review**: All PRs require security review
2. **No Secrets**: Never commit credentials or API keys
3. **Input Validation**: Always validate and sanitize inputs
4. **Least Privilege**: Use minimum required permissions
5. **Audit Trail**: Log all state-changing operations
6. **Test Security**: Include security tests in test suite

### For Swarm Deployments

1. **Isolate Workers**: Run workers in separate containers/VMs
2. **Network Segmentation**: Use firewalls between components
3. **Encrypt Transit**: Use TLS for all network communication
4. **Encrypt at Rest**: Use encrypted volumes for state databases
5. **Monitor Resources**: Prevent resource exhaustion attacks
6. **Rate Limiting**: Implement rate limits on API endpoints

## Known Limitations

### Current Security Considerations

1. **Database Access**: Rust injector requires direct MySQL access (mitigated by prepared statements)
2. **File System Access**: PowerShell engine can execute system commands (mitigated by validation)
3. **Manifest Execution**: YAML/TOML manifests can define arbitrary operations (validate before execution)
4. **Multi-Language Attack Surface**: 8 languages = broader attack surface (comprehensive testing mitigates)

### Not Recommended For

- ❌ Public-facing untrusted manifest execution
- ❌ Multi-tenant environments without isolation
- ❌ Systems requiring formal verification proofs
- ❌ Environments where users cannot be trusted

### Recommended For

- ✅ Internal WordPress automation
- ✅ Trusted developer workflows
- ✅ CI/CD pipelines with access control
- ✅ Site migrations and bulk operations

## Security Audit History

| Date | Auditor | Scope | Findings | Status |
|------|---------|-------|----------|--------|
| 2025-11-22 | Internal | Initial codebase review | 0 critical | Addressed |

## Compliance

### Standards

- **OWASP Top 10**: Protections against common web vulnerabilities
- **RFC 9116**: security.txt for vulnerability disclosure
- **WordPress Coding Standards**: Security best practices followed
- **AGPL-3.0**: License compliance requires source disclosure

### Certifications

- None currently (v0.1.0 is early release)
- Future: OWASP ASVS, CWE/SANS Top 25

## Security Features Roadmap

### Planned

- [ ] Rate limiting for all API endpoints
- [ ] Formal security audit by third party
- [ ] OWASP ASVS Level 2 compliance
- [ ] Container security scanning (Trivy/Grype)
- [ ] SAST/DAST integration in CI/CD
- [ ] Secrets scanning (Gitleaks/TruffleHog)
- [ ] Supply chain security (SBOM generation)
- [ ] Zero-trust architecture documentation

### Under Consideration

- Formal verification for critical Rust components (SPARK/TLA+)
- Hardware security module (HSM) support for key material
- Multi-factor authentication (MFA) for admin operations
- Intrusion detection system (IDS) integration

## Contact

- **Security Team**: security@wp-praxis.dev
- **General Questions**: https://github.com/hyperpolymath/wp-praxis/discussions
- **Bug Reports** (non-security): https://github.com/hyperpolymath/wp-praxis/issues

## Acknowledgments

We thank the security community for responsible disclosure and appreciate:

- Security researchers who report vulnerabilities privately
- Open source security tools (cargo-audit, npm-audit, OWASP)
- WordPress security team for best practices guidance

---

**Last Updated**: 2025-11-22
**Version**: 1.0
**PGP Key**: Coming soon
**security.txt**: https://wp-praxis.dev/.well-known/security.txt
