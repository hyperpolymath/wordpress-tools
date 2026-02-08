# WP Praxis Symbolic Engine - PowerShell Core

This directory contains the PowerShell implementation of the WP Praxis Symbolic Engine, which serves as the core orchestration layer for symbolic workflow execution.

## Files Overview

### 1. symbolic.ps1 (Main Entry Point)
**639 lines** - The main orchestrator for the symbolic workflow system

**Key Features:**
- Loads and parses YAML/TOML manifests
- Dispatches symbolic operations to appropriate modules
- Provides verbose logging and comprehensive error handling
- Coordinates execution across multiple layers (Rust, PHP, Elixir)
- Interactive mode for manual operation
- Supports multiple operation types: Audit, Baseline, Execute, Validate, Visualize

**Main Functions:**
- `Import-SymbolicManifest` - Loads YAML/TOML manifests
- `Import-TomlManifest` / `Import-YamlManifest` - Format-specific parsers
- `Invoke-SymbolicDispatch` - Routes operations to appropriate handlers
- `Start-InteractiveMode` - Interactive CLI interface
- `Show-SymbolicStatus` - Display engine status
- `Save-SymbolicState` - Persist execution state

**Usage:**
```powershell
# Execute workflow from manifest
.\symbolic.ps1 -ManifestPath "workflow.toml" -Operation Execute -Verbose

# Interactive mode
.\symbolic.ps1 -Operation Interactive

# Audit with specific output path
.\symbolic.ps1 -ManifestPath "workflow.yaml" -Operation Audit -OutputPath "./reports"
```

---

### 2. Run-SymbolicAudit.ps1 (Audit Engine)
**696 lines** - Analyzes symbolic state and compares against baseline

**Key Features:**
- Reads and compares current symbolic index against normative baseline
- Reports deviations, inconsistencies, and potential issues
- Validates symbol, role, and action integrity
- Performs semantic coherence analysis
- Multiple output formats: Text, JSON, HTML
- Configurable severity filtering

**Main Functions:**
- `Invoke-SymbolicAudit` - Main audit orchestrator
- `Test-SymbolIntegrity` - Validates individual symbols
- `Test-RoleIntegrity` - Validates role definitions
- `Test-ActionIntegrity` - Validates action configurations
- `Test-SemanticCoherence` - Checks for semantic issues
- `Format-AuditReport` - Generates formatted reports
- `Show-AuditSummary` - Display audit results

**Usage:**
```powershell
# Basic audit
Invoke-SymbolicAudit -Manifest $manifest

# Detailed audit with JSON output
Invoke-SymbolicAudit -Manifest $manifest -OutputFormat JSON -IncludeDetails

# Audit with custom baseline
Invoke-SymbolicAudit -Manifest $manifest -BaselinePath "./custom-baseline.toml"
```

---

### 3. Set-NormativeBaseline.ps1 (Baseline Manager)
**421 lines** - Establishes and manages normative baselines

**Key Features:**
- Captures current symbolic state as baseline
- Creates baseline TOML configuration files
- Validates baseline integrity before creation
- Stores metadata for tracking and comparison
- Supports force overwrite with confirmation
- Generates human-readable and machine-parsable formats

**Main Functions:**
- `Set-SymbolicBaseline` - Main baseline creation function
- `Test-ManifestIntegrity` - Pre-baseline validation
- `New-BaselineStructure` - Constructs baseline data structure
- `ConvertTo-TomlBaseline` - TOML serialization
- `Get-ManifestHash` - Creates fingerprint for comparison
- `Show-BaselineSummary` - Display baseline information

**Usage:**
```powershell
# Create baseline from current manifest
Set-SymbolicBaseline -Manifest $manifest

# Create baseline with description
Set-SymbolicBaseline -Manifest $manifest -Description "Production v1.0" -Force

# Include detailed metadata
Set-SymbolicBaseline -Manifest $manifest -IncludeMetadata
```

---

### 4. Trigger-SymbolicActions.ps1 (Action Executor)
**670 lines** - Executes symbolic actions and manages workflows

**Key Features:**
- Parses action definitions from manifests
- Dispatches to appropriate executors (Rust, PHP, Elixir, PowerShell, External)
- Tracks execution state and progress
- Handles rollback on failure
- Supports dry-run mode for testing
- Timeout management per action
- Continue-on-error option for fault tolerance

**Main Functions:**
- `Invoke-SymbolicActions` - Main action orchestrator
- `Invoke-SingleAction` - Execute individual actions
- `Test-ActionExecutability` - Pre-execution validation
- `Test-ExecutorAvailability` - Check executor prerequisites
- `Invoke-ExecutorDispatch` - Route to specific executor
- `Invoke-RustExecutor` / `Invoke-PhpExecutor` / `Invoke-ElixirExecutor` / `Invoke-PowerShellExecutor` / `Invoke-ExternalExecutor` - Executor implementations
- `Invoke-ActionRollback` - Rollback failed executions
- `Show-ExecutionSummary` - Display results
- `Save-ExecutionLog` - Persist execution history

