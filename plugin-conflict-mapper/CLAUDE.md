# WP Plugin Conflict Mapper - Claude Context

## Project Overview
**Name**: WP Plugin Conflict Mapper
**Author**: Jonathan
**License**: GNU Affero General Public License v3.0
**Created**: 2025-07-31
**Purpose**: Plugin overlap and conflict diagnostics with ranked plugin recommendations for WordPress

This project was generated during system architecture and optimization discussions focused on WordPress performance and security.

## Project Description
The WP Plugin Conflict Mapper is a WordPress tool designed to:
- Detect and diagnose plugin conflicts and overlaps
- Provide ranked recommendations for plugin compatibility
- Improve WordPress site performance by identifying problematic plugin interactions
- Enhance security through conflict analysis

## Technology Stack
- **Platform**: WordPress
- **Language**: PHP (WordPress plugin development)
- **Focus Areas**: Performance optimization, security, plugin compatibility

## Project Structure
```
/
├── README.md          # Project documentation
├── LICENSE            # GNU AGPL v3.0 license
├── index.md           # Main notes and scripts
├── CLAUDE.md          # This file - context for AI assistance
└── .gitignore         # Git ignore patterns
```

## Development Guidelines

### WordPress Plugin Standards
When working on this project, follow WordPress plugin development best practices:
- Use WordPress coding standards (WordPress-Core)
- Follow WordPress PHP coding standards
- Implement proper WordPress hooks and filters
- Use WordPress nonce verification for security
- Follow WordPress database interaction patterns (wpdb)
- Implement proper capability checks for admin functions

### Security Considerations
This is a diagnostic and security-focused tool, so:
- **CRITICAL**: Always sanitize user inputs
- Use WordPress escaping functions (esc_html, esc_attr, esc_url, etc.)
- Implement proper nonce verification for all forms and AJAX requests
- Check user capabilities before performing privileged operations
- Use prepared statements for all database queries
- Avoid SQL injection, XSS, CSRF, and other OWASP top 10 vulnerabilities
- Follow the principle of least privilege

### Performance Best Practices
- Minimize database queries
- Use WordPress transients API for caching
- Avoid loading unnecessary scripts/styles on all admin pages
- Implement lazy loading where appropriate
- Use WordPress enqueue system for assets

### Code Style
- Follow PSR-12 coding standards where applicable
- Use meaningful variable and function names
- Add PHPDoc comments for functions and classes
- Keep functions focused and single-purpose
- Prefer WordPress core functions over custom implementations

## Common WordPress Development Patterns

### Plugin Structure
```php
<?php
/**
 * Plugin Name: WP Plugin Conflict Mapper
 * Description: Plugin overlap and conflict diagnostics with ranked plugin recommendations
 * Version: 1.0.0
 * Author: Jonathan
 * License: AGPL-3.0
 * License URI: https://www.gnu.org/licenses/agpl-3.0.html
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}
```

### Database Interactions
```php
global $wpdb;
$results = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM {$wpdb->prefix}table WHERE id = %d",
        $id
    )
);
```

### Admin Menus
```php
add_action('admin_menu', 'plugin_conflict_mapper_menu');
function plugin_conflict_mapper_menu() {
    add_menu_page(
        'Plugin Conflict Mapper',
        'Conflict Mapper',
        'manage_options',
        'plugin-conflict-mapper',
        'plugin_conflict_mapper_page'
    );
}
```

### AJAX Handlers
```php
add_action('wp_ajax_check_conflicts', 'check_conflicts_handler');
function check_conflicts_handler() {
    check_ajax_referer('conflict_check_nonce');
    if (!current_user_can('manage_options')) {
        wp_die('Unauthorized');
    }
    // Handler logic
    wp_send_json_success($data);
}
```

## Key Features to Implement
1. **Plugin Scanning**: Detect all active and inactive plugins
2. **Conflict Detection**: Identify potential conflicts between plugins
3. **Overlap Analysis**: Find plugins with overlapping functionality
4. **Ranking System**: Provide scored recommendations
5. **Admin Dashboard**: User-friendly interface for viewing results
6. **Reporting**: Generate detailed conflict reports

## Testing Considerations
- Test with various WordPress versions (ensure compatibility)
- Test with popular plugins (WooCommerce, Yoast SEO, etc.)
- Test performance with large numbers of plugins
- Test security measures (nonce verification, capability checks)
- Test on different PHP versions (7.4+, 8.0+)

## License Compliance
This project uses **GNU AGPL v3.0**:
- Any modifications must also be AGPL v3.0
- Network use requires source code availability
- Maintain copyright notices
- Include license text with distribution

## Useful Resources
- [WordPress Plugin Handbook](https://developer.wordpress.org/plugins/)
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [WordPress Security Best Practices](https://developer.wordpress.org/apis/security/)
- [Plugin API Reference](https://developer.wordpress.org/reference/)

## Notes for Claude
- Always check for WordPress context before suggesting non-WP solutions
- Prioritize WordPress core functions over custom implementations
- Security is paramount - this tool analyzes other plugins
- Performance matters - sites may have many plugins installed
- Follow WordPress naming conventions (underscores, not camelCase)
- Remember to use WordPress i18n functions for all user-facing strings
