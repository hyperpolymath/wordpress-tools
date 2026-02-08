<#
.SYNOPSIS
    Establish normative baseline for symbolic state

.DESCRIPTION
    Captures the current symbolic state and creates a baseline TOML configuration
    for future comparisons. This baseline represents the "known good" state that
    audits will compare against to detect deviations and maintain semantic integrity.

.PARAMETER Manifest
    The loaded manifest hashtable containing current symbolic definitions

.PARAMETER OutputPath
    Path where the baseline TOML file will be saved

.PARAMETER Description
    Description of this baseline for documentation purposes

.PARAMETER Force
    Overwrite existing baseline without prompting

.PARAMETER IncludeMetadata
    Include detailed metadata in the baseline

.EXAMPLE
    Set-SymbolicBaseline -Manifest $manifest

.EXAMPLE
    Set-SymbolicBaseline -Manifest $manifest -Description "Production baseline v1.0" -Force

.NOTES
    Part of WP Praxis Symbolic Engine
    Creates immutable snapshots for comparison and validation
#>

function Set-SymbolicBaseline {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$Description = '',

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata
    )

    Write-Verbose "Establishing normative baseline..."

    try {
        # Determine output path
        if (-not $OutputPath) {
            $baseOutputPath = if ($script:Paths.Output) { $script:Paths.Output } else { Join-Path $PSScriptRoot "../../output" }
            $OutputPath = Join-Path $baseOutputPath "symbolic-baseline.toml"
        }

        # Check if baseline exists
        if ((Test-Path $OutputPath) -and -not $Force) {
            $response = Read-Host "Baseline already exists at $OutputPath. Overwrite? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Host "Baseline creation cancelled." -ForegroundColor Yellow
                return $null
            }
        }

        if ($PSCmdlet.ShouldProcess($OutputPath, "Create baseline")) {
            # Validate manifest before creating baseline
            Write-Verbose "Validating manifest integrity..."
            $validation = Test-ManifestIntegrity -Manifest $Manifest

            if (-not $validation.IsValid) {
                Write-Warning "Manifest has validation issues. Creating baseline anyway, but review recommended."
                foreach ($issue in $validation.Issues) {
                    Write-Warning "  - $($issue.Message)"
                }
            }

            # Create baseline structure
            $baseline = New-BaselineStructure -Manifest $Manifest -Description $Description -IncludeMetadata:$IncludeMetadata

            # Convert to TOML format
            $tomlContent = ConvertTo-TomlBaseline -Baseline $baseline

            # Save baseline file
            $tomlContent | Set-Content -Path $OutputPath -Encoding UTF8

            # Create baseline metadata file
            $metadataPath = $OutputPath -replace '\.toml$', '.meta.json'
            $metadata = @{
                CreatedAt = Get-Date -Format 'o'
                Description = $Description
                ManifestHash = Get-ManifestHash -Manifest $Manifest
                SymbolCount = $Manifest.symbols.Count
                RoleCount = $Manifest.roles.Count
                ActionCount = $Manifest.actions.Count
                ValidationStatus = if ($validation.IsValid) { 'Valid' } else { 'HasIssues' }
                ValidationIssues = $validation.Issues.Count
                EngineVersion = $script:EngineVersion ?? '0.1.0'
            }
            $metadata | ConvertTo-Json -Depth 10 | Set-Content -Path $metadataPath

            # Display summary
            Show-BaselineSummary -Baseline $baseline -OutputPath $OutputPath

            Write-Host "`nBaseline established successfully!" -ForegroundColor Green
            Write-Host "Baseline file: $OutputPath" -ForegroundColor Cyan
            Write-Host "Metadata file: $metadataPath" -ForegroundColor Cyan

            return @{
                Success = $true
                BaselinePath = $OutputPath
                MetadataPath = $metadataPath
                Timestamp = Get-Date -Format 'o'
                Summary = $metadata
            }
        }
    }
    catch {
        Write-Error "Failed to establish baseline: $_"
        throw
    }
}

#region Helper Functions

