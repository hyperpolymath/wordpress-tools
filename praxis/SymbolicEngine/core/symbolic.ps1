<#
.SYNOPSIS
    WP Praxis Symbolic Engine - Main Entry Point

.DESCRIPTION
    The main orchestrator for the WP Praxis symbolic workflow system.
    Loads declarative manifests (YAML/TOML), dispatches symbolic operations,
    and coordinates execution across multiple layers (Rust, PHP, Elixir).

.PARAMETER ManifestPath
    Path to the workflow manifest file (YAML or TOML format)

.PARAMETER Operation
    The symbolic operation to perform: Audit, Baseline, Execute, Validate, Visualize

.PARAMETER Context
    The execution context (wordpress, cli, web, etc.)

.PARAMETER OutputPath
    Path for output files (logs, reports, etc.)

.PARAMETER Verbose
    Enable verbose logging

.PARAMETER WhatIf
    Show what would happen without executing

.EXAMPLE
    .\symbolic.ps1 -ManifestPath "workflow.toml" -Operation Execute

.EXAMPLE
    .\symbolic.ps1 -ManifestPath "workflow.yaml" -Operation Audit -Verbose

.NOTES
    Version: 0.1.0
    Part of WP Praxis - A modular symbolic system for WordPress workflows
    License: GNU AGPL v3
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "Manifest file not found: $_"
        }
        if ($_ -notmatch '\.(ya?ml|toml)$') {
            throw "Manifest must be YAML or TOML format"
        }
        return $true
    })]
    [string]$ManifestPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Audit', 'Baseline', 'Execute', 'Validate', 'Visualize', 'Interactive')]
    [string]$Operation = 'Interactive',

    [Parameter(Mandatory = $false)]
    [string]$Context = 'cli',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path $PSScriptRoot "../../output"),

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation
)

#region Module Initialization

# Script metadata
$script:EngineVersion = '0.1.0'
$script:EngineName = 'WP Praxis Symbolic Engine'
$script:ScriptRoot = $PSScriptRoot

# Initialize paths
$script:Paths = @{
    Root         = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Core         = $PSScriptRoot
    Output       = $OutputPath
    StateFile    = Join-Path $OutputPath "symbolic-state.json"
    BaselineFile = Join-Path $OutputPath "symbolic-baseline.toml"
    LogFile      = Join-Path $OutputPath "symbolic-engine.log"
}

# Ensure output directory exists
if (-not (Test-Path $script:Paths.Output)) {
    New-Item -ItemType Directory -Path $script:Paths.Output -Force | Out-Null
}

# Load helper modules
$script:Modules = @(
    'Run-SymbolicAudit.ps1'
    'Set-NormativeBaseline.ps1'
    'Trigger-SymbolicActions.ps1'
    'Validate-SymbolicRoles.ps1'
    'Visualize-SymbolicDiff.ps1'
)

foreach ($module in $script:Modules) {
    $modulePath = Join-Path $PSScriptRoot $module
    if (Test-Path $modulePath) {
        . $modulePath
        Write-Verbose "Loaded module: $module"
    } else {
        Write-Warning "Module not found: $module"
    }
}

#endregion

#region Logging Functions

function Write-SymbolicLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Info',

        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to log file
    Add-Content -Path $script:Paths.LogFile -Value $logEntry -ErrorAction SilentlyContinue

    # Write to console with appropriate formatting
    if (-not $NoConsole) {
        switch ($Level) {
            'Error'   { Write-Host $logEntry -ForegroundColor Red }
            'Warning' { Write-Host $logEntry -ForegroundColor Yellow }
            'Success' { Write-Host $logEntry -ForegroundColor Green }
            'Debug'   { Write-Verbose $logEntry }
            default   { Write-Host $logEntry -ForegroundColor Cyan }
        }
    }
}

function Write-SymbolicHeader {
    [CmdletBinding()]
    param([string]$Title)

    $border = "=" * 70
    Write-Host "`n$border" -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Magenta
    Write-Host "$border`n" -ForegroundColor Magenta
}

#endregion

#region Manifest Parsing

function Import-SymbolicManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-SymbolicLog "Loading manifest: $Path" -Level Info

    try {
        $extension = [System.IO.Path]::GetExtension($Path).ToLower()

        switch ($extension) {
            '.toml' {
                return Import-TomlManifest -Path $Path
            }
            '.yaml' {
                return Import-YamlManifest -Path $Path
            }
            '.yml' {
                return Import-YamlManifest -Path $Path
            }
            default {
                throw "Unsupported manifest format: $extension"
            }
        }
    }
    catch {
        Write-SymbolicLog "Failed to load manifest: $_" -Level Error
        throw
    }
}

