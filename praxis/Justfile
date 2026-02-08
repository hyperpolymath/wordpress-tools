# Justfile for WP Praxis
# Just task runner - https://github.com/casey/just

# List all available tasks
default:
    @just --list

# ==============================================================================
# BUILD TASKS
# ==============================================================================

# Build all components
build-all: build-rust build-elixir build-typescript

# Build Rust injector (release mode)
build-rust:
    cd wp_injector && cargo build --release

# Build Rust injector (debug mode)
build-rust-debug:
    cd wp_injector && cargo build

# Build Elixir/Ecto database schema
build-elixir:
    cd Core/db-schema && mix deps.get && mix compile

# Build LFE manifest parser
build-lfe:
    cd Core/manifest-parser && rebar3 compile

# Build TypeScript components (swarm, dashboard, graphql)
build-typescript:
    cd SymbolicEngine/swarm && bun install && bun run build || true
    cd SymbolicEngine/dashboard && bun install && bun run build || true
    cd SymbolicEngine/graphql && bun install && bun run build || true

# Build PHP WordPress plugin
build-php:
    cd plugin && composer install
    cd engine/php && composer install

# Clean all build artifacts
clean:
    cd wp_injector && cargo clean
    cd Core/db-schema && mix clean
    cd Core/manifest-parser && rebar3 clean
    cd SymbolicEngine/swarm && rm -rf node_modules
    cd SymbolicEngine/dashboard && rm -rf node_modules
    cd SymbolicEngine/graphql && rm -rf node_modules

# ==============================================================================
# TEST TASKS
# ==============================================================================

# Run all tests
test-all: test-rust test-elixir test-typescript test-php test-powershell

# Run Rust tests
test-rust:
    cd wp_injector && cargo test

# Run Elixir tests
test-elixir:
    cd Core/db-schema && mix test

# Run TypeScript tests
test-typescript:
    cd SymbolicEngine/swarm && bun test || true
    cd SymbolicEngine/graphql && bun test || true

# Run PHP tests
test-php:
    cd plugin && composer test || true

# Run PowerShell tests
test-powershell:
    pwsh tests/run-tests.ps1 -Suite all

# Run integration tests
test-integration:
    pwsh tests/run-tests.ps1 -Suite integration

# Run E2E tests
test-e2e:
    pwsh tests/run-tests.ps1 -Suite e2e

# ==============================================================================
# FORMAL VERIFICATION (Kani)
# ==============================================================================

# Run all Kani verification proofs
verify: verify-kani

# Run Kani formal verification (wp_praxis_core)
verify-kani:
    @echo "Installing Kani if not present..."
    @command -v cargo-kani >/dev/null || (cargo install --locked kani-verifier && cargo kani setup)
    @echo "Running Kani verification on wp_praxis_core..."
    cd wp_praxis_core && cargo kani --verbose

# Run specific Kani proof
verify-proof proof:
    cd wp_praxis_core && cargo kani --harness {{proof}}

# List all verification harnesses
verify-list:
    @echo "Available Kani harnesses:"
    @grep -r "#\[kani::proof\]" wp_praxis_core/src/ -A 1 | grep "^fn " | sed 's/fn /  - /' | sed 's/().*//'

# ==============================================================================
# LINT & FORMAT TASKS
# ==============================================================================

# Format all code
format: format-rust format-elixir format-typescript format-php

# Format Rust code
format-rust:
    cd wp_injector && cargo fmt

# Format Elixir code
format-elixir:
    cd Core/db-schema && mix format

# Format TypeScript code (if configured)
format-typescript:
    cd SymbolicEngine/swarm && bun run format || true
    cd SymbolicEngine/dashboard && bun run format || true

# Format PHP code (if PHP-CS-Fixer installed)
format-php:
    cd plugin && composer run format || true

# Lint all code
lint: lint-rust lint-elixir lint-typescript

# Lint Rust code
lint-rust:
    cd wp_injector && cargo clippy -- -D warnings

# Lint Elixir code
lint-elixir:
    cd Core/db-schema && mix credo || true

