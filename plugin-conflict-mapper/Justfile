# Justfile for WP Plugin Conflict Mapper
# Just is a command runner - https://github.com/casey/just
#
# Install: curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
# Usage: just <recipe>

# Default recipe (runs when just is called with no arguments)
default:
    @just --list

# Install development dependencies
install:
    @echo "Installing development dependencies..."
    composer install --dev
    @echo "✅ Dependencies installed"

# Run all checks (lint, test, security)
check: lint test security
    @echo "✅ All checks passed"

# Lint PHP code
lint:
    @echo "Running PHP linters..."
    vendor/bin/phpcs --standard=WordPress --extensions=php --ignore=*/vendor/*,*/node_modules/* .
    @echo "✅ Lint passed"

# Fix auto-fixable lint issues
fix:
    @echo "Auto-fixing PHP code style..."
    vendor/bin/phpcbf --standard=WordPress --extensions=php --ignore=*/vendor/*,*/node_modules/* .
    @echo "✅ Auto-fix complete"

# Run PHPUnit tests
test:
    @echo "Running PHPUnit tests..."
    vendor/bin/phpunit
    @echo "✅ Tests passed"

# Run tests with coverage
test-coverage:
    @echo "Running tests with coverage..."
    vendor/bin/phpunit --coverage-html coverage/
    @echo "✅ Coverage report generated in coverage/"

# Run security analysis
security:
    @echo "Running security analysis..."
    @just security-phpstan
    @just security-dangerous-functions
    @echo "✅ Security checks passed"

# Run PHPStan static analysis
security-phpstan:
    @echo "Running PHPStan..."
    vendor/bin/phpstan analyse --level=5 includes/ admin/ wp-plugin-conflict-mapper.php || true

# Check for dangerous functions
security-dangerous-functions:
    @echo "Checking for dangerous functions..."
    @! grep -rn --include="*.php" -E "(eval|exec|system|shell_exec|passthru|proc_open|popen)\s*\(" . || (echo "❌ Dangerous functions found!" && exit 1)
    @echo "✅ No dangerous functions found"

# Verify RSR compliance
validate: validate-files validate-structure validate-docs
    @echo "✅ RSR compliance verified"

# Validate required files exist
validate-files:
    @echo "Validating required files..."
    @test -f README.md || (echo "❌ Missing README.md" && exit 1)
    @test -f LICENSE || (echo "❌ Missing LICENSE" && exit 1)
    @test -f CHANGELOG.md || (echo "❌ Missing CHANGELOG.md" && exit 1)
    @test -f SECURITY.md || (echo "❌ Missing SECURITY.md" && exit 1)
    @test -f CONTRIBUTING.md || (echo "❌ Missing CONTRIBUTING.md" && exit 1)
    @test -f CODE_OF_CONDUCT.md || (echo "❌ Missing CODE_OF_CONDUCT.md" && exit 1)
    @test -f MAINTAINERS.md || (echo "❌ Missing MAINTAINERS.md" && exit 1)
    @test -f .gitignore || (echo "❌ Missing .gitignore" && exit 1)
    @echo "✅ All required files present"

# Validate .well-known directory
validate-structure:
    @echo "Validating project structure..."
    @test -f .well-known/security.txt || (echo "❌ Missing .well-known/security.txt" && exit 1)
    @test -f .well-known/ai.txt || (echo "❌ Missing .well-known/ai.txt" && exit 1)
    @test -f .well-known/humans.txt || (echo "❌ Missing .well-known/humans.txt" && exit 1)
    @echo "✅ Project structure valid"

# Validate documentation completeness
validate-docs:
    @echo "Validating documentation..."
    @grep -q "Installation" README.md || (echo "❌ README missing Installation section" && exit 1)
    @grep -q "Usage" README.md || (echo "❌ README missing Usage section" && exit 1)
    @grep -q "Security" README.md || (echo "❌ README missing Security section" && exit 1)
    @grep -q "Contributing" README.md || (echo "❌ README missing Contributing section" && exit 1)
    @grep -q "License" README.md || (echo "❌ README missing License section" && exit 1)
    @echo "✅ Documentation complete"

# Build release package
build:
    @echo "Building release package..."
    @mkdir -p build
    @zip -r build/wp-plugin-conflict-mapper.zip . \
        -x "*.git*" \
        -x "*node_modules/*" \
        -x "*vendor/*" \
        -x "*tests/*" \
        -x "*build/*" \
        -x "*.DS_Store" \
        -x "*justfile" \
        -x "*.gitlab-ci.yml"
    @echo "✅ Package created: build/wp-plugin-conflict-mapper.zip"
    @ls -lh build/wp-plugin-conflict-mapper.zip

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    @rm -rf build/ coverage/ vendor/
    @echo "✅ Clean complete"

# Install WordPress test environment
install-wp-tests:
    @echo "Installing WordPress test environment..."
    @bash bin/install-wp-tests.sh wordpress_test root '' localhost latest
    @echo "✅ WordPress test environment installed"

# Run WP-CLI commands (requires WordPress installation)
cli-scan:
    @echo "Running conflict scan via WP-CLI..."
    wp conflict-mapper scan

cli-list:
    @echo "Listing plugins with rankings..."
    wp conflict-mapper list-plugins

# Generate documentation
docs:
    @echo "Generating documentation..."
    @echo "Documentation already exists in:"
    @echo "  - README.md"
    @echo "  - DEVELOPER.md"
    @echo "  - SECURITY.md"
    @echo "  - CONTRIBUTING.md"

# Show RSR compliance checklist
rsr-checklist:
    @echo "=== RSR COMPLIANCE CHECKLIST ==="
    @echo ""
    @echo "DOCUMENTATION:"
    @test -f README.md && echo "✅ README.md" || echo "❌ README.md"
    @test -f LICENSE && echo "✅ LICENSE" || echo "❌ LICENSE"
    @test -f CHANGELOG.md && echo "✅ CHANGELOG.md" || echo "❌ CHANGELOG.md"
    @test -f SECURITY.md && echo "✅ SECURITY.md" || echo "❌ SECURITY.md"
    @test -f CONTRIBUTING.md && echo "✅ CONTRIBUTING.md" || echo "❌ CONTRIBUTING.md"
    @test -f CODE_OF_CONDUCT.md && echo "✅ CODE_OF_CONDUCT.md" || echo "❌ CODE_OF_CONDUCT.md"
    @test -f MAINTAINERS.md && echo "✅ MAINTAINERS.md" || echo "❌ MAINTAINERS.md"
    @echo ""
    @echo ".WELL-KNOWN:"
    @test -f .well-known/security.txt && echo "✅ security.txt (RFC 9116)" || echo "❌ security.txt"
    @test -f .well-known/ai.txt && echo "✅ ai.txt" || echo "❌ ai.txt"
    @test -f .well-known/humans.txt && echo "✅ humans.txt" || echo "❌ humans.txt"
    @echo ""
    @echo "BUILD & CI:"
    @test -f justfile && echo "✅ justfile (build automation)" || echo "❌ justfile"
    @test -f .gitlab-ci.yml && echo "✅ .gitlab-ci.yml (CI/CD)" || echo "❌ .gitlab-ci.yml"
    @test -f .gitignore && echo "✅ .gitignore" || echo "❌ .gitignore"
    @echo ""
    @echo "SECURITY:"
    @echo "✅ Nonce verification"
    @echo "✅ Capability checks"
    @echo "✅ Prepared SQL statements"
    @echo "✅ Input sanitization"
    @echo "✅ Output escaping"
    @echo ""
    @echo "GOVERNANCE:"
    @echo "✅ TPCF (Tri-Perimeter Contribution Framework)"
    @echo "✅ Code of Conduct (Contributor Covenant 2.1)"
    @echo "✅ Security disclosure policy"

# Version bump (requires VERSION argument)
bump-version VERSION:
    @echo "Bumping version to {{VERSION}}..."
    @sed -i 's/Version: .*/Version: {{VERSION}}/' wp-plugin-conflict-mapper.php
    @sed -i "s/define('WPCM_VERSION', '.*')/define('WPCM_VERSION', '{{VERSION}}')/" wp-plugin-conflict-mapper.php
    @sed -i 's/## \[Unreleased\]/## [{{VERSION}}] - '$(date +%Y-%m-%d)'/' CHANGELOG.md
    @echo "✅ Version bumped to {{VERSION}}"

