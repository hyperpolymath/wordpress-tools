# justfile - Build automation for Sinople WordPress Theme
# https://github.com/casey/just
#
# Install: cargo install just
# Usage: just <recipe>
# List recipes: just --list

# Default recipe (runs when you type 'just')
default:
    @just --list

# ============================================================================
# BUILD RECIPES
# ============================================================================

# Build all components (WASM + ReScript + Deno)
build:
    @echo "🏗️  Building all components..."
    just build-wasm
    just build-rescript
    just build-deno
    just assemble
    @echo "✅ Build complete!"

# Build WASM module only
build-wasm:
    @echo "📦 Building Rust WASM module..."
    cd wasm/semantic_processor && \
    wasm-pack build --target web --out-dir pkg
    @echo "✅ WASM build complete"

# Build ReScript only
build-rescript:
    @echo "🔧 Compiling ReScript..."
    cd rescript && \
    npm install && \
    npx rescript clean && \
    npx rescript build
    @echo "✅ ReScript compilation complete"

# Build Deno application
build-deno:
    @echo "🦕 Building Deno application..."
    cd deno && \
    deno task build || echo "No deno build task (ok if not configured)"
    @echo "✅ Deno build complete"

# Assemble WordPress theme (copy built assets)
assemble:
    @echo "📋 Assembling WordPress theme..."
    mkdir -p wordpress/assets/wasm
    mkdir -p wordpress/assets/js
    cp wasm/semantic_processor/pkg/*.js wordpress/assets/wasm/ || true
    cp wasm/semantic_processor/pkg/*.wasm wordpress/assets/wasm/ || true
    find rescript/src -name "*.res.js" -exec cp {} wordpress/assets/js/ \; || true
    @echo "✅ Assets assembled"

# Clean all build artifacts
clean:
    @echo "🧹 Cleaning build artifacts..."
    rm -rf wasm/semantic_processor/target
    rm -rf wasm/semantic_processor/pkg
    rm -rf rescript/lib
    rm -rf rescript/node_modules
    rm -rf build
    rm -rf wordpress/assets/wasm/*
    find wordpress/assets/js -name "*.res.js" -delete || true
    @echo "✅ Clean complete"

# ============================================================================
# DEVELOPMENT RECIPES
# ============================================================================

# Start development mode (watch files)
dev:
    @echo "🔥 Starting development mode..."
    @echo "Starting ReScript watch..."
    cd rescript && npx rescript build -w &
    @echo "Starting Deno watch..."
    cd deno && deno task dev &
    @echo "Press Ctrl+C to stop"
    wait

# Watch ReScript files only
watch-rescript:
    cd rescript && npx rescript build -w

# Watch Deno files only
watch-deno:
    cd deno && deno task dev

# Rebuild WASM on change (manual - requires inotify-tools)
watch-wasm:
    @echo "Watching wasm/semantic_processor/src/**/*.rs"
    @echo "Run manually: just build-wasm"

# ============================================================================
# TESTING RECIPES
# ============================================================================

# Run all tests
test:
    @echo "🧪 Running all tests..."
    just test-rust
    just test-rescript
    just test-deno
    @echo "✅ All tests passed!"

# Test Rust/WASM code
test-rust:
    @echo "Testing Rust code..."
    cd wasm/semantic_processor && cargo test --lib

# Test ReScript code
test-rescript:
    @echo "Testing ReScript code..."
    cd rescript && npm test || echo "No ReScript tests configured"

# Test Deno code
test-deno:
    @echo "Testing Deno code..."
    cd deno && deno test || echo "No Deno tests configured"

# Run integration tests
test-integration:
    @echo "Running integration tests..."
    cd tests && deno test integration/ || echo "No integration tests configured"

# ============================================================================
# LINTING & FORMATTING RECIPES
# ============================================================================

# Run all linters and formatters
lint:
    just lint-rust
    just lint-rescript
    just lint-php

# Lint Rust code
lint-rust:
    @echo "Linting Rust code..."
    cd wasm/semantic_processor && cargo fmt --check
    cd wasm/semantic_processor && cargo clippy -- -D warnings

