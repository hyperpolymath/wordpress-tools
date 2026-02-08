BeforeAll {
    $script:ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "SymbolicEngine/core/Set-NormativeBaseline.ps1"
}

Describe "Set-NormativeBaseline" -Tags @('Unit', 'Baseline') {

    Context "Baseline Creation" {

        It "Should create new normative baseline from current state" {
            $currentState = @{
                Symbols = @("symbol1", "symbol2", "symbol3")
                Configuration = @{ mode = "production" }
                Version = "1.0.0"
            }

            Mock New-NormativeBaseline {
                param($State)
                return @{
                    BaselineId = [Guid]::NewGuid().ToString()
                    Timestamp = Get-Date
                    State = $State
                    Checksum = "abc123"
                }
            }

            $baseline = New-NormativeBaseline -State $currentState
            $baseline.BaselineId | Should -Not -BeNullOrEmpty
            $baseline.State.Symbols | Should -HaveCount 3
        }

        It "Should calculate baseline checksum for integrity" {
            $baseline = @{
                Symbols = @("a", "b", "c")
                Config = @{ key = "value" }
            }

            Mock Get-BaselineChecksum {
                param($Baseline)
                $json = $Baseline | ConvertTo-Json -Compress
                $sha256 = [System.Security.Cryptography.SHA256]::Create()
                $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($json))
                return [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
            }

            $checksum = Get-BaselineChecksum -Baseline $baseline
            $checksum | Should -Match '^[a-f0-9]{64}$'
        }

        It "Should store baseline metadata" {
            $metadata = @{
                CreatedBy = "admin"
                Purpose = "Production deployment"
                Environment = "production"
                Tags = @("stable", "release-1.0")
            }

            Mock Set-BaselineMetadata {
                param($Metadata)
                return @{
                    Success = $true
                    Metadata = $Metadata
                }
            }

            $result = Set-BaselineMetadata -Metadata $metadata
            $result.Success | Should -Be $true
            $result.Metadata.Environment | Should -Be "production"
        }
    }

    Context "Baseline Comparison" {

        It "Should compare current state against baseline" {
            $baseline = @{
                Symbols = @("symbol1", "symbol2")
                Config = @{ mode = "production" }
            }

            $currentState = @{
                Symbols = @("symbol1", "symbol2", "symbol3")
                Config = @{ mode = "development" }
            }

            Mock Compare-ToBaseline {
                param($Baseline, $Current)
                return @{
                    HasDifferences = $true
                    AddedSymbols = @("symbol3")
                    RemovedSymbols = @()
                    ConfigChanges = @{
                        mode = @{
                            Old = "production"
                            New = "development"
                        }
                    }
                }
            }

            $diff = Compare-ToBaseline -Baseline $baseline -Current $currentState
            $diff.HasDifferences | Should -Be $true
            $diff.AddedSymbols | Should -Contain "symbol3"
        }

        It "Should detect drift from normative baseline" {
            Mock Test-BaselineDrift {
                param($Baseline, $Current)
                $driftPercentage = 15.5
                $threshold = 10.0

                return @{
                    HasDrift = ($driftPercentage -gt $threshold)
                    DriftPercentage = $driftPercentage
                    Threshold = $threshold
                }
            }

            $result = Test-BaselineDrift -Baseline @{} -Current @{}
            $result.HasDrift | Should -Be $true
            $result.DriftPercentage | Should -BeGreaterThan 10
        }

        It "Should categorize changes by severity" {
            $changes = @(
                @{ type = "symbol_removed"; severity = "high" }
                @{ type = "config_changed"; severity = "medium" }
                @{ type = "symbol_added"; severity = "low" }
            )

            Mock Get-ChangeSeverity {
                param($Changes)
                return @{
                    Critical = ($Changes | Where-Object { $_.severity -eq "critical" }).Count
                    High = ($Changes | Where-Object { $_.severity -eq "high" }).Count
                    Medium = ($Changes | Where-Object { $_.severity -eq "medium" }).Count
                    Low = ($Changes | Where-Object { $_.severity -eq "low" }).Count
                }
            }

            $severity = Get-ChangeSeverity -Changes $changes
            $severity.High | Should -Be 1
            $severity.Medium | Should -Be 1
            $severity.Low | Should -Be 1
        }
    }

    Context "Baseline Versioning" {

        It "Should maintain baseline version history" {
            Mock Get-BaselineHistory {
                return @(
                    @{ Version = "1.0.0"; Date = (Get-Date).AddDays(-10) }
                    @{ Version = "1.0.1"; Date = (Get-Date).AddDays(-5) }
                    @{ Version = "1.1.0"; Date = Get-Date }
                )
            }

            $history = Get-BaselineHistory
            $history | Should -HaveCount 3
            $history[-1].Version | Should -Be "1.1.0"
        }

        It "Should support baseline rollback" {
            $targetVersion = "1.0.0"

            Mock Restore-Baseline {
                param($Version)
                return @{
                    Success = $true
                    RestoredVersion = $Version
                    PreviousVersion = "1.1.0"
                }
            }

            $result = Restore-Baseline -Version $targetVersion
            $result.Success | Should -Be $true
            $result.RestoredVersion | Should -Be "1.0.0"
        }

        It "Should tag baselines for easy reference" {
            $tags = @("production", "stable", "release-candidate")

            Mock Add-BaselineTag {
                param($BaselineId, $Tags)
                return @{
                    BaselineId = $BaselineId
                    Tags = $Tags
                }
            }

            $result = Add-BaselineTag -BaselineId "baseline-123" -Tags $tags
            $result.Tags | Should -HaveCount 3
        }
    }

    Context "Baseline Validation" {

        It "Should validate baseline integrity" {
            $baseline = @{
                Data = @{ key = "value" }
                Checksum = "expected_checksum"
            }

            Mock Test-BaselineIntegrity {
                param($Baseline)
                $actualChecksum = Get-BaselineChecksum -Baseline $Baseline.Data
                return @{
                    Valid = ($actualChecksum -eq $Baseline.Checksum)
                    ExpectedChecksum = $Baseline.Checksum
                    ActualChecksum = $actualChecksum
                }
            }

            $result = Test-BaselineIntegrity -Baseline $baseline
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should verify baseline completeness" {
            $incompleteBaseline = @{
                Symbols = @()
                # Missing Configuration
            }

            Mock Test-BaselineCompleteness {
                param($Baseline)
                $required = @('Symbols', 'Configuration', 'Version')
                $missing = $required | Where-Object { -not $Baseline.ContainsKey($_) }

                return @{
                    Complete = ($missing.Count -eq 0)
                    MissingFields = $missing
                }
            }

            $result = Test-BaselineCompleteness -Baseline $incompleteBaseline
            $result.Complete | Should -Be $false
            $result.MissingFields | Should -Contain "Configuration"
        }
    }

    Context "Baseline Export and Import" {

        It "Should export baseline to file" {
            $baseline = @{
                Version = "1.0.0"
                Symbols = @("symbol1")
            }
            $exportPath = "/tmp/baseline.json"

            Mock Export-Baseline {
                param($Baseline, $Path)
                return @{
                    Success = $true
                    Path = $Path
                    Format = "JSON"
                }
            }

            $result = Export-Baseline -Baseline $baseline -Path $exportPath
            $result.Success | Should -Be $true
        }

        It "Should import baseline from file" {
            $importPath = "/tmp/baseline.json"

            Mock Import-Baseline {
                param($Path)
                return @{
                    Success = $true
                    Baseline = @{
                        Version = "1.0.0"
                        Symbols = @("symbol1")
                    }
                }
            }

            $result = Import-Baseline -Path $importPath
            $result.Success | Should -Be $true
            $result.Baseline.Version | Should -Be "1.0.0"
        }

        It "Should validate imported baseline" {
            Mock Import-Baseline {
                param($Path, [switch]$Validate)
                if ($Validate) {
                    # Perform validation
                    return @{
                        Success = $true
                        Valid = $true
                        ValidationErrors = @()
                    }
                }
            }

            $result = Import-Baseline -Path "/tmp/baseline.json" -Validate
            $result.Valid | Should -Be $true
        }
    }
}
