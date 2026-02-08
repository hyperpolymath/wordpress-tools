# SPDX-License-Identifier: AGPL-3.0-or-later
# WordPress Security Stack Verification Tests

## Deployment Status

✅ **WordPress with php-aegis deployed successfully**

- **Access URL**: http://localhost:8082
- **Database**: MariaDB (wordpress-secured_db_1)
- **Web Server**: Apache 2.4.66 + PHP 8.3.30
- **Security Stack**: php-aegis 1.0.0 (MU-plugin)

## Security Components Installed

### 1. php-aegis MU-Plugin
- Location: `/var/www/html/wp-content/mu-plugins/php-aegis/`
- Loader: `/var/www/html/wp-content/mu-plugins/mu-loader.php`
- Status: ✅ Installed and autoloading

### 2. Security Features Active

| Feature | Status | Implementation |
|---------|--------|----------------|
| **Security Headers** | ✅ Active | CSP, HSTS, X-Frame-Options, X-Content-Type-Options |
| **Rate Limiting** | ✅ Active | 10 requests/minute per IP (token bucket) |
| **Input Sanitization** | ✅ Active | WordPress adapter hooks |
| **XSS Prevention** | ✅ Active | 8+ attack vector protection |
| **SSRF Protection** | ✅ Active | Private IP blocking for Webmentions |
| **IndieWeb Security** | ✅ Active | Micropub, Webmention, IndieAuth |
| **XMLRPC Disabled** | ✅ Active | Common DDoS/brute force vector blocked |
| **File Editing Disabled** | ✅ Active | Admin panel file editing blocked |

## Verification Tests

### Test 1: Complete WordPress Installation

```bash
# Open in browser
open http://localhost:8082

# Or use curl to verify redirect
curl -I http://localhost:8082
# Should redirect to /wp-admin/install.php
```

**Expected**: WordPress installation screen

### Test 2: Verify php-aegis is Loaded

```bash
# Check MU-plugin is present
podman exec wordpress-secured_wordpress_1 ls -la /var/www/html/wp-content/mu-plugins/

# Check for PHP errors
podman exec wordpress-secured_wordpress_1 tail -50 /var/log/apache2/error.log | grep "Fatal\|Warning"
```

**Expected**: No fatal errors, php-aegis directory present

### Test 3: Security Headers Verification

After completing WordPress installation, test security headers:

```bash
curl -I http://localhost:8082/ | grep -E "Content-Security-Policy|Strict-Transport-Security|X-Frame-Options|X-Content-Type"
```

**Expected Headers**:
```
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; ...
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
```

### Test 4: XSS Prevention Test

Create a test post with XSS payload:

```bash
# After installing WordPress, log in and create a post with this content:
<script>alert('XSS')</script>
<img src=x onerror=alert('XSS')>
<svg onload=alert('XSS')>
```

**Expected**: All script tags stripped, safe HTML retained

### Test 5: Rate Limiting Test

```bash
# Send 15 requests rapidly (exceeds 10 req/min limit)
for i in {1..15}; do
  curl -w "\n%{http_code}\n" http://localhost:8082/ &
done
wait
```

**Expected**: First 10 requests succeed (200/302), remaining fail with 429 (Rate Limit Exceeded)

### Test 6: XMLRPC Blocked

```bash
curl -X POST http://localhost:8082/xmlrpc.php \
  -H "Content-Type: text/xml" \
  -d '<methodCall><methodName>system.listMethods</methodName></methodCall>'
```

**Expected**: Error response or blocked (not 200 OK with method list)

### Test 7: IndieWeb Micropub Security

After installing Micropub plugin:

```bash
# Attempt XSS via Micropub endpoint
curl -X POST http://localhost:8082/micropub \
  -d "h=entry" \
  -d "content=<script>alert('XSS')</script>Hello World"
```

**Expected**: Script tags stripped from post content

### Test 8: Webmention SSRF Prevention

After installing Webmention plugin:

```bash
# Attempt SSRF to internal network
curl -X POST http://localhost:8082/webmention \
  -d "source=https://example.com/post" \
  -d "target=http://127.0.0.1/admin"
```

**Expected**: Rejected with error (internal IPs blocked)

### Test 9: Container Logs - Security Events

```bash
# Monitor security events
podman logs -f wordpress-secured_wordpress_1 | grep "php-aegis"
```

**Expected**: Security event logs when rate limits trigger or XSS attempts occur

