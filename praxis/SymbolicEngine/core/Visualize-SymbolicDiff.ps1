<#
.SYNOPSIS
    Visualize differences between symbolic states

.DESCRIPTION
    Compares two symbolic states (manifests, baselines, or execution snapshots),
    generates visual diff representations in multiple formats, highlights semantic
    changes, and outputs detailed comparison reports. Supports text, HTML, and
    JSON output formats with configurable detail levels.

.PARAMETER Manifest
    The current manifest to compare

.PARAMETER BaselinePath
    Path to baseline file for comparison (TOML format)

.PARAMETER ComparePath
    Path to alternative manifest/state for comparison

.PARAMETER OutputFormat
    Output format: Text, HTML, JSON, Side-by-Side

.PARAMETER HighlightLevel
    Highlighting detail: Minimal, Standard, Detailed

.PARAMETER ShowUnchanged
    Include unchanged elements in the output

.PARAMETER ColorScheme
    Color scheme for terminal output: Default, HighContrast, Monochrome

.EXAMPLE
    Show-SymbolicDiff -Manifest $manifest

.EXAMPLE
    Show-SymbolicDiff -Manifest $manifest -OutputFormat HTML

.EXAMPLE
    Show-SymbolicDiff -Manifest $manifest -ComparePath "previous-state.toml" -ShowUnchanged

.NOTES
    Part of WP Praxis Symbolic Engine
    Provides semantic change visualization and impact analysis
#>

