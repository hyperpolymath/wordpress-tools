<#
.SYNOPSIS
    Validate symbolic role definitions and assignments

.DESCRIPTION
    Checks symbolic role definitions for correctness, validates role constraints
    and permissions, ensures role consistency across workflows, and reports
    validation errors. Supports hierarchical roles, permission inheritance,
    and context-specific role validation.

.PARAMETER Manifest
    The loaded manifest hashtable containing role definitions

.PARAMETER StrictMode
    Enable strict validation (fails on warnings)

.PARAMETER CheckReferences
    Verify all role references in symbols and actions exist

.PARAMETER OutputFormat
    Output format for validation report: Text, JSON, HTML

.EXAMPLE
    Test-SymbolicRoles -Manifest $manifest

.EXAMPLE
    Test-SymbolicRoles -Manifest $manifest -StrictMode -CheckReferences

.EXAMPLE
    Test-SymbolicRoles -Manifest $manifest -OutputFormat JSON

.NOTES
    Part of WP Praxis Symbolic Engine
    Ensures role-based access control integrity
#>

function Test-SymbolicRoles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory = $false)]
        [switch]$StrictMode,

        [Parameter(Mandatory = $false)]
        [switch]$CheckReferences,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Text', 'JSON', 'HTML')]
        [string]$OutputFormat = 'Text'
    )

    Write-Verbose "Validating symbolic roles..."

    # Initialize validation report
    $validation = @{
        Timestamp = Get-Date -Format 'o'
        IsValid = $true
        StrictMode = $StrictMode.IsPresent
        Summary = @{
            TotalRoles = 0
            ValidRoles = 0
            InvalidRoles = 0
            TotalPermissions = 0
            TotalConstraints = 0
            Warnings = 0
            Errors = 0
            Critical = 0
        }
        RoleValidations = @()
        Issues = @()
        Recommendations = @()
        RoleHierarchy = @()
        PermissionMatrix = @()
    }

    try {
        # Check if roles are defined
        if (-not $Manifest.roles) {
            Add-ValidationIssue -Validation $validation -Severity 'Warning' `
                -Category 'Structure' -Message 'No roles defined in manifest' `
                -Recommendation 'Define roles for access control and workflow management'

            Show-ValidationSummary -Validation $validation
            return $validation
        }

        $validation.Summary.TotalRoles = $Manifest.roles.Count

        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "  ROLE VALIDATION" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan

        # Validate each role
        foreach ($role in $Manifest.roles) {
            $roleValidation = Test-SingleRole -Role $role -AllRoles $Manifest.roles

            $validation.RoleValidations += $roleValidation

            if ($roleValidation.IsValid) {
                $validation.Summary.ValidRoles++
                Write-Host "  [OK] " -NoNewline -ForegroundColor Green
                Write-Host $role.name -ForegroundColor Cyan
            } else {
                $validation.Summary.InvalidRoles++
                $validation.IsValid = $false
                Write-Host "  [FAIL] " -NoNewline -ForegroundColor Red
                Write-Host $role.name -NoNewline -ForegroundColor Cyan
                Write-Host " - $($roleValidation.Issues.Count) issue(s)" -ForegroundColor Red
            }

            # Collect issues
            foreach ($issue in $roleValidation.Issues) {
                Add-ValidationIssue -Validation $validation -Severity $issue.Severity `
                    -Category $issue.Category -Message $issue.Message `
                    -Details "Role: $($role.name)" -Recommendation $issue.Recommendation

                # Count by severity
                switch ($issue.Severity) {
                    'Critical' { $validation.Summary.Critical++ }
                    'Error' { $validation.Summary.Errors++ }
                    'Warning' { $validation.Summary.Warnings++ }
                }
            }

            # Track permissions and constraints
            if ($roleValidation.Permissions) {
                $validation.Summary.TotalPermissions += $roleValidation.Permissions.Count
            }
            if ($roleValidation.Constraints) {
                $validation.Summary.TotalConstraints += $roleValidation.Constraints.Count
            }
        }

        # Check for role hierarchy issues
        Write-Verbose "Analyzing role hierarchy..."
        $hierarchyIssues = Test-RoleHierarchy -Roles $Manifest.roles
        $validation.RoleHierarchy = $hierarchyIssues

        foreach ($issue in $hierarchyIssues) {
            Add-ValidationIssue -Validation $validation -Severity $issue.Severity `
                -Category 'Hierarchy' -Message $issue.Message `
                -Details $issue.Details -Recommendation $issue.Recommendation
        }

        # Check role references in symbols and actions
        if ($CheckReferences) {
            Write-Verbose "Checking role references..."
            $referenceIssues = Test-RoleReferences -Manifest $Manifest
            foreach ($issue in $referenceIssues) {
                Add-ValidationIssue -Validation $validation -Severity $issue.Severity `
                    -Category 'Reference' -Message $issue.Message `
                    -Details $issue.Details -Recommendation $issue.Recommendation
            }
        }

        # Build permission matrix
        Write-Verbose "Building permission matrix..."
        $validation.PermissionMatrix = Build-PermissionMatrix -Roles $Manifest.roles

        # Generate recommendations
        $validation.Recommendations = Get-RoleRecommendations -Validation $validation

        # Apply strict mode
        if ($StrictMode -and $validation.Summary.Warnings -gt 0) {
            $validation.IsValid = $false
            Add-ValidationIssue -Validation $validation -Severity 'Error' `
                -Category 'StrictMode' -Message 'Strict mode enabled: warnings treated as errors' `
                -Details "$($validation.Summary.Warnings) warning(s) found"
        }

        # Format and save report
        $report = Format-ValidationReport -Validation $validation -Format $OutputFormat
        Save-ValidationReport -Report $report -Format $OutputFormat

        # Display summary
        Show-ValidationSummary -Validation $validation

        return $validation
    }
    catch {
        Write-Error "Role validation failed: $_"
        $validation.IsValid = $false
        throw
    }
}