function Test-ManifestIntegrity {
    [CmdletBinding()]
    param([hashtable]$Manifest)

    $validation = @{
        IsValid = $true
        Issues = @()
    }

    # Check for required sections
    if (-not $Manifest.symbols) {
        $validation.Issues += @{
            Severity = 'Warning'
            Message = 'No symbols defined in manifest'
        }
    }

    # Validate symbols
    foreach ($symbol in $Manifest.symbols) {
        if (-not $symbol.name) {
            $validation.IsValid = $false
            $validation.Issues += @{
                Severity = 'Error'
                Message = 'Symbol missing name field'
            }
        }
        if (-not $symbol.type) {
            $validation.Issues += @{
                Severity = 'Warning'
                Message = "Symbol '$($symbol.name)' missing type field"
            }
        }
    }

    # Check for duplicate names
    $symbolNames = $Manifest.symbols | ForEach-Object { $_.name } | Where-Object { $_ }
    $duplicates = $symbolNames | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($dup in $duplicates) {
        $validation.IsValid = $false
        $validation.Issues += @{
            Severity = 'Error'
            Message = "Duplicate symbol name: $($dup.Name)"
        }
    }

    return $validation
}

function New-BaselineStructure {
    [CmdletBinding()]
    param(
        [hashtable]$Manifest,
        [string]$Description,
        [bool]$IncludeMetadata
    )

    $baseline = @{
        metadata = @{
            version = '1.0'
            timestamp = Get-Date -Format 'o'
            description = $Description
            generator = 'WP Praxis Symbolic Engine'
            engine_version = $script:EngineVersion ?? '0.1.0'
        }
        symbols = @()
        roles = @()
        actions = @()
    }

    # Process symbols
    foreach ($symbol in $Manifest.symbols) {
        $baselineSymbol = @{
            name = $symbol.name
            type = $symbol.type
        }

        # Include all fields from manifest
        foreach ($key in $symbol.Keys) {
            if ($key -notin @('name', 'type')) {
                $baselineSymbol[$key] = $symbol[$key]
            }
        }

        if ($IncludeMetadata) {
            $baselineSymbol['baseline_timestamp'] = Get-Date -Format 'o'
            $baselineSymbol['hash'] = Get-ObjectHash -Object $symbol
        }

        $baseline.symbols += $baselineSymbol
    }

    # Process roles
    foreach ($role in $Manifest.roles) {
        $baselineRole = @{}
        foreach ($key in $role.Keys) {
            $baselineRole[$key] = $role[$key]
        }

        if ($IncludeMetadata) {
            $baselineRole['baseline_timestamp'] = Get-Date -Format 'o'
            $baselineRole['hash'] = Get-ObjectHash -Object $role
        }

        $baseline.roles += $baselineRole
    }

    # Process actions
    foreach ($action in $Manifest.actions) {
        $baselineAction = @{}
        foreach ($key in $action.Keys) {
            $baselineAction[$key] = $action[$key]
        }

        if ($IncludeMetadata) {
            $baselineAction['baseline_timestamp'] = Get-Date -Format 'o'
            $baselineAction['hash'] = Get-ObjectHash -Object $action
        }

        $baseline.actions += $baselineAction
    }

    return $baseline
}