function Show-SymbolicDiff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory = $false)]
        [string]$BaselinePath,

        [Parameter(Mandatory = $false)]
        [string]$ComparePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Text', 'HTML', 'JSON', 'Side-by-Side')]
        [string]$OutputFormat = 'Text',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Minimal', 'Standard', 'Detailed')]
        [string]$HighlightLevel = 'Standard',

        [Parameter(Mandatory = $false)]
        [switch]$ShowUnchanged,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'HighContrast', 'Monochrome')]
        [string]$ColorScheme = 'Default'
    )

    Write-Verbose "Generating symbolic diff visualization..."

    # Initialize diff report
    $diff = @{
        Timestamp = Get-Date -Format 'o'
        SourceType = 'Manifest'
        CompareType = $null
        OutputFormat = $OutputFormat
        HighlightLevel = $HighlightLevel
        Changes = @{
            Symbols = @()
            Roles = @()
            Actions = @()
            Metadata = @()
        }
        Statistics = @{
            TotalChanges = 0
            Added = 0
            Modified = 0
            Removed = 0
            Unchanged = 0
        }
        SemanticImpact = @{
            Level = 'Low'
            AffectedAreas = @()
            BreakingChanges = $false
        }
    }

    try {
        # Determine comparison source
        $compareManifest = $null

        if ($ComparePath) {
            Write-Verbose "Loading comparison file: $ComparePath"
            $compareManifest = Import-ComparisonFile -Path $ComparePath
            $diff.CompareType = 'File'
        } elseif ($BaselinePath) {
            Write-Verbose "Loading baseline: $BaselinePath"
            $compareManifest = Import-ComparisonFile -Path $BaselinePath
            $diff.CompareType = 'Baseline'
        } else {
            # Try to find default baseline
            $defaultBaseline = if ($script:Paths.Output) {
                Join-Path $script:Paths.Output "symbolic-baseline.toml"
            } else {
                Join-Path $PSScriptRoot "../../output/symbolic-baseline.toml"
            }

            if (Test-Path $defaultBaseline) {
                Write-Verbose "Using default baseline: $defaultBaseline"
                $compareManifest = Import-ComparisonFile -Path $defaultBaseline
                $diff.CompareType = 'Baseline'
            } else {
                Write-Warning "No comparison source specified and no baseline found"
                Write-Host "Run Set-NormativeBaseline first to create a baseline for comparison" -ForegroundColor Yellow
                return $null
            }
        }

        Write-Host "`n========================================" -ForegroundColor Magenta
        Write-Host "  SYMBOLIC DIFF VISUALIZATION" -ForegroundColor Magenta
        Write-Host "========================================`n" -ForegroundColor Magenta

        # Compare symbols
        Write-Verbose "Comparing symbols..."
        $diff.Changes.Symbols = Compare-SymbolicElements -Current $Manifest.symbols `
            -Baseline $compareManifest.symbols -ElementType 'Symbol'

        # Compare roles
        Write-Verbose "Comparing roles..."
        $diff.Changes.Roles = Compare-SymbolicElements -Current $Manifest.roles `
            -Baseline $compareManifest.roles -ElementType 'Role'

        # Compare actions
        Write-Verbose "Comparing actions..."
        $diff.Changes.Actions = Compare-SymbolicElements -Current $Manifest.actions `
            -Baseline $compareManifest.actions -ElementType 'Action'

        # Compare metadata
        Write-Verbose "Comparing metadata..."
        $diff.Changes.Metadata = Compare-Metadata -Current $Manifest.metadata `
            -Baseline $compareManifest.metadata

        # Calculate statistics
        $diff.Statistics = Calculate-DiffStatistics -Changes $diff.Changes

        # Analyze semantic impact
        $diff.SemanticImpact = Analyze-SemanticImpact -Changes $diff.Changes

        # Generate visualization
        $visualization = Format-DiffVisualization -Diff $diff -ColorScheme $ColorScheme `
            -ShowUnchanged:$ShowUnchanged

        # Display visualization
        Write-Host $visualization

        # Display statistics summary
        Show-DiffStatistics -Diff $diff

        # Save report
        $reportPath = Save-DiffReport -Diff $diff -Format $OutputFormat

        Write-Verbose "Diff report saved to: $reportPath"

        return $diff
    }
    catch {
        Write-Error "Failed to generate diff: $_"
        throw
    }
}

#region Comparison Logic

function Import-ComparisonFile {
    [CmdletBinding()]
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        throw "Comparison file not found: $Path"
    }

    $extension = [System.IO.Path]::GetExtension($Path).ToLower()

    # Use the same parser as the main engine
    if ($extension -eq '.toml') {
        return Import-TomlFile -Path $Path
    } elseif ($extension -match '\.(yaml|yml)$') {
        return Import-YamlFile -Path $Path
    } elseif ($extension -eq '.json') {
        $content = Get-Content -Path $Path -Raw | ConvertFrom-Json
        return Convert-JsonToHashtable -Json $content
    } else {
        throw "Unsupported file format: $extension"
    }
}

function Import-TomlFile {
    [CmdletBinding()]
    param([string]$Path)

    $content = Get-Content -Path $Path -Raw
    $manifest = @{
        symbols = @()
        roles = @()
        actions = @()
        metadata = @{}
    }

    $currentSection = 'metadata'
    $currentItem = @{}

    foreach ($line in ($content -split "`n")) {
        $line = $line.Trim()

        if ($line -match '^\s*#' -or $line -eq '') { continue }

        if ($line -match '^\[\[?([^\]]+)\]\]?') {
            $section = $Matches[1]

            if ($section -match '^(symbols|roles|actions)') {
                if ($currentItem.Count -gt 0 -and $currentSection -ne 'metadata') {
                    $manifest.$currentSection += $currentItem
                }
                $currentSection = $section -replace '\..*', ''
                $currentItem = @{}
            } else {
                $currentSection = 'metadata'
            }
            continue
        }

        if ($line -match '^([^=]+)=(.+)$') {
            $key = $Matches[1].Trim()
            $value = $Matches[2].Trim() -replace '^["'']|["'']$', ''

            if ($currentSection -eq 'metadata') {
                $manifest.metadata[$key] = $value
            } else {
                $currentItem[$key] = $value
            }
        }
    }

    if ($currentItem.Count -gt 0) {
        $manifest.$currentSection += $currentItem
    }

    return $manifest
}

function Import-YamlFile {
    [CmdletBinding()]
    param([string]$Path)

    # Simplified YAML import
    return Import-TomlFile -Path $Path
}

function Convert-JsonToHashtable {
    [CmdletBinding()]
    param($Json)

    $hashtable = @{}

    foreach ($property in $Json.PSObject.Properties) {
        $value = $property.Value

        if ($value -is [PSCustomObject]) {
            $hashtable[$property.Name] = Convert-JsonToHashtable -Json $value
        } elseif ($value -is [System.Array]) {
            $hashtable[$property.Name] = @($value | ForEach-Object {
                if ($_ -is [PSCustomObject]) {
                    Convert-JsonToHashtable -Json $_
                } else {
                    $_
                }
            })
        } else {
            $hashtable[$property.Name] = $value
        }
    }

    return $hashtable
}