**Usage:**
```powershell
# Execute all actions in manifest
Invoke-SymbolicActions -Manifest $manifest -Context wordpress

# Execute specific actions with dry-run
Invoke-SymbolicActions -Manifest $manifest -ActionFilter "deploy*" -DryRun

# Execute with error tolerance
Invoke-SymbolicActions -Manifest $manifest -ContinueOnError -Timeout 600
```

---

### 5. Validate-SymbolicRoles.ps1 (Role Validator)
**827 lines** - Validates role definitions and permissions

**Key Features:**
- Checks symbolic role definitions for correctness
- Validates role constraints and permissions
- Ensures role consistency across workflows
- Detects circular dependencies in role hierarchies
- Validates role references in symbols and actions
- Builds comprehensive permission matrix
- Supports strict mode (warnings as errors)

**Main Functions:**
- `Test-SymbolicRoles` - Main validation orchestrator
- `Test-SingleRole` - Validate individual role
- `Test-RolePermissions` - Permission validation
- `Test-RoleConstraints` - Constraint validation
- `Test-RoleCapabilities` - WordPress capability validation
- `Test-RoleHierarchy` - Hierarchy and circular dependency checks
- `Test-RoleReferences` - Cross-reference validation
- `Build-PermissionMatrix` - Permission inheritance mapping
- `Show-ValidationSummary` - Display validation results

**Usage:**
```powershell
# Basic role validation
Test-SymbolicRoles -Manifest $manifest

# Strict validation with reference checking
Test-SymbolicRoles -Manifest $manifest -StrictMode -CheckReferences

# JSON output for CI/CD
Test-SymbolicRoles -Manifest $manifest -OutputFormat JSON
```

---

### 6. Visualize-SymbolicDiff.ps1 (Diff Visualizer)
**762 lines** - Visualizes differences between symbolic states

**Key Features:**
- Compares two symbolic states (current vs baseline/previous)
- Generates visual diff in multiple formats
- Highlights semantic changes
- Analyzes semantic impact and breaking changes
- Supports Text, HTML, JSON, Side-by-Side output
- Configurable detail levels
- Color scheme options for accessibility

**Main Functions:**
- `Show-SymbolicDiff` - Main diff orchestrator
- `Import-ComparisonFile` - Load comparison source
- `Compare-SymbolicElements` - Element-level comparison
- `Compare-Metadata` - Metadata comparison
- `Calculate-DiffStatistics` - Statistical analysis
- `Analyze-SemanticImpact` - Impact assessment
- `Format-DiffVisualization` - Visual formatting
- `Show-DiffStatistics` - Display statistics
- `Save-DiffReport` - Persist comparison report

**Usage:**
```powershell
# Compare against default baseline
Show-SymbolicDiff -Manifest $manifest

# Compare with custom baseline and HTML output
Show-SymbolicDiff -Manifest $manifest -OutputFormat HTML

# Detailed comparison showing unchanged elements
Show-SymbolicDiff -Manifest $manifest -ComparePath "previous.toml" -ShowUnchanged

# High contrast visualization
Show-SymbolicDiff -Manifest $manifest -ColorScheme HighContrast
```

---

## Architecture Integration

The PowerShell symbolic engine integrates with other WP Praxis components:

```
┌─────────────────────────────────────────────────────┐
│         symbolic.ps1 (Main Entry Point)             │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐│
│  │   Manifest   │  │   Config     │  │   State   ││
│  │   Parser     │  │   Loader     │  │   Manager ││
│  └──────────────┘  └──────────────┘  └───────────┘│
└──────────────┬──────────────────────────────────────┘
               │
       ┌───────┴───────────────────────────────┐
       │                                       │
       ▼                                       ▼
┌─────────────┐                        ┌─────────────┐
│  Operation  │                        │  Operation  │
│  Modules    │                        │  Modules    │
│             │                        │             │
│ • Audit     │                        │ • Execute   │
│ • Baseline  │                        │ • Validate  │
│ • Visualize │                        │             │
└──────┬──────┘                        └──────┬──────┘
       │                                      │
       │         ┌────────────────────────────┘
       │         │
       ▼         ▼
┌─────────────────────────────────────┐
│     Executor Dispatch Layer         │
│                                     │
│  ┌──────┐  ┌──────┐  ┌──────────┐ │
│  │ Rust │  │ PHP  │  │  Elixir  │ │
│  └──────┘  └──────┘  └──────────┘ │
└─────────────────────────────────────┘
```

## Output Files

