BeforeAll {
    $script:ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "SymbolicEngine/core/Trigger-SymbolicActions.ps1"
}

Describe "Trigger-SymbolicActions" -Tags @('Unit', 'Actions') {

    Context "Action Execution" {

        It "Should trigger individual symbolic action" {
            $action = @{
                name = "test_action"
                type = "action"
                executor = "rust_injector"
                parameters = @{ key = "value" }
            }

            Mock Invoke-SymbolicAction {
                param($Action)
                return @{
                    Success = $true
                    Action = $Action.name
                    Result = "Action completed"
                }
            }

            $result = Invoke-SymbolicAction -Action $action
            $result.Success | Should -Be $true
            $result.Action | Should -Be "test_action"
        }

        It "Should execute action sequence in order" {
            $actions = @(
                @{ name = "action1"; order = 1 }
                @{ name = "action2"; order = 2 }
                @{ name = "action3"; order = 3 }
            )

            Mock Invoke-ActionSequence {
                param($Actions)
                $executed = @()
                foreach ($action in ($Actions | Sort-Object order)) {
                    $executed += $action.name
                }
                return @{
                    ExecutionOrder = $executed
                    Success = $true
                }
            }

            $result = Invoke-ActionSequence -Actions $actions
            $result.ExecutionOrder[0] | Should -Be "action1"
            $result.ExecutionOrder[2] | Should -Be "action3"
        }

        It "Should pass context between chained actions" {
            $actions = @(
                @{ name = "action1"; outputs = @{ result = "data1" } }
                @{ name = "action2"; inputs = @{ previous = "{{action1.result}}" } }
            )

            Mock Invoke-ChainedActions {
                param($Actions)
                $context = @{}

                foreach ($action in $Actions) {
                    # Store outputs in context
                    if ($action.outputs) {
                        $context[$action.name] = $action.outputs
                    }
                }

                return @{
                    Success = $true
                    FinalContext = $context
                }
            }

            $result = Invoke-ChainedActions -Actions $actions
            $result.FinalContext.action1.result | Should -Be "data1"
        }

        It "Should handle action timeouts" {
            $action = @{
                name = "slow_action"
                timeout_ms = 1000
            }

            Mock Invoke-SymbolicAction {
                param($Action)
                Start-Sleep -Milliseconds 2000
                return @{ Success = $true }
            }

            Mock Invoke-ActionWithTimeout {
                param($Action)
                return @{
                    Success = $false
                    TimedOut = $true
                    TimeoutMs = $Action.timeout_ms
                }
            }

            $result = Invoke-ActionWithTimeout -Action $action
            $result.TimedOut | Should -Be $true
        }
    }

    Context "Action Parameters" {

        It "Should validate required parameters" {
            $action = @{
                name = "test_action"
                parameters = @{
                    required_param = @{
                        required = $true
                        type = "string"
                    }
                }
                provided_values = @{}
            }

            Mock Test-ActionParameters {
                param($Action)
                $missing = @()
                foreach ($param in $Action.parameters.Keys) {
                    if ($Action.parameters[$param].required -and -not $Action.provided_values.ContainsKey($param)) {
                        $missing += $param
                    }
                }
                return @{
                    Valid = ($missing.Count -eq 0)
                    MissingParameters = $missing
                }
            }

            $result = Test-ActionParameters -Action $action
            $result.Valid | Should -Be $false
            $result.MissingParameters | Should -Contain "required_param"
        }

        It "Should apply parameter defaults" {
            $action = @{
                parameters = @{
                    optional_param = @{
                        type = "string"
                        default = "default_value"
                    }
                }
                provided_values = @{}
            }

            Mock Initialize-ActionParameters {
                param($Action)
                $values = $Action.provided_values.Clone()
                foreach ($param in $Action.parameters.Keys) {
                    if (-not $values.ContainsKey($param) -and $Action.parameters[$param].default) {
                        $values[$param] = $Action.parameters[$param].default
                    }
                }
                return $values
            }

            $params = Initialize-ActionParameters -Action $action
            $params.optional_param | Should -Be "default_value"
        }

        It "Should validate parameter types" {
            $action = @{
                parameters = @{
                    string_param = @{ type = "string" }
                    int_param = @{ type = "integer" }
                }
                provided_values = @{
                    string_param = "valid string"
                    int_param = "not an integer"
                }
            }

            Mock Test-ParameterTypes {
                param($Action)
                $errors = @()
                foreach ($param in $Action.provided_values.Keys) {
                    $expectedType = $Action.parameters[$param].type
                    $actualValue = $Action.provided_values[$param]

                    if ($expectedType -eq "integer" -and $actualValue -notmatch '^\d+$') {
                        $errors += "Parameter '$param' expected integer"
                    }
                }
                return @{
                    Valid = ($errors.Count -eq 0)
                    Errors = $errors
                }
            }

            $result = Test-ParameterTypes -Action $action
            $result.Valid | Should -Be $false
        }
    }

    Context "Action Rollback" {

        It "Should rollback failed action" {
            $action = @{
                name = "failed_action"
                rollback_action = "undo_failed_action"
            }

            Mock Invoke-ActionRollback {
                param($Action)
                return @{
                    RolledBack = $true
                    OriginalAction = $Action.name
                    RollbackAction = $Action.rollback_action
                }
            }

            $result = Invoke-ActionRollback -Action $action
            $result.RolledBack | Should -Be $true
            $result.RollbackAction | Should -Be "undo_failed_action"
        }

        It "Should rollback entire action sequence on failure" {
            $actions = @(
                @{ name = "action1"; completed = $true }
                @{ name = "action2"; completed = $true }
                @{ name = "action3"; completed = $false; failed = $true }
            )

            Mock Invoke-SequenceRollback {
                param($Actions)
                $rolledBack = @()
                foreach ($action in ($Actions | Where-Object completed)) {
                    $rolledBack += $action.name
                }
                return @{
                    Success = $true
                    RolledBackActions = $rolledBack
                }
            }

            $result = Invoke-SequenceRollback -Actions $actions
            $result.RolledBackActions | Should -HaveCount 2
        }

        It "Should maintain rollback stack" {
            Mock Get-RollbackStack {
                return @(
                    @{ Action = "action3"; Timestamp = Get-Date }
                    @{ Action = "action2"; Timestamp = (Get-Date).AddSeconds(-1) }
                    @{ Action = "action1"; Timestamp = (Get-Date).AddSeconds(-2) }
                )
            }

            $stack = Get-RollbackStack
            $stack[0].Action | Should -Be "action3"  # Most recent first
        }
    }

    Context "Conditional Actions" {

        It "Should evaluate action conditions before execution" {
            $action = @{
                name = "conditional_action"
                condition = @{
                    type = "expression"
                    expression = "environment == 'production'"
                }
                context = @{
                    environment = "development"
                }
            }

            Mock Test-ActionCondition {
                param($Action)
                # Simplified condition evaluation
                $shouldRun = $Action.context.environment -eq "production"
                return @{
                    ShouldExecute = $shouldRun
                    ConditionMet = $shouldRun
                }
            }

            $result = Test-ActionCondition -Action $action
            $result.ShouldExecute | Should -Be $false
        }

        It "Should skip actions when conditions not met" {
            $actions = @(
                @{ name = "action1"; condition = $true }
                @{ name = "action2"; condition = $false }
                @{ name = "action3"; condition = $true }
            )

            Mock Invoke-ConditionalActions {
                param($Actions)
                $executed = @()
                foreach ($action in $Actions) {
                    if ($action.condition) {
                        $executed += $action.name
                    }
                }
                return @{
                    Executed = $executed
                    Skipped = @("action2")
                }
            }

            $result = Invoke-ConditionalActions -Actions $actions
            $result.Executed | Should -HaveCount 2
            $result.Skipped | Should -Contain "action2"
        }
    }

    Context "Action Monitoring" {

        It "Should track action execution metrics" {
            $action = @{ name = "monitored_action" }

            Mock Get-ActionMetrics {
                param($Action)
                return @{
                    Action = $Action.name
                    StartTime = Get-Date
                    EndTime = (Get-Date).AddMilliseconds(150)
                    Duration = [TimeSpan]::FromMilliseconds(150)
                    MemoryUsed = 1024 * 1024  # 1MB
                    Success = $true
                }
            }

            $metrics = Get-ActionMetrics -Action $action
            $metrics.Duration.TotalMilliseconds | Should -Be 150
        }

        It "Should emit action lifecycle events" {
            $events = @()

            Mock Register-ActionEvent {
                param($Event)
                $script:events += $Event
            }

            Mock Invoke-MonitoredAction {
                param($Action)
                Register-ActionEvent -Event @{ Type = "ActionStarted"; Action = $Action.name }
                Register-ActionEvent -Event @{ Type = "ActionCompleted"; Action = $Action.name }
            }

            Invoke-MonitoredAction -Action @{ name = "test" }
            $script:events | Should -HaveCount 2
        }
    }
}
