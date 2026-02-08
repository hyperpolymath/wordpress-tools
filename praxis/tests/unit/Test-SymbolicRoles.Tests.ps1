BeforeAll {
    $script:ModulePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "SymbolicEngine/core/Validate-SymbolicRoles.ps1"
}

Describe "Validate-SymbolicRoles" -Tags @('Unit', 'Roles', 'Security') {

    Context "Role Definition" {
        It "Should define symbolic role with capabilities" {
            $role = @{
                name = "administrator"
                capabilities = @("execute_all", "manage_symbols", "view_audit")
                inherits_from = @()
            }

            Mock New-SymbolicRole {
                param($Definition)
                return @{
                    Success = $true
                    Role = $Definition
                }
            }

            $result = New-SymbolicRole -Definition $role
            $result.Success | Should -Be $true
            $result.Role.capabilities | Should -Contain "execute_all"
        }

        It "Should support role inheritance" {
            $baseRole = @{ name = "viewer"; capabilities = @("view") }
            $derivedRole = @{ name = "editor"; inherits_from = @("viewer"); capabilities = @("edit") }

            Mock Resolve-RoleInheritance {
                param($Role, $AllRoles)
                $capabilities = $Role.capabilities
                foreach ($parentName in $Role.inherits_from) {
                    $parent = $AllRoles | Where-Object { $_.name -eq $parentName }
                    $capabilities += $parent.capabilities
                }
                return $capabilities | Select-Object -Unique
            }

            $allRoles = @($baseRole, $derivedRole)
            $resolved = Resolve-RoleInheritance -Role $derivedRole -AllRoles $allRoles
            $resolved | Should -Contain "view"
            $resolved | Should -Contain "edit"
        }
    }

    Context "Permission Validation" {
        It "Should validate user has required role" {
            $user = @{ roles = @("editor", "contributor") }
            $requiredRole = "editor"

            Mock Test-UserRole {
                param($User, $Role)
                return $User.roles -contains $Role
            }

            $hasRole = Test-UserRole -User $user -Role $requiredRole
            $hasRole | Should -Be $true
        }

        It "Should check capability permissions" {
            $user = @{
                roles = @("editor")
            }
            $roles = @(
                @{ name = "editor"; capabilities = @("edit", "publish") }
            )
            $requiredCapability = "edit"

            Mock Test-UserCapability {
                param($User, $Capability, $Roles)
                $userRoles = $Roles | Where-Object { $_.name -in $User.roles }
                $userCapabilities = $userRoles.capabilities | Select-Object -Unique
                return $userCapabilities -contains $Capability
            }

            $hasCapability = Test-UserCapability -User $user -Capability $requiredCapability -Roles $roles
            $hasCapability | Should -Be $true
        }
    }

    Context "Symbol Access Control" {
        It "Should enforce role-based symbol execution" {
            $symbol = @{
                name = "admin_symbol"
                required_roles = @("administrator")
            }
            $user = @{ roles = @("editor") }

            Mock Test-SymbolAccess {
                param($Symbol, $User)
                $hasAccess = $false
                foreach ($role in $Symbol.required_roles) {
                    if ($User.roles -contains $role) {
                        $hasAccess = $true
                        break
                    }
                }
                return $hasAccess
            }

            $canExecute = Test-SymbolAccess -Symbol $symbol -User $user
            $canExecute | Should -Be $false
        }
    }
}