function Compare-SymbolicElements {
    [CmdletBinding()]
    param(
        [array]$Current,
        [array]$Baseline,
        [string]$ElementType
    )

    $changes = @()

    # Ensure arrays
    $Current = @($Current)
    $Baseline = @($Baseline)

    # Build name indexes
    $currentNames = @{}
    foreach ($item in $Current) {
        if ($item.name) {
            $currentNames[$item.name] = $item
        }
    }

    $baselineNames = @{}
    foreach ($item in $Baseline) {
        if ($item.name) {
            $baselineNames[$item.name] = $item
        }
    }

    # Find added elements
    foreach ($name in $currentNames.Keys) {
        if (-not $baselineNames.ContainsKey($name)) {
            $changes += @{
                ChangeType = 'Added'
                ElementType = $ElementType
                Name = $name
                Current = $currentNames[$name]
                Baseline = $null
                Details = @()
            }
        }
    }

    # Find removed elements
    foreach ($name in $baselineNames.Keys) {
        if (-not $currentNames.ContainsKey($name)) {
            $changes += @{
                ChangeType = 'Removed'
                ElementType = $ElementType
                Name = $name
                Current = $null
                Baseline = $baselineNames[$name]
                Details = @()
            }
        }
    }

    # Find modified elements
    foreach ($name in $currentNames.Keys) {
        if ($baselineNames.ContainsKey($name)) {
            $currentItem = $currentNames[$name]
            $baselineItem = $baselineNames[$name]

            $differences = @()

            # Compare all fields
            $allKeys = @($currentItem.Keys) + @($baselineItem.Keys) | Select-Object -Unique

            foreach ($key in $allKeys) {
                if ($key -eq 'baseline_timestamp' -or $key -eq 'hash') {
                    continue  # Skip metadata fields
                }

                $currentValue = $currentItem[$key]
                $baselineValue = $baselineItem[$key]

                if ($currentValue -ne $baselineValue) {
                    $differences += @{
                        Field = $key
                        CurrentValue = $currentValue
                        BaselineValue = $baselineValue
                    }
                }
            }

            if ($differences.Count -gt 0) {
                $changes += @{
                    ChangeType = 'Modified'
                    ElementType = $ElementType
                    Name = $name
                    Current = $currentItem
                    Baseline = $baselineItem
                    Details = $differences
                }
            } else {
                $changes += @{
                    ChangeType = 'Unchanged'
                    ElementType = $ElementType
                    Name = $name
                    Current = $currentItem
                    Baseline = $baselineItem
                    Details = @()
                }
            }
        }
    }

    return $changes
}

function Compare-Metadata {
    [CmdletBinding()]
    param(
        [hashtable]$Current,
        [hashtable]$Baseline
    )

    $changes = @()

    if (-not $Current) { $Current = @{} }
    if (-not $Baseline) { $Baseline = @{} }

    $allKeys = @($Current.Keys) + @($Baseline.Keys) | Select-Object -Unique

    foreach ($key in $allKeys) {
        if ($key -eq 'timestamp' -or $key -eq 'version') {
            continue  # Skip timestamp fields
        }

        $currentValue = $Current[$key]
        $baselineValue = $Baseline[$key]

        if ($currentValue -ne $baselineValue) {
            $changeType = if (-not $baselineValue) {
                'Added'
            } elseif (-not $currentValue) {
                'Removed'
            } else {
                'Modified'
            }

            $changes += @{
                ChangeType = $changeType
                ElementType = 'Metadata'
                Name = $key
                Current = $currentValue
                Baseline = $baselineValue
                Details = @()
            }
        }
    }

    return $changes
}

#endregion

#region Statistics and Analysis

function Calculate-DiffStatistics {
    [CmdletBinding()]
    param([hashtable]$Changes)

    $stats = @{
        TotalChanges = 0
        Added = 0
        Modified = 0
        Removed = 0
        Unchanged = 0
    }

    $allChanges = @()
    $allChanges += $Changes.Symbols
    $allChanges += $Changes.Roles
    $allChanges += $Changes.Actions
    $allChanges += $Changes.Metadata

    foreach ($change in $allChanges) {
        switch ($change.ChangeType) {
            'Added' {
                $stats.Added++
                $stats.TotalChanges++
            }
            'Modified' {
                $stats.Modified++
                $stats.TotalChanges++
            }
            'Removed' {
                $stats.Removed++
                $stats.TotalChanges++
            }
            'Unchanged' {
                $stats.Unchanged++
            }
        }
    }

    return $stats
}

