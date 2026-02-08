#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Master test runner for WP Praxis test suite

.DESCRIPTION
    Orchestrates all test suites across PowerShell, Rust, Elixir, PHP, and TypeScript layers.
    Supports selective test execution, coverage reporting, and CI integration.

.PARAMETER Suite
    Specific test suite to run: all, powershell, rust, elixir, php, typescript, integration

.PARAMETER Coverage
    Generate coverage reports

.PARAMETER Verbose
    Enable verbose test output

.PARAMETER FailFast
    Stop on first test failure

.EXAMPLE
    ./run-tests.ps1 -Suite all -Coverage
    ./run-tests.ps1 -Suite powershell -Verbose
    ./run-tests.ps1 -Suite integration -FailFast
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('all', 'powershell', 'rust', 'elixir', 'php', 'typescript', 'integration', 'e2e')]
    [string]$Suite = 'all',

    [Parameter()]
    [switch]$Coverage,

    [Parameter()]
    [switch]$FailFast,

    [Parameter()]
    [string]$OutputFormat = 'NUnitXml'
)

$ErrorActionPreference = 'Stop'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Color output helpers
function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-TestSuccess {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-TestFailure {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-TestWarning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

# Test result tracking
$script:TestResults = @{
    PowerShell = $null
    Rust = $null
    Elixir = $null
    PHP = $null
    TypeScript = $null
    Integration = $null
    E2E = $null
}

$script:StartTime = Get-Date

# Check if Pester is installed
function Install-PesterIfNeeded {
    Write-Host "Checking for Pester module..." -ForegroundColor Gray

    $pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [Version]'5.0.0' }

    if (-not $pester) {
        Write-TestWarning "Pester 5.0+ not found. Installing..."
        Install-Module -Name Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
        Write-TestSuccess "Pester installed successfully"
    } else {
        Write-Host "Pester $($pester.Version) found" -ForegroundColor Gray
    }
}

# Run PowerShell tests with Pester
function Invoke-PowerShellTests {
    Write-TestHeader "Running PowerShell Tests (Pester)"

    Install-PesterIfNeeded

    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = Join-Path $PSScriptRoot "unit", "integration"
    $pesterConfig.Run.Exit = $false
    $pesterConfig.Output.Verbosity = if ($VerbosePreference -eq 'Continue') { 'Detailed' } else { 'Normal' }

    if ($Coverage) {
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = Join-Path $ProjectRoot "SymbolicEngine/core/*.ps1"
        $pesterConfig.CodeCoverage.OutputPath = Join-Path $PSScriptRoot "coverage/powershell-coverage.xml"
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
    }

    if ($FailFast) {
        $pesterConfig.Run.SkipRemainingOnFailure = 'Run'
    }

    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path $PSScriptRoot "results/powershell-results.xml"
    $pesterConfig.TestResult.OutputFormat = $OutputFormat

    try {
        $result = Invoke-Pester -Configuration $pesterConfig
        $script:TestResults.PowerShell = $result

        if ($result.FailedCount -eq 0) {
            Write-TestSuccess "PowerShell tests passed ($($result.PassedCount) passed)"
            return $true
        } else {
            Write-TestFailure "PowerShell tests failed ($($result.FailedCount) failed, $($result.PassedCount) passed)"
            return $false
        }
    } catch {
        Write-TestFailure "PowerShell test execution error: $_"
        return $false
    }
}

# Run Rust tests
function Invoke-RustTests {
    Write-TestHeader "Running Rust Tests (Cargo)"

    $rustProjects = @(
        (Join-Path $ProjectRoot "wp_injector"),
        (Join-Path $ProjectRoot "Core/injectors")
    )

    $allPassed = $true

    foreach ($project in $rustProjects) {
        if (Test-Path $project) {
            Write-Host "Testing: $project" -ForegroundColor Gray

            Push-Location $project
            try {
                $output = if ($Coverage) {
                    cargo tarpaulin --out Xml --output-dir (Join-Path $PSScriptRoot "coverage")
                } else {
                    cargo test --all-features -- --nocapture
                }

                if ($LASTEXITCODE -eq 0) {
                    Write-TestSuccess "Rust tests passed in $project"
                } else {
                    Write-TestFailure "Rust tests failed in $project"
                    $allPassed = $false
                    if ($FailFast) { break }
                }
            } catch {
                Write-TestFailure "Rust test execution error: $_"
                $allPassed = $false
                if ($FailFast) { break }
            } finally {
                Pop-Location
            }
        } else {
            Write-TestWarning "Rust project not found: $project"
        }
    }

    $script:TestResults.Rust = $allPassed
    return $allPassed
}

# Run Elixir tests
function Invoke-ElixirTests {
    Write-TestHeader "Running Elixir Tests (ExUnit)"

    $elixirProjects = @(
        (Join-Path $ProjectRoot "Core/cli-wrapper"),
        (Join-Path $ProjectRoot "Core/db-schema")
    )

    $allPassed = $true

    foreach ($project in $elixirProjects) {
        if (Test-Path $project) {
            Write-Host "Testing: $project" -ForegroundColor Gray

            Push-Location $project
            try {
                # Get dependencies first
                mix deps.get | Out-Null

                # Run tests
                $output = if ($Coverage) {
                    mix test --cover
                } else {
                    mix test
                }

                if ($LASTEXITCODE -eq 0) {
                    Write-TestSuccess "Elixir tests passed in $project"
                } else {
                    Write-TestFailure "Elixir tests failed in $project"
                    $allPassed = $false
                    if ($FailFast) { break }
                }
            } catch {
                Write-TestFailure "Elixir test execution error: $_"
                $allPassed = $false
                if ($FailFast) { break }
            } finally {
                Pop-Location
            }
        } else {
            Write-TestWarning "Elixir project not found: $project"
        }
    }

    $script:TestResults.Elixir = $allPassed
    return $allPassed
}

# Run PHP tests
function Invoke-PHPTests {
    Write-TestHeader "Running PHP Tests (PHPUnit)"

    $phpunitConfig = Join-Path $ProjectRoot "phpunit.xml"

    if (Test-Path $phpunitConfig) {
        try {
            Push-Location $ProjectRoot

            $phpunitCmd = if ($Coverage) {
                "vendor/bin/phpunit --coverage-xml tests/coverage/php --coverage-html tests/coverage/php-html"
            } else {
                "vendor/bin/phpunit"
            }

            Invoke-Expression $phpunitCmd

            if ($LASTEXITCODE -eq 0) {
                Write-TestSuccess "PHP tests passed"
                $script:TestResults.PHP = $true
                return $true
            } else {
                Write-TestFailure "PHP tests failed"
                $script:TestResults.PHP = $false
                return $false
            }
        } catch {
            Write-TestFailure "PHP test execution error: $_"
            $script:TestResults.PHP = $false
            return $false
        } finally {
            Pop-Location
        }
    } else {
        Write-TestWarning "PHPUnit configuration not found: $phpunitConfig"
        return $null
    }
}

# Run TypeScript tests
function Invoke-TypeScriptTests {
    Write-TestHeader "Running TypeScript Tests (Bun)"

    $tsProjects = @(
        (Join-Path $ProjectRoot "SymbolicEngine/swarm"),
        (Join-Path $ProjectRoot "SymbolicEngine/dashboard")
    )

    $allPassed = $true

    foreach ($project in $tsProjects) {
        if (Test-Path $project) {
            Write-Host "Testing: $project" -ForegroundColor Gray

            Push-Location $project
            try {
                # Install dependencies
                bun install | Out-Null

                # Run tests
                $output = if ($Coverage) {
                    bun test --coverage
                } else {
                    bun test
                }

                if ($LASTEXITCODE -eq 0) {
                    Write-TestSuccess "TypeScript tests passed in $project"
                } else {
                    Write-TestFailure "TypeScript tests failed in $project"
                    $allPassed = $false
                    if ($FailFast) { break }
                }
            } catch {
                Write-TestFailure "TypeScript test execution error: $_"
                $allPassed = $false
                if ($FailFast) { break }
            } finally {
                Pop-Location
            }
        } else {
            Write-TestWarning "TypeScript project not found: $project"
        }
    }

    $script:TestResults.TypeScript = $allPassed
    return $allPassed
}

# Run integration tests
function Invoke-IntegrationTests {
    Write-TestHeader "Running Integration Tests"

    $integrationPath = Join-Path $PSScriptRoot "integration"

    if (Test-Path $integrationPath) {
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $integrationPath
        $pesterConfig.Run.Exit = $false
        $pesterConfig.Output.Verbosity = if ($VerbosePreference -eq 'Continue') { 'Detailed' } else { 'Normal' }

        if ($FailFast) {
            $pesterConfig.Run.SkipRemainingOnFailure = 'Run'
        }

        try {
            $result = Invoke-Pester -Configuration $pesterConfig

            if ($result.FailedCount -eq 0) {
                Write-TestSuccess "Integration tests passed ($($result.PassedCount) passed)"
                $script:TestResults.Integration = $true
                return $true
            } else {
                Write-TestFailure "Integration tests failed ($($result.FailedCount) failed)"
                $script:TestResults.Integration = $false
                return $false
            }
        } catch {
            Write-TestFailure "Integration test execution error: $_"
            $script:TestResults.Integration = $false
            return $false
        }
    } else {
        Write-TestWarning "Integration tests not found: $integrationPath"
        return $null
    }
}

# Run E2E tests
function Invoke-E2ETests {
    Write-TestHeader "Running End-to-End Tests"

    $e2ePath = Join-Path $PSScriptRoot "e2e"

    if (Test-Path $e2ePath) {
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = $e2ePath
        $pesterConfig.Run.Exit = $false
        $pesterConfig.Output.Verbosity = if ($VerbosePreference -eq 'Continue') { 'Detailed' } else { 'Detailed' }

        if ($FailFast) {
            $pesterConfig.Run.SkipRemainingOnFailure = 'Run'
        }

        try {
            $result = Invoke-Pester -Configuration $pesterConfig

            if ($result.FailedCount -eq 0) {
                Write-TestSuccess "E2E tests passed ($($result.PassedCount) passed)"
                $script:TestResults.E2E = $true
                return $true
            } else {
                Write-TestFailure "E2E tests failed ($($result.FailedCount) failed)"
                $script:TestResults.E2E = $false
                return $false
            }
        } catch {
            Write-TestFailure "E2E test execution error: $_"
            $script:TestResults.E2E = $false
            return $false
        }
    } else {
        Write-TestWarning "E2E tests not found: $e2ePath"
        return $null
    }
}

# Main test orchestration
function Invoke-TestSuite {
    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║   WP Praxis Test Suite Runner         ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Magenta

    # Create output directories
    $outputDirs = @('results', 'coverage')
    foreach ($dir in $outputDirs) {
        $path = Join-Path $PSScriptRoot $dir
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }

    $overallSuccess = $true

    # Run selected test suites
    switch ($Suite) {
        'all' {
            $overallSuccess = (Invoke-PowerShellTests) -and $overallSuccess
            $overallSuccess = (Invoke-RustTests) -and $overallSuccess
            $overallSuccess = (Invoke-ElixirTests) -and $overallSuccess
            $overallSuccess = (Invoke-PHPTests) -and $overallSuccess
            $overallSuccess = (Invoke-TypeScriptTests) -and $overallSuccess
            $overallSuccess = (Invoke-IntegrationTests) -and $overallSuccess
            $overallSuccess = (Invoke-E2ETests) -and $overallSuccess
        }
        'powershell' { $overallSuccess = Invoke-PowerShellTests }
        'rust' { $overallSuccess = Invoke-RustTests }
        'elixir' { $overallSuccess = Invoke-ElixirTests }
        'php' { $overallSuccess = Invoke-PHPTests }
        'typescript' { $overallSuccess = Invoke-TypeScriptTests }
        'integration' { $overallSuccess = Invoke-IntegrationTests }
        'e2e' { $overallSuccess = Invoke-E2ETests }
    }

    # Summary report
    $elapsed = (Get-Date) - $script:StartTime

    Write-Host "`n╔════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║         Test Summary                   ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════╝`n" -ForegroundColor Magenta

    foreach ($suite in $script:TestResults.Keys) {
        $result = $script:TestResults[$suite]
        if ($null -ne $result) {
            $status = if ($result -eq $true) { "PASS" } else { "FAIL" }
            $color = if ($result -eq $true) { "Green" } else { "Red" }
            Write-Host "$suite : " -NoNewline
            Write-Host $status -ForegroundColor $color
        }
    }

    Write-Host "`nTotal Time: $($elapsed.TotalSeconds.ToString('F2')) seconds" -ForegroundColor Gray

    if ($overallSuccess) {
        Write-Host "`n✓ All tests passed!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n✗ Some tests failed!" -ForegroundColor Red
        exit 1
    }
}

# Run the test suite
Invoke-TestSuite