#region Role Validation

function Test-SingleRole {
    [CmdletBinding()]
    param(
        [hashtable]$Role,
        [array]$AllRoles
    )

    $validation = @{
        RoleName = $Role.name
        IsValid = $true
        Issues = @()
        Permissions = @()
        Constraints = @()
    }

    # Required fields
    if (-not $Role.name -or [string]::IsNullOrWhiteSpace($Role.name)) {
        $validation.IsValid = $false
        $validation.Issues += @{
            Severity = 'Error'
            Category = 'Required'
            Message = 'Role missing name field'
            Recommendation = 'Add unique name to role definition'
        }
        return $validation
    }

    # Name format validation
    if ($Role.name -notmatch '^[a-zA-Z][a-zA-Z0-9_-]*$') {
        $validation.IsValid = $false
        $validation.Issues += @{
            Severity = 'Error'
            Category = 'Format'
            Message = "Invalid role name format: $($Role.name)"
            Recommendation = 'Use alphanumeric characters, hyphens, and underscores only'
        }
    }

    # Check for description (recommended)
    if (-not $Role.description) {
        $validation.Issues += @{
            Severity = 'Warning'
            Category = 'Documentation'
            Message = "Role '$($Role.name)' missing description"
            Recommendation = 'Add description for better documentation'
        }
    }

    # Validate permissions
    if ($Role.permissions) {
        $permissionValidation = Test-RolePermissions -Permissions $Role.permissions -RoleName $Role.name
        $validation.Permissions = $permissionValidation.Permissions

        foreach ($issue in $permissionValidation.Issues) {
            $validation.Issues += $issue
            if ($issue.Severity -eq 'Error' -or $issue.Severity -eq 'Critical') {
                $validation.IsValid = $false
            }
        }
    }

    # Validate constraints
    if ($Role.constraints) {
        $constraintValidation = Test-RoleConstraints -Constraints $Role.constraints -RoleName $Role.name
        $validation.Constraints = $constraintValidation.Constraints

        foreach ($issue in $constraintValidation.Issues) {
            $validation.Issues += $issue
            if ($issue.Severity -eq 'Error' -or $issue.Severity -eq 'Critical') {
                $validation.IsValid = $false
            }
        }
    }

    # Check parent role (if hierarchical)
    if ($Role.parent) {
        $parentExists = $AllRoles | Where-Object { $_.name -eq $Role.parent }
        if (-not $parentExists) {
            $validation.IsValid = $false
            $validation.Issues += @{
                Severity = 'Error'
                Category = 'Hierarchy'
                Message = "Parent role '$($Role.parent)' not found"
                Recommendation = 'Define parent role or remove parent reference'
            }
        }
    }

    # Check for capability definitions (WordPress-specific)
    if ($Role.capabilities) {
        $capabilityValidation = Test-RoleCapabilities -Capabilities $Role.capabilities -RoleName $Role.name
        foreach ($issue in $capabilityValidation.Issues) {
            $validation.Issues += $issue
        }
    }

    return $validation
}