function Import-TomlManifest {
    [CmdletBinding()]
    param([string]$Path)

    # Simple TOML parser for basic key-value structures
    # For production, consider using a proper TOML library

    $content = Get-Content -Path $Path -Raw
    $manifest = @{
        symbols = @()
        roles = @()
        actions = @()
        metadata = @{}
    }

    $currentSection = $null
    $currentObject = $null

    foreach ($line in ($content -split "`n")) {
        $line = $line.Trim()

        # Skip comments and empty lines
        if ($line -match '^\s*#' -or $line -eq '') {
            continue
        }

        # Section headers
        if ($line -match '^\[(.+)\]$') {
            $sectionName = $Matches[1]
            $currentSection = $sectionName

            if ($sectionName -match '^(symbols|roles|actions)\.') {
                $currentObject = @{}
            }
            continue
        }

        # Key-value pairs
        if ($line -match '^([^=]+)=(.+)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim() -replace '^["'']|["'']$', ''

            if ($currentObject) {
                $currentObject[$key] = $value
            } else {
                $manifest.metadata[$key] = $value
            }
        }

        # Add completed objects to arrays
        if ($currentSection -match '^symbols\.' -and $line -match '^\[symbols\.') {
            if ($currentObject -and $currentObject.Count -gt 0) {
                $manifest.symbols += $currentObject
            }
            $currentObject = @{}
        }
        if ($currentSection -match '^roles\.' -and $line -match '^\[roles\.') {
            if ($currentObject -and $currentObject.Count -gt 0) {
                $manifest.roles += $currentObject
            }
            $currentObject = @{}
        }
        if ($currentSection -match '^actions\.' -and $line -match '^\[actions\.') {
            if ($currentObject -and $currentObject.Count -gt 0) {
                $manifest.actions += $currentObject
            }
            $currentObject = @{}
        }
    }

    # Add last object
    if ($currentObject -and $currentObject.Count -gt 0) {
        if ($currentSection -match '^symbols\.') { $manifest.symbols += $currentObject }
        if ($currentSection -match '^roles\.') { $manifest.roles += $currentObject }
        if ($currentSection -match '^actions\.') { $manifest.actions += $currentObject }
    }

    return $manifest
}

function Import-YamlManifest {
    [CmdletBinding()]
    param([string]$Path)

    # Simple YAML parser for basic structures
    # For production, consider using powershell-yaml module

    $content = Get-Content -Path $Path -Raw
    $manifest = @{
        symbols = @()
        roles = @()
        actions = @()
        metadata = @{}
    }

    # Basic YAML parsing (simplified)
    # This handles simple key-value and list structures

    $lines = $content -split "`n"
    $currentSection = $null
    $currentObject = $null
    $indent = 0

    foreach ($line in $lines) {
        if ($line -match '^\s*#' -or $line -match '^\s*$') {
            continue
        }

        $currentIndent = ($line -replace '^(\s*).*', '$1').Length

        # Top-level sections
        if ($line -match '^(\w+):') {
            $currentSection = $Matches[1]
            continue
        }

        # List items
        if ($line -match '^\s+- (\w+):\s*(.*)') {
            if ($currentObject -and $currentObject.Count -gt 0) {
                $manifest.$currentSection += $currentObject
            }
            $currentObject = @{
                $Matches[1] = $Matches[2]
            }
            continue
        }

        # Object properties
        if ($line -match '^\s+(\w+):\s*(.*)') {
            $key = $Matches[1]
            $value = $Matches[2]

            if ($currentObject) {
                $currentObject[$key] = $value
            } else {
                $manifest.metadata[$key] = $value
            }
        }
    }

    # Add last object
    if ($currentObject -and $currentObject.Count -gt 0) {
        $manifest.$currentSection += $currentObject
    }

    return $manifest
}

#endregion

#region Symbolic Dispatch

