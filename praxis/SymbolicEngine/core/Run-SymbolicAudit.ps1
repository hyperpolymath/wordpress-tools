<#
.SYNOPSIS
    Run symbolic state audit and comparison

.DESCRIPTION
    Analyzes the current symbolic state, compares it against the normative baseline,
    and reports deviations, inconsistencies, and potential issues. This provides
    semantic traceability and helps maintain symbolic integrity.

.PARAMETER Manifest
    The loaded manifest hashtable containing symbolic definitions

.PARAMETER BaselinePath
    Path to the baseline TOML file (defaults to output/symbolic-baseline.toml)

.PARAMETER OutputFormat
    Output format for the audit report: Text, JSON, HTML

.PARAMETER IncludeDetails
    Include detailed analysis in the audit report

.PARAMETER Severity
    Minimum severity level to report: Info, Warning, Error, Critical

.EXAMPLE
    Invoke-SymbolicAudit -Manifest $manifest

.EXAMPLE
    Invoke-SymbolicAudit -Manifest $manifest -OutputFormat JSON -IncludeDetails

.NOTES
    Part of WP Praxis Symbolic Engine
    Provides introspection and semantic validation
#>

function Invoke-SymbolicAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory = $false)]
        [string]$BaselinePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Text', 'JSON', 'HTML')]
        [string]$OutputFormat = 'Text',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDetails,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Critical')]
        [string]$Severity = 'Info'
    )

    Write-Verbose "Starting symbolic audit..."

    # Initialize audit report
    $auditReport = @{
        Timestamp = Get-Date -Format 'o'
        Summary = @{
            TotalSymbols = 0
            ValidSymbols = 0
            InvalidSymbols = 0
            TotalRoles = 0
            ValidRoles = 0
            InvalidRoles = 0
            TotalActions = 0
            ValidActions = 0
            InvalidActions = 0
        }
        Findings = @()
        Deviations = @()
        Recommendations = @()
        BaselineComparison = $null
    }

    try {
        # Determine baseline path
        if (-not $BaselinePath) {
            $outputPath = if ($script:Paths.Output) { $script:Paths.Output } else { Join-Path $PSScriptRoot "../../output" }
            $BaselinePath = Join-Path $outputPath "symbolic-baseline.toml"
        }

        # Load baseline if it exists
        $baseline = $null
        if (Test-Path $BaselinePath) {
            Write-Verbose "Loading baseline from: $BaselinePath"
            $baseline = Import-BaselineFile -Path $BaselinePath
            $auditReport.BaselineComparison = @{
                BaselinePath = $BaselinePath
                BaselineTimestamp = $baseline.metadata.timestamp
                HasBaseline = $true
            }
        } else {
            Write-Warning "No baseline found at: $BaselinePath"
            Add-AuditFinding -Report $auditReport -Severity 'Warning' -Category 'Baseline' `
                -Message 'No baseline established' `
                -Recommendation 'Run Set-NormativeBaseline to create a baseline for comparison'
        }

        # Audit symbols
        Write-Verbose "Auditing symbols..."
        $auditReport.Summary.TotalSymbols = $Manifest.symbols.Count
        foreach ($symbol in $Manifest.symbols) {
            $symbolAudit = Test-SymbolIntegrity -Symbol $symbol -Baseline $baseline

            if ($symbolAudit.IsValid) {
                $auditReport.Summary.ValidSymbols++
            } else {
                $auditReport.Summary.InvalidSymbols++
                foreach ($issue in $symbolAudit.Issues) {
                    Add-AuditFinding -Report $auditReport -Severity $issue.Severity `
                        -Category 'Symbol' -Message $issue.Message `
                        -Details $issue.Details -Recommendation $issue.Recommendation
                }
            }

            # Check for deviations from baseline
            if ($baseline -and $symbolAudit.Deviations) {
                foreach ($deviation in $symbolAudit.Deviations) {
                    $auditReport.Deviations += $deviation
                }
            }
        }

        # Audit roles
        Write-Verbose "Auditing roles..."
        $auditReport.Summary.TotalRoles = $Manifest.roles.Count
        foreach ($role in $Manifest.roles) {
            $roleAudit = Test-RoleIntegrity -Role $role -Baseline $baseline

            if ($roleAudit.IsValid) {
                $auditReport.Summary.ValidRoles++
            } else {
                $auditReport.Summary.InvalidRoles++
                foreach ($issue in $roleAudit.Issues) {
                    Add-AuditFinding -Report $auditReport -Severity $issue.Severity `
                        -Category 'Role' -Message $issue.Message `
                        -Details $issue.Details -Recommendation $issue.Recommendation
                }
            }
        }

        # Audit actions
        Write-Verbose "Auditing actions..."
        $auditReport.Summary.TotalActions = $Manifest.actions.Count
        foreach ($action in $Manifest.actions) {
            $actionAudit = Test-ActionIntegrity -Action $action -Baseline $baseline

            if ($actionAudit.IsValid) {
                $auditReport.Summary.ValidActions++
            } else {
                $auditReport.Summary.InvalidActions++
                foreach ($issue in $actionAudit.Issues) {
                    Add-AuditFinding -Report $auditReport -Severity $issue.Severity `
                        -Category 'Action' -Message $issue.Message `
                        -Details $issue.Details -Recommendation $issue.Recommendation
                }
            }
        }

        # Perform semantic analysis
        Write-Verbose "Performing semantic analysis..."
        $semanticIssues = Test-SemanticCoherence -Manifest $Manifest
        foreach ($issue in $semanticIssues) {
            Add-AuditFinding -Report $auditReport -Severity $issue.Severity `
                -Category 'Semantic' -Message $issue.Message `
                -Details $issue.Details -Recommendation $issue.Recommendation
        }

        # Generate recommendations
        $auditReport.Recommendations = Get-AuditRecommendations -Report $auditReport

        # Format and output report
        $formattedReport = Format-AuditReport -Report $auditReport -Format $OutputFormat -IncludeDetails:$IncludeDetails

        # Save report to file
        $reportPath = Save-AuditReport -Report $formattedReport -Format $OutputFormat

        # Display summary
        Show-AuditSummary -Report $auditReport

        Write-Verbose "Audit completed. Report saved to: $reportPath"

        return $auditReport
    }
    catch {
        Write-Error "Audit failed: $_"
        throw
    }
}

