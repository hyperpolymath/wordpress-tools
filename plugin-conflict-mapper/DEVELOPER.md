# Developer Documentation

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Class Structure](#class-structure)
- [Hooks & Filters](#hooks--filters)
- [Database Schema](#database-schema)
- [REST API Reference](#rest-api-reference)
- [WP-CLI Reference](#wp-cli-reference)
- [Code Examples](#code-examples)
- [Testing](#testing)
- [Contributing](#contributing)

## Architecture Overview

WP Plugin Conflict Mapper follows a modular, object-oriented architecture built on WordPress best practices.

### Design Patterns

- **Singleton**: Main plugin class uses singleton pattern
- **Dependency Injection**: Classes receive dependencies through constructors
- **Factory**: Plugin scanner creates analyzer instances
- **Strategy**: Different conflict detection strategies for each type
- **Observer**: WordPress hooks for event handling

### Core Components

```
┌─────────────────────────────────────┐
│   WP_Plugin_Conflict_Mapper         │
│   (Main Controller)                 │
└───────────┬─────────────────────────┘
            │
    ┌───────┴────────┬─────────────┬──────────────┐
    │                │             │              │
┌───▼────┐    ┌─────▼─────┐  ┌───▼───┐    ┌─────▼──────┐
│Scanner │    │ Detector  │  │Overlap│    │  Ranking   │
│        │    │           │  │Analyzer│    │  Engine    │
└────────┘    └───────────┘  └───────┘    └────────────┘
                                                │
                        ┌───────────────────────┴─────┬─────────────┐
                        │                             │             │
                  ┌─────▼──────┐            ┌────────▼────┐  ┌────▼──────┐
                  │  Security  │            │Performance  │  │  Database │
                  │  Scanner   │            │  Analyzer   │  │           │
                  └────────────┘            └─────────────┘  └───────────┘
```

## Class Structure

### Main Plugin Class

**File**: `wp-plugin-conflict-mapper.php`

```php
class WP_Plugin_Conflict_Mapper {
    // Singleton instance
    private static $instance;

    // Component instances
    public $scanner;
    public $detector;
    public $admin;

    // Methods
    public static function instance()
    private function __construct()
    private function load_dependencies()
    private function init_hooks()
    public function init()
    public function load_textdomain()
    public function activate()
    public function deactivate()
}
```

### WPCM_Plugin_Scanner

**Purpose**: Scans WordPress installation for plugin information

**Key Methods**:
```php
get_all_plugins()              // Returns all installed plugins
get_active_plugins()           // Returns only active plugins
scan_plugin_hooks($file)       // Scans for add_action/add_filter
scan_plugin_functions($file)   // Detects function definitions
scan_plugin_globals($file)     // Finds global variable usage
scan_plugin_tables($file)      // Detects database table creation
get_plugin_size($file)         // Calculates total file size
get_plugin_complexity($file)   // Measures code complexity
```

### WPCM_Conflict_Detector

**Purpose**: Identifies conflicts between plugins

**Key Methods**:
```php
detect_conflicts($plugins)           // Main detection method
detect_hook_conflicts($plugins)      // Hook overlap detection
detect_function_conflicts($plugins)  // Function name collisions
detect_global_conflicts($plugins)    // Global variable conflicts
detect_table_conflicts($plugins)     // Database table conflicts
get_conflict_summary($conflicts)     // Statistical summary
```

**Conflict Structure**:
```php
array(
    'hook_conflicts' => [
        [
            'type' => 'actions|filters',
            'hook' => 'init',
            'plugins' => ['Plugin A', 'Plugin B'],
            'severity' => 'low|medium|high|critical'
        ]
    ],
    'function_conflicts' => [...],
    'global_conflicts' => [...],
    'table_conflicts' => [...]
)
```

### WPCM_Overlap_Analyzer

**Purpose**: Identifies functional overlaps

**Categories**: SEO, caching, security, backup, forms, ecommerce, social, analytics, media, email, builder, spam

**Key Methods**:
```php
analyze_overlaps($plugins)              // Main analysis method
categorize_plugin($plugin_data)         // Assigns categories
calculate_overlap_severity($cat, $cnt)  // Determines severity
get_category_recommendation($cat)       // Suggests actions
get_category_alternatives($cat)         // Recommended plugins
analyze_hook_patterns($plugins)         // Similarity detection
```

### WPCM_Ranking_Engine

**Purpose**: Ranks plugins by compatibility and performance

**Scoring Algorithm**:
```php
Base Score: 100

Deductions:
- Conflicts: up to -40 points (15 per high, 8 per medium, 3 per low)
- Overlaps: up to -30 points (12 per high, 6 per medium, 2 per low)
- Complexity: up to -20 points (based on LOC/functions/classes)
- Size: up to -10 points (large files > 10MB)
- Maintenance: -20 points (missing version info)

Final Score: max(0, Base - Deductions)
```

**Key Methods**:
```php
rank_plugins($plugins, $conflicts, $overlaps)  // Main ranking
calculate_plugin_score(...)                    // Score calculation
get_recommendations($score_data)               // Generates advice
get_comparative_ranking($ranked)               // Percentile ranks
get_priority_actions($ranked)                  // Action items
```

### WPCM_Security_Scanner

**Purpose**: Scans for security vulnerabilities

**Detection Patterns**:

```php
// Dangerous functions
$dangerous_functions = [
    'eval', 'base64_decode', 'system', 'exec',
    'shell_exec', 'passthru', 'proc_open'
];

// SQL injection
/\$wpdb->query.*\$_(GET|POST|REQUEST)/

// XSS
/echo\s+\$_(GET|POST|REQUEST)/

// File operations
/(file_get_contents|fopen).*\$_(GET|POST)/
```

**Key Methods**:
```php
scan_plugin($plugin_file)              // Main security scan
scan_dangerous_functions($content)     // Risky function usage
scan_sql_injection($content)           // SQL vulnerability check
scan_xss_risks($content)               // XSS vulnerability check
scan_file_operations($content)         // File op security check
calculate_risk_level($issues)          // Overall risk assessment
```

### WPCM_Performance_Analyzer

**Purpose**: Analyzes plugin performance impact

**Metrics**:
- File size (MB)
- Code complexity (lines + functions + classes)
- Database tables created
- Asset files (CSS/JS)
- Hook registrations (actions + filters)

**Rating Scale**:
- Excellent: 90-100
- Good: 75-89
- Fair: 60-74
- Poor: <60

**Key Methods**:
```php
analyze_plugin($plugin_file)     // Complete analysis
analyze_size(...)                // File size metrics
analyze_complexity(...)          // Code complexity
analyze_database_impact(...)     // DB table count
analyze_asset_impact(...)        // CSS/JS file count
analyze_hooks_count(...)         // Hook registration
generate_report($analysis)       // Final report
```

## Hooks & Filters

### Actions

```php
// After plugin loaded
do_action('wpcm_loaded');

// Before scan starts
do_action('wpcm_before_scan', $plugins);

// After scan completes
do_action('wpcm_after_scan', $scan_id, $results);

// During conflict detection
do_action('wpcm_detect_conflicts', $plugins);

// On plugin activation
do_action('wpcm_activated');

// On plugin deactivation
do_action('wpcm_deactivated');
```

### Filters

```php
// Modify scan results before saving
apply_filters('wpcm_scan_results', $results);

// Modify conflict detection
apply_filters('wpcm_conflicts', $conflicts, $plugins);

// Modify overlap analysis
apply_filters('wpcm_overlaps', $overlaps, $plugins);

// Modify plugin score
apply_filters('wpcm_plugin_score', $score, $plugin_file, $data);

// Modify security scan results
apply_filters('wpcm_security_results', $results, $plugin_file);

// Modify performance results
apply_filters('wpcm_performance_results', $results, $plugin_file);

// Add custom plugin categories
apply_filters('wpcm_plugin_categories', $categories);

// Modify severity calculation
apply_filters('wpcm_conflict_severity', $severity, $conflict_data);
```

### Usage Examples

```php
// Add custom conflict detection
add_action('wpcm_detect_conflicts', function($plugins) {
    // Your custom detection logic
    foreach ($plugins as $plugin) {
        // Check for specific conditions
    }
});

// Modify plugin score based on custom criteria
add_filter('wpcm_plugin_score', function($score, $plugin_file) {
    // Bonus points for specific plugins
    if (strpos($plugin_file, 'my-favorite-plugin') !== false) {
        $score += 10;
    }
    return $score;
}, 10, 2);

// Add custom category
add_filter('wpcm_plugin_categories', function($categories) {
    $categories['crm'] = ['customer', 'relationship', 'management'];
    return $categories;
});
```

## Database Schema

### Table: wpcm_scans

```sql
CREATE TABLE wp_wpcm_scans (
    id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    scan_date datetime NOT NULL,
    plugin_count int(11) NOT NULL DEFAULT 0,
    conflict_count int(11) NOT NULL DEFAULT 0,
    overlap_count int(11) NOT NULL DEFAULT 0,
    scan_data longtext,
    scan_type varchar(50) NOT NULL DEFAULT 'manual',
    PRIMARY KEY (id),
    KEY scan_date (scan_date),
    KEY scan_type (scan_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Table: wpcm_conflicts

```sql
CREATE TABLE wp_wpcm_conflicts (
    id bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
    scan_id bigint(20) UNSIGNED NOT NULL,
    conflict_type varchar(50) NOT NULL,
    severity varchar(20) NOT NULL DEFAULT 'low',
    affected_plugins text,
    conflict_data longtext,
    created_at datetime NOT NULL,
    PRIMARY KEY (id),
    KEY scan_id (scan_id),
    KEY severity (severity),
    KEY conflict_type (conflict_type),
    CONSTRAINT fk_scan_id FOREIGN KEY (scan_id)
        REFERENCES wp_wpcm_scans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### Database Operations

```php
// Save scan
$database = new WPCM_Database();
$scan_id = $database->save_scan([
    'plugin_count' => 10,
    'conflict_count' => 5,
    'overlap_count' => 3,
    'scan_type' => 'manual',
    'full_data' => $data
]);

// Get scan
$scan = $database->get_scan($scan_id);

// Get recent scans
$scans = $database->get_recent_scans(10);

// Save conflicts
$database->save_conflicts($scan_id, $conflicts);

// Get conflicts for scan
$conflicts = $database->get_scan_conflicts($scan_id);

// Cleanup old scans
$deleted = $database->cleanup_old_scans(30);

// Get statistics
$stats = $database->get_statistics();
```

## REST API Reference

**Base URL**: `/wp-json/wpcm/v1/`

**Authentication**: Requires `manage_options` capability

### Endpoints

#### GET /plugins

Get all installed plugins

**Response**:
```json
{
    "success": true,
    "data": {
        "plugin-slug/plugin.php": {
            "name": "Plugin Name",
            "version": "1.0.0",
            "is_active": true
        }
    },
    "count": 10
}
```

#### POST /scan

Run a new conflict scan

**Response**:
```json
{
    "success": true,
    "scan_id": 42,
    "summary": {
        "plugins": 10,
        "conflicts": 5,
        "overlaps": 3
    }
}
```

#### GET /scan/{id}

Get specific scan results

**Parameters**:
- `id` (required): Scan ID

**Response**:
```json
{
    "success": true,
    "data": {
        "id": 42,
        "scan_date": "2025-07-31 12:00:00",
        "plugin_count": 10,
        "conflict_count": 5,
        "scan_data": {...}
    }
}
```

#### GET /scans

Get recent scans

**Query Parameters**:
- `limit` (optional): Number of scans to return (default: 10)

**Response**:
```json
{
    "success": true,
    "data": [...],
    "count": 10
}
```

#### GET /stats

Get scanning statistics

**Response**:
```json
{
    "success": true,
    "data": {
        "total_scans": 100,
        "avg_conflicts": 5.5,
        "last_scan": "2025-07-31 12:00:00",
        "high_severity_conflicts": 10
    }
}
```

## WP-CLI Reference

### Commands

#### scan

Run a conflict scan

```bash
wp conflict-mapper scan [--format=<format>] [--save]
```

**Options**:
- `--format`: Output format (table, json, csv). Default: table
- `--save`: Save results to database

**Examples**:
```bash
wp conflict-mapper scan
wp conflict-mapper scan --format=json
wp conflict-mapper scan --save
wp conflict-mapper scan --format=json --save
```

#### list-plugins

List all plugins with rankings

```bash
wp conflict-mapper list-plugins [--format=<format>]
```

**Examples**:
```bash
wp conflict-mapper list-plugins
wp conflict-mapper list-plugins --format=json
```

#### report

Get detailed report for a plugin

```bash
wp conflict-mapper report <plugin>
```

**Arguments**:
- `plugin`: Plugin slug or name

**Examples**:
```bash
wp conflict-mapper report akismet
wp conflict-mapper report "Yoast SEO"
```

#### clear-cache

Clear all cached data

```bash
wp conflict-mapper clear-cache
```

## Code Examples

### Custom Conflict Detector

```php
class My_Custom_Detector {
    public function __construct() {
        add_filter('wpcm_conflicts', [$this, 'add_custom_conflicts'], 10, 2);
    }

    public function add_custom_conflicts($conflicts, $plugins) {
        // Add custom detection logic
        $custom_conflicts = $this->detect_my_conflicts($plugins);

        if (!empty($custom_conflicts)) {
            $conflicts['custom_conflicts'] = $custom_conflicts;
        }

        return $conflicts;
    }

    private function detect_my_conflicts($plugins) {
        // Your detection logic here
        return [];
    }
}

new My_Custom_Detector();
```

### Custom Ranking Modifier

```php
add_filter('wpcm_plugin_score', function($score, $plugin_file, $data) {
    // Bonus for plugins from trusted authors
    $trusted_authors = ['Yoast', 'Automattic', 'WooCommerce'];

    foreach ($trusted_authors as $author) {
        if (stripos($data['author'], $author) !== false) {
            $score += 5; // 5 point bonus
            break;
        }
    }

    return min(100, $score); // Cap at 100
}, 10, 3);
```

### Scheduled Scanning

```php
add_action('init', function() {
    if (!wp_next_scheduled('my_daily_scan')) {
        wp_schedule_event(time(), 'daily', 'my_daily_scan');
    }
});

add_action('my_daily_scan', function() {
    $scanner = new WPCM_Plugin_Scanner();
    $detector = new WPCM_Conflict_Detector();

    $plugins = $scanner->get_active_plugins();
    $conflicts = $detector->detect_conflicts($plugins);

    // Email results if conflicts found
    if (!empty($conflicts['function_conflicts'])) {
        wp_mail(
            get_option('admin_email'),
            'Plugin Conflicts Detected',
            'Function conflicts found: ' . count($conflicts['function_conflicts'])
        );
    }
});
```

## Testing

### Manual Testing Checklist

- [ ] Install plugin on fresh WordPress installation
- [ ] Activate plugin - check for errors
- [ ] Run scan with no plugins - verify results
- [ ] Install 5+ plugins and run scan
- [ ] Test export functionality (JSON, CSV)
- [ ] Test WP-CLI commands
- [ ] Test REST API endpoints
- [ ] Deactivate - verify no errors
- [ ] Uninstall - verify cleanup

### Test Environment Setup

```bash
# Using Local by Flywheel or similar
1. Create new WordPress site
2. Install WP-CLI
3. Clone plugin to wp-content/plugins
4. Activate via wp plugin activate wp-plugin-conflict-mapper
5. Run wp conflict-mapper scan --save
```

## Contributing

See main README.md for contribution guidelines.

### Development Workflow

1. Fork repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Follow WordPress coding standards
4. Add PHPDoc comments
5. Test thoroughly
6. Submit pull request

### Coding Standards

```bash
# Install PHP_CodeSniffer
composer global require squizlabs/php_codesniffer

# Install WordPress Coding Standards
composer global require wp-coding-standards/wpcs

# Check code
phpcs --standard=WordPress wp-plugin-conflict-mapper.php
```

---

For more information, see README.md and CLAUDE.md.
