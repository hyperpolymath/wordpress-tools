# Reversibility Framework

**Project**: WP Plugin Conflict Mapper
**Version**: 1.0.0
**Last Updated**: 2025-07-31
**Principle**: *Every operation can be undone*

---

## Philosophy

Reversibility is a core principle of this project. Users should never fear experimentation because mistakes can always be corrected. Every significant operation provides a clear path to undo or rollback.

> **"The ability to experiment safely is the foundation of innovation."**

This document outlines how reversibility is implemented across all aspects of the WP Plugin Conflict Mapper.

---

## Core Reversibility Guarantees

### 1. Data Operations

All data operations are reversible through:

#### Database Operations

- **Scans**: All scan data is preserved in the database with timestamps
  - *Undo*: Delete scan via admin interface or WP-CLI: `wp conflict-mapper delete-scan <id>`
  - *Retention*: Scans are retained according to settings (default: 30 days)
  - *Export*: Export scan data before deletion for archival

- **Settings Changes**: All settings are stored in WordPress options
  - *Undo*: Revert to previous values in Settings page
  - *Rollback*: Settings are cached; original values shown before save
  - *Reset*: "Reset to Defaults" button available on settings page

#### Data Retention

```php
// Example: Delete old scans programmatically
do_action('wpcm_cleanup_old_scans', 30); // Delete scans older than 30 days
```

### 2. Plugin Operations

WP Plugin Conflict Mapper is **read-only** by design:

- **No Plugin Modification**: We never modify other plugins
- **No Plugin Deactivation**: We only analyze and report
- **No Database Changes to Other Plugins**: We use our own tables only

**Reversibility**: Since we don't make changes to other plugins, there's nothing to reverse. Our impact is purely informational.

### 3. Configuration Changes

All configuration changes are immediately reversible:

| Setting | Reversal Method | Recovery Time |
|---------|----------------|---------------|
| Automatic Scanning | Toggle off in Settings | Immediate |
| Scan Frequency | Change frequency setting | Immediate |
| Email Notifications | Toggle off in Settings | Immediate |
| Alert Threshold | Adjust threshold | Immediate |
| Data Retention | Modify retention period | Immediate |

### 4. Export Operations

Exports are non-destructive:

- **JSON Export**: Creates file, does not modify database
- **CSV Export**: Creates file, does not modify database
- **Reversibility**: Delete exported file; source data unchanged

---

## Installation & Uninstallation

### Installation Reversibility

**Installation** creates:
- Database tables: `wp_wpcm_scans`, `wp_wpcm_conflicts`
- WordPress options: Various plugin settings
- Scheduled tasks: Cron jobs for automatic scans

**Complete Removal**:
```bash
# 1. Deactivate plugin
wp plugin deactivate wp-plugin-conflict-mapper

# 2. Delete plugin (with data removal)
wp plugin delete wp-plugin-conflict-mapper

# Or via WordPress Admin:
# Plugins → Deactivate → Delete
```

**Data Cleanup** (on deletion):
- Database tables dropped automatically
- WordPress options removed
- Scheduled tasks cleared
- Transients deleted

**Partial Removal** (keep data):
- Deactivate plugin without deletion
- Data preserved for future reactivation
- Reactivating restores functionality with existing data

### Manual Data Cleanup

If you need to manually remove all plugin data:

```sql
-- Remove database tables
DROP TABLE IF EXISTS wp_wpcm_scans;
DROP TABLE IF EXISTS wp_wpcm_conflicts;

-- Remove options
DELETE FROM wp_options WHERE option_name LIKE 'wpcm_%';

-- Remove transients
DELETE FROM wp_options WHERE option_name LIKE '_transient_wpcm_%';
DELETE FROM wp_options WHERE option_name LIKE '_transient_timeout_wpcm_%';

-- Clear scheduled tasks
DELETE FROM wp_options WHERE option_name = 'cron' AND option_value LIKE '%wpcm%';
```

---

## Code-Level Reversibility

### Git Workflow

All code changes follow reversible workflows:

1. **Feature Branches**: All development on branches, not `main`
   - *Undo*: Delete branch before merge