function Analyze-SemanticImpact {
    [CmdletBinding()]
    param([hashtable]$Changes)

    $impact = @{
        Level = 'Low'
        AffectedAreas = @()
        BreakingChanges = $false
        Details = @()
    }

    # Check for removed symbols or actions (breaking changes)
    $removedSymbols = $Changes.Symbols | Where-Object { $_.ChangeType -eq 'Removed' }
    $removedActions = $Changes.Actions | Where-Object { $_.ChangeType -eq 'Removed' }

    if ($removedSymbols.Count -gt 0 -or $removedActions.Count -gt 0) {
        $impact.BreakingChanges = $true
        $impact.Level = 'Critical'
        $impact.AffectedAreas += 'Removed elements may break existing workflows'
    }

    # Check for modified roles (medium impact)
    $modifiedRoles = $Changes.Roles | Where-Object { $_.ChangeType -eq 'Modified' }
    if ($modifiedRoles.Count -gt 0) {
        $impact.AffectedAreas += 'Role modifications may affect permissions'
        if ($impact.Level -eq 'Low') {
            $impact.Level = 'Medium'
        }
    }

    # Check for symbol type changes (breaking)
    $symbolTypeChanges = $Changes.Symbols | Where-Object {
        $_.ChangeType -eq 'Modified' -and
        ($_.Details | Where-Object { $_.Field -eq 'type' })
    }

    if ($symbolTypeChanges.Count -gt 0) {
        $impact.BreakingChanges = $true
        $impact.Level = 'Critical'
        $impact.AffectedAreas += 'Symbol type changes are breaking changes'
    }

    # Count total changes for impact assessment
    $totalChanges = ($Changes.Symbols + $Changes.Roles + $Changes.Actions |
        Where-Object { $_.ChangeType -ne 'Unchanged' }).Count

    if ($totalChanges -gt 20 -and $impact.Level -eq 'Low') {
        $impact.Level = 'Medium'
        $impact.AffectedAreas += 'Large number of changes detected'
    }

    return $impact
}

#endregion

#region Visualization

function Format-DiffVisualization {
    [CmdletBinding()]
    param(
        [hashtable]$Diff,
        [string]$ColorScheme,
        [bool]$ShowUnchanged
    )

    # Set color scheme
    $colors = Get-ColorScheme -Scheme $ColorScheme

    $output = New-Object System.Text.StringBuilder

    # Header
    [void]$output.AppendLine("Comparison: Current vs $($Diff.CompareType)")
    [void]$output.AppendLine("Generated: $($Diff.Timestamp)")
    [void]$output.AppendLine("")

    # Symbols
    if ($Diff.Changes.Symbols.Count -gt 0) {
        [void]$output.AppendLine("SYMBOLS:")
        [void]$output.AppendLine("--------")
        foreach ($change in $Diff.Changes.Symbols) {
            if (-not $ShowUnchanged -and $change.ChangeType -eq 'Unchanged') {
                continue
            }
            [void]$output.AppendLine((Format-ChangeEntry -Change $change))
        }
        [void]$output.AppendLine("")
    }

    # Roles
    if ($Diff.Changes.Roles.Count -gt 0) {
        [void]$output.AppendLine("ROLES:")
        [void]$output.AppendLine("------")
        foreach ($change in $Diff.Changes.Roles) {
            if (-not $ShowUnchanged -and $change.ChangeType -eq 'Unchanged') {
                continue
            }
            [void]$output.AppendLine((Format-ChangeEntry -Change $change))
        }
        [void]$output.AppendLine("")
    }

    # Actions
    if ($Diff.Changes.Actions.Count -gt 0) {
        [void]$output.AppendLine("ACTIONS:")
        [void]$output.AppendLine("--------")
        foreach ($change in $Diff.Changes.Actions) {
            if (-not $ShowUnchanged -and $change.ChangeType -eq 'Unchanged') {
                continue
            }
            [void]$output.AppendLine((Format-ChangeEntry -Change $change))
        }
        [void]$output.AppendLine("")
    }

    return $output.ToString()
}