function Test-RolePermissions {
    [CmdletBinding()]
    param(
        $Permissions,
        [string]$RoleName
    )

    $validation = @{
        Permissions = @()
        Issues = @()
    }

    # Permissions can be array or comma-separated string
    $permissionList = @()
    if ($Permissions -is [array]) {
        $permissionList = $Permissions
    } elseif ($Permissions -is [string]) {
        $permissionList = $Permissions -split ',' | ForEach-Object { $_.Trim() }
    }

    $validPermissions = @(
        'read', 'write', 'delete', 'execute', 'admin',
        'create_symbols', 'modify_symbols', 'delete_symbols',
        'trigger_actions', 'view_audit', 'manage_roles'
    )

    foreach ($permission in $permissionList) {
        $validation.Permissions += $permission

        if ($permission -notin $validPermissions) {
            $validation.Issues += @{
                Severity = 'Warning'
                Category = 'Permission'
                Message = "Unknown permission '$permission' in role '$RoleName'"
                Recommendation = "Use standard permissions: $($validPermissions -join ', ')"
            }
        }
    }

    # Check for dangerous permission combinations
    if ($permissionList -contains 'delete' -and $permissionList -contains 'admin') {
        $validation.Issues += @{
            Severity = 'Warning'
            Category = 'Security'
            Message = "Role '$RoleName' has both 'delete' and 'admin' permissions"
            Recommendation = 'Review if this role requires such broad permissions'
        }
    }

    return $validation
}

function Test-RoleConstraints {
    [CmdletBinding()]
    param(
        $Constraints,
        [string]$RoleName
    )

    $validation = @{
        Constraints = @()
        Issues = @()
    }

    # Constraints should be hashtable or object
    if ($Constraints -is [hashtable]) {
        foreach ($key in $Constraints.Keys) {
            $validation.Constraints += @{
                Type = $key
                Value = $Constraints[$key]
            }

            # Validate known constraint types
            switch ($key) {
                'max_actions' {
                    if ($Constraints[$key] -notmatch '^\d+$') {
                        $validation.Issues += @{
                            Severity = 'Error'
                            Category = 'Constraint'
                            Message = "Invalid max_actions value in role '$RoleName'"
                            Recommendation = 'Use numeric value for max_actions'
                        }
                    }
                }
                'allowed_contexts' {
                    # Validate context list
                    $contexts = $Constraints[$key] -split ',' | ForEach-Object { $_.Trim() }
                    $validContexts = @('wordpress', 'cli', 'web', 'api', 'test')
                    foreach ($ctx in $contexts) {
                        if ($ctx -notin $validContexts) {
                            $validation.Issues += @{
                                Severity = 'Warning'
                                Category = 'Constraint'
                                Message = "Unknown context '$ctx' in role '$RoleName'"
                                Recommendation = "Use standard contexts: $($validContexts -join ', ')"
                            }
                        }
                    }
                }
                'time_restriction' {
                    # Validate time format (basic check)
                    if ($Constraints[$key] -notmatch '^\d{1,2}:\d{2}-\d{1,2}:\d{2}$') {
                        $validation.Issues += @{
                            Severity = 'Warning'
                            Category = 'Constraint'
                            Message = "Time restriction format may be invalid in role '$RoleName'"
                            Recommendation = 'Use format HH:MM-HH:MM for time restrictions'
                        }
                    }
                }
            }
        }
    }

    return $validation
}