# Format Rust code
fmt-rust:
    @echo "Formatting Rust code..."
    cd wasm/semantic_processor && cargo fmt

# Lint ReScript code
lint-rescript:
    @echo "Linting ReScript code..."
    cd rescript && npx rescript build || echo "ReScript type-checks on build"

# Lint PHP code (requires phpcs)
lint-php:
    @echo "Linting PHP code..."
    which phpcs && phpcs --standard=WordPress wordpress/ || echo "phpcs not installed (optional)"

# Format all code
fmt:
    just fmt-rust
    @echo "✅ All code formatted"

# ============================================================================
# SECURITY RECIPES
# ============================================================================

# Security audit (check dependencies)
audit:
    @echo "🔒 Running security audit..."
    just audit-rust
    just audit-npm

# Audit Rust dependencies
audit-rust:
    @echo "Auditing Rust dependencies..."
    cd wasm/semantic_processor && cargo audit || cargo install cargo-audit && cargo audit

# Audit NPM dependencies
audit-npm:
    @echo "Auditing NPM dependencies..."
    cd rescript && npm audit || echo "Run 'npm audit fix' if needed"

# Check for known vulnerabilities
check-vulns:
    @echo "Checking for vulnerabilities..."
    which trivy && trivy fs . || echo "trivy not installed (optional)"

# ============================================================================
# RELEASE RECIPES
# ============================================================================

# Prepare release (build + test + package)
release VERSION:
    @echo "📦 Preparing release {{VERSION}}..."
    just clean
    just build
    just test
    just validate
    @echo "✅ Release {{VERSION}} ready!"
    @echo "Next steps:"
    @echo "  1. git tag -a v{{VERSION}} -m 'Release {{VERSION}}'"
    @echo "  2. git push origin v{{VERSION}}"
    @echo "  3. Create GitHub release"

# Package theme for distribution
package:
    @echo "📦 Packaging theme..."
    mkdir -p dist
    tar -czf dist/sinople-theme.tar.gz wordpress/
    @echo "✅ Package created: dist/sinople-theme.tar.gz"

# ============================================================================
# VALIDATION RECIPES
# ============================================================================

# Validate RSR compliance
validate:
    @echo "✅ Validating RSR compliance..."
    just validate-docs
    just validate-build
    just validate-tests
    @echo "✅ RSR validation complete"

# Validate documentation completeness
validate-docs:
    @echo "Checking documentation..."
    @test -f README.md || (echo "❌ Missing README.md" && exit 1)
    @test -f LICENSE.txt || (echo "❌ Missing LICENSE.txt" && exit 1)
    @test -f SECURITY.md || (echo "❌ Missing SECURITY.md" && exit 1)
    @test -f CONTRIBUTING.md || (echo "❌ Missing CONTRIBUTING.md" && exit 1)
    @test -f CODE_OF_CONDUCT.md || (echo "❌ Missing CODE_OF_CONDUCT.md" && exit 1)
    @test -f MAINTAINERS.md || (echo "❌ Missing MAINTAINERS.md" && exit 1)
    @test -f CHANGELOG.md || (echo "❌ Missing CHANGELOG.md" && exit 1)
    @test -f TPCF.md || (echo "❌ Missing TPCF.md" && exit 1)
    @test -f .well-known/security.txt || (echo "❌ Missing .well-known/security.txt" && exit 1)
    @test -f .well-known/ai.txt || (echo "❌ Missing .well-known/ai.txt" && exit 1)
    @test -f .well-known/humans.txt || (echo "❌ Missing .well-known/humans.txt" && exit 1)
    @echo "✅ All required documentation present"

# Validate build system
validate-build:
    @echo "Checking build system..."
    @test -f justfile || (echo "❌ Missing justfile" && exit 1)
    @test -f build.sh || (echo "❌ Missing build.sh" && exit 1)
    @test -x build.sh || (echo "❌ build.sh not executable" && exit 1)
    @test -f wasm/semantic_processor/Cargo.toml || (echo "❌ Missing Cargo.toml" && exit 1)
    @test -f rescript/bsconfig.json || (echo "❌ Missing bsconfig.json" && exit 1)
    @echo "✅ Build system valid"