function Format-ChangeEntry {
    [CmdletBinding()]
    param([hashtable]$Change)

    $symbol = switch ($Change.ChangeType) {
        'Added' { '[+]' }
        'Modified' { '[~]' }
        'Removed' { '[-]' }
        'Unchanged' { '[ ]' }
    }

    $entry = "  $symbol $($Change.Name)"

    if ($Change.ChangeType -eq 'Modified' -and $Change.Details.Count -gt 0) {
        $entry += "`n"
        foreach ($detail in $Change.Details) {
            $entry += "      $($detail.Field): '$($detail.BaselineValue)' -> '$($detail.CurrentValue)'`n"
        }
    }

    return $entry
}

function Get-ColorScheme {
    [CmdletBinding()]
    param([string]$Scheme)

    # Placeholder for color schemes
    return @{
        Added = 'Green'
        Modified = 'Yellow'
        Removed = 'Red'
        Unchanged = 'Gray'
    }
}

#endregion

#region Reporting

function Show-DiffStatistics {
    [CmdletBinding()]
    param([hashtable]$Diff)

    Write-Host "`n========================================" -ForegroundColor Magenta
    Write-Host "  DIFF STATISTICS" -ForegroundColor Magenta
    Write-Host "========================================`n" -ForegroundColor Magenta

    Write-Host "Total changes:  " -NoNewline
    Write-Host $Diff.Statistics.TotalChanges -ForegroundColor White

    Write-Host "Added:          " -NoNewline
    if ($Diff.Statistics.Added -gt 0) {
        Write-Host $Diff.Statistics.Added -ForegroundColor Green
    } else {
        Write-Host "0" -ForegroundColor Gray
    }

    Write-Host "Modified:       " -NoNewline
    if ($Diff.Statistics.Modified -gt 0) {
        Write-Host $Diff.Statistics.Modified -ForegroundColor Yellow
    } else {
        Write-Host "0" -ForegroundColor Gray
    }

    Write-Host "Removed:        " -NoNewline
    if ($Diff.Statistics.Removed -gt 0) {
        Write-Host $Diff.Statistics.Removed -ForegroundColor Red
    } else {
        Write-Host "0" -ForegroundColor Gray
    }

    Write-Host "Unchanged:      " -NoNewline
    Write-Host $Diff.Statistics.Unchanged -ForegroundColor Gray

    Write-Host "`nSemantic Impact:" -ForegroundColor Yellow
    Write-Host "Level:          " -NoNewline

    $impactColor = switch ($Diff.SemanticImpact.Level) {
        'Critical' { 'Red' }
        'High' { 'Red' }
        'Medium' { 'Yellow' }
        'Low' { 'Green' }
        default { 'White' }
    }
    Write-Host $Diff.SemanticImpact.Level -ForegroundColor $impactColor

    if ($Diff.SemanticImpact.BreakingChanges) {
        Write-Host "Breaking:       " -NoNewline
        Write-Host "YES" -ForegroundColor Red
    }

    if ($Diff.SemanticImpact.AffectedAreas.Count -gt 0) {
        Write-Host "`nAffected Areas:" -ForegroundColor Yellow
        foreach ($area in $Diff.SemanticImpact.AffectedAreas) {
            Write-Host "  - $area" -ForegroundColor Cyan
        }
    }

    Write-Host ""
}

function Save-DiffReport {
    [CmdletBinding()]
    param(
        [hashtable]$Diff,
        [string]$Format
    )

    try {
        $outputPath = if ($script:Paths.Output) { $script:Paths.Output } else { Join-Path $PSScriptRoot "../../output" }

        $extension = switch ($Format) {
            'JSON' { 'json' }
            'HTML' { 'html' }
            default { 'txt' }
        }

        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $reportPath = Join-Path $outputPath "diff-report-$timestamp.$extension"

        $reportContent = switch ($Format) {
            'JSON' {
                $Diff | ConvertTo-Json -Depth 10
            }
            default {
                $Diff | ConvertTo-Json -Depth 10
            }
        }

        $reportContent | Set-Content -Path $reportPath -Encoding UTF8

        return $reportPath
    }
    catch {
        Write-Warning "Failed to save diff report: $_"
        return $null
    }
}

#endregion

# Export function
Export-ModuleMember -Function Show-SymbolicDiff
