# WP Praxis Test Suite Documentation

## Overview

The WP Praxis test suite is a comprehensive, multi-language testing framework designed to ensure the reliability, performance, and security of the WP Praxis symbolic system. Tests are organized by layer and language, reflecting the project's polyglot architecture.

## Table of Contents

- [Quick Start](#quick-start)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Coverage Reports](#coverage-reports)
- [CI/CD Integration](#cicd-integration)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Prerequisites

Install the required dependencies for each layer:

```bash
# PowerShell (Pester)
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force

# Rust (Cargo)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Elixir (Mix)
# Install Elixir and Erlang via your package manager

# PHP (PHPUnit)
composer install

# TypeScript/Bun
curl -fsSL https://bun.sh/install | bash
```

### Run All Tests

```bash
# From project root
pwsh tests/run-tests.ps1 -Suite all -Coverage
```

### Run Specific Test Suite

```bash
# PowerShell tests only
pwsh tests/run-tests.ps1 -Suite powershell

# Rust tests only
pwsh tests/run-tests.ps1 -Suite rust

# PHP tests only
pwsh tests/run-tests.ps1 -Suite php

# TypeScript tests only
pwsh tests/run-tests.ps1 -Suite typescript

# Integration tests
pwsh tests/run-tests.ps1 -Suite integration

# E2E tests
pwsh tests/run-tests.ps1 -Suite e2e
```

## Test Structure

```
tests/
├── run-tests.ps1                # Master test runner
├── README.md                    # This file
│
├── unit/                        # Unit tests (PowerShell)
│   ├── Test-SymbolicEngine.Tests.ps1
│   ├── Test-SymbolicAudit.Tests.ps1
│   ├── Test-NormativeBaseline.Tests.ps1
│   ├── Test-SymbolicActions.Tests.ps1
│   ├── Test-SymbolicRoles.Tests.ps1
│   └── Test-SymbolicDiff.Tests.ps1
│
├── integration/                 # Integration tests (PowerShell)
│   ├── Test-EndToEndWorkflow.Tests.ps1
│   ├── Test-ManifestParsing.Tests.ps1
│   └── Test-DispatchChain.Tests.ps1
│
├── e2e/                        # End-to-end tests
│   └── Test-FullWorkflow.Tests.ps1
│
├── fixtures/                   # Test data and fixtures
│   ├── complete-workflow.yaml
│   ├── test-symbols.toml
│   └── test-data.json
│
├── results/                    # Test results (generated)
│   ├── powershell-results.xml
│   ├── phpunit-results.xml
│   └── ...
│
└── coverage/                   # Coverage reports (generated)
    ├── powershell-coverage.xml
    ├── php-clover.xml
    ├── php-html/
    └── ...
```

### Layer-Specific Tests

#### PowerShell Tests (`tests/unit/` and `tests/integration/`)
- **Framework**: Pester 5.x
- **Coverage**: SymbolicEngine core scripts
- **Scope**: Unit tests and integration tests

#### Rust Tests (`wp_injector/tests/`)
- **Framework**: Cargo test
- **Coverage**: Injector logic, manifest parsing, symbol operations
- **Scope**: Unit tests and integration tests

#### Elixir Tests (`Core/db-schema/test/`)
- **Framework**: ExUnit
- **Coverage**: Ecto schemas, database queries
- **Scope**: Schema validation, query tests

#### PHP Tests (`plugin/tests/`)
- **Framework**: PHPUnit
- **Coverage**: WordPress integration, Symbol class, Symbolic Engine
- **Scope**: Unit tests, WordPress integration tests

#### TypeScript Tests (`SymbolicEngine/swarm/tests/`)
- **Framework**: Bun test
- **Coverage**: Dispatcher, Worker, Coordinator
- **Scope**: Unit tests, integration tests

## Running Tests

### PowerShell Tests (Pester)

```powershell
# Run all PowerShell tests
Invoke-Pester -Path tests/unit, tests/integration

# Run specific test file
Invoke-Pester -Path tests/unit/Test-SymbolicEngine.Tests.ps1

# Run with coverage
Invoke-Pester -CodeCoverage SymbolicEngine/core/*.ps1

# Run tests by tag
Invoke-Pester -Tag Unit
Invoke-Pester -Tag Integration
Invoke-Pester -Tag Security

# Verbose output
Invoke-Pester -Output Detailed
```

### Rust Tests (Cargo)

```bash
# Run all tests
cd wp_injector
cargo test

# Run with output
cargo test -- --nocapture

# Run specific test
cargo test test_inject_valid_symbol

# Run with coverage (requires cargo-tarpaulin)
cargo tarpaulin --out Html --output-dir ../tests/coverage

# Run benchmarks
cargo bench
```

### Elixir Tests (ExUnit)

```bash
# Run all tests
cd Core/db-schema
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/schema_test.exs

# Run specific test
mix test test/schema_test.exs:10

# Watch mode
mix test.watch
```

### PHP Tests (PHPUnit)

```bash
# Run all tests
vendor/bin/phpunit

# Run specific test suite
vendor/bin/phpunit --testsuite "Unit Tests"

# Run specific test file
vendor/bin/phpunit plugin/tests/SymbolTest.php

# Run with coverage
vendor/bin/phpunit --coverage-html tests/coverage/php-html

# Filter by test name
vendor/bin/phpunit --filter test_create_symbol
```

### TypeScript Tests (Bun)

```bash
# Run all tests
cd SymbolicEngine/swarm
bun test

# Run with coverage
bun test --coverage

# Watch mode
bun test --watch

# Run specific test file
bun test tests/dispatcher.test.ts
```

### Integration and E2E Tests

```powershell
# Run integration tests
pwsh tests/run-tests.ps1 -Suite integration

# Run E2E tests
pwsh tests/run-tests.ps1 -Suite e2e

# Run with fail-fast
pwsh tests/run-tests.ps1 -Suite all -FailFast
```

## Writing Tests

### PowerShell Test Example (Pester)

```powershell
BeforeAll {
    $script:ModulePath = "path/to/module.ps1"
}

Describe "Feature Name" -Tags @('Unit', 'FeatureName') {

    Context "Specific Scenario" {

        It "Should perform expected behavior" {
            # Arrange
            $input = "test"

            # Act
            $result = Invoke-Function -Input $input

            # Assert
            $result | Should -Be "expected"
        }

        It "Should handle edge case" {
            # Test edge case
            { Invoke-Function -Input $null } | Should -Throw
        }
    }
}
```

### Rust Test Example

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_feature() {
        // Arrange
        let input = "test";

        // Act
        let result = process_input(input);

        // Assert
        assert_eq!(result, "expected");
    }

    #[test]
    #[should_panic(expected = "error message")]
    fn test_error_handling() {
        process_invalid_input();
    }
}
```

### PHP Test Example (PHPUnit)

```php
<?php
namespace WPPraxis\Tests;

use PHPUnit\Framework\TestCase;

class FeatureTest extends TestCase
{
    public function test_feature()
    {
        // Arrange
        $input = 'test';

        // Act
        $result = process($input);

        // Assert
        $this->assertEquals('expected', $result);
    }

    public function test_exception_handling()
    {
        $this->expectException(\InvalidArgumentException::class);
        process_invalid();
    }
}
```

### TypeScript Test Example (Bun)

```typescript
import { describe, test, expect } from "bun:test";

describe("Feature", () => {
  test("should perform expected behavior", () => {
    // Arrange
    const input = "test";

    // Act
    const result = processInput(input);

    // Assert
    expect(result).toBe("expected");
  });

  test("should handle errors", () => {
    // Assert
    expect(() => processInvalid()).toThrow("error message");
  });
});
```

### Test Organization Guidelines

1. **One assertion per test** when possible
2. **Use descriptive test names** that explain what is being tested
3. **Follow AAA pattern** (Arrange, Act, Assert)
4. **Use tags** to categorize tests (@Unit, @Integration, @E2E, @Slow, @Security)
5. **Mock external dependencies** in unit tests
6. **Use fixtures** for consistent test data
7. **Clean up after tests** to avoid side effects

## Coverage Reports

### Viewing Coverage

```bash
# PowerShell coverage
# Open tests/coverage/powershell-coverage.xml

# Rust coverage
open wp_injector/target/tarpaulin/index.html

# PHP coverage
open tests/coverage/php-html/index.html

# TypeScript coverage
open SymbolicEngine/swarm/coverage/index.html
```

### Coverage Goals

- **Unit Tests**: 80% minimum coverage
- **Integration Tests**: 60% minimum coverage
- **Critical Paths**: 95% minimum coverage
- **Security-sensitive code**: 100% coverage

### Coverage by Layer

| Layer | Target Coverage | Current Coverage |
|-------|----------------|------------------|
| PowerShell Core | 80% | TBD |
| Rust Injector | 85% | TBD |
| Elixir DB Schema | 75% | TBD |
| PHP WordPress | 80% | TBD |
| TypeScript Swarm | 75% | TBD |

## CI/CD Integration

### GitHub Actions

Tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

### Workflow Stages

1. **PowerShell Tests** (Ubuntu + Windows)
2. **Rust Tests** (Ubuntu)
3. **Elixir Tests** (Ubuntu)
4. **PHP Tests** (Ubuntu with MySQL)
5. **TypeScript Tests** (Ubuntu)
6. **E2E Tests** (Ubuntu, requires all previous stages)
7. **Coverage Report** (Combined coverage)

### CI Configuration

See `.github/workflows/test.yml` for complete CI configuration.

### Local CI Simulation

```bash
# Run tests as CI would
pwsh tests/run-tests.ps1 -Suite all -Coverage -FailFast
```

## Test Data and Fixtures

### Test Manifests

- **`tests/fixtures/complete-workflow.yaml`**: Comprehensive workflow for integration testing
- **`tests/fixtures/test-symbols.toml`**: Various symbol definitions for unit testing
- **`tests/fixtures/test-data.json`**: Sample data for database tests

### Creating New Fixtures

1. Place fixtures in `tests/fixtures/`
2. Use descriptive names
3. Include comments explaining the test scenario
4. Keep fixtures minimal but realistic
5. Version control all fixtures

## Troubleshooting

### Common Issues

#### Pester Module Not Found

```powershell
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force -SkipPublisherCheck
```

#### Rust Tests Fail to Compile

```bash
cd wp_injector
cargo clean
cargo build
cargo test
```

#### PHP Tests Can't Connect to Database

```bash
# Check MySQL is running
sudo systemctl status mysql

# Update phpunit.xml with correct credentials
```

#### TypeScript Tests Fail

```bash
cd SymbolicEngine/swarm
rm -rf node_modules
bun install
bun test
```

### Debug Mode

```powershell
# PowerShell debug
$VerbosePreference = 'Continue'
Invoke-Pester -Output Detailed

# Rust debug
RUST_BACKTRACE=1 cargo test

# PHP debug
vendor/bin/phpunit --debug

# Bun debug
bun test --verbose
```

### Getting Help

1. Check test output for specific error messages
2. Review relevant test file documentation
3. Check CI logs for additional context
4. Review `CLAUDE.md` for project-specific conventions
5. Consult layer-specific documentation in `Docs/`

## Performance Testing

### Running Benchmarks

```bash
# Rust benchmarks
cd wp_injector
cargo bench

# PowerShell performance tests
Invoke-Pester -Tag Performance
```

### Performance Targets

- Symbol parsing: < 10ms per symbol
- Symbol injection: < 50ms per symbol
- Workflow execution: < 5s for 100 symbols
- Database queries: < 100ms per query

## Security Testing

### Security Test Tags

```powershell
# Run security-focused tests
Invoke-Pester -Tag Security

# Run input validation tests
Invoke-Pester -Tag Validation

# Run access control tests
Invoke-Pester -Tag Authorization
```

### Security Test Coverage

- Input sanitization
- SQL injection prevention
- XSS prevention
- CSRF protection
- Role-based access control
- Nonce verification
- Capability checks

## Contributing

### Adding New Tests

1. Follow the existing test structure
2. Use appropriate framework for the layer
3. Include both positive and negative test cases
4. Add relevant tags
5. Update this README if adding new test categories

### Test Review Checklist

- [ ] Tests follow naming conventions
- [ ] Tests are properly categorized with tags
- [ ] Tests clean up after themselves
- [ ] Tests don't depend on external state
- [ ] Tests are deterministic
- [ ] Tests run in reasonable time
- [ ] Coverage meets minimum requirements
- [ ] Documentation updated if needed

## Version History

- **1.0.0** (2025-11-22): Initial comprehensive test suite

---

For more information, see:
- Project documentation: `Docs/`
- Architecture overview: `CLAUDE.md`
- Technology stack: `Docs/STACK.md`