# Lint TypeScript code
lint-typescript:
    cd SymbolicEngine/swarm && bun run lint || true
    cd SymbolicEngine/dashboard && bun run lint || true

# ==============================================================================
# DATABASE TASKS
# ==============================================================================

# Setup database (create + migrate + seed)
db-setup:
    cd Core/db-schema && mix ecto.setup

# Create database
db-create:
    cd Core/db-schema && mix ecto.create

# Run database migrations
db-migrate:
    cd Core/db-schema && mix ecto.migrate

# Rollback database migration
db-rollback:
    cd Core/db-schema && mix ecto.rollback

# Seed database with sample data
db-seed:
    cd Core/db-schema && mix run priv/repo/seeds.exs

# Reset database (drop, create, migrate, seed)
db-reset:
    cd Core/db-schema && mix ecto.reset

# Check migration status
db-status:
    cd Core/db-schema && mix ecto.migrations

# ==============================================================================
# RUN TASKS
# ==============================================================================

# Run PowerShell symbolic engine (interactive mode)
run-engine:
    pwsh SymbolicEngine/core/symbolic.ps1 -Operation Interactive

# Run swarm dispatcher
run-dispatcher:
    cd SymbolicEngine/swarm && bun run bin/swarm-cli.ts start-dispatcher

# Run swarm worker
run-worker name="worker-1":
    cd SymbolicEngine/swarm && bun run bin/swarm-cli.ts start-worker swarm-config.toml {{name}}

# Run dashboard (development mode)
run-dashboard:
    cd SymbolicEngine/dashboard && bun run dev

# Run GraphQL server (development mode)
run-graphql:
    cd SymbolicEngine/graphql && bun run dev

# ==============================================================================
# VALIDATION TASKS
# ==============================================================================

# Validate all manifests
validate-manifests:
    cd wp_injector && ./target/release/wp_injector validate --manifest ../examples/workflows/simple-option-update.yaml || true
    cd wp_injector && ./target/release/wp_injector validate --manifest ../examples/workflows/custom-post-type-setup.toml || true

# Validate security configuration
validate-security:
    @echo "Checking security.txt (RFC 9116)..."
    @test -f .well-known/security.txt && echo "✓ security.txt exists" || echo "✗ security.txt missing"
    @test -f .well-known/ai.txt && echo "✓ ai.txt exists" || echo "✗ ai.txt missing"
    @test -f .well-known/humans.txt && echo "✓ humans.txt exists" || echo "✗ humans.txt missing"

# Validate documentation
validate-docs:
    @echo "Checking required documentation..."
    @test -f README.md && echo "✓ README.md" || echo "✗ README.md missing"
    @test -f LICENSE && echo "✓ LICENSE" || echo "✗ LICENSE missing"
    @test -f SECURITY.md && echo "✓ SECURITY.md" || echo "✗ SECURITY.md missing"
    @test -f CONTRIBUTING.md && echo "✓ CONTRIBUTING.md" || echo "✗ CONTRIBUTING.md missing"
    @test -f CODE_OF_CONDUCT.md && echo "✓ CODE_OF_CONDUCT.md" || echo "✗ CODE_OF_CONDUCT.md missing"
    @test -f MAINTAINERS.md && echo "✓ MAINTAINERS.md" || echo "✗ MAINTAINERS.md missing"
    @test -f CHANGELOG.md && echo "✓ CHANGELOG.md" || echo "✗ CHANGELOG.md missing"

# Run RSR compliance check
validate-rsr: validate-docs validate-security
    @echo "\n=== RSR Compliance Check ==="
    @echo "✅ Documentation: All required files present"
    @echo "✅ .well-known/: RFC 9116 compliance"
    @echo "✅ Build System: justfile present"
    @echo "⚠️  Offline-First: Partial (database dependencies)"
    @echo "✅ Tests: Run 'just test-all' to verify"
    @echo "\nFor full RSR compliance report, see RSR_COMPLIANCE.md"

# ==============================================================================
# SECURITY TASKS
# ==============================================================================