All operations generate output files in the configured output directory (default: `../../output/`):

| File | Generator | Purpose |
|------|-----------|---------|
| `symbolic-state.json` | symbolic.ps1 | Current execution state |
| `symbolic-baseline.toml` | Set-NormativeBaseline.ps1 | Normative baseline definition |
| `symbolic-baseline.meta.json` | Set-NormativeBaseline.ps1 | Baseline metadata |
| `audit-report-*.{txt,json,html}` | Run-SymbolicAudit.ps1 | Audit reports |
| `execution-log-*.json` | Trigger-SymbolicActions.ps1 | Action execution logs |
| `role-validation-*.{txt,json,html}` | Validate-SymbolicRoles.ps1 | Role validation reports |
| `diff-report-*.{txt,json,html}` | Visualize-SymbolicDiff.ps1 | Diff comparison reports |
| `symbolic-engine.log` | symbolic.ps1 | Consolidated engine log |

## PowerShell Best Practices Implemented

All scripts follow PowerShell best practices:

1. **Approved Verbs**: All functions use approved PowerShell verbs (Get, Set, Test, Invoke, Show, etc.)
2. **Comment-Based Help**: Every function includes comprehensive help documentation
3. **Parameter Validation**: Robust parameter validation with ValidateSet, ValidateScript, etc.
4. **Error Handling**: Try/catch blocks with meaningful error messages
5. **Verbose Support**: -Verbose parameter support throughout
6. **WhatIf Support**: -WhatIf for destructive operations
7. **Pipeline Support**: Functions accept pipeline input where appropriate
8. **Module Exports**: Proper Export-ModuleMember declarations

## Manifest Structure

The engine expects YAML or TOML manifests with this structure:

```yaml
# YAML Example
symbols:
  - name: example_symbol
    type: action
    context: wordpress
    dispatch: rust
    parameters:
      key: value

roles:
  - name: editor
    permissions: read,write,modify_symbols
    constraints:
      max_actions: 10
      allowed_contexts: wordpress,cli

actions:
  - name: deploy_changes
    executor: rust
    command: deploy
    context: wordpress
```

```toml
# TOML Example
[[symbols]]
name = "example_symbol"
type = "action"
context = "wordpress"
dispatch = "rust"

[[roles]]
name = "editor"
permissions = "read,write,modify_symbols"

[[actions]]
name = "deploy_changes"
executor = "rust"
command = "deploy"
context = "wordpress"
```

## Error Handling

All scripts implement comprehensive error handling:

- **Validation Errors**: Pre-execution validation with clear error messages
- **Execution Errors**: Runtime error capture with rollback support
- **File Errors**: Graceful handling of missing or malformed files
- **Timeout Errors**: Configurable timeouts with proper cleanup
- **Logging**: All errors logged to `symbolic-engine.log`

## Testing

To test the symbolic engine:

```powershell
# 1. Create a test manifest
$testManifest = @{
    symbols = @(
        @{ name = "test_symbol"; type = "action" }
    )
    roles = @(
        @{ name = "test_role"; permissions = "read,write" }
    )
    actions = @(
        @{ name = "test_action"; executor = "powershell"; script = "Write-Host 'Test'" }
    )
    metadata = @{ version = "1.0" }
}

# 2. Set baseline
Set-SymbolicBaseline -Manifest $testManifest

# 3. Run audit
Invoke-SymbolicAudit -Manifest $testManifest

# 4. Validate roles
Test-SymbolicRoles -Manifest $testManifest

# 5. Execute actions (dry run)
Invoke-SymbolicActions -Manifest $testManifest -DryRun

# 6. Visualize diff
Show-SymbolicDiff -Manifest $testManifest
```

## Dependencies

### Required:
- PowerShell 5.1+ or PowerShell Core 7+
- Write access to output directory

### Optional (for full functionality):
- **Rust**: For Rust executor support (`cargo` must be in PATH)
- **PHP**: For PHP executor support (`php` must be in PATH)
- **Elixir**: For Elixir executor support (`elixir` and `mix` must be in PATH)

### Future Enhancements:
- **PowerShell-Yaml**: For improved YAML parsing
- **Pester**: For automated testing framework

## Total Implementation

- **6 PowerShell scripts**
- **4,015 lines of code**
- **50+ functions**
- **Comprehensive error handling**
- **Full manifest support (YAML/TOML)**
- **Multi-executor dispatch**
- **Complete introspection and reporting**

## Version

- **Engine Version**: 0.1.0
- **Last Updated**: 2025-11-22
- **License**: GNU AGPL v3

---

For more information, see:
- `/home/user/wp-praxis/CLAUDE.md` - Project overview and guidelines
- `/home/user/wp-praxis/Docs/` - Comprehensive documentation
- `/home/user/wp-praxis/examples/` - Example workflows