function Test-RoleCapabilities {
    [CmdletBinding()]
    param(
        $Capabilities,
        [string]$RoleName
    )

    $validation = @{
        Issues = @()
    }

    # WordPress capability validation
    $standardCapabilities = @(
        'read', 'edit_posts', 'delete_posts', 'publish_posts',
        'upload_files', 'manage_options', 'manage_categories'
    )

    if ($Capabilities -is [hashtable]) {
        foreach ($cap in $Capabilities.Keys) {
            if ($cap -notin $standardCapabilities -and $cap -notmatch '^[a-z_]+$') {
                $validation.Issues += @{
                    Severity = 'Info'
                    Category = 'Capability'
                    Message = "Custom capability '$cap' in role '$RoleName'"
                    Recommendation = 'Ensure custom capabilities are implemented in WordPress'
                }
            }
        }
    }

    return $validation
}

#endregion

#region Hierarchy and References

function Test-RoleHierarchy {
    [CmdletBinding()]
    param([array]$Roles)

    $issues = @()
    $hierarchy = @{}

    # Build hierarchy map
    foreach ($role in $Roles) {
        if ($role.parent) {
            if (-not $hierarchy.ContainsKey($role.parent)) {
                $hierarchy[$role.parent] = @()
            }
            $hierarchy[$role.parent] += $role.name
        }
    }

    # Check for circular dependencies
    foreach ($role in $Roles) {
        $visited = @{}
        $current = $role.name
        $path = @($current)

        while ($current) {
            if ($visited.ContainsKey($current)) {
                $issues += @{
                    Severity = 'Critical'
                    Category = 'Hierarchy'
                    Message = "Circular role dependency detected"
                    Details = "Path: $($path -join ' -> ') -> $current"
                    Recommendation = 'Remove circular parent references'
                }
                break
            }

            $visited[$current] = $true
            $parent = ($Roles | Where-Object { $_.name -eq $current }).parent

            if ($parent) {
                $current = $parent
                $path += $current
            } else {
                break
            }
        }
    }

    # Check for orphaned role hierarchies
    foreach ($role in $Roles) {
        if ($role.parent) {
            $maxDepth = 10
            $depth = 0
            $current = $role.parent

            while ($current -and $depth -lt $maxDepth) {
                $parentRole = $Roles | Where-Object { $_.name -eq $current }
                if ($parentRole) {
                    $current = $parentRole.parent
                    $depth++
                } else {
                    break
                }
            }

            if ($depth -ge $maxDepth) {
                $issues += @{
                    Severity = 'Warning'
                    Category = 'Hierarchy'
                    Message = "Role hierarchy depth exceeds recommended limit"
                    Details = "Role '$($role.name)' has depth > $maxDepth"
                    Recommendation = 'Simplify role hierarchy to improve performance'
                }
            }
        }
    }

    return $issues
}