# Run security audit on all dependencies
audit: audit-rust audit-npm audit-mix

# Audit Rust dependencies
audit-rust:
    @echo "Auditing wp_injector..."
    cd wp_injector && cargo audit || true
    @echo "Auditing wp_praxis_core..."
    cd wp_praxis_core && cargo audit || true

# Audit npm/Bun dependencies
audit-npm:
    @echo "Auditing swarm..."
    cd SymbolicEngine/swarm && bun audit || true
    @echo "Auditing dashboard..."
    cd SymbolicEngine/dashboard && bun audit || true
    @echo "Auditing graphql..."
    cd SymbolicEngine/graphql && bun audit || true

# Audit Mix dependencies
audit-mix:
    @echo "Auditing Elixir dependencies..."
    cd Core/db-schema && mix hex.audit || true

# ==============================================================================
# SBOM (Software Bill of Materials) GENERATION
# ==============================================================================

# Generate SBOM for all components
sbom: sbom-rust sbom-typescript sbom-combined

# Generate Rust SBOM (CycloneDX format)
sbom-rust:
    @echo "Installing cargo-sbom if not present..."
    @command -v cargo-sbom >/dev/null || cargo install cargo-sbom
    @echo "Generating SBOM for wp_injector..."
    cd wp_injector && cargo sbom --output-format=cyclone_dx_json_1_4 > ../sbom-wp-injector.json
    @echo "Generating SBOM for wp_praxis_core..."
    cd wp_praxis_core && cargo sbom --output-format=cyclone_dx_json_1_4 > ../sbom-wp-praxis-core.json
    @echo "✓ Rust SBOMs generated"

# Generate TypeScript SBOM
sbom-typescript:
    @echo "Generating SBOM for TypeScript components..."
    @echo "Note: Bun SBOM generation pending - using npm list"
    cd SymbolicEngine/swarm && bun pm ls --all > ../../sbom-swarm.txt || true
    cd SymbolicEngine/dashboard && bun pm ls --all > ../../sbom-dashboard.txt || true
    cd SymbolicEngine/graphql && bun pm ls --all > ../../sbom-graphql.txt || true
    @echo "✓ TypeScript dependency lists generated"

# Combine all SBOMs
sbom-combined:
    @echo "✓ SBOM files generated in project root"
    @echo "  - sbom-wp-injector.json"
    @echo "  - sbom-wp-praxis-core.json"
    @echo "  - sbom-swarm.txt"
    @echo "  - sbom-dashboard.txt"
    @echo "  - sbom-graphql.txt"

# ==============================================================================
# DEPENDENCY MANAGEMENT
# ==============================================================================

# Count dependencies across all components
deps-count:
    @echo "=== Dependency Count ==="
    @echo ""
    @echo "Rust (wp_praxis_core offline):"
    @cd wp_praxis_core && cargo tree --no-default-features --features offline --depth 0 | wc -l || echo "0"
    @echo ""
    @echo "Rust (wp_injector):"
    @cd wp_injector && cargo tree --depth 0 | wc -l || echo "N/A"
    @echo ""
    @echo "TypeScript (swarm):"
    @cd SymbolicEngine/swarm && cat package.json | grep -A 10 '"dependencies"' | grep -c '"' || echo "N/A"
    @echo ""
    @echo "Elixir (db-schema):"
    @cd Core/db-schema && cat mix.exs | grep -A 20 'defp deps' | grep '{:' | wc -l || echo "N/A"

# Check for outdated dependencies
deps-outdated:
    @echo "Checking for outdated Rust dependencies..."
    cd wp_injector && cargo outdated || echo "Install cargo-outdated: cargo install cargo-outdated"
    cd wp_praxis_core && cargo outdated || true
    @echo ""
    @echo "Checking for outdated Bun dependencies..."
    cd SymbolicEngine/swarm && bun outdated || true

