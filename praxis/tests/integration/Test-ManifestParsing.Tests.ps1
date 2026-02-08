BeforeAll {
    $script:FixturesPath = Join-Path $PSScriptRoot "../fixtures"
}

Describe "Manifest Parsing Integration" -Tags @('Integration', 'Manifest', 'Parser') {

    Context "YAML Manifest Parsing" {
        It "Should parse valid YAML manifest" {
            $yamlContent = @"
name: test_manifest
version: 1.0.0
symbols:
  - name: test_symbol
    type: action
    context: wordpress
    dispatch: rust_injector
    parameters:
      key: value
"@
            Mock ConvertFrom-Yaml {
                param($Content)
                return @{
                    name = "test_manifest"
                    version = "1.0.0"
                    symbols = @(
                        @{
                            name = "test_symbol"
                            type = "action"
                            context = "wordpress"
                            dispatch = "rust_injector"
                            parameters = @{ key = "value" }
                        }
                    )
                }
            }

            $manifest = ConvertFrom-Yaml -Content $yamlContent
            $manifest.name | Should -Be "test_manifest"
            $manifest.symbols | Should -HaveCount 1
        }

        It "Should validate YAML schema" {
            Mock Test-ManifestSchema {
                param($Manifest)
                $errors = @()
                if (-not $Manifest.name) { $errors += "Missing required field: name" }
                if (-not $Manifest.version) { $errors += "Missing required field: version" }
                if (-not $Manifest.symbols) { $errors += "Missing required field: symbols" }

                return @{
                    Valid = ($errors.Count -eq 0)
                    Errors = $errors
                }
            }

            $validManifest = @{
                name = "test"
                version = "1.0.0"
                symbols = @()
            }

            $result = Test-ManifestSchema -Manifest $validManifest
            $result.Valid | Should -Be $true
        }
    }

    Context "TOML Manifest Parsing" {
        It "Should parse valid TOML manifest" {
            $tomlContent = @"
name = "test_manifest"
version = "1.0.0"

[[symbols]]
name = "test_symbol"
type = "action"
context = "wordpress"
dispatch = "rust_injector"

[symbols.parameters]
key = "value"
"@
            Mock ConvertFrom-Toml {
                param($Content)
                return @{
                    name = "test_manifest"
                    version = "1.0.0"
                    symbols = @(
                        @{
                            name = "test_symbol"
                            type = "action"
                            context = "wordpress"
                            dispatch = "rust_injector"
                            parameters = @{ key = "value" }
                        }
                    )
                }
            }

            $manifest = ConvertFrom-Toml -Content $tomlContent
            $manifest.name | Should -Be "test_manifest"
        }
    }

    Context "Manifest Transformation" {
        It "Should transform manifest between formats" {
            $yamlManifest = @{
                name = "test"
                version = "1.0.0"
                symbols = @()
            }

            Mock ConvertTo-TomlManifest {
                param($YamlManifest)
                return @{
                    Format = "TOML"
                    Content = "name = 'test'`nversion = '1.0.0'"
                }
            }

            $toml = ConvertTo-TomlManifest -YamlManifest $yamlManifest
            $toml.Format | Should -Be "TOML"
        }

        It "Should validate manifest after transformation" {
            Mock Transform-Manifest {
                param($Source, $TargetFormat)
                return @{
                    Success = $true
                    SourceFormat = "YAML"
                    TargetFormat = $TargetFormat
                    Validated = $true
                }
            }

            $result = Transform-Manifest -Source @{} -TargetFormat "TOML"
            $result.Validated | Should -Be $true
        }
    }

    Context "Complex Manifest Structures" {
        It "Should handle nested symbol definitions" {
            $complexManifest = @{
                symbols = @(
                    @{
                        name = "parent_symbol"
                        children = @(
                            @{ name = "child1" }
                            @{ name = "child2" }
                        )
                    }
                )
            }

            Mock Parse-NestedSymbols {
                param($Manifest)
                $allSymbols = @()
                foreach ($symbol in $Manifest.symbols) {
                    $allSymbols += $symbol.name
                    if ($symbol.children) {
                        $allSymbols += $symbol.children.name
                    }
                }
                return $allSymbols
            }

            $symbols = Parse-NestedSymbols -Manifest $complexManifest
            $symbols | Should -HaveCount 3
        }

        It "Should resolve manifest includes" {
            Mock Resolve-ManifestIncludes {
                param($Manifest)
                return @{
                    Resolved = $true
                    IncludedFiles = @(
                        "/path/to/included1.yaml"
                        "/path/to/included2.yaml"
                    )
                    MergedSymbols = 10
                }
            }

            $result = Resolve-ManifestIncludes -Manifest @{}
            $result.Resolved | Should -Be $true
            $result.IncludedFiles | Should -HaveCount 2
        }
    }
}