function Test-RoleReferences {
    [CmdletBinding()]
    param([hashtable]$Manifest)

    $issues = @()
    $roleNames = $Manifest.roles | ForEach-Object { $_.name }

    # Check symbols for role references
    foreach ($symbol in $Manifest.symbols) {
        if ($symbol.role -and $symbol.role -notin $roleNames) {
            $issues += @{
                Severity = 'Error'
                Category = 'Reference'
                Message = "Symbol '$($symbol.name)' references undefined role '$($symbol.role)'"
                Details = "Available roles: $($roleNames -join ', ')"
                Recommendation = 'Define role or remove reference'
            }
        }
        if ($symbol.required_role -and $symbol.required_role -notin $roleNames) {
            $issues += @{
                Severity = 'Error'
                Category = 'Reference'
                Message = "Symbol '$($symbol.name)' requires undefined role '$($symbol.required_role)'"
                Details = "Available roles: $($roleNames -join ', ')"
                Recommendation = 'Define role or remove requirement'
            }
        }
    }

    # Check actions for role references
    foreach ($action in $Manifest.actions) {
        if ($action.role -and $action.role -notin $roleNames) {
            $issues += @{
                Severity = 'Error'
                Category = 'Reference'
                Message = "Action '$($action.name)' references undefined role '$($action.role)'"
                Details = "Available roles: $($roleNames -join ', ')"
                Recommendation = 'Define role or remove reference'
            }
        }
    }

    return $issues
}

#endregion

#region Permission Matrix

function Build-PermissionMatrix {
    [CmdletBinding()]
    param([array]$Roles)

    $matrix = @()

    foreach ($role in $Roles) {
        $permissions = @()

        if ($role.permissions) {
            if ($role.permissions -is [array]) {
                $permissions = $role.permissions
            } elseif ($role.permissions -is [string]) {
                $permissions = $role.permissions -split ',' | ForEach-Object { $_.Trim() }
            }
        }

        # Inherit parent permissions
        if ($role.parent) {
            $parentRole = $Roles | Where-Object { $_.name -eq $role.parent }
            if ($parentRole -and $parentRole.permissions) {
                $parentPerms = if ($parentRole.permissions -is [array]) {
                    $parentRole.permissions
                } else {
                    $parentRole.permissions -split ',' | ForEach-Object { $_.Trim() }
                }
                $permissions = @($permissions) + @($parentPerms) | Select-Object -Unique
            }
        }

        $matrix += @{
            Role = $role.name
            Permissions = $permissions
            Inherited = $role.parent -ne $null
            Parent = $role.parent
        }
    }

    return $matrix
}

#endregion

#region Reporting

function Add-ValidationIssue {
    [CmdletBinding()]
    param(
        [hashtable]$Validation,
        [string]$Severity,
        [string]$Category,
        [string]$Message,
        [string]$Details = '',
        [string]$Recommendation = ''
    )

    $Validation.Issues += @{
        Severity = $Severity
        Category = $Category
        Message = $Message
        Details = $Details
        Recommendation = $Recommendation
        Timestamp = Get-Date -Format 'o'
    }
}

function Get-RoleRecommendations {
    [CmdletBinding()]
    param([hashtable]$Validation)

    $recommendations = @()

    if ($Validation.Summary.InvalidRoles -gt 0) {
        $recommendations += 'Fix invalid role definitions before deployment'
    }

    if ($Validation.Summary.TotalRoles -eq 0) {
        $recommendations += 'Define roles for better access control and workflow management'
    }

    if ($Validation.Summary.Critical -gt 0) {
        $recommendations += "Address $($Validation.Summary.Critical) critical issue(s) immediately"
    }

    $undocumentedRoles = $Validation.RoleValidations | Where-Object {
        $_.Issues | Where-Object { $_.Category -eq 'Documentation' }
    }
    if ($undocumentedRoles.Count -gt 0) {
        $recommendations += "Add descriptions to $($undocumentedRoles.Count) undocumented role(s)"
    }

    return $recommendations
}

function Format-ValidationReport {
    [CmdletBinding()]
    param(
        [hashtable]$Validation,
        [string]$Format
    )

    switch ($Format) {
        'JSON' {
            return $Validation | ConvertTo-Json -Depth 10
        }
        'HTML' {
            return ConvertTo-HtmlValidationReport -Validation $Validation
        }
        default {
            return ConvertTo-TextValidationReport -Validation $Validation
        }
    }
}