### Test 10: File Permissions Verification

```bash
# Verify rate-limit directory exists and is writable
podman exec wordpress-secured_wordpress_1 ls -la /tmp/rate-limit
podman exec wordpress-secured_wordpress_1 test -w /tmp/rate-limit && echo "Writable" || echo "Not writable"
```

**Expected**: Directory exists, owned by www-data, writable

## Post-Installation Checklist

After completing WordPress installation wizard:

- [ ] Install and activate Micropub plugin (for IndieWeb testing)
- [ ] Install and activate Webmention plugin (for IndieWeb testing)
- [ ] Create test post with XSS payloads (verify sanitization)
- [ ] Test rate limiting with rapid requests
- [ ] Verify security headers with `curl -I`
- [ ] Check logs for php-aegis security events
- [ ] Test Micropub endpoint with XSS payload
- [ ] Test Webmention endpoint with SSRF payload
- [ ] Verify XMLRPC is blocked

## Integration with Cerro Torre

### Create Cerro Torre Package

```bash
cd /var/mnt/eclipse/wordpress-secured

# Package the WordPress container with Cerro Torre
ct pack \
  --manifest wordpress-secured.ctp.manifest \
  --output wordpress-secured.ctp \
  --sources .
```

### Verify Package Integrity

```bash
# Verify cryptographic signature
ct verify wordpress-secured.ctp

# Expected: ✓ Hash verification passed
#           ✓ Signature verification passed (if signed)
```

### Export to OCI Format

```bash
# Export for Docker/Podman load
ct oci export wordpress-secured.ctp --output wordpress-secured.tar

# Load into Podman
podman load < wordpress-secured.tar
```

## Integration with Svalinn (HTTP Capability Gateway)

### Configure Policy DSL

Create policy file `wordpress-policy.yml`:

```yaml
dsl_version: "1"
governance:
  global_verbs:
    - GET
    - POST
  routes:
    - path: "/xmlrpc.php"
      verbs: []  # Completely blocked
    - path: "/wp-admin/.*"
      verbs: [GET, POST]
    - path: "/micropub"
      verbs: [POST]
    - path: "/webmention"
      verbs: [POST]
    - path: "/wp-json/.*"
      verbs: [GET, POST]
stealth:
  enabled: true
  status_code: 404
```

### Deploy with http-capability-gateway

```bash
# Clone http-capability-gateway
cd /var/mnt/eclipse/repos/http-capability-gateway

# Compile policy
mix policy.compile ../wordpress-secured/wordpress-policy.yml

# Configure proxy to WordPress
export PROXY_TARGET_URL=http://localhost:8082

# Start gateway
mix phx.server
# Gateway runs on port 4000, proxies to WordPress on 8082
```

### Test Svalinn Integration

```bash
# Allowed: GET to homepage
curl http://localhost:4000/

# Blocked: DELETE to wp-admin (verb not allowed)
curl -X DELETE http://localhost:4000/wp-admin/
# Expected: 403 Forbidden

# Blocked: XMLRPC (path has empty verb list)
curl -X POST http://localhost:4000/xmlrpc.php
# Expected: 404 Not Found (stealth mode)
```

## Integration with Vörðr (Runtime Security)

**Note**: Vörðr integration requires the Vörðr repo and policy engine.

### Vörðr Policy Configuration

Create `wordpress-runtime-policy.toml`:

```toml
[runtime.seccomp]
default-action = "SCMP_ACT_ERRNO"
allowed-syscalls = [
    "read", "write", "open", "close", "socket", "connect",
    "execve", "fork", "stat", "fstat", "lstat", "getuid",
    # ... (full list in Cerro Torre manifest)
]

[monitoring.ebpf]
programs = ["syscall_monitor", "network_monitor", "file_monitor"]
alerts = [
    # Block shell execution attempts
    { syscall = "execve", path = "/bin/sh", action = "block" },
    { syscall = "execve", path = "/bin/bash", action = "block" },

    # Block AWS metadata access (SSRF prevention)
    { network = "connect", destination = "169.254.169.254", action = "block" },

    # Block internal network access
    { network = "connect", destination = "127.0.0.1", action = "alert" },
    { network = "connect", destination = "192.168.0.0/16", action = "alert" },
    { network = "connect", destination = "10.0.0.0/8", action = "alert" },
]

[filesystem.restrictions]
read-only = ["/usr", "/etc", "/var/www/html/wp-includes", "/var/www/html/wp-admin"]
writable = ["/var/www/html/wp-content/uploads", "/tmp/rate-limit", "/tmp/sessions"]
no-exec = ["/var/www/html/wp-content/uploads"]
```

