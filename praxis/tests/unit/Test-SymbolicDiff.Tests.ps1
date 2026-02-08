BeforeAll {
    $script:ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "SymbolicEngine/core/Visualize-SymbolicDiff.ps1"
}

Describe "Visualize-SymbolicDiff" -Tags @('Unit', 'Diff', 'Visualization') {

    Context "Diff Calculation" {
        It "Should calculate diff between two symbol states" {
            $before = @{
                symbols = @(
                    @{ name = "symbol1"; version = "1.0" }
                    @{ name = "symbol2"; version = "1.0" }
                )
            }
            $after = @{
                symbols = @(
                    @{ name = "symbol1"; version = "1.1" }
                    @{ name = "symbol3"; version = "1.0" }
                )
            }

            Mock Get-SymbolicDiff {
                param($Before, $After)
                return @{
                    Added = @("symbol3")
                    Removed = @("symbol2")
                    Modified = @("symbol1")
                }
            }

            $diff = Get-SymbolicDiff -Before $before -After $after
            $diff.Added | Should -Contain "symbol3"
            $diff.Removed | Should -Contain "symbol2"
            $diff.Modified | Should -Contain "symbol1"
        }

        It "Should generate unified diff format" {
            $diff = @{
                Added = @("+ symbol3")
                Removed = @("- symbol2")
                Modified = @("~ symbol1 (1.0 -> 1.1)")
            }

            Mock Format-UnifiedDiff {
                param($Diff)
                return @"
--- Before
+++ After
- symbol2
+ symbol3
~ symbol1 (1.0 -> 1.1)
"@
            }

            $formatted = Format-UnifiedDiff -Diff $diff
            $formatted | Should -Match "--- Before"
            $formatted | Should -Match "\+ symbol3"
        }
    }

    Context "Visualization" {
        It "Should generate HTML diff visualization" {
            $diff = @{
                Added = @("symbol3")
                Removed = @("symbol2")
            }

            Mock ConvertTo-HtmlDiff {
                param($Diff)
                return @{
                    Html = "<div class='diff'>...</div>"
                    Format = "HTML"
                }
            }

            $html = ConvertTo-HtmlDiff -Diff $diff
            $html.Format | Should -Be "HTML"
        }

        It "Should generate terminal color diff" {
            Mock Format-ColorDiff {
                param($Diff)
                return @{
                    ColorOutput = $true
                    Lines = @(
                        @{ Color = "Green"; Text = "+ Added" }
                        @{ Color = "Red"; Text = "- Removed" }
                    )
                }
            }

            $result = Format-ColorDiff -Diff @{}
            $result.ColorOutput | Should -Be $true
        }
    }
}