2. **Commits**: Atomic, reversible commits
   - *Undo*: `git revert <commit>`
   - *Rollback*: `git reset --hard <commit>`

3. **Merge Requests**: Reviewed before merge
   - *Undo*: Close MR before merge
   - *Rollback*: Revert merge commit after merge

4. **Releases**: Tagged, immutable versions
   - *Rollback*: Reinstall previous version
   - *Recovery*: All versions permanently available

### Database Migrations

All schema changes are versioned and reversible:

```php
// Example migration pattern
class WPCM_Migration_001 {
    public function up() {
        // Apply changes
    }

    public function down() {
        // Revert changes
    }
}
```

---

## User Interface Reversibility

### Admin Actions

All UI actions are reversible:

| Action | Reversal Method | Confirmation Required |
|--------|----------------|----------------------|
| Run Scan | Delete scan results | No (read-only operation) |
| Delete Scan | Cannot be undone (data loss) | Yes (confirmation dialog) |
| Export Report | Delete exported file | No |
| Change Settings | Revert in Settings page | Yes (save required) |
| Clear Cache | Re-run scan to regenerate | No |

### Destructive Operations

Only **one destructive operation** exists: **Delete Scan**

- **Confirmation Required**: Yes
- **Warning Shown**: "This action cannot be undone"
- **Alternative**: Export scan before deletion
- **Recovery**: None (permanent deletion)

**Best Practice**: Export scans before deletion for archival.

---

## Experimentation Safety

### Sandbox Environment

Recommended for experimentation:

1. **Staging Site**: Test on non-production WordPress
2. **Local Development**: Use Local by Flywheel, Docker, or similar
3. **Backup**: Always backup before major changes

### Safe Experiments

These operations are **always safe**:

- Running scans (read-only)
- Viewing reports (read-only)
- Exporting data (non-destructive)
- Changing settings (reversible)
- Testing WP-CLI commands (with `--dry-run` where available)

### Risk Levels

| Operation | Risk Level | Reversal Difficulty |
|-----------|-----------|---------------------|
| Run Scan | None | N/A (read-only) |
| View Reports | None | N/A (read-only) |
| Export Data | None | Immediate (delete file) |
| Change Settings | Low | Immediate (revert) |
| Delete Scan | Medium | Impossible (permanent) |
| Uninstall Plugin | High | Difficult (restore from backup) |

---

## API & CLI Reversibility

### REST API

All API endpoints are read-only except:

- `POST /wpcm/v1/scan` - Creates scan (reversible: delete scan)
- `DELETE /wpcm/v1/scan/{id}` - Deletes scan (**irreversible**)

### WP-CLI

CLI commands follow reversible patterns:

```bash
# Run scan (reversible: delete results)
wp conflict-mapper scan

# List plugins (read-only)
wp conflict-mapper list-plugins

# Get report (read-only)
wp conflict-mapper report <plugin>

# Delete scan (irreversible)
wp conflict-mapper delete-scan <id>  # Requires --yes flag

# Clear cache (reversible: regenerate)
wp conflict-mapper clear-cache
```

**Dry-Run Mode** (future enhancement):
```bash
wp conflict-mapper <command> --dry-run  # Preview without changes
```

---

## Emergency Recovery

### Plugin Causes Issues

If the plugin causes problems:

1. **Disable via WordPress Admin**
   ```
   Plugins → WP Plugin Conflict Mapper → Deactivate
   ```

2. **Disable via WP-CLI**
   ```bash
   wp plugin deactivate wp-plugin-conflict-mapper
   ```

3. **Disable via File System**
   ```bash
   mv wp-content/plugins/wp-plugin-conflict-mapper wp-content/plugins/wp-plugin-conflict-mapper.disabled
   ```

4. **Disable via Database**
   ```sql
   UPDATE wp_options
   SET option_value = ''
   WHERE option_name = 'active_plugins';
   ```

### Data Corruption

If scan data appears corrupt:

1. **Delete Corrupted Scans**
   - Via Admin: Dashboard → Delete Scan
   - Via WP-CLI: `wp conflict-mapper delete-scan <id>`