function Invoke-SymbolicDispatch {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory = $true)]
        [string]$Operation,

        [Parameter(Mandatory = $false)]
        [string]$Context = 'cli'
    )

    Write-SymbolicLog "Dispatching operation: $Operation (Context: $Context)" -Level Info

    $result = @{
        Success = $false
        Operation = $Operation
        Context = $Context
        Timestamp = Get-Date -Format 'o'
        Output = $null
        Errors = @()
    }

    try {
        if ($PSCmdlet.ShouldProcess("Symbolic Operation: $Operation", "Execute")) {
            switch ($Operation) {
                'Audit' {
                    $result.Output = Invoke-SymbolicAudit -Manifest $Manifest
                    $result.Success = $true
                }
                'Baseline' {
                    $result.Output = Set-SymbolicBaseline -Manifest $Manifest
                    $result.Success = $true
                }
                'Execute' {
                    $result.Output = Invoke-SymbolicActions -Manifest $Manifest -Context $Context
                    $result.Success = $true
                }
                'Validate' {
                    $result.Output = Test-SymbolicRoles -Manifest $Manifest
                    $result.Success = $true
                }
                'Visualize' {
                    $result.Output = Show-SymbolicDiff -Manifest $Manifest
                    $result.Success = $true
                }
                'Interactive' {
                    $result.Output = Start-InteractiveMode -Manifest $Manifest
                    $result.Success = $true
                }
                default {
                    throw "Unknown operation: $Operation"
                }
            }
        }
    }
    catch {
        $result.Success = $false
        $result.Errors += $_.Exception.Message
        Write-SymbolicLog "Operation failed: $_" -Level Error
        throw
    }

    # Save execution state
    Save-SymbolicState -Result $result

    return $result
}

function Save-SymbolicState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )

    try {
        $state = @{
            LastExecution = $Result
            EngineVersion = $script:EngineVersion
            Timestamp = Get-Date -Format 'o'
        }

        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $script:Paths.StateFile
        Write-Verbose "Saved execution state to: $($script:Paths.StateFile)"
    }
    catch {
        Write-Warning "Failed to save state: $_"
    }
}

#endregion

#region Interactive Mode

function Start-InteractiveMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Manifest
    )

    Write-SymbolicHeader "WP Praxis Symbolic Engine - Interactive Mode"

    Write-Host "Available operations:" -ForegroundColor Yellow
    Write-Host "  1. Audit     - Run symbolic state audit"
    Write-Host "  2. Baseline  - Set normative baseline"
    Write-Host "  3. Execute   - Trigger symbolic actions"
    Write-Host "  4. Validate  - Validate symbolic roles"
    Write-Host "  5. Visualize - Visualize symbolic differences"
    Write-Host "  6. Status    - Show current status"
    Write-Host "  7. Help      - Show detailed help"
    Write-Host "  Q. Quit      - Exit interactive mode"
    Write-Host ""

    while ($true) {
        $choice = Read-Host "Select operation [1-7, Q]"

        switch ($choice.ToUpper()) {
            '1' {
                if ($Manifest) {
                    Invoke-SymbolicAudit -Manifest $Manifest
                } else {
                    Write-Host "No manifest loaded. Load a manifest first." -ForegroundColor Yellow
                }
            }
            '2' {
                if ($Manifest) {
                    Set-SymbolicBaseline -Manifest $Manifest
                } else {
                    Write-Host "No manifest loaded. Load a manifest first." -ForegroundColor Yellow
                }
            }
            '3' {
                if ($Manifest) {
                    $context = Read-Host "Enter context (default: cli)"
                    if ([string]::IsNullOrEmpty($context)) { $context = 'cli' }
                    Invoke-SymbolicActions -Manifest $Manifest -Context $context
                } else {
                    Write-Host "No manifest loaded. Load a manifest first." -ForegroundColor Yellow
                }
            }
            '4' {
                if ($Manifest) {
                    Test-SymbolicRoles -Manifest $Manifest
                } else {
                    Write-Host "No manifest loaded. Load a manifest first." -ForegroundColor Yellow
                }
            }
            '5' {
                if ($Manifest) {
                    Show-SymbolicDiff -Manifest $Manifest
                } else {
                    Write-Host "No manifest loaded. Load a manifest first." -ForegroundColor Yellow
                }
            }
            '6' {
                Show-SymbolicStatus
            }
            '7' {
                Show-SymbolicHelp
            }
            'Q' {
                Write-Host "Exiting interactive mode..." -ForegroundColor Green
                return
            }
            default {
                Write-Host "Invalid choice. Please select 1-7 or Q." -ForegroundColor Red
            }
        }
        Write-Host ""
    }
}

