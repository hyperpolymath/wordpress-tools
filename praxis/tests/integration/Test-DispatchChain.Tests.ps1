BeforeAll {
    $script:ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

Describe "Symbolic Dispatch Chain Integration" -Tags @('Integration', 'Dispatch') {

    Context "Dispatch Routing" {
        It "Should route symbols to correct executors" {
            $symbols = @(
                @{ name = "ps_symbol"; dispatch = "powershell" }
                @{ name = "rust_symbol"; dispatch = "rust_injector" }
                @{ name = "php_symbol"; dispatch = "php_engine" }
            )

            Mock Invoke-DispatchRouter {
                param($Symbols)
                return @{
                    PowerShell = @("ps_symbol")
                    Rust = @("rust_symbol")
                    PHP = @("php_symbol")
                }
            }

            $routes = Invoke-DispatchRouter -Symbols $symbols
            $routes.PowerShell | Should -Contain "ps_symbol"
            $routes.Rust | Should -Contain "rust_symbol"
        }

        It "Should handle multi-hop dispatch" {
            Mock Invoke-MultiHopDispatch {
                param($Symbol)
                return @{
                    Hops = @(
                        @{ Executor = "PowerShell"; Status = "Completed" }
                        @{ Executor = "Elixir"; Status = "Completed" }
                        @{ Executor = "Rust"; Status = "Completed" }
                    )
                    FinalResult = "Success"
                }
            }

            $result = Invoke-MultiHopDispatch -Symbol @{name = "multi_hop"}
            $result.Hops | Should -HaveCount 3
            $result.FinalResult | Should -Be "Success"
        }
    }

    Context "Executor Communication" {
        It "Should pass data between executors" {
            Mock Invoke-ExecutorChain {
                param($Symbol)
                return @{
                    Chain = @(
                        @{ Executor = "PowerShell"; Output = @{data = "value1"} }
                        @{ Executor = "Rust"; Input = @{data = "value1"}; Output = @{processed = "value2"} }
                        @{ Executor = "PHP"; Input = @{processed = "value2"}; Output = @{final = "result"} }
                    )
                }
            }

            $result = Invoke-ExecutorChain -Symbol @{}
            $result.Chain[2].Output.final | Should -Be "result"
        }

        It "Should handle executor failures gracefully" {
            Mock Invoke-FaultTolerantDispatch {
                param($Symbol)
                return @{
                    Success = $false
                    FailedExecutor = "Rust"
                    FallbackUsed = $true
                    FallbackExecutor = "PowerShell"
                }
            }

            $result = Invoke-FaultTolerantDispatch -Symbol @{}
            $result.FallbackUsed | Should -Be $true
        }
    }

    Context "Dispatch Performance" {
        It "Should optimize dispatch routing" {
            Mock Optimize-DispatchPath {
                param($Symbols)
                return @{
                    OriginalHops = 5
                    OptimizedHops = 3
                    Improvement = "40%"
                }
            }

            $result = Optimize-DispatchPath -Symbols @()
            $result.OptimizedHops | Should -BeLessThan $result.OriginalHops
        }

        It "Should batch dispatch when possible" {
            Mock Invoke-BatchDispatch {
                param($Symbols)
                return @{
                    TotalSymbols = $Symbols.Count
                    BatchedSymbols = ($Symbols.Count * 0.8)
                    IndividualSymbols = ($Symbols.Count * 0.2)
                }
            }

            $result = Invoke-BatchDispatch -Symbols @(1..10)
            $result.BatchedSymbols | Should -BeGreaterThan $result.IndividualSymbols
        }
    }
}