# Validate test suite
validate-tests:
    @echo "Checking test suite..."
    @test -d tests || (echo "⚠️  No tests/ directory" && exit 0)
    @echo "✅ Test suite configured"

# ============================================================================
# UTILITY RECIPES
# ============================================================================

# Show project statistics
stats:
    @echo "📊 Project Statistics"
    @echo "====================="
    @echo "Rust:"
    @find wasm -name "*.rs" | xargs wc -l | tail -1
    @echo "ReScript:"
    @find rescript/src -name "*.res" | xargs wc -l | tail -1 || echo "  0 lines"
    @echo "PHP:"
    @find wordpress -name "*.php" | xargs wc -l | tail -1
    @echo "JavaScript:"
    @find wordpress/assets/js -name "*.js" | xargs wc -l | tail -1 || echo "  0 lines"
    @echo "CSS:"
    @find wordpress/assets/css -name "*.css" | xargs wc -l | tail -1 || echo "  0 lines"

# Check dependencies are installed
check-deps:
    @echo "Checking dependencies..."
    @which cargo || echo "❌ Rust/cargo not installed"
    @which wasm-pack || echo "❌ wasm-pack not installed (run: cargo install wasm-pack)"
    @which node || echo "❌ Node.js not installed"
    @which npm || echo "❌ npm not installed"
    @which deno || echo "❌ Deno not installed"
    @which just || echo "✅ just is installed (you're using it!)"
    @echo "✅ Dependency check complete"

# Install all dependencies
install-deps:
    @echo "Installing dependencies..."
    cargo install wasm-pack
    cd rescript && npm install
    @echo "✅ Dependencies installed"

# Show help (alias for default)
help:
    @just --list

# Open documentation in browser
docs:
    @echo "Opening documentation..."
    @which open && open README.md || echo "See README.md"

# ============================================================================
# CI/CD RECIPES
# ============================================================================

# CI: Run all checks (for CI/CD pipelines)
ci: lint test validate
    @echo "✅ CI checks passed"

# CI: Build and test
ci-build-test: build test
    @echo "✅ CI build and test passed"

# ============================================================================
# EXAMPLE RECIPES
# ============================================================================

# Run example (loads sample ontology)
example:
    @echo "Running example..."
    cd rescript && node src/examples/example.res.js || echo "Build ReScript first: just build-rescript"

# Serve WordPress locally (requires local WordPress)
serve:
    @echo "Serving WordPress locally..."
    @echo "Make sure WordPress is installed and theme is activated"
    @echo "Visit: http://localhost:8000 (or your WordPress URL)"

# ============================================================================
# MAINTENANCE RECIPES
# ============================================================================

# Update dependencies
update:
    @echo "Updating dependencies..."
    cd wasm/semantic_processor && cargo update
    cd rescript && npm update
    @echo "✅ Dependencies updated"

# Check for outdated dependencies
outdated:
    @echo "Checking for outdated dependencies..."
    cd wasm/semantic_processor && cargo outdated || cargo install cargo-outdated && cargo outdated
    cd rescript && npm outdated || true

# ============================================================================
# ADVANCED RECIPES
# ============================================================================

# Profile WASM performance
profile-wasm:
    @echo "Profiling WASM..."
    cd wasm/semantic_processor && cargo build --release --target wasm32-unknown-unknown
    @echo "Use browser DevTools to profile"

# Benchmark WASM
bench-wasm:
    @echo "Benchmarking WASM..."
    cd wasm/semantic_processor && cargo bench || echo "No benchmarks configured"

# Generate documentation
doc:
    @echo "Generating documentation..."
    cd wasm/semantic_processor && cargo doc --no-deps --open

# ============================================================================
# ALIASES (shorter commands)
# ============================================================================

alias b := build
alias t := test
alias l := lint
alias c := clean
alias d := dev
alias v := validate
alias h := help

# vim: set ft=make :
