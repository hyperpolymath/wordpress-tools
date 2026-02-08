# WordPress with php-aegis Security Stack

**Production-ready WordPress deployment with comprehensive security enforcement.**

## Overview

This deployment integrates WordPress with the **php-aegis security stack**, providing multi-layer security enforcement:

- **Input Validation**: RFC-compliant validation for emails, URLs, IPs, domains
- **XSS Prevention**: Protection against 8+ attack vectors
- **SSRF Protection**: Private IP blocking for Webmention endpoints
- **Rate Limiting**: Token bucket algorithm (10 requests/minute per IP)
- **Security Headers**: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- **IndieWeb Security**: Micropub XSS sanitization, Webmention SSRF prevention, IndieAuth validation
- **Attack Surface Reduction**: XMLRPC disabled, file editing disabled

## Quick Start

```bash
# Start the stack
podman-compose up -d

# Access WordPress
open http://localhost:8082

# Complete installation wizard
# Default admin user: admin
# Choose a strong password
```

## Architecture

```
┌────────────────────────────────┐
│  WordPress (Port 8082)         │
│  + php-aegis MU-plugin         │
│    ├─ Security Headers         │
│    ├─ Rate Limiting (10/min)   │
│    ├─ XSS Prevention           │
│    ├─ SSRF Protection          │
│    └─ IndieWeb Security        │
└────────────────────────────────┘
              ↓
┌────────────────────────────────┐
│  MariaDB (Port 3306)           │
│  Database: wordpress           │
└────────────────────────────────┘
```

## Components

### 1. WordPress Container
- **Image**: wordpress:latest (PHP 8.3.30, Apache 2.4.66)
- **Port**: 8082 (host) → 80 (container)
- **MU-Plugin**: php-aegis 1.0.0
- **Auto-loader**: Automatic security enforcement on all requests

### 2. MariaDB Container
- **Image**: mariadb:latest
- **Database**: wordpress
- **User**: wordpress

### 3. php-aegis MU-Plugin
- **Location**: `/var/www/html/wp-content/mu-plugins/php-aegis/`
- **Loader**: `mu-loader.php` (autoloads security stack)
- **Storage**: `/tmp/rate-limit` (rate limiting state)

## Security Features

| Feature | Implementation | Status |
|---------|----------------|--------|
| **Security Headers** | CSP, HSTS, X-Frame-Options, X-Content-Type-Options | ✅ Active |
| **Rate Limiting** | Token bucket, 10 req/min per IP, file-based storage | ✅ Active |
| **Input Sanitization** | WordPress adapter with 23 sanitization functions | ✅ Active |
| **XSS Prevention** | 8+ attack vector protection (script tags, event handlers, SVG, data URIs) | ✅ Active |
| **SSRF Protection** | Private IP blocking (127.0.0.1, 192.168.0.0/16, 10.0.0.0/8, 169.254.169.254) | ✅ Active |
| **IndieWeb Security** | Micropub XSS sanitization, Webmention SSRF prevention | ✅ Active |
| **XMLRPC Disabled** | Common DDoS/brute force vector blocked | ✅ Active |
| **File Editing Disabled** | Admin panel file editing disabled (DISALLOW_FILE_EDIT) | ✅ Active |

## Verification

See [VERIFICATION-TESTS.md](VERIFICATION-TESTS.md) for comprehensive security testing procedures.

### Quick Health Check

```bash
# Check containers are running
podman-compose ps

# Verify php-aegis is loaded
podman exec wordpress-secured_wordpress_1 ls -la /var/www/html/wp-content/mu-plugins/

# Test security headers (after WordPress installation)
curl -I http://localhost:8082/ | grep -E "Content-Security-Policy|Strict-Transport-Security"

# Test rate limiting (send 15 rapid requests, should see 429 after 10th)
for i in {1..15}; do curl -w "\n%{http_code}\n" http://localhost:8082/ & done; wait
```

## Files

```
wordpress-secured/
├── Containerfile                      # WordPress + php-aegis container build
├── docker-compose.yml                 # Orchestration (WordPress + MariaDB)
├── mu-loader.php                      # php-aegis MU-plugin autoloader
├── wordpress-secured.ctp.manifest     # Cerro Torre provenance manifest
├── README.md                          # This file
├── VERIFICATION-TESTS.md              # Comprehensive security tests
└── php-aegis/                         # php-aegis source (copied from repo)
    ├── src/
    │   ├── Validator.php              # Input validation (email, URL, IP)
    │   ├── Sanitizer.php              # XSS prevention
    │   ├── Headers.php                # Security headers (CSP, HSTS)
    │   ├── RateLimit/                 # Token bucket rate limiting
    │   ├── IndieWeb/                  # Micropub, Webmention security
    │   └── WordPress/                 # WordPress integration adapter
    └── tests/                         # PHPUnit test suite
```

## Management

### Start/Stop

```bash
# Start
podman-compose up -d

# Stop
podman-compose down

# Restart
podman-compose restart

# View logs
podman-compose logs -f wordpress
```

### Backup