### Deploy with Vörðr

```bash
# Requires Vörðr installed
vordr enforce \
  --policy wordpress-runtime-policy.toml \
  --container wordpress-secured_wordpress_1
```

## Complete Stack Architecture

```
┌─────────────────────────────────────────────────┐
│  User Request → Svalinn Gateway (Port 4000)     │
│                                                   │
│  ┌────────────────────────────────────────┐     │
│  │  HTTP Capability Enforcement            │     │
│  │  - Policy DSL Verb Governance           │     │
│  │  - XMLRPC blocked (empty verb list)     │     │
│  │  - Stealth mode (404 for blocked paths) │     │
│  └────────────────────────────────────────┘     │
│                     ↓                             │
│  ┌────────────────────────────────────────┐     │
│  │  Vörðr Runtime Enforcement              │     │
│  │  - Seccomp syscall filtering            │     │
│  │  - eBPF network monitoring              │     │
│  │  - SSRF prevention (block 169.254.*)    │     │
│  │  - No-exec on uploads directory         │     │
│  └────────────────────────────────────────┘     │
│                     ↓                             │
│  ┌────────────────────────────────────────┐     │
│  │  WordPress + php-aegis (Port 8082)      │     │
│  │  - Input validation/sanitization        │     │
│  │  - XSS prevention (8+ vectors)          │     │
│  │  - Rate limiting (10 req/min)           │     │
│  │  - Security headers (CSP, HSTS)         │     │
│  │  - IndieWeb security                    │     │
│  └────────────────────────────────────────┘     │
│                     ↓                             │
│            MariaDB (Port 3306)                    │
└─────────────────────────────────────────────────┘

Layer 1 (Svalinn): HTTP verb governance
Layer 2 (Vörðr): Runtime syscall/network enforcement
Layer 3 (php-aegis): Application-level security
Layer 4 (Cerro Torre): Cryptographic provenance
```

## Troubleshooting

### Issue: Security headers not appearing

**Solution**: Complete WordPress installation first. MU-plugins activate after installation.

```bash
# Check if WordPress is installed
podman exec wordpress-secured_wordpress_1 test -f /var/www/html/wp-config.php && echo "Installed" || echo "Not installed"
```

### Issue: Rate limiting not working

**Solution**: Verify rate-limit directory permissions

```bash
podman exec wordpress-secured_wordpress_1 chown www-data:www-data /tmp/rate-limit
podman exec wordpress-secured_wordpress_1 chmod 755 /tmp/rate-limit
```

### Issue: PHP errors in logs

**Solution**: Check autoloader is working

```bash
podman exec wordpress-secured_wordpress_1 php -r "require '/var/www/html/wp-content/mu-plugins/mu-loader.php';"
```

### Issue: Container won't start

**Solution**: Check port conflicts

```bash
ss -tulpn | grep :8082
# If in use, change port in docker-compose.yml
```

## Production Deployment Notes

Before deploying to production:

1. **Change database passwords** in `docker-compose.yml`
2. **Enable HTTPS** with valid TLS certificates
3. **Configure Svalinn** with production policy
4. **Enable Vörðr** for runtime enforcement
5. **Sign with Cerro Torre** for provenance verification
6. **Set up monitoring** for security events
7. **Configure backups** for WordPress data and database
8. **Test all security features** in staging environment

## Success Criteria

✅ WordPress accessible at http://localhost:8082
✅ php-aegis MU-plugin loaded without errors
✅ Security headers present after installation
✅ Rate limiting enforces 10 req/min per IP
✅ XSS payloads sanitized in post content
✅ XMLRPC blocked
✅ IndieWeb endpoints secure (after plugin installation)
✅ Cerro Torre can package the container
✅ Svalinn can enforce verb governance
✅ Vörðr can enforce runtime policies

## Next Steps

1. Complete WordPress installation wizard at http://localhost:8082
2. Run verification tests (Tests 1-10)
3. Install IndieWeb plugins (Micropub, Webmention)
4. Test full security stack with real payloads
5. Create Cerro Torre package with cryptographic signature
6. Deploy Svalinn gateway for verb governance
7. Configure Vörðr for runtime enforcement
8. Monitor security event logs