function ConvertTo-TomlBaseline {
    [CmdletBinding()]
    param([hashtable]$Baseline)

    $toml = New-Object System.Text.StringBuilder

    # Header comment
    [void]$toml.AppendLine("# WP Praxis Symbolic Baseline")
    [void]$toml.AppendLine("# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$toml.AppendLine("# DO NOT EDIT MANUALLY - Use Set-NormativeBaseline to update")
    [void]$toml.AppendLine("")

    # Metadata section
    [void]$toml.AppendLine("[metadata]")
    foreach ($key in $Baseline.metadata.Keys | Sort-Object) {
        $value = $Baseline.metadata[$key]
        [void]$toml.AppendLine("$key = ""$value""")
    }
    [void]$toml.AppendLine("")

    # Symbols section
    if ($Baseline.symbols.Count -gt 0) {
        [void]$toml.AppendLine("# Symbolic Definitions")
        for ($i = 0; $i -lt $Baseline.symbols.Count; $i++) {
            $symbol = $Baseline.symbols[$i]
            [void]$toml.AppendLine("[[symbols]]")

            foreach ($key in $symbol.Keys | Sort-Object) {
                $value = $symbol[$key]
                if ($null -ne $value) {
                    $escapedValue = $value -replace '"', '\"'
                    [void]$toml.AppendLine("$key = ""$escapedValue""")
                }
            }
            [void]$toml.AppendLine("")
        }
    }

    # Roles section
    if ($Baseline.roles.Count -gt 0) {
        [void]$toml.AppendLine("# Role Definitions")
        for ($i = 0; $i -lt $Baseline.roles.Count; $i++) {
            $role = $Baseline.roles[$i]
            [void]$toml.AppendLine("[[roles]]")

            foreach ($key in $role.Keys | Sort-Object) {
                $value = $role[$key]
                if ($null -ne $value) {
                    $escapedValue = $value -replace '"', '\"'
                    [void]$toml.AppendLine("$key = ""$escapedValue""")
                }
            }
            [void]$toml.AppendLine("")
        }
    }

    # Actions section
    if ($Baseline.actions.Count -gt 0) {
        [void]$toml.AppendLine("# Action Definitions")
        for ($i = 0; $i -lt $Baseline.actions.Count; $i++) {
            $action = $Baseline.actions[$i]
            [void]$toml.AppendLine("[[actions]]")

            foreach ($key in $action.Keys | Sort-Object) {
                $value = $action[$key]
                if ($null -ne $value) {
                    $escapedValue = $value -replace '"', '\"'
                    [void]$toml.AppendLine("$key = ""$escapedValue""")
                }
            }
            [void]$toml.AppendLine("")
        }
    }

    return $toml.ToString()
}

function Get-ManifestHash {
    [CmdletBinding()]
    param([hashtable]$Manifest)

    # Create a stable string representation for hashing
    $representation = @(
        "symbols:$($Manifest.symbols.Count)"
        "roles:$($Manifest.roles.Count)"
        "actions:$($Manifest.actions.Count)"
    ) -join '|'

    $representation += '|' + (($Manifest.symbols | ForEach-Object { $_.name }) -join ',')

    # Generate hash
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($representation)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hasher.ComputeHash($bytes)
    $hash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''

    return $hash.Substring(0, 16)
}

function Get-ObjectHash {
    [CmdletBinding()]
    param([hashtable]$Object)

    # Create stable string representation
    $representation = ($Object.Keys | Sort-Object | ForEach-Object {
        "$_=$($Object[$_])"
    }) -join '|'

    # Generate hash
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($representation)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hasher.ComputeHash($bytes)
    $hash = [System.BitConverter]::ToString($hashBytes) -replace '-', ''

    return $hash.Substring(0, 12)
}

function Show-BaselineSummary {
    [CmdletBinding()]
    param(
        [hashtable]$Baseline,
        [string]$OutputPath
    )

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  BASELINE SUMMARY" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta

    Write-Host "Timestamp:    " -NoNewline
    Write-Host $Baseline.metadata.timestamp -ForegroundColor Cyan

    Write-Host "Version:      " -NoNewline
    Write-Host $Baseline.metadata.version -ForegroundColor Cyan

    if ($Baseline.metadata.description) {
        Write-Host "Description:  " -NoNewline
        Write-Host $Baseline.metadata.description -ForegroundColor Cyan
    }

    Write-Host "`nContent Summary:" -ForegroundColor Yellow
    Write-Host "  Symbols:  " -NoNewline
    Write-Host $Baseline.symbols.Count -ForegroundColor Green

    Write-Host "  Roles:    " -NoNewline
    Write-Host $Baseline.roles.Count -ForegroundColor Green

    Write-Host "  Actions:  " -NoNewline
    Write-Host $Baseline.actions.Count -ForegroundColor Green

    if ($Baseline.symbols.Count -gt 0) {
        Write-Host "`nSymbol Types:" -ForegroundColor Yellow
        $symbolTypes = $Baseline.symbols | Group-Object -Property type
        foreach ($group in $symbolTypes) {
            Write-Host "  $($group.Name): " -NoNewline
            Write-Host $group.Count -ForegroundColor Cyan
        }
    }

    Write-Host ""
}

#endregion

# Export function
Export-ModuleMember -Function Set-SymbolicBaseline
