# Installation & Compatibility

## WordPress Compatibility Matrix

| Sinople Version | WordPress | PHP | MySQL/MariaDB | Status |
|-----------------|-----------|-----|---------------|--------|
| 0.1.x | 6.4 - 6.7 | 8.1 - 8.4 | 8.0+ / 10.5+ | Active Development |

### Detailed Compatibility

#### WordPress Versions

| WP Version | Compatibility | Notes |
|------------|---------------|-------|
| 6.7.x | Full | Tested, recommended |
| 6.6.x | Full | Tested |
| 6.5.x | Full | Tested |
| 6.4.x | Full | Minimum required |
| 6.3.x | Partial | Missing `appearance-tools` support |
| < 6.3 | Unsupported | Block editor features unavailable |

#### PHP Versions

| PHP Version | Compatibility | Notes |
|-------------|---------------|-------|
| 8.4.x | Full | Tested |
| 8.3.x | Full | Recommended |
| 8.2.x | Full | Tested |
| 8.1.x | Full | Minimum required |
| 8.0.x | Unsupported | EOL December 2023 |
| 7.x | Unsupported | Missing required features |

#### Database

| Database | Version | Notes |
|----------|---------|-------|
| MySQL | 8.0+ | Recommended |
| MariaDB | 10.5+ | Recommended |
| MySQL | 5.7.x | Functional, not recommended |

#### Web Server

| Server | Compatibility | Notes |
|--------|---------------|-------|
| Apache | 2.4+ | `.htaccess` included |
| Nginx | 1.18+ | See nginx config below |
| LiteSpeed | 6.0+ | Full support |
| Caddy | 2.x | Full support |

---

## Installation

### Method 1: Manual Installation

```bash
# Clone the repository
git clone https://github.com/hyperpolymath/sinople-theme.git

# Navigate to your WordPress themes directory
cd /path/to/wordpress/wp-content/themes/

# Move or symlink the theme
mv /path/to/sinople-theme ./sinople
# or
ln -s /path/to/sinople-theme ./sinople
```

Then activate via **WordPress Admin > Appearance > Themes**.

### Method 2: Composer (Recommended for Development)

Add to your `composer.json`:

```json
{
  "repositories": [
    {
      "type": "vcs",
      "url": "https://github.com/hyperpolymath/sinople-theme"
    }
  ],
  "require": {
    "hyperpolymath/sinople-theme": "^0.1"
  },
  "extra": {
    "installer-paths": {
      "wp-content/themes/{$name}/": ["type:wordpress-theme"]
    }
  }
}
```

Then run:

```bash
composer install
```

### Method 3: WordPress Admin Upload

1. Download the latest release as a ZIP file
2. Go to **WordPress Admin > Appearance > Themes > Add New > Upload Theme**
3. Select the ZIP file and click **Install Now**
4. Activate the theme

---

## Build Steps (Development)

### Prerequisites

- PHP 8.1+
- Composer 2.x
- Node.js 20+ (for CSS tooling, optional)

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/hyperpolymath/sinople-theme.git
cd sinople-theme

# Install PHP dependencies
composer install

# Verify installation
composer check
```

### Available Commands

| Command | Description |
|---------|-------------|
| `composer install` | Install all dependencies |
| `composer lint` | Run PHP CodeSniffer (WPCS) |
| `composer format` | Auto-fix coding standards issues |
| `composer analyze` | Run PHPStan static analysis |
| `composer test` | Run PHPUnit tests |
| `composer test:coverage` | Run tests with coverage report |
| `composer audit` | Check for security vulnerabilities |
| `composer check` | Run lint + analyze + test |

### Running Tests

```bash
# Run all tests
composer test

# Run with coverage
composer test:coverage

# Run specific test file
./vendor/bin/phpunit tests/php/test-accessibility.php

# Run specific test method
./vendor/bin/phpunit --filter test_skip_link_output
```

### Code Quality

```bash
# Check coding standards
composer lint

# Auto-fix issues
composer format

# Static analysis
composer analyze
```

---

## Recommended Plugins

These plugins enhance Sinople's IndieWeb and semantic capabilities:

### IndieWeb Stack

| Plugin | Purpose | Required |
|--------|---------|----------|
| [Webmention](https://wordpress.org/plugins/webmention/) | Send/receive webmentions | Recommended |
| [Semantic-Linkbacks](https://wordpress.org/plugins/semantic-linkbacks/) | Rich webmention display | Recommended |
| [IndieAuth](https://wordpress.org/plugins/indieauth/) | Decentralized authentication | Optional |
| [Micropub](https://wordpress.org/plugins/micropub/) | Post from external clients | Optional |
| [Post Kinds](https://wordpress.org/plugins/indieweb-post-kinds/) | Post type taxonomy | Recommended |
| [Syndication Links](https://wordpress.org/plugins/syndication-links/) | POSSE support | Optional |

### Accessibility

| Plugin | Purpose |
|--------|---------|
| [WP Accessibility](https://wordpress.org/plugins/wp-accessibility/) | Additional a11y features |
| [One Click Accessibility](https://wordpress.org/plugins/pojo-accessibility/) | User-facing controls |

---

## Server Configuration

### Nginx Configuration

```nginx
# Add to your server block for semantic endpoints
location = /void.rdf {
    rewrite ^ /index.php?void=1 last;
}

location = /.well-known/void {
    rewrite ^ /index.php?void=1 last;
}

location = /feed/ndjson {
    rewrite ^ /index.php?ndjson=1 last;
}

location = /feed/capnproto {
    rewrite ^ /index.php?capnproto=1 last;
}

# Security headers (recommended)
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### Apache Configuration

The theme includes `.htaccess` support. Ensure `mod_rewrite` is enabled:

```bash
sudo a2enmod rewrite
sudo systemctl restart apache2
```

---

## Post-Installation

1. **Activate the theme** via WordPress Admin
2. **Flush permalinks**: Settings > Permalinks > Save Changes
3. **Configure menus**: Appearance > Menus
4. **Install IndieWeb plugins** (optional but recommended)
5. **Test accessibility**: Run WAVE or axe DevTools

### Verify Installation

Check these endpoints after activation:

- `https://yoursite.com/void.rdf` - VoID dataset description
- `https://yoursite.com/feed/ndjson` - NDJSON feed
- `https://yoursite.com/.well-known/void` - Well-known VoID endpoint

---

## Troubleshooting

### Common Issues

**Theme not appearing in admin**
- Ensure `style.css` exists with valid theme header
- Check file permissions (755 for directories, 644 for files)

**Permalinks not working**
- Flush permalinks: Settings > Permalinks > Save Changes
- Verify `.htaccess` is writable (Apache)
- Check Nginx rewrite rules

**PHP version errors**
- Sinople requires PHP 8.1+
- Check version: `php -v`
- Update PHP or contact your host

**Composer install fails**
- Ensure Composer 2.x: `composer --version`
- Clear cache: `composer clear-cache`
- Try with verbose: `composer install -vvv`

### Getting Help

- [GitHub Issues](https://github.com/hyperpolymath/sinople-theme/issues)
- [Documentation](https://github.com/hyperpolymath/sinople-theme/blob/main/docs/)

---

## Updating

### Via Git

```bash
cd wp-content/themes/sinople
git pull origin main
composer install --no-dev
```

### Via Composer

```bash
composer update hyperpolymath/sinople-theme
```

### Post-Update

1. Clear any caching plugins
2. Flush permalinks if semantic endpoints changed
3. Test site functionality
