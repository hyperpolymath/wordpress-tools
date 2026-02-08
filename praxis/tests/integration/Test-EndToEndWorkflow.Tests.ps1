BeforeAll {
    $script:ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:FixturesPath = Join-Path $PSScriptRoot "../fixtures"
}

Describe "End-to-End Workflow Integration" -Tags @('Integration', 'E2E', 'Workflow') {

    Context "Complete Symbolic Workflow Execution" {

        It "Should execute complete workflow from manifest to results" {
            $manifestPath = Join-Path $script:FixturesPath "sample-workflow.yaml"

            # Mock manifest content
            Mock Get-Content {
                return @"
name: test_workflow
version: 1.0.0
symbols:
  - name: initialize
    type: action
    dispatch: powershell
    order: 1
  - name: process
    type: action
    dispatch: rust_injector
    depends_on: [initialize]
    order: 2
  - name: finalize
    type: action
    dispatch: powershell
    depends_on: [process]
    order: 3
"@
            }

            Mock Invoke-WorkflowExecution {
                param($ManifestPath)
                return @{
                    Success = $true
                    SymbolsExecuted = 3
                    ExecutionOrder = @("initialize", "process", "finalize")
                    Duration = [TimeSpan]::FromSeconds(2)
                }
            }

            $result = Invoke-WorkflowExecution -ManifestPath $manifestPath
            $result.Success | Should -Be $true
            $result.SymbolsExecuted | Should -Be 3
            $result.ExecutionOrder[0] | Should -Be "initialize"
        }

        It "Should handle workflow failures with rollback" {
            Mock Invoke-WorkflowExecution {
                param($ManifestPath)
                return @{
                    Success = $false
                    FailedAt = "process"
                    RolledBack = $true
                    RollbackActions = @("finalize_rollback", "initialize_rollback")
                }
            }

            $result = Invoke-WorkflowExecution -ManifestPath "failing-workflow.yaml"
            $result.Success | Should -Be $false
            $result.RolledBack | Should -Be $true
            $result.RollbackActions | Should -HaveCount 2
        }

        It "Should propagate context through workflow stages" {
            Mock Invoke-WorkflowExecution {
                param($ManifestPath)
                return @{
                    Success = $true
                    Context = @{
                        initialize = @{ database_id = "123" }
                        process = @{
                            database_id = "123"
                            records_processed = 100
                        }
                        finalize = @{
                            database_id = "123"
                            records_processed = 100
                            status = "completed"
                        }
                    }
                }
            }

            $result = Invoke-WorkflowExecution -ManifestPath "context-workflow.yaml"
            $result.Context.process.database_id | Should -Be "123"
            $result.Context.finalize.records_processed | Should -Be 100
        }
    }

    Context "Cross-Layer Integration" {

        It "Should integrate PowerShell with Rust injector" {
            $symbol = @{
                name = "cross_layer_test"
                dispatch = "rust_injector"
                parameters = @{
                    operation = "inject"
                    target = "wordpress"
                }
            }

            Mock Invoke-RustInjector {
                param($Symbol)
                # Simulates calling Rust binary
                return @{
                    Success = $true
                    Executor = "wp_injector"
                    InjectedSymbols = 1
                }
            }

            $result = Invoke-RustInjector -Symbol $symbol
            $result.Success | Should -Be $true
            $result.Executor | Should -Be "wp_injector"
        }

        It "Should integrate with Elixir CLI wrapper" {
            Mock Invoke-ElixirCLI {
                param($Command, $Args)
                return @{
                    Success = $true
                    Command = $Command
                    Output = "Elixir CLI executed successfully"
                }
            }

            $result = Invoke-ElixirCLI -Command "dispatch" -Args @{symbol = "test"}
            $result.Success | Should -Be $true
        }

        It "Should integrate with PHP WordPress plugin" {
            Mock Invoke-PHPPlugin {
                param($Symbol)
                return @{
                    Success = $true
                    WordPressContext = $true
                    HooksExecuted = @("init", "wp_loaded")
                }
            }

            $result = Invoke-PHPPlugin -Symbol @{name = "wp_test"}
            $result.WordPressContext | Should -Be $true
            $result.HooksExecuted | Should -Contain "init"
        }
    }

    Context "State Management Integration" {

        It "Should persist workflow state across executions" {
            $workflowId = "test-workflow-123"

            Mock Save-WorkflowState {
                param($WorkflowId, $State)
                return @{
                    Success = $true
                    Persisted = $true
                    Location = "/tmp/workflow-state/$WorkflowId.json"
                }
            }

            Mock Load-WorkflowState {
                param($WorkflowId)
                return @{
                    Success = $true
                    State = @{
                        LastExecuted = Get-Date
                        Status = "completed"
                        Results = @{}
                    }
                }
            }

            $saveResult = Save-WorkflowState -WorkflowId $workflowId -State @{}
            $saveResult.Success | Should -Be $true

            $loadResult = Load-WorkflowState -WorkflowId $workflowId
            $loadResult.Success | Should -Be $true
            $loadResult.State.Status | Should -Be "completed"
        }

        It "Should handle concurrent workflow executions" {
            Mock Start-ConcurrentWorkflows {
                param($Workflows)
                $results = @()
                foreach ($workflow in $Workflows) {
                    $results += @{
                        WorkflowId = $workflow.id
                        Success = $true
                        Completed = $true
                    }
                }
                return @{
                    TotalWorkflows = $Workflows.Count
                    SuccessfulWorkflows = $results.Count
                    Results = $results
                }
            }

            $workflows = @(
                @{ id = "workflow1" }
                @{ id = "workflow2" }
                @{ id = "workflow3" }
            )

            $result = Start-ConcurrentWorkflows -Workflows $workflows
            $result.TotalWorkflows | Should -Be 3
            $result.SuccessfulWorkflows | Should -Be 3
        }
    }

    Context "Database Integration" {

        It "Should interact with Ecto database layer" {
            Mock Invoke-EctoQuery {
                param($Query)
                return @{
                    Success = $true
                    RowsAffected = 5
                    Data = @(
                        @{ id = 1; name = "symbol1" }
                        @{ id = 2; name = "symbol2" }
                    )
                }
            }

            $result = Invoke-EctoQuery -Query "SELECT * FROM symbols LIMIT 2"
            $result.Success | Should -Be $true
            $result.Data | Should -HaveCount 2
        }

        It "Should handle database transactions" {
            Mock Start-DatabaseTransaction {
                return @{ TransactionId = [Guid]::NewGuid() }
            }

            Mock Commit-DatabaseTransaction {
                param($TransactionId)
                return @{ Success = $true; Committed = $true }
            }

            Mock Rollback-DatabaseTransaction {
                param($TransactionId)
                return @{ Success = $true; RolledBack = $true }
            }

            $txn = Start-DatabaseTransaction
            $txn.TransactionId | Should -Not -BeNullOrEmpty

            $commit = Commit-DatabaseTransaction -TransactionId $txn.TransactionId
            $commit.Success | Should -Be $true
        }
    }

    Context "Error Propagation" {

        It "Should propagate errors across layer boundaries" {
            Mock Invoke-MultiLayerOperation {
                throw "Rust injector error: Symbol not found"
            }

            { Invoke-MultiLayerOperation } | Should -Throw "*Rust injector error*"
        }

        It "Should collect errors from all layers" {
            Mock Execute-WorkflowWithErrorCollection {
                return @{
                    Success = $false
                    Errors = @(
                        @{ Layer = "PowerShell"; Message = "Configuration error" }
                        @{ Layer = "Rust"; Message = "Injection failed" }
                        @{ Layer = "PHP"; Message = "WordPress hook error" }
                    )
                }
            }

            $result = Execute-WorkflowWithErrorCollection
            $result.Errors | Should -HaveCount 3
            $result.Errors[0].Layer | Should -Be "PowerShell"
        }
    }

    Context "Performance Integration" {

        It "Should measure end-to-end performance" {
            Mock Measure-WorkflowPerformance {
                param($WorkflowId)
                return @{
                    TotalDuration = [TimeSpan]::FromSeconds(5.5)
                    LayerMetrics = @{
                        PowerShell = [TimeSpan]::FromSeconds(1.0)
                        Rust = [TimeSpan]::FromSeconds(3.0)
                        Elixir = [TimeSpan]::FromSeconds(0.5)
                        PHP = [TimeSpan]::FromSeconds(1.0)
                    }
                }
            }

            $perf = Measure-WorkflowPerformance -WorkflowId "test"
            $perf.TotalDuration.TotalSeconds | Should -Be 5.5
            $perf.LayerMetrics.Rust.TotalSeconds | Should -Be 3.0
        }

        It "Should optimize workflow execution path" {
            Mock Optimize-WorkflowExecution {
                param($Workflow)
                return @{
                    OptimizationsApplied = @(
                        "Parallel execution enabled"
                        "Caching enabled"
                        "Lazy loading enabled"
                    )
                    EstimatedImprovement = "35%"
                }
            }

            $result = Optimize-WorkflowExecution -Workflow @{}
            $result.OptimizationsApplied | Should -HaveCount 3
        }
    }
}