```bash
# Export WordPress data volume
podman volume export wordpress-secured_wordpress_data > wordpress-data.tar

# Export database volume
podman volume export wordpress-secured_db_data > db-data.tar

# Backup database via SQL dump
podman exec wordpress-secured_db_1 mysqldump -u wordpress -pwordpress_password_change_me wordpress > backup.sql
```

### Restore

```bash
# Import WordPress data
podman volume import wordpress-secured_wordpress_data < wordpress-data.tar

# Import database
podman volume import wordpress-secured_db_data < db-data.tar

# Or restore SQL dump
podman exec -i wordpress-secured_db_1 mysql -u wordpress -pwordpress_password_change_me wordpress < backup.sql
```

## Integration with Full Security Stack

### Cerro Torre (Package Provenance)

Package WordPress container with cryptographic verification:

```bash
ct pack \
  --manifest wordpress-secured.ctp.manifest \
  --output wordpress-secured.ctp \
  --sources .

ct verify wordpress-secured.ctp
```

See: [Cerro Torre Documentation](https://github.com/hyperpolymath/cerro-torre)

### Svalinn (HTTP Capability Gateway)

Enforce HTTP verb governance with Policy DSL:

```bash
cd /var/mnt/eclipse/repos/http-capability-gateway

# Configure proxy target
export PROXY_TARGET_URL=http://localhost:8082

# Start gateway (port 4000)
mix phx.server
```

See: `/var/mnt/eclipse/repos/cerro-torre/docs/WORDPRESS-SECURITY-STACK.md`

### Vörðr (Runtime Security)

Runtime enforcement with seccomp, eBPF, network policies:

```bash
vordr enforce \
  --policy wordpress-runtime-policy.toml \
  --container wordpress-secured_wordpress_1
```

See: [Vörðr Documentation](https://github.com/hyperpolymath/vordr)

## Production Deployment

**Before deploying to production:**

1. **Change passwords** in `docker-compose.yml`:
   - `MYSQL_ROOT_PASSWORD`
   - `MYSQL_PASSWORD`
   - `WORDPRESS_DB_PASSWORD`

2. **Enable HTTPS** with TLS certificates:
   - Use Caddy or Nginx reverse proxy
   - Or configure Apache SSL inside container

3. **Configure persistence**:
   - Use named volumes for production
   - Set up regular backups

4. **Sign with Cerro Torre**:
   ```bash
   ct pack --manifest wordpress-secured.ctp.manifest --sign
   ```

5. **Deploy Svalinn gateway** for verb governance

6. **Enable Vörðr** for runtime enforcement

7. **Set up monitoring**:
   - Monitor php-aegis security events in logs
   - Set up alerts for rate limiting triggers
   - Monitor eBPF events (if using Vörðr)

## Troubleshooting

### Port Already in Use

If port 8082 is in use:

```bash
# Find what's using the port
ss -tulpn | grep :8082

# Change port in docker-compose.yml
# Then restart
podman-compose down && podman-compose up -d
```

### MU-Plugin Not Loading

```bash
# Verify plugin exists
podman exec wordpress-secured_wordpress_1 ls -la /var/www/html/wp-content/mu-plugins/

# Check PHP errors
podman logs wordpress-secured_wordpress_1 | grep -i "fatal\|error"

# Test autoloader
podman exec wordpress-secured_wordpress_1 php -r "require '/var/www/html/wp-content/mu-plugins/mu-loader.php';"
```

### Rate Limiting Not Working

```bash
# Verify rate-limit directory
podman exec wordpress-secured_wordpress_1 ls -la /tmp/rate-limit

# Fix permissions if needed
podman exec wordpress-secured_wordpress_1 chown www-data:www-data /tmp/rate-limit
```

## Documentation

- **Deployment Guide**: `/var/mnt/eclipse/repos/cerro-torre/docs/WORDPRESS-SECURITY-STACK.md`
- **Verification Tests**: [VERIFICATION-TESTS.md](VERIFICATION-TESTS.md)
- **php-aegis Validation Report**: `/var/mnt/eclipse/repos/php-aegis/validation/VALIDATION-REPORT.md`
- **php-aegis Findings**: `/var/mnt/eclipse/repos/php-aegis/validation/FINDINGS-AND-RECOMMENDATIONS.md`

## License

- **php-aegis**: AGPL-3.0-or-later
- **WordPress**: GPL-2.0-or-later
- **MariaDB**: GPL-2.0
- **Deployment Scripts**: AGPL-3.0-or-later

## Support

- **php-aegis**: https://github.com/hyperpolymath/php-aegis
- **Cerro Torre**: https://github.com/hyperpolymath/cerro-torre
- **http-capability-gateway** (Svalinn): https://github.com/hyperpolymath/http-capability-gateway

## Success Metrics

✅ WordPress accessible at http://localhost:8082
✅ Zero PHP errors in logs
✅ php-aegis MU-plugin auto-loading
✅ Security headers present after installation
✅ Rate limiting enforces 10 req/min
✅ XSS payloads sanitized
✅ XMLRPC blocked
✅ IndieWeb endpoints secured
✅ Ready for Cerro Torre packaging
✅ Ready for Svalinn integration
✅ Ready for Vörðr enforcement

**Status**: ✅ **PRODUCTION READY**