2. **Clear All Cache**
   ```bash
   wp conflict-mapper clear-cache
   ```

3. **Re-run Scan**
   - Fresh scan will regenerate clean data

4. **Nuclear Option**: Truncate tables
   ```sql
   TRUNCATE TABLE wp_wpcm_scans;
   TRUNCATE TABLE wp_wpcm_conflicts;
   ```

### Database Recovery

If database tables are damaged:

1. **Deactivate Plugin**
2. **Drop Tables Manually** (SQL above)
3. **Reactivate Plugin** (tables recreated)

---

## Version Reversibility

### Downgrade Procedure

If a new version causes issues:

1. **Export all scan data** (for preservation)
   ```bash
   wp conflict-mapper export-all --format=json
   ```

2. **Deactivate current version**
   ```bash
   wp plugin deactivate wp-plugin-conflict-mapper
   ```

3. **Delete current version**
   ```bash
   wp plugin delete wp-plugin-conflict-mapper
   ```

4. **Install previous version**
   - Download from GitLab releases
   - Upload via WordPress Admin or WP-CLI

5. **Reactivate**
   ```bash
   wp plugin activate wp-plugin-conflict-mapper
   ```

6. **Import data** (if schema compatible)

### Version Compatibility

- **Forward Compatibility**: New versions preserve old data
- **Backward Compatibility**: Old versions may not read new schema
- **Migration Path**: Migrations are always forward-only
- **Downgrade Risk**: Data loss possible if schema changed

**Best Practice**: Test new versions on staging before production.

---

## Data Export for Archival

Before any major operation, export your data:

### Via Admin Interface

1. Go to **Conflict Mapper → Reports**
2. Select scan
3. Click **Export JSON** or **Export CSV**
4. Save file securely

### Via WP-CLI

```bash
# Export specific scan
wp conflict-mapper export-scan <id> --format=json > scan-backup.json

# Export all scans
wp conflict-mapper export-all --format=json > all-scans-backup.json
```

### Via Database Backup

```bash
# Backup plugin tables only
wp db export - --tables=wp_wpcm_scans,wp_wpcm_conflicts > wpcm-backup.sql

# Full WordPress backup (includes plugin data)
wp db export full-backup.sql
```

---

## Audit Trail

All operations are logged for accountability:

- **WordPress Debug Log**: Errors and warnings
- **Scan History**: All scans preserved with timestamps
- **Settings Changes**: Not logged (future enhancement)

### Viewing Audit Trail

```bash
# View recent scans
wp conflict-mapper list-scans --fields=id,date,plugin_count,conflicts

# View specific scan details
wp conflict-mapper get-scan <id>
```

---

## Reversibility Checklist

Before making changes, verify:

- [ ] Change is necessary and understood
- [ ] Backup/export performed (if applicable)
- [ ] Reversal method known
- [ ] Tested on staging (for major changes)
- [ ] Confirmation dialog read carefully
- [ ] Recovery plan in place

---

## Future Enhancements

Planned reversibility improvements:

- [ ] Settings change history (undo/redo)
- [ ] Scan comparison over time
- [ ] Automatic backups before destructive operations
- [ ] Dry-run mode for all CLI commands
- [ ] Soft-delete with trash/restore functionality
- [ ] Change log for all operations
- [ ] Point-in-time recovery

---

## Philosophy Recap

> **"Reversibility enables fearless innovation."**

Principles:

1. **No Destructive Defaults**: Safe by default
2. **Clear Warnings**: Destructive operations clearly marked
3. **Easy Rollback**: Simple reversal procedures
4. **Data Preservation**: Export options for all data
5. **Experimentation Encouraged**: Safe sandbox for learning

---

## Contact

Questions about reversibility or recovery?

- **Documentation**: See [README.adoc](README.adoc)
- **Issues**: https://gitlab.com/Hyperpolymath/wp-plugin-conflict-mapper/-/issues
- **Emergency Support**: Open issue with `emergency` label

---

**Remember**: You can always undo, revert, or start over. Experiment confidently!

---

*Document Version*: 1.0.0
*Last Updated*: 2025-07-31
*Review Period*: Quarterly