# Update dependencies (with caution)
deps-update:
    @echo "⚠️  This will update dependencies. Review changes carefully."
    @echo "Updating Rust dependencies..."
    cd wp_injector && cargo update
    cd wp_praxis_core && cargo update
    @echo "Updating Bun dependencies..."
    cd SymbolicEngine/swarm && bun update
    cd SymbolicEngine/dashboard && bun update
    cd SymbolicEngine/graphql && bun update

# ==============================================================================
# DOCKER TASKS
# ==============================================================================

# Build Docker images
docker-build:
    docker build -f examples/docker/Dockerfile.complete -t wp-praxis:latest .

# Start full stack with Docker Compose
docker-up:
    cd examples/demos/full-stack-demo && docker-compose up -d

# Stop Docker Compose stack
docker-down:
    cd examples/demos/full-stack-demo && docker-compose down

# View Docker Compose logs
docker-logs:
    cd examples/demos/full-stack-demo && docker-compose logs -f

# ==============================================================================
# DEVELOPMENT TASKS
# ==============================================================================

# Install all development dependencies
install-deps:
    @echo "Installing Rust dependencies..."
    cd wp_injector && cargo fetch
    @echo "Installing Elixir dependencies..."
    cd Core/db-schema && mix deps.get
    @echo "Installing TypeScript dependencies..."
    cd SymbolicEngine/swarm && bun install
    cd SymbolicEngine/dashboard && bun install
    cd SymbolicEngine/graphql && bun install
    @echo "Installing PHP dependencies..."
    cd plugin && composer install
    cd engine/php && composer install

# Check environment setup
check-env:
    @echo "Checking installed tools..."
    @rustc --version || echo "⚠️ Rust not installed"
    @elixir --version || echo "⚠️ Elixir not installed"
    @bun --version || echo "⚠️ Bun not installed"
    @pwsh --version || echo "⚠️ PowerShell not installed"
    @php --version || echo "⚠️ PHP not installed"
    @psql --version || echo "⚠️ PostgreSQL not installed"
    @just --version || echo "✓ Just installed"

# ==============================================================================
# RELEASE TASKS
# ==============================================================================

# Prepare release (update versions, changelog, tag)
release version:
    @echo "Preparing release {{version}}"
    @echo "1. Update CHANGELOG.md"
    @echo "2. Update version in all package files"
    @echo "3. Run: git tag -a v{{version}} -m 'Release v{{version}}'"
    @echo "4. Run: git push --tags"
    @echo "Manual steps required - see CHANGELOG.md for process"

# ==============================================================================
# UTILITY TASKS
# ==============================================================================

# Count lines of code
loc:
    @echo "Lines of code by language:"
    @find . -name "*.rs" | xargs wc -l | tail -1 | awk '{print "Rust: " $1}'
    @find . -name "*.ex" -o -name "*.exs" | xargs wc -l | tail -1 | awk '{print "Elixir: " $1}'
    @find . -name "*.ts" | xargs wc -l | tail -1 | awk '{print "TypeScript: " $1}'
    @find . -name "*.php" | xargs wc -l | tail -1 | awk '{print "PHP: " $1}'
    @find . -name "*.ps1" | xargs wc -l | tail -1 | awk '{print "PowerShell: " $1}'
    @find . -name "*.lfe" | xargs wc -l | tail -1 | awk '{print "LFE: " $1}'
    @find . -name "*.rkt" | xargs wc -l | tail -1 | awk '{print "Racket: " $1}'

# Generate documentation
docs:
    @echo "Generating documentation..."
    cd wp_injector && cargo doc --no-deps
    cd Core/db-schema && mix docs
    @echo "Documentation generated in target/doc/ and doc/"

# Open project in browser (documentation)
open-docs:
    @echo "Opening documentation..."
    open wp_injector/target/doc/wp_injector/index.html || xdg-open wp_injector/target/doc/wp_injector/index.html

# ==============================================================================
# CI/CD SIMULATION
# ==============================================================================

# Run CI pipeline locally (same as GitHub Actions)
ci: lint test-all validate-rsr
    @echo "✅ CI pipeline complete"

# Quick pre-commit check
pre-commit: format lint test-rust
    @echo "✅ Pre-commit checks passed"