function ConvertTo-TextValidationReport {
    [CmdletBinding()]
    param([hashtable]$Validation)

    $text = @"
========================================
ROLE VALIDATION REPORT
========================================
Timestamp: $($Validation.Timestamp)
Strict Mode: $($Validation.StrictMode)

SUMMARY:
--------
Total Roles:        $($Validation.Summary.TotalRoles)
Valid Roles:        $($Validation.Summary.ValidRoles)
Invalid Roles:      $($Validation.Summary.InvalidRoles)
Total Permissions:  $($Validation.Summary.TotalPermissions)
Total Constraints:  $($Validation.Summary.TotalConstraints)

Issues:
  Critical: $($Validation.Summary.Critical)
  Error:    $($Validation.Summary.Errors)
  Warning:  $($Validation.Summary.Warnings)

Overall Status: $(if ($Validation.IsValid) { 'VALID' } else { 'INVALID' })

"@

    if ($Validation.Issues.Count -gt 0) {
        $text += "`nISSUES:`n--------`n"
        foreach ($issue in $Validation.Issues) {
            $text += "[$($issue.Severity)] $($issue.Category): $($issue.Message)`n"
            if ($issue.Details) {
                $text += "  Details: $($issue.Details)`n"
            }
            if ($issue.Recommendation) {
                $text += "  Recommendation: $($issue.Recommendation)`n"
            }
            $text += "`n"
        }
    }

    if ($Validation.Recommendations.Count -gt 0) {
        $text += "`nRECOMMENDATIONS:`n---------------`n"
        foreach ($rec in $Validation.Recommendations) {
            $text += "  - $rec`n"
        }
    }

    return $text
}

function ConvertTo-HtmlValidationReport {
    [CmdletBinding()]
    param([hashtable]$Validation)

    # Similar to audit report HTML generation
    return ConvertTo-TextValidationReport -Validation $Validation
}

function Save-ValidationReport {
    [CmdletBinding()]
    param(
        [string]$Report,
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
        $reportPath = Join-Path $outputPath "role-validation-$timestamp.$extension"

        $Report | Set-Content -Path $reportPath -Encoding UTF8

        Write-Verbose "Validation report saved to: $reportPath"
    }
    catch {
        Write-Warning "Failed to save validation report: $_"
    }
}

function Show-ValidationSummary {
    [CmdletBinding()]
    param([hashtable]$Validation)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  VALIDATION SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Total roles:    " -NoNewline
    Write-Host $Validation.Summary.TotalRoles -ForegroundColor White

    Write-Host "Valid:          " -NoNewline
    Write-Host $Validation.Summary.ValidRoles -ForegroundColor Green

    Write-Host "Invalid:        " -NoNewline
    if ($Validation.Summary.InvalidRoles -gt 0) {
        Write-Host $Validation.Summary.InvalidRoles -ForegroundColor Red
    } else {
        Write-Host "0" -ForegroundColor Green
    }

    if ($Validation.Summary.TotalPermissions -gt 0) {
        Write-Host "Permissions:    " -NoNewline
        Write-Host $Validation.Summary.TotalPermissions -ForegroundColor Cyan
    }

    if ($Validation.Summary.TotalConstraints -gt 0) {
        Write-Host "Constraints:    " -NoNewline
        Write-Host $Validation.Summary.TotalConstraints -ForegroundColor Cyan
    }

    Write-Host "`nIssues:         " -NoNewline
    if ($Validation.Summary.Critical -gt 0) {
        Write-Host "$($Validation.Issues.Count) ($($Validation.Summary.Critical) critical)" -ForegroundColor Red
    } elseif ($Validation.Summary.Errors -gt 0) {
        Write-Host "$($Validation.Issues.Count) ($($Validation.Summary.Errors) errors)" -ForegroundColor Yellow
    } else {
        Write-Host $Validation.Issues.Count -ForegroundColor Green
    }

    Write-Host "`nOverall status: " -NoNewline
    if ($Validation.IsValid) {
        Write-Host "VALID" -ForegroundColor Green
    } else {
        Write-Host "INVALID" -ForegroundColor Red
    }

    Write-Host ""
}

#endregion

# Export function
Export-ModuleMember -Function Test-SymbolicRoles
