# Reversibility

<!--
SPDX-License-Identifier: PMPL-1.0-or-later-or-later
SPDX-FileCopyrightText: 2025 WP Praxis Contributors
-->

**Core Principle**: Every operation in WP Praxis can be undone. No destructive defaults. Safe experimentation.

## Philosophy

WP Praxis is built on the principle that **reversibility reduces fear of change**. When contributors know their changes can be easily undone, they experiment more freely, learn faster, and innovate boldly.

### Key Tenets

1. **No Permanent Consequences**: Every operation has an undo mechanism
2. **Safe by Default**: Destructive operations require explicit confirmation
3. **Git + RVC = Safety**: Version control + Robot Vacuum Cleaner automated tidying
4. **Rollback Strategies**: Database operations have built-in rollback support

## Reversible Operations

### 1. Code Changes

**Mechanism**: Git version control

```bash
# Undo uncommitted changes
git restore <file>

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Revert a published commit
git revert <commit-hash>
```

**Safety**: Git history is never lost unless explicitly pruned.

### 2. Symbolic Operations

**Mechanism**: Rollback strategies in symbol definitions

```yaml
symbols:
  - name: update_site_title
    type: option
    operation: update
    rollback: store_previous  # Automatically stores old value
```

**Rollback Strategies**:
- `store_previous`: Save old value before modification
- `backup`: Create full backup before operation
- `custom`: User-defined rollback logic
- `none`: No rollback (use with caution)

**Implementation**: See `wp_praxis_core/src/symbol.rs:RollbackStrategy`

### 3. Database Operations

**Mechanism**: Transaction-based rollback

```rust
// Automatic rollback on error
let result = db.transaction(|tx| {
    tx.execute("UPDATE options SET value = ?", [new_value])?;
    Ok(())
});

// Explicit rollback
if !confirm_dangerous_operation() {
    tx.rollback()?;
}
```

**Safety**: All database operations wrapped in transactions by default.

### 4. Configuration Changes

**Mechanism**: Configuration versioning

```bash
# Save current config
just config-snapshot

# Restore previous config
just config-restore <snapshot-id>

# List available snapshots
just config-list
```

**Location**: `.config/wp-praxis/snapshots/`

### 5. File System Operations

**Mechanism**: RVC (Robot Vacuum Cleaner) automated backup

- Pre-commit hook: Snapshot before changes
- Pre-push hook: Verify no unintended deletions
- Automated cleanup: Old snapshots purged after 30 days

**Recovery**: `just rvc-restore <timestamp>`

## Non-Reversible Operations

Some operations are intentionally irreversible to prevent accidents:

### 1. Publishing Releases

**Why**: Once published, releases are immutable (SemVer contract)
**Mitigation**: Strict release checklist, multiple reviewer approval

### 2. Deleting Remote Branches

**Why**: Can orphan dependent work
**Mitigation**: Require explicit confirmation, 7-day grace period (soft delete)

### 3. Purging Old Data

**Why**: Reclaim storage space
**Mitigation**: Explicit opt-in, export option before purge, 90-day warning

## Confirmation Levels

WP Praxis uses a tiered confirmation system:

### Level 0: No Confirmation
- Idempotent operations (can run multiple times safely)
- Read-only operations
- Automatically reversible (stored in Git)

### Level 1: Soft Confirmation
- One-time prompt: "Are you sure? (y/N)"
- Destructive but reversible operations
- Example: Deleting local branch

### Level 2: Explicit Confirmation
- Type operation name to confirm
- Destructive with difficult reversal
- Example: Dropping database table

### Level 3: Time-Delayed Confirmation
- 24-hour waiting period + explicit confirmation
- Irreversible with widespread impact
- Example: Deleting production data

## Rollback Testing

Every destructive operation must have a corresponding test:

```rust
#[test]
fn test_symbol_deletion_rollback() {
    let symbol = create_test_symbol();
    let backup = symbol.clone();

    // Perform deletion
    delete_symbol(&symbol).unwrap();

    // Verify rollback works
    rollback_symbol(&backup).unwrap();
    assert_eq!(get_symbol(symbol.id), Some(backup));
}
```

**Coverage**: 100% of destructive operations must have rollback tests.

## Emergency Recovery

If something goes wrong:

### 1. Code Issues
```bash
# Find when it broke
git bisect start
git bisect bad HEAD
git bisect good <last-known-good-commit>

# Restore to working state
git reset --hard <last-known-good-commit>
```

### 2. Database Issues
```bash
# Restore from backup
just db-restore <timestamp>

# Rollback specific migration
just db-rollback <migration-name>
```

### 3. Configuration Issues
```bash
# Use last known-good config
just config-restore auto-latest

# Reset to defaults
just config-reset --confirm
```

### 4. File System Issues
```bash
# RVC cleanup recovery
just rvc-restore <timestamp>

# Full project recovery (nuclear option)
rm -rf ./* && git reset --hard HEAD
```

## Continuous Reversibility

### Pre-Commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
# Create snapshot before each commit
just rvc-snapshot pre-commit
```

### CI/CD Integration

```yaml
# .github/workflows/reversibility-test.yml
- name: Test Rollback Mechanisms
  run: |
    just test-rollbacks
    just verify-no-destructive-defaults
```

### Manual Audits

Quarterly checklist:
- [ ] All destructive operations have rollback tests
- [ ] Confirmation levels appropriate
- [ ] RVC backups not exceeding storage limits
- [ ] Recovery procedures documented and tested

## Philosophy in Practice

### Example: Symbol Deletion

**Before WP Praxis** (traditional approach):
```php
// Destructive, no rollback
delete_option('my_option');  // Gone forever if you made a mistake
```

**With WP Praxis** (reversible approach):
```yaml
symbols:
  - name: remove_old_option
    type: option
    operation: delete
    target: my_option
    rollback: store_previous  # Automatically saved
    confirmation_level: 1      # Requires confirmation
```

**Result**: Same operation, but:
- ✅ Old value automatically stored
- ✅ Confirmation required before execution
- ✅ Can be rolled back: `just rollback remove_old_option`
- ✅ Audit trail in Git history

## Benefits

1. **Psychological Safety**: Contributors feel safe experimenting
2. **Faster Learning**: Mistakes are learning opportunities, not disasters
3. **Better Testing**: Rollback tests validate correctness
4. **Operational Resilience**: Production issues can be quickly reverted
5. **Compliance**: Audit trails for regulatory requirements

## See Also

- [Symbol Rollback Strategies](wp_praxis_core/src/symbol.rs)
- [Database Transactions](wp_injector/src/main.rs)
- [RVC Configuration](.rvc/config.toml)
- [Git Workflow](CONTRIBUTING.md#git-workflow)

---

**Last Updated**: 2025-11-23
**Version**: 1.0.0
**Next Review**: 2026-02-23 (Quarterly)

"The best way to avoid mistakes is to make them reversible."