#region Helper Functions

function Import-BaselineFile {
    [CmdletBinding()]
    param([string]$Path)

    $content = Get-Content -Path $Path -Raw

    # Simple TOML parsing for baseline
    $baseline = @{
        metadata = @{}
        symbols = @()
        roles = @()
        actions = @()
    }

    $currentSection = 'metadata'
    $currentItem = @{}

    foreach ($line in ($content -split "`n")) {
        $line = $line.Trim()

        if ($line -match '^\s*#' -or $line -eq '') { continue }

        if ($line -match '^\[([^\]]+)\]') {
            $section = $Matches[1]
            if ($section -match '^(symbols|roles|actions)') {
                if ($currentItem.Count -gt 0) {
                    $baseline.$currentSection += $currentItem
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
                $baseline.metadata[$key] = $value
            } else {
                $currentItem[$key] = $value
            }
        }
    }

    if ($currentItem.Count -gt 0) {
        $baseline.$currentSection += $currentItem
    }

    return $baseline
}

function Test-SymbolIntegrity {
    [CmdletBinding()]
    param(
        [hashtable]$Symbol,
        [hashtable]$Baseline
    )

    $result = @{
        IsValid = $true
        Issues = @()
        Deviations = @()
    }

    # Required fields validation
    $requiredFields = @('name', 'type')
    foreach ($field in $requiredFields) {
        if (-not $Symbol.ContainsKey($field) -or [string]::IsNullOrEmpty($Symbol[$field])) {
            $result.IsValid = $false
            $result.Issues += @{
                Severity = 'Error'
                Message = "Symbol missing required field: $field"
                Details = "Symbol: $($Symbol.name ?? 'unnamed')"
                Recommendation = "Add required field '$field' to symbol definition"
            }
        }
    }

    # Type validation
    $validTypes = @('action', 'filter', 'hook', 'query', 'transform')
    if ($Symbol.type -and $Symbol.type -notin $validTypes) {
        $result.IsValid = $false
        $result.Issues += @{
            Severity = 'Error'
            Message = "Invalid symbol type: $($Symbol.type)"
            Details = "Valid types: $($validTypes -join ', ')"
            Recommendation = "Use one of the valid symbol types"
        }
    }

    # Baseline comparison
    if ($Baseline) {
        $baselineSymbol = $Baseline.symbols | Where-Object { $_.name -eq $Symbol.name } | Select-Object -First 1
        if ($baselineSymbol) {
            foreach ($key in $baselineSymbol.Keys) {
                if ($Symbol[$key] -ne $baselineSymbol[$key]) {
                    $result.Deviations += @{
                        Type = 'Symbol'
                        Name = $Symbol.name
                        Field = $key
                        BaselineValue = $baselineSymbol[$key]
                        CurrentValue = $Symbol[$key]
                        Severity = 'Warning'
                    }
                }
            }
        }
    }

    return $result
}

function Test-RoleIntegrity {
    [CmdletBinding()]
    param(
        [hashtable]$Role,
        [hashtable]$Baseline
    )

    $result = @{
        IsValid = $true
        Issues = @()
        Deviations = @()
    }

    # Required fields
    if (-not $Role.name) {
        $result.IsValid = $false
        $result.Issues += @{
            Severity = 'Error'
            Message = 'Role missing name'
            Details = 'All roles must have a unique name'
            Recommendation = 'Add name field to role definition'
        }
    }

    # Baseline comparison
    if ($Baseline) {
        $baselineRole = $Baseline.roles | Where-Object { $_.name -eq $Role.name } | Select-Object -First 1
        if ($baselineRole) {
            foreach ($key in $baselineRole.Keys) {
                if ($Role[$key] -ne $baselineRole[$key]) {
                    $result.Deviations += @{
                        Type = 'Role'
                        Name = $Role.name
                        Field = $key
                        BaselineValue = $baselineRole[$key]
                        CurrentValue = $Role[$key]
                        Severity = 'Info'
                    }
                }
            }
        }
    }

    return $result
}

function Test-ActionIntegrity {
    [CmdletBinding()]
    param(
        [hashtable]$Action,
        [hashtable]$Baseline
    )

    $result = @{
        IsValid = $true
        Issues = @()
        Deviations = @()
    }

    # Required fields
    $requiredFields = @('name', 'executor')
    foreach ($field in $requiredFields) {
        if (-not $Action[$field]) {
            $result.IsValid = $false
            $result.Issues += @{
                Severity = 'Error'
                Message = "Action missing required field: $field"
                Details = "Action: $($Action.name ?? 'unnamed')"
                Recommendation = "Add required field '$field' to action definition"
            }
        }
    }

    # Executor validation
    $validExecutors = @('rust', 'php', 'elixir', 'powershell', 'external')
    if ($Action.executor -and $Action.executor -notin $validExecutors) {
        $result.Issues += @{
            Severity = 'Warning'
            Message = "Unknown executor type: $($Action.executor)"
            Details = "Common executors: $($validExecutors -join ', ')"
            Recommendation = 'Verify executor is available and properly configured'
        }
    }

    return $result
}

function Test-SemanticCoherence {
    [CmdletBinding()]
    param([hashtable]$Manifest)

    $issues = @()

    # Check for circular dependencies
    # Check for orphaned references
    # Check for naming conflicts
    # Check for semantic consistency

    $symbolNames = @($Manifest.symbols | ForEach-Object { $_.name })
    $roleNames = @($Manifest.roles | ForEach-Object { $_.name })
    $actionNames = @($Manifest.actions | ForEach-Object { $_.name })

    # Check for duplicate names
    $duplicateSymbols = $symbolNames | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($dup in $duplicateSymbols) {
        $issues += @{
            Severity = 'Error'
            Message = "Duplicate symbol name: $($dup.Name)"
            Details = "Found $($dup.Count) symbols with the same name"
            Recommendation = 'Use unique names for all symbols'
        }
    }

    $duplicateRoles = $roleNames | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($dup in $duplicateRoles) {
        $issues += @{
            Severity = 'Error'
            Message = "Duplicate role name: $($dup.Name)"
            Details = "Found $($dup.Count) roles with the same name"
            Recommendation = 'Use unique names for all roles'
        }
    }

    return $issues
}

function Add-AuditFinding {
    [CmdletBinding()]
    param(
        [hashtable]$Report,
        [string]$Severity,
        [string]$Category,
        [string]$Message,
        [string]$Details = '',
        [string]$Recommendation = ''
    )

    $Report.Findings += @{
        Severity = $Severity
        Category = $Category
        Message = $Message
        Details = $Details
        Recommendation = $Recommendation
        Timestamp = Get-Date -Format 'o'
    }
}

function Get-AuditRecommendations {
    [CmdletBinding()]
    param([hashtable]$Report)

    $recommendations = @()

    if ($Report.Summary.InvalidSymbols -gt 0) {
        $recommendations += 'Fix invalid symbol definitions to ensure proper execution'
    }

    if ($Report.Deviations.Count -gt 0) {
        $recommendations += "Review $($Report.Deviations.Count) deviations from baseline"
    }

    if (-not $Report.BaselineComparison.HasBaseline) {
        $recommendations += 'Establish a normative baseline using Set-NormativeBaseline'
    }

    $criticalFindings = $Report.Findings | Where-Object { $_.Severity -eq 'Critical' }
    if ($criticalFindings.Count -gt 0) {
        $recommendations += "Address $($criticalFindings.Count) critical findings immediately"
    }

    return $recommendations
}

function Format-AuditReport {
    [CmdletBinding()]
    param(
        [hashtable]$Report,
        [string]$Format,
        [bool]$IncludeDetails
    )

    switch ($Format) {
        'JSON' {
            return $Report | ConvertTo-Json -Depth 10
        }
        'HTML' {
            return ConvertTo-HtmlReport -Report $Report -IncludeDetails $IncludeDetails
        }
        default {
            return ConvertTo-TextReport -Report $Report -IncludeDetails $IncludeDetails
        }
    }
}

function ConvertTo-TextReport {
    [CmdletBinding()]
    param([hashtable]$Report, [bool]$IncludeDetails)

    $text = @"
========================================
SYMBOLIC AUDIT REPORT
========================================
Timestamp: $($Report.Timestamp)

SUMMARY:
--------
Symbols:  $($Report.Summary.ValidSymbols)/$($Report.Summary.TotalSymbols) valid
Roles:    $($Report.Summary.ValidRoles)/$($Report.Summary.TotalRoles) valid
Actions:  $($Report.Summary.ValidActions)/$($Report.Summary.TotalActions) valid

Findings: $($Report.Findings.Count)
  - Critical: $(($Report.Findings | Where-Object { $_.Severity -eq 'Critical' }).Count)
  - Error:    $(($Report.Findings | Where-Object { $_.Severity -eq 'Error' }).Count)
  - Warning:  $(($Report.Findings | Where-Object { $_.Severity -eq 'Warning' }).Count)
  - Info:     $(($Report.Findings | Where-Object { $_.Severity -eq 'Info' }).Count)

Deviations from baseline: $($Report.Deviations.Count)

"@

    if ($IncludeDetails -and $Report.Findings.Count -gt 0) {
        $text += "`nFINDINGS:`n---------`n"
        foreach ($finding in $Report.Findings) {
            $text += "[$($finding.Severity)] $($finding.Category): $($finding.Message)`n"
            if ($finding.Details) {
                $text += "  Details: $($finding.Details)`n"
            }
            if ($finding.Recommendation) {
                $text += "  Recommendation: $($finding.Recommendation)`n"
            }
            $text += "`n"
        }
    }

    if ($Report.Recommendations.Count -gt 0) {
        $text += "`nRECOMMENDATIONS:`n---------------`n"
        foreach ($rec in $Report.Recommendations) {
            $text += "  - $rec`n"
        }
    }

    $text += "`n========================================`n"

    return $text
}

function ConvertTo-HtmlReport {
    [CmdletBinding()]
    param([hashtable]$Report, [bool]$IncludeDetails)

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Symbolic Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #666; margin-top: 20px; }
        .summary { background: #e8f5e9; padding: 15px; border-radius: 4px; margin: 15px 0; }
        .finding { margin: 10px 0; padding: 10px; border-left: 4px solid #ddd; background: #fafafa; }
        .critical { border-left-color: #f44336; }
        .error { border-left-color: #ff9800; }
        .warning { border-left-color: #ffc107; }
        .info { border-left-color: #2196F3; }
        .timestamp { color: #999; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Symbolic Audit Report</h1>
        <p class="timestamp">Generated: $($Report.Timestamp)</p>

        <div class="summary">
            <h2>Summary</h2>
            <p><strong>Symbols:</strong> $($Report.Summary.ValidSymbols)/$($Report.Summary.TotalSymbols) valid</p>
            <p><strong>Roles:</strong> $($Report.Summary.ValidRoles)/$($Report.Summary.TotalRoles) valid</p>
            <p><strong>Actions:</strong> $($Report.Summary.ValidActions)/$($Report.Summary.TotalActions) valid</p>
            <p><strong>Total Findings:</strong> $($Report.Findings.Count)</p>
            <p><strong>Deviations:</strong> $($Report.Deviations.Count)</p>
        </div>
"@

    if ($IncludeDetails -and $Report.Findings.Count -gt 0) {
        $html += "<h2>Findings</h2>`n"
        foreach ($finding in $Report.Findings) {
            $severityClass = $finding.Severity.ToLower()
            $html += "<div class='finding $severityClass'>`n"
            $html += "  <strong>[$($finding.Severity)] $($finding.Category):</strong> $($finding.Message)<br>`n"
            if ($finding.Details) {
                $html += "  <em>$($finding.Details)</em><br>`n"
            }
            if ($finding.Recommendation) {
                $html += "  <strong>Recommendation:</strong> $($finding.Recommendation)`n"
            }
            $html += "</div>`n"
        }
    }

    $html += @"
    </div>
</body>
</html>
"@

    return $html
}

function Save-AuditReport {
    [CmdletBinding()]
    param(
        [string]$Report,
        [string]$Format
    )

    $outputPath = if ($script:Paths.Output) { $script:Paths.Output } else { Join-Path $PSScriptRoot "../../output" }

    $extension = switch ($Format) {
        'JSON' { 'json' }
        'HTML' { 'html' }
        default { 'txt' }
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportPath = Join-Path $outputPath "audit-report-$timestamp.$extension"

    $Report | Set-Content -Path $reportPath -Encoding UTF8

    return $reportPath
}

function Show-AuditSummary {
    [CmdletBinding()]
    param([hashtable]$Report)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  SYMBOLIC AUDIT SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Symbols:  " -NoNewline
    if ($Report.Summary.InvalidSymbols -eq 0) {
        Write-Host "$($Report.Summary.ValidSymbols)/$($Report.Summary.TotalSymbols) valid" -ForegroundColor Green
    } else {
        Write-Host "$($Report.Summary.ValidSymbols)/$($Report.Summary.TotalSymbols) valid" -ForegroundColor Yellow
    }

    Write-Host "Roles:    " -NoNewline
    if ($Report.Summary.InvalidRoles -eq 0) {
        Write-Host "$($Report.Summary.ValidRoles)/$($Report.Summary.TotalRoles) valid" -ForegroundColor Green
    } else {
        Write-Host "$($Report.Summary.ValidRoles)/$($Report.Summary.TotalRoles) valid" -ForegroundColor Yellow
    }

    Write-Host "Actions:  " -NoNewline
    if ($Report.Summary.InvalidActions -eq 0) {
        Write-Host "$($Report.Summary.ValidActions)/$($Report.Summary.TotalActions) valid" -ForegroundColor Green
    } else {
        Write-Host "$($Report.Summary.ValidActions)/$($Report.Summary.TotalActions) valid" -ForegroundColor Yellow
    }

    Write-Host "`nFindings: " -NoNewline
    $criticalCount = ($Report.Findings | Where-Object { $_.Severity -eq 'Critical' }).Count
    $errorCount = ($Report.Findings | Where-Object { $_.Severity -eq 'Error' }).Count

    if ($criticalCount -gt 0) {
        Write-Host "$($Report.Findings.Count) ($criticalCount critical, $errorCount errors)" -ForegroundColor Red
    } elseif ($errorCount -gt 0) {
        Write-Host "$($Report.Findings.Count) ($errorCount errors)" -ForegroundColor Yellow
    } else {
        Write-Host "$($Report.Findings.Count)" -ForegroundColor Green
    }

    if ($Report.Deviations.Count -gt 0) {
        Write-Host "Deviations: $($Report.Deviations.Count)" -ForegroundColor Yellow
    }

    Write-Host ""
}

#endregion

# Export function
Export-ModuleMember -Function Invoke-SymbolicAudit
