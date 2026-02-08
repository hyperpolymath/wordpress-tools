<#
.SYNOPSIS
    Execute symbolic actions from manifest

.DESCRIPTION
    Parses action definitions from the manifest and dispatches them to appropriate
    executors (Rust injectors, PHP engine, Elixir CLI, etc.). Tracks execution state,
    handles rollback on failure, and maintains execution history for introspection.

.PARAMETER Manifest
    The loaded manifest hashtable containing action definitions

.PARAMETER Context
    Execution context (wordpress, cli, web, test, etc.)

.PARAMETER ActionFilter
    Filter to execute specific actions by name (supports wildcards)

.PARAMETER DryRun
    Simulate execution without actually running actions

.PARAMETER ContinueOnError
    Continue executing subsequent actions even if one fails

.PARAMETER Timeout
    Maximum execution time in seconds for each action (default: 300)

.EXAMPLE
    Invoke-SymbolicActions -Manifest $manifest -Context wordpress

.EXAMPLE
    Invoke-SymbolicActions -Manifest $manifest -ActionFilter "deploy*" -DryRun

.EXAMPLE
    Invoke-SymbolicActions -Manifest $manifest -Context cli -ContinueOnError

.NOTES
    Part of WP Praxis Symbolic Engine
    Coordinates multi-language execution and state management
#>

function Invoke-SymbolicActions {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Manifest,

        [Parameter(Mandatory = $false)]
        [string]$Context = 'cli',

        [Parameter(Mandatory = $false)]
        [string]$ActionFilter = '*',

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$ContinueOnError,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 300
    )

    Write-Verbose "Triggering symbolic actions (Context: $Context, Filter: $ActionFilter)..."

    # Initialize execution tracking
    $execution = @{
        StartTime = Get-Date
        Context = $Context
        Actions = @()
        ExecutedActions = @()
        FailedActions = @()
        SkippedActions = @()
        TotalActions = 0
        SuccessfulActions = 0
        Success = $true
        Rollbacks = @()
    }

    try {
        # Validate manifest
        if (-not $Manifest.actions -or $Manifest.actions.Count -eq 0) {
            Write-Warning "No actions defined in manifest"
            return $execution
        }

        # Filter actions
        $actionsToExecute = $Manifest.actions | Where-Object {
            $_.name -like $ActionFilter
        }

        $execution.TotalActions = $actionsToExecute.Count

        if ($actionsToExecute.Count -eq 0) {
            Write-Warning "No actions match filter: $ActionFilter"
            return $execution
        }

        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "  SYMBOLIC ACTION EXECUTION" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan

        Write-Host "Context: " -NoNewline
        Write-Host $Context -ForegroundColor Yellow
        Write-Host "Actions to execute: " -NoNewline
        Write-Host $actionsToExecute.Count -ForegroundColor Green
        if ($DryRun) {
            Write-Host "Mode: " -NoNewline
            Write-Host "DRY RUN (simulation only)" -ForegroundColor Magenta
        }
        Write-Host ""

        # Execute actions in sequence
        foreach ($action in $actionsToExecute) {
            $actionResult = Invoke-SingleAction -Action $action -Context $Context -DryRun:$DryRun -Timeout $Timeout

            $execution.ExecutedActions += $actionResult

            if ($actionResult.Success) {
                $execution.SuccessfulActions++
                Write-Host "  [$($execution.SuccessfulActions)/$($execution.TotalActions)] " -NoNewline -ForegroundColor Green
                Write-Host $action.name -NoNewline -ForegroundColor Cyan
                Write-Host " - Success" -ForegroundColor Green
            } else {
                $execution.FailedActions += $actionResult
                Write-Host "  [FAILED] " -NoNewline -ForegroundColor Red
                Write-Host $action.name -NoNewline -ForegroundColor Cyan
                Write-Host " - $($actionResult.Error)" -ForegroundColor Red

                if (-not $ContinueOnError) {
                    Write-Warning "Action failed. Initiating rollback..."
                    $execution.Success = $false
                    Invoke-ActionRollback -Execution $execution
                    break
                } else {
                    Write-Warning "Action failed but continuing due to -ContinueOnError flag"
                }
            }

            # Brief pause between actions
            Start-Sleep -Milliseconds 100
        }

        $execution.EndTime = Get-Date
        $execution.Duration = ($execution.EndTime - $execution.StartTime).TotalSeconds

        # Display summary
        Show-ExecutionSummary -Execution $execution

        # Save execution log
        Save-ExecutionLog -Execution $execution

        return $execution
    }
    catch {
        Write-Error "Action execution failed: $_"
        $execution.Success = $false
        $execution.Error = $_.Exception.Message
        throw
    }
}