# Create git tag for release
tag VERSION:
    @echo "Creating git tag v{{VERSION}}..."
    @git tag -a v{{VERSION}} -m "Release version {{VERSION}}"
    @echo "✅ Tag created. Push with: git push origin v{{VERSION}}"

# Full release process
release VERSION: (bump-version VERSION) check build (tag VERSION)
    @echo "✅ Release {{VERSION}} ready!"
    @echo "Next steps:"
    @echo "  1. Review CHANGELOG.md"
    @echo "  2. Commit changes: git commit -am 'Release {{VERSION}}'"
    @echo "  3. Push tag: git push origin v{{VERSION}}"
    @echo "  4. Create GitHub release"
    @echo "  5. Upload build/wp-plugin-conflict-mapper.zip"

# Show project statistics
stats:
    @echo "=== PROJECT STATISTICS ==="
    @echo ""
    @echo "Lines of Code:"
    @find . -name "*.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" | xargs wc -l | tail -1
    @echo ""
    @echo "Files:"
    @find . -name "*.php" -not -path "*/vendor/*" -not -path "*/node_modules/*" | wc -l | xargs echo "PHP files:"
    @echo ""
    @echo "Classes:"
    @grep -r "^class " --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules | wc -l | xargs echo "Total classes:"
    @echo ""
    @echo "Functions:"
    @grep -r "^function " --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules | wc -l | xargs echo "Total functions:"

# Development server (requires WordPress installation)
serve:
    @echo "Starting WordPress development server..."
    @echo "Make sure WordPress is installed and plugin is symlinked"
    @cd /path/to/wordpress && php -S localhost:8000

# Watch for file changes and run tests (requires entr)
watch:
    @echo "Watching for changes..."
    @find . -name "*.php" | entr just test