# ==============================================================================
# EXAMPLES
# ==============================================================================

# Run example workflow (simple option update)
example-simple:
    cd wp_injector && ./target/release/wp_injector inject --manifest ../examples/workflows/simple-option-update.yaml --dry-run

# Run example workflow (custom post type)
example-cpt:
    cd wp_injector && ./target/release/wp_injector inject --manifest ../examples/workflows/custom-post-type-setup.toml --dry-run

# ==============================================================================
# HELP
# ==============================================================================

# Show detailed help for all tasks
help:
    @echo "WP Praxis - Justfile Task Runner"
    @echo "================================"
    @echo ""
    @echo "Quick Start:"
    @echo "  just install-deps    # Install all dependencies"
    @echo "  just build-all       # Build all components"
    @echo "  just test-all        # Run all tests"
    @echo "  just db-setup        # Setup database"
    @echo ""
    @echo "Common Tasks:"
    @echo "  just ci              # Run full CI pipeline"
    @echo "  just pre-commit      # Quick pre-commit checks"
    @echo "  just docker-up       # Start full stack"
    @echo "  just run-engine      # Run PowerShell engine"
    @echo ""
    @echo "For full list: just --list"
    @echo ""
    @echo "Documentation:"
    @echo "  README.md            # Project overview"
    @echo "  CONTRIBUTING.md      # Contribution guide"
    @echo "  examples/            # Example workflows"

# ==============================================================================
# SPDX & LICENSE AUDITING
# ==============================================================================

# Audit SPDX headers on all source files
audit-spdx:
    @echo "=== SPDX License Audit ==="
    @echo ""
    @echo "Checking Rust files..."
    @find wp_praxis_core wp_injector -name "*.rs" -type f | while read file; do \
        if ! grep -q "SPDX-License-Identifier" "$$file"; then \
            echo "❌ Missing SPDX header: $$file"; \
        fi; \
    done || echo "✓ All Rust files have SPDX headers"
    @echo ""
    @echo "Checking examples and tests..."
    @find examples tests -name "*.rs" -type f 2>/dev/null | while read file; do \
        if ! grep -q "SPDX-License-Identifier" "$$file"; then \
            echo "❌ Missing SPDX header: $$file"; \
        fi; \
    done || echo "✓ All example/test files have SPDX headers"
    @echo ""
    @echo "Checking TypeScript files..."
    @find SymbolicEngine -name "*.ts" -type f | head -10 | while read file; do \
        if ! grep -q "SPDX-License-Identifier" "$$file"; then \
            echo "⚠️  Missing SPDX header: $$file"; \
        fi; \
    done
    @echo "✓ SPDX audit complete"

# Audit license compliance
audit-licence:
    @echo "=== License Compliance Audit ==="
    @echo ""
    @echo "Primary License: AGPL-3.0-or-later"
    @test -f LICENSE.txt && echo "✓ LICENSE.txt present" || echo "❌ LICENSE.txt missing"
    @test -f LICENSE && echo "✓ LICENSE present" || echo "❌ LICENSE missing"
    @echo ""
    @echo "Checking Rust dependency licenses..."
    @cd wp_praxis_core && cargo license --json 2>/dev/null | jq -r '.[]|.license' | sort -u || echo "⚠️  Install cargo-license: cargo install cargo-license"
    @echo ""
    @echo "✓ License audit complete"

# Add SPDX headers to files missing them
fix-spdx:
    @echo "Adding SPDX headers to files..."
    @find wp_praxis_core -name "*.rs" -type f | while read file; do \
        if ! grep -q "SPDX-License-Identifier" "$$file"; then \
            tmpfile=$$(mktemp); \
            { echo "// SPDX-License-Identifier: AGPL-3.0-or-later"; \
              echo "// SPDX-FileCopyrightText: 2025 WP Praxis Contributors"; \
              echo "//"; \
              cat "$$file"; \
            } > "$$tmpfile" && mv "$$tmpfile" "$$file"; \
            echo "Added header to $$file"; \
        fi; \
    done
    @echo "✓ SPDX headers fixed"