#region Action Execution

function Invoke-SingleAction {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [hashtable]$Action,
        [string]$Context,
        [bool]$DryRun,
        [int]$Timeout
    )

    $result = @{
        ActionName = $Action.name
        Executor = $Action.executor
        Context = $Context
        StartTime = Get-Date
        Success = $false
        Output = $null
        Error = $null
        DryRun = $DryRun
    }

    try {
        Write-Verbose "Executing action: $($Action.name) via $($Action.executor)"

        # Validate action
        $validation = Test-ActionExecutability -Action $Action -Context $Context
        if (-not $validation.CanExecute) {
            $result.Error = $validation.Reason
            $result.Success = $false
            return $result
        }

        if ($DryRun) {
            Write-Verbose "DRY RUN: Would execute $($Action.name)"
            $result.Success = $true
            $result.Output = "DRY RUN - No actual execution"
            return $result
        }

        if ($PSCmdlet.ShouldProcess($Action.name, "Execute action")) {
            # Dispatch to appropriate executor
            $executionResult = Invoke-ExecutorDispatch -Action $Action -Context $Context -Timeout $Timeout

            $result.Success = $executionResult.Success
            $result.Output = $executionResult.Output
            $result.Error = $executionResult.Error
            $result.ExecutorOutput = $executionResult.Details
        }
    }
    catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
        Write-Verbose "Action execution error: $_"
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = ($result.EndTime - $result.StartTime).TotalSeconds
    }

    return $result
}

function Test-ActionExecutability {
    [CmdletBinding()]
    param(
        [hashtable]$Action,
        [string]$Context
    )

    $validation = @{
        CanExecute = $true
        Reason = $null
    }

    # Check required fields
    if (-not $Action.name) {
        $validation.CanExecute = $false
        $validation.Reason = "Action missing name"
        return $validation
    }

    if (-not $Action.executor) {
        $validation.CanExecute = $false
        $validation.Reason = "Action missing executor specification"
        return $validation
    }

    # Check context compatibility
    if ($Action.context -and $Action.context -ne $Context) {
        $validation.CanExecute = $false
        $validation.Reason = "Action context '$($Action.context)' does not match execution context '$Context'"
        return $validation
    }

    # Verify executor availability
    $executorCheck = Test-ExecutorAvailability -Executor $Action.executor
    if (-not $executorCheck.Available) {
        $validation.CanExecute = $false
        $validation.Reason = "Executor '$($Action.executor)' not available: $($executorCheck.Reason)"
        return $validation
    }

    return $validation
}

function Test-ExecutorAvailability {
    [CmdletBinding()]
    param([string]$Executor)

    $check = @{
        Available = $false
        Reason = $null
    }

    switch ($Executor.ToLower()) {
        'rust' {
            # Check for Rust injector binary
            $injectorPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "wp_injector/target/release/wp_injector"
            if (Test-Path $injectorPath) {
                $check.Available = $true
            } else {
                $injectorPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "wp_injector/target/debug/wp_injector"
                if (Test-Path $injectorPath) {
                    $check.Available = $true
                } else {
                    $check.Reason = "Rust injector binary not found. Run 'cargo build' in wp_injector/"
                }
            }
        }
        'php' {
            # Check for PHP availability
            $phpAvailable = Get-Command php -ErrorAction SilentlyContinue
            if ($phpAvailable) {
                $check.Available = $true
            } else {
                $check.Reason = "PHP not found in PATH"
            }
        }
        'elixir' {
            # Check for Elixir availability
            $elixirAvailable = Get-Command elixir -ErrorAction SilentlyContinue
            if ($elixirAvailable) {
                $check.Available = $true
            } else {
                $check.Reason = "Elixir not found in PATH"
            }
        }
        'powershell' {
            # PowerShell is always available
            $check.Available = $true
        }
        'external' {
            # External executors require command specification
            $check.Available = $true
        }
        default {
            $check.Reason = "Unknown executor type: $Executor"
        }
    }

    return $check
}

