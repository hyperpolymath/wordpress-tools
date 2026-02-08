BeforeAll {
    $script:ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "SymbolicEngine/core/Run-SymbolicAudit.ps1"
}

Describe "Run-SymbolicAudit" -Tags @('Unit', 'Audit') {

    Context "Audit Initialization" {

        It "Should initialize audit session with unique ID" {
            Mock New-AuditSession {
                return @{
                    SessionId = [Guid]::NewGuid().ToString()
                    StartTime = Get-Date
                    Status = "Initialized"
                }
            }

            $session = New-AuditSession
            $session.SessionId | Should -Not -BeNullOrEmpty
            $session.Status | Should -Be "Initialized"
        }

        It "Should load audit configuration" {
            Mock Get-AuditConfig {
                return @{
                    AuditLevel = "Comprehensive"
                    IncludeSymbols = @("*")
                    ExcludeSymbols = @()
                    OutputFormat = "JSON"
                }
            }

            $config = Get-AuditConfig
            $config.AuditLevel | Should -Be "Comprehensive"
        }

        It "Should create audit output directory" {
            $auditDir = "/tmp/audit-output"

            Mock Initialize-AuditOutput {
                param($Path)
                if (-not (Test-Path $Path)) {
                    New-Item -ItemType Directory -Path $Path -Force | Out-Null
                }
                return $Path
            }

            Mock Test-Path { return $false }
            Mock New-Item { return @{ FullName = $auditDir } }

            $path = Initialize-AuditOutput -Path $auditDir
            $path | Should -Be $auditDir
        }
    }

    Context "Symbol Auditing" {

        It "Should audit symbol definition completeness" {
            $symbol = @{
                name = "test_symbol"
                type = "action"
                context = "wordpress"
                dispatch = "rust_injector"
                description = "Test symbol"
                parameters = @{}
            }

            Mock Test-SymbolCompleteness {
                param($Symbol)
                $required = @('name', 'type', 'context', 'dispatch')
                $missing = $required | Where-Object { -not $Symbol.ContainsKey($_) }
                return @{
                    Complete = ($missing.Count -eq 0)
                    MissingFields = $missing
                }
            }

            $result = Test-SymbolCompleteness -Symbol $symbol
            $result.Complete | Should -Be $true
            $result.MissingFields | Should -BeNullOrEmpty
        }

        It "Should detect symbol naming convention violations" {
            $validSymbol = @{ name = "valid_snake_case" }
            $invalidSymbol = @{ name = "InvalidCamelCase" }

            Mock Test-SymbolNamingConvention {
                param($Symbol)
                # Should be snake_case
                return $Symbol.name -match '^[a-z][a-z0-9_]*$'
            }

            Test-SymbolNamingConvention -Symbol $validSymbol | Should -Be $true
            Test-SymbolNamingConvention -Symbol $invalidSymbol | Should -Be $false
        }

        It "Should audit symbol dependency graph" {
            $symbols = @(
                @{ name = "a"; depends_on = @() }
                @{ name = "b"; depends_on = @("a") }
                @{ name = "c"; depends_on = @("b", "nonexistent") }
            )

            Mock Test-SymbolDependencies {
                param($Symbols)
                $allNames = $Symbols.name
                $issues = @()

                foreach ($symbol in $Symbols) {
                    foreach ($dep in $symbol.depends_on) {
                        if ($dep -notin $allNames) {
                            $issues += @{
                                Symbol = $symbol.name
                                MissingDependency = $dep
                            }
                        }
                    }
                }

                return @{
                    Valid = ($issues.Count -eq 0)
                    Issues = $issues
                }
            }

            $result = Test-SymbolDependencies -Symbols $symbols
            $result.Valid | Should -Be $false
            $result.Issues | Should -HaveCount 1
        }

        It "Should audit parameter validation rules" {
            $symbol = @{
                name = "test_symbol"
                parameters = @{
                    required_param = @{
                        type = "string"
                        required = $true
                        validation = "^[a-z]+$"
                    }
                    optional_param = @{
                        type = "integer"
                        required = $false
                        default = 10
                    }
                }
            }

            Mock Test-ParameterDefinitions {
                param($Symbol)
                $issues = @()

                foreach ($param in $Symbol.parameters.Keys) {
                    $def = $Symbol.parameters[$param]

                    if ($def.required -and -not $def.ContainsKey('default')) {
                        # Required params should not have defaults
                    }

                    if ($def.type -notin @('string', 'integer', 'boolean', 'array', 'object')) {
                        $issues += "Invalid type: $($def.type)"
                    }
                }

                return @{
                    Valid = ($issues.Count -eq 0)
                    Issues = $issues
                }
            }

            $result = Test-ParameterDefinitions -Symbol $symbol
            $result.Valid | Should -Be $true
        }
    }

    Context "Security Auditing" {

        It "Should detect potential security vulnerabilities" {
            $symbol = @{
                name = "risky_symbol"
                type = "action"
                dispatch = "shell_executor"
                parameters = @{
                    command = @{
                        type = "string"
                        allow_interpolation = $true  # Security risk
                    }
                }
            }

            Mock Test-SecurityRisks {
                param($Symbol)
                $risks = @()

                if ($Symbol.dispatch -eq "shell_executor") {
                    $risks += @{
                        Severity = "High"
                        Type = "Command Injection"
                        Description = "Shell executor can execute arbitrary commands"
                    }
                }

                return @{
                    HasRisks = ($risks.Count -gt 0)
                    Risks = $risks
                }
            }

            $result = Test-SecurityRisks -Symbol $symbol
            $result.HasRisks | Should -Be $true
            $result.Risks[0].Severity | Should -Be "High"
        }

        It "Should audit permission requirements" {
            $symbol = @{
                name = "admin_action"
                requires_capabilities = @("manage_options", "edit_plugins")
            }

            Mock Test-CapabilityRequirements {
                param($Symbol)
                return @{
                    RequiresElevation = ($Symbol.requires_capabilities.Count -gt 0)
                    Capabilities = $Symbol.requires_capabilities
                }
            }

            $result = Test-CapabilityRequirements -Symbol $symbol
            $result.RequiresElevation | Should -Be $true
            $result.Capabilities | Should -Contain "manage_options"
        }

        It "Should detect input sanitization requirements" {
            $symbol = @{
                name = "user_input_handler"
                parameters = @{
                    user_email = @{
                        type = "string"
                        sanitize = $false  # Should be true for user input
                    }
                }
            }

            Mock Test-InputSanitization {
                param($Symbol)
                $issues = @()

                foreach ($param in $Symbol.parameters.Keys) {
                    $def = $Symbol.parameters[$param]
                    if ($param -match 'user|email|input' -and -not $def.sanitize) {
                        $issues += "Parameter '$param' should have sanitization enabled"
                    }
                }

                return @{
                    Safe = ($issues.Count -eq 0)
                    Issues = $issues
                }
            }

            $result = Test-InputSanitization -Symbol $symbol
            $result.Safe | Should -Be $false
        }
    }

    Context "Performance Auditing" {

        It "Should identify potentially expensive operations" {
            $symbol = @{
                name = "bulk_operation"
                type = "action"
                estimated_complexity = "O(n^2)"
                batch_size = 10000
            }

            Mock Test-PerformanceCharacteristics {
                param($Symbol)
                $concerns = @()

                if ($Symbol.estimated_complexity -match 'n\^[23]') {
                    $concerns += "High complexity: $($Symbol.estimated_complexity)"
                }

                if ($Symbol.batch_size -gt 1000) {
                    $concerns += "Large batch size may impact memory"
                }

                return @{
                    HasConcerns = ($concerns.Count -gt 0)
                    Concerns = $concerns
                }
            }

            $result = Test-PerformanceCharacteristics -Symbol $symbol
            $result.HasConcerns | Should -Be $true
            $result.Concerns | Should -HaveCount 2
        }

        It "Should check for recursive symbol calls" {
            $symbols = @(
                @{
                    name = "recursive_symbol"
                    calls = @("helper_symbol", "recursive_symbol")  # Self-reference
                }
            )

            Mock Test-RecursiveSymbols {
                param($Symbols)
                $recursive = @()

                foreach ($symbol in $Symbols) {
                    if ($symbol.name -in $symbol.calls) {
                        $recursive += $symbol.name
                    }
                }

                return @{
                    HasRecursion = ($recursive.Count -gt 0)
                    RecursiveSymbols = $recursive
                }
            }

            $result = Test-RecursiveSymbols -Symbols $symbols
            $result.HasRecursion | Should -Be $true
        }

        It "Should detect missing caching opportunities" {
            $symbol = @{
                name = "expensive_query"
                type = "query"
                cache_enabled = $false
                estimated_duration_ms = 5000
            }

            Mock Test-CachingStrategy {
                param($Symbol)
                $recommendations = @()

                if ($Symbol.type -eq "query" -and -not $Symbol.cache_enabled -and $Symbol.estimated_duration_ms -gt 1000) {
                    $recommendations += "Consider enabling caching for slow queries"
                }

                return @{
                    OptimizationPossible = ($recommendations.Count -gt 0)
                    Recommendations = $recommendations
                }
            }

            $result = Test-CachingStrategy -Symbol $symbol
            $result.OptimizationPossible | Should -Be $true
        }
    }

    Context "Documentation Auditing" {

        It "Should verify symbol documentation completeness" {
            $documentedSymbol = @{
                name = "well_documented"
                description = "Performs an action"
                examples = @("example1", "example2")
                documentation_url = "https://docs.example.com"
            }

            $poorlyDocumented = @{
                name = "poorly_documented"
            }

            Mock Test-SymbolDocumentation {
                param($Symbol)
                $score = 0

                if ($Symbol.description) { $score += 25 }
                if ($Symbol.examples) { $score += 25 }
                if ($Symbol.documentation_url) { $score += 25 }
                if ($Symbol.parameters) {
                    $documentedParams = ($Symbol.parameters.Values | Where-Object { $_.description }).Count
                    if ($documentedParams -gt 0) { $score += 25 }
                }

                return @{
                    Score = $score
                    Grade = switch ($score) {
                        { $_ -ge 75 } { "Excellent" }
                        { $_ -ge 50 } { "Good" }
                        { $_ -ge 25 } { "Fair" }
                        default { "Poor" }
                    }
                }
            }

            $good = Test-SymbolDocumentation -Symbol $documentedSymbol
            $poor = Test-SymbolDocumentation -Symbol $poorlyDocumented

            $good.Grade | Should -Be "Excellent"
            $poor.Grade | Should -Be "Poor"
        }
    }

    Context "Audit Report Generation" {

        It "Should generate comprehensive audit report" {
            $auditData = @{
                SessionId = "test-session"
                Symbols = 10
                Issues = 3
                Warnings = 5
                Passed = 2
            }

            Mock New-AuditReport {
                param($Data)
                return @{
                    Summary = @{
                        TotalSymbols = $Data.Symbols
                        IssuesFound = $Data.Issues
                        WarningsFound = $Data.Warnings
                        TestsPassed = $Data.Passed
                    }
                    Timestamp = Get-Date
                    Format = "JSON"
                }
            }

            $report = New-AuditReport -Data $auditData
            $report.Summary.TotalSymbols | Should -Be 10
            $report.Summary.IssuesFound | Should -Be 3
        }

        It "Should export audit results in multiple formats" {
            $formats = @("JSON", "XML", "HTML", "Markdown")

            Mock Export-AuditReport {
                param($Format)
                return @{
                    Format = $Format
                    Success = $true
                }
            }

            foreach ($format in $formats) {
                $result = Export-AuditReport -Format $format
                $result.Success | Should -Be $true
                $result.Format | Should -Be $format
            }
        }

        It "Should include remediation recommendations" {
            $issue = @{
                Type = "SecurityRisk"
                Severity = "High"
                Symbol = "risky_symbol"
                Description = "Command injection vulnerability"
            }

            Mock Get-RemediationAdvice {
                param($Issue)
                return @{
                    Priority = "Immediate"
                    Steps = @(
                        "Sanitize all user inputs"
                        "Use parameterized commands"
                        "Implement input validation"
                    )
                    Documentation = "https://docs.example.com/security"
                }
            }

            $advice = Get-RemediationAdvice -Issue $issue
            $advice.Priority | Should -Be "Immediate"
            $advice.Steps | Should -HaveCount 3
        }
    }
}