function Show-SymbolicStatus {
    [CmdletBinding()]
    param()

    Write-SymbolicHeader "Symbolic Engine Status"

    Write-Host "Engine Version: " -NoNewline
    Write-Host $script:EngineVersion -ForegroundColor Green

    Write-Host "Output Path: " -NoNewline
    Write-Host $script:Paths.Output -ForegroundColor Cyan

    if (Test-Path $script:Paths.StateFile) {
        $state = Get-Content -Path $script:Paths.StateFile -Raw | ConvertFrom-Json
        Write-Host "Last Execution: " -NoNewline
        Write-Host $state.LastExecution.Timestamp -ForegroundColor Yellow
        Write-Host "Last Operation: " -NoNewline
        Write-Host $state.LastExecution.Operation -ForegroundColor Yellow
        Write-Host "Success: " -NoNewline
        if ($state.LastExecution.Success) {
            Write-Host "Yes" -ForegroundColor Green
        } else {
            Write-Host "No" -ForegroundColor Red
        }
    } else {
        Write-Host "No execution history found." -ForegroundColor Gray
    }

    if (Test-Path $script:Paths.BaselineFile) {
        Write-Host "Baseline: " -NoNewline
        Write-Host "Present" -ForegroundColor Green
    } else {
        Write-Host "Baseline: " -NoNewline
        Write-Host "Not set" -ForegroundColor Yellow
    }
}

function Show-SymbolicHelp {
    [CmdletBinding()]
    param()

    Write-SymbolicHeader "WP Praxis Symbolic Engine - Help"

    Write-Host @"
OVERVIEW:
  The Symbolic Engine is the core PowerShell orchestration layer for WP Praxis.
  It coordinates symbolic workflow execution across multiple programming languages.

OPERATIONS:
  Audit     - Analyzes current symbolic state and compares against baseline
  Baseline  - Captures current state as normative baseline for future comparisons
  Execute   - Triggers symbolic actions defined in the manifest
  Validate  - Validates symbolic role definitions and constraints
  Visualize - Generates visual diff between symbolic states

MANIFEST STRUCTURE:
  Manifests define declarative workflows using YAML or TOML format:

  - symbols: Declarative operation definitions
  - roles: Role-based access control definitions
  - actions: Executable action definitions
  - metadata: Workflow metadata and configuration

EXECUTION FLOW:
  1. Manifest loaded and parsed
  2. Symbols validated and dispatched
  3. Appropriate executor invoked (Rust, PHP, Elixir)
  4. Results captured and introspection feedback generated
  5. State saved for future operations

For more information, see: CLAUDE.md and Docs/
"@ -ForegroundColor Gray
}

#endregion

#region Main Execution

try {
    # Display header
    Write-SymbolicHeader "$script:EngineName v$script:EngineVersion"

    Write-SymbolicLog "Initializing symbolic engine..." -Level Info
    Write-SymbolicLog "Output directory: $($script:Paths.Output)" -Level Debug

    # Load manifest if provided
    $manifest = $null
    if ($ManifestPath) {
        $manifest = Import-SymbolicManifest -Path $ManifestPath
        Write-SymbolicLog "Manifest loaded successfully" -Level Success
        Write-SymbolicLog "Symbols: $($manifest.symbols.Count), Roles: $($manifest.roles.Count), Actions: $($manifest.actions.Count)" -Level Info
    } else {
        Write-SymbolicLog "No manifest specified, entering interactive mode" -Level Info
    }

    # Execute operation
    if ($manifest -or $Operation -eq 'Interactive') {
        $result = Invoke-SymbolicDispatch -Manifest $manifest -Operation $Operation -Context $Context

        if ($result.Success) {
            Write-SymbolicLog "Operation completed successfully" -Level Success
        } else {
            Write-SymbolicLog "Operation completed with errors" -Level Warning
            foreach ($error in $result.Errors) {
                Write-SymbolicLog "  - $error" -Level Error
            }
        }
    } else {
        Write-SymbolicLog "No operation specified and no manifest loaded" -Level Warning
        Show-SymbolicHelp
    }

    Write-SymbolicLog "Symbolic engine shutdown complete" -Level Info
}
catch {
    Write-SymbolicLog "Fatal error: $_" -Level Error
    Write-SymbolicLog "Stack trace: $($_.ScriptStackTrace)" -Level Debug
    exit 1
}

#endregion