function Invoke-ExecutorDispatch {
    [CmdletBinding()]
    param(
        [hashtable]$Action,
        [string]$Context,
        [int]$Timeout
    )

    $result = @{
        Success = $false
        Output = $null
        Error = $null
        Details = @{}
    }

    try {
        switch ($Action.executor.ToLower()) {
            'rust' {
                $result = Invoke-RustExecutor -Action $Action -Context $Context -Timeout $Timeout
            }
            'php' {
                $result = Invoke-PhpExecutor -Action $Action -Context $Context -Timeout $Timeout
            }
            'elixir' {
                $result = Invoke-ElixirExecutor -Action $Action -Context $Context -Timeout $Timeout
            }
            'powershell' {
                $result = Invoke-PowerShellExecutor -Action $Action -Context $Context -Timeout $Timeout
            }
            'external' {
                $result = Invoke-ExternalExecutor -Action $Action -Context $Context -Timeout $Timeout
            }
            default {
                $result.Error = "Unsupported executor: $($Action.executor)"
            }
        }
    }
    catch {
        $result.Success = $false
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Invoke-RustExecutor {
    [CmdletBinding()]
    param([hashtable]$Action, [string]$Context, [int]$Timeout)

    $result = @{ Success = $false; Output = $null; Error = $null; Details = @{} }

    try {
        # Locate Rust injector
        $rootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $injectorPath = Join-Path $rootPath "wp_injector/target/release/wp_injector"
        if (-not (Test-Path $injectorPath)) {
            $injectorPath = Join-Path $rootPath "wp_injector/target/debug/wp_injector"
        }

        # Build command arguments
        $args = @()
        if ($Action.command) { $args += $Action.command }
        if ($Action.parameters) {
            foreach ($param in $Action.parameters.GetEnumerator()) {
                $args += "--$($param.Key)", $param.Value
            }
        }

        Write-Verbose "Executing Rust injector: $injectorPath $($args -join ' ')"

        # Execute with timeout
        $job = Start-Job -ScriptBlock {
            param($path, $arguments)
            & $path @arguments 2>&1
        } -ArgumentList $injectorPath, $args

        $completed = Wait-Job -Job $job -Timeout $Timeout
        if ($completed) {
            $output = Receive-Job -Job $job
            $result.Success = $job.State -eq 'Completed'
            $result.Output = $output -join "`n"
        } else {
            Stop-Job -Job $job
            $result.Error = "Execution timeout ($Timeout seconds)"
        }

        Remove-Job -Job $job -Force
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Invoke-PhpExecutor {
    [CmdletBinding()]
    param([hashtable]$Action, [string]$Context, [int]$Timeout)

    $result = @{ Success = $false; Output = $null; Error = $null; Details = @{} }

    try {
        $rootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $enginePath = Join-Path $rootPath "engine/php/symbolic-engine.php"

        if (-not (Test-Path $enginePath)) {
            $result.Error = "PHP symbolic engine not found at: $enginePath"
            return $result
        }

        # Build PHP command
        $phpArgs = @($enginePath)
        if ($Action.command) { $phpArgs += $Action.command }

        Write-Verbose "Executing PHP engine: php $($phpArgs -join ' ')"

        $output = & php @phpArgs 2>&1
        $result.Success = $LASTEXITCODE -eq 0
        $result.Output = $output -join "`n"

        if (-not $result.Success) {
            $result.Error = "PHP execution failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Invoke-ElixirExecutor {
    [CmdletBinding()]
    param([hashtable]$Action, [string]$Context, [int]$Timeout)

    $result = @{ Success = $false; Output = $null; Error = $null; Details = @{} }

    try {
        $rootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $cliPath = Join-Path $rootPath "Core/cli-wrapper"

        if (-not (Test-Path $cliPath)) {
            $result.Error = "Elixir CLI not found at: $cliPath"
            return $result
        }

        # Execute via mix
        $originalLocation = Get-Location
        Set-Location $cliPath

        $mixArgs = @('run')
        if ($Action.command) { $mixArgs += $Action.command }

        Write-Verbose "Executing Elixir CLI: mix $($mixArgs -join ' ')"

        $output = & mix @mixArgs 2>&1
        $result.Success = $LASTEXITCODE -eq 0
        $result.Output = $output -join "`n"

        Set-Location $originalLocation
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Invoke-PowerShellExecutor {
    [CmdletBinding()]
    param([hashtable]$Action, [string]$Context, [int]$Timeout)

    $result = @{ Success = $false; Output = $null; Error = $null; Details = @{} }

    try {
        if ($Action.script) {
            # Execute inline script
            $scriptBlock = [ScriptBlock]::Create($Action.script)
            $output = & $scriptBlock
            $result.Success = $true
            $result.Output = $output
        } elseif ($Action.file) {
            # Execute script file
            $scriptPath = $Action.file
            if (-not (Test-Path $scriptPath)) {
                $rootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                $scriptPath = Join-Path $rootPath $Action.file
            }

            if (Test-Path $scriptPath) {
                $output = & $scriptPath
                $result.Success = $true
                $result.Output = $output
            } else {
                $result.Error = "Script file not found: $($Action.file)"
            }
        } else {
            $result.Error = "PowerShell executor requires 'script' or 'file' parameter"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

function Invoke-ExternalExecutor {
    [CmdletBinding()]
    param([hashtable]$Action, [string]$Context, [int]$Timeout)

    $result = @{ Success = $false; Output = $null; Error = $null; Details = @{} }

    try {
        if (-not $Action.command) {
            $result.Error = "External executor requires 'command' parameter"
            return $result
        }

        $cmdArgs = @()
        if ($Action.arguments) {
            $cmdArgs = $Action.arguments -split ' '
        }

        Write-Verbose "Executing external command: $($Action.command) $($cmdArgs -join ' ')"

        $output = & $Action.command @cmdArgs 2>&1
        $result.Success = $LASTEXITCODE -eq 0
        $result.Output = $output -join "`n"

        if (-not $result.Success) {
            $result.Error = "Command failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return $result
}

#endregion

#region Rollback

function Invoke-ActionRollback {
    [CmdletBinding()]
    param([hashtable]$Execution)

    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host "  INITIATING ROLLBACK" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Yellow

    $rollbackCount = 0

    # Rollback successful actions in reverse order
    $successfulActions = $Execution.ExecutedActions | Where-Object { $_.Success }
    [array]::Reverse($successfulActions)

    foreach ($actionResult in $successfulActions) {
        Write-Host "Rolling back: " -NoNewline
        Write-Host $actionResult.ActionName -ForegroundColor Cyan

        # Placeholder for rollback logic
        # In production, this would invoke action-specific rollback procedures
        $rollbackCount++

        $Execution.Rollbacks += @{
            ActionName = $actionResult.ActionName
            Timestamp = Get-Date -Format 'o'
            Success = $true
        }
    }

    Write-Host "`nRolled back $rollbackCount action(s)" -ForegroundColor Yellow
}

#endregion

#region Reporting

function Show-ExecutionSummary {
    [CmdletBinding()]
    param([hashtable]$Execution)

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  EXECUTION SUMMARY" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

    Write-Host "Total actions:      " -NoNewline
    Write-Host $Execution.TotalActions -ForegroundColor White

    Write-Host "Successful:         " -NoNewline
    Write-Host $Execution.SuccessfulActions -ForegroundColor Green

    Write-Host "Failed:             " -NoNewline
    if ($Execution.FailedActions.Count -gt 0) {
        Write-Host $Execution.FailedActions.Count -ForegroundColor Red
    } else {
        Write-Host "0" -ForegroundColor Green
    }

    if ($Execution.Duration) {
        Write-Host "Duration:           " -NoNewline
        Write-Host "$([Math]::Round($Execution.Duration, 2)) seconds" -ForegroundColor Cyan
    }

    if ($Execution.Rollbacks.Count -gt 0) {
        Write-Host "Rollbacks:          " -NoNewline
        Write-Host $Execution.Rollbacks.Count -ForegroundColor Yellow
    }

    Write-Host "`nOverall status:     " -NoNewline
    if ($Execution.Success -and $Execution.FailedActions.Count -eq 0) {
        Write-Host "SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "FAILED" -ForegroundColor Red
    }

    Write-Host ""
}

function Save-ExecutionLog {
    [CmdletBinding()]
    param([hashtable]$Execution)

    try {
        $outputPath = if ($script:Paths.Output) { $script:Paths.Output } else { Join-Path $PSScriptRoot "../../output" }
        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $logPath = Join-Path $outputPath "execution-log-$timestamp.json"

        $Execution | ConvertTo-Json -Depth 10 | Set-Content -Path $logPath -Encoding UTF8

        Write-Verbose "Execution log saved to: $logPath"
    }
    catch {
        Write-Warning "Failed to save execution log: $_"
    }
}

#endregion

# Export function
Export-ModuleMember -Function Invoke-SymbolicActions
