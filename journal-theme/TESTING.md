# Testing Guide

This document provides comprehensive guidance for running tests in the Sinople theme.

## Overview

Sinople implements a multi-language test suite covering:
- **PHP** (WordPress theme code) - PHPUnit
- **JavaScript/TypeScript** - Jest
- **Rust** (WebAssembly) - cargo test

## Prerequisites

### PHP Testing

```bash
# Install Composer dependencies
composer install --dev

# Install WordPress test suite
bash bin/install-wp-tests.sh wordpress_test root '' localhost latest
```

Required environment variables:
- `WP_TESTS_DIR` - Path to WordPress test library (default: `/tmp/wordpress-tests-lib`)
- `WP_CORE_DIR` - Path to WordPress core (default: `/tmp/wordpress`)

### JavaScript Testing

```bash
# Install npm dependencies
npm ci
```

### Rust Testing

```bash
# Install Rust and wasm target
rustup target add wasm32-unknown-unknown
```

## Running Tests

### Quick Start

```bash
# Run all tests (via justfile)
just test

# Quick validation before commit
just check
```

### PHP Tests

```bash
# Run all PHP tests
vendor/bin/phpunit

# Run with testdox output (human-readable)
vendor/bin/phpunit --testdox

# Run specific test file
vendor/bin/phpunit tests/php/test-setup.php

# Generate coverage report
vendor/bin/phpunit --coverage-html coverage/html --coverage-text

# Via npm
npm run test:php
```

### JavaScript Tests

```bash
# Run all JavaScript tests
npm test

# Run in watch mode (for development)
npm run test:watch

# Generate coverage report
npm run test:coverage

# Run specific test file
npm test -- accessibility.test.ts

# Update snapshots
npm test -- -u
```

### Rust Tests

```bash
cd assets/wasm

# Run all tests
cargo test

# Run tests verbosely
cargo test -- --nocapture

# Run specific test
cargo test test_sanitize_html

# Run tests for WASM target
cargo test --target wasm32-unknown-unknown
```

## Test Structure

### PHP Tests (`tests/php/`)

```
tests/php/
├── SinopleTestCase.php          # Base test case class
├── test-setup.php               # Setup & utility functions
├── test-semantic.php            # JSON-LD, Open Graph, RDFa
├── test-accessibility.php       # WCAG compliance, ARIA
├── test-security.php            # Security headers, sanitization
├── test-indieweb.php            # Microformats, webmentions
└── test-serialization.php       # NDJSON, FlatBuffers, Cap'n Proto
```

#### Base Test Case

All test classes extend `SinopleTestCase`, which provides:

```php
// Create test post
$post_id = $this->create_test_post([
    'post_title' => 'Test Post',
    'post_type' => 'field_note',
]);

// Create test user
$user_id = $this->create_test_user('author');

// Assert valid JSON-LD
$this->assertValidJsonLd($json_ld_string);

// Assert microformats present
$this->assertHasMicroformat($html, 'h-entry');

// Assert ARIA attributes
$this->assertHasAriaAttribute($html, 'aria-label');
```

### JavaScript Tests (`tests/js/`)

```
tests/js/
├── setup.ts                     # Jest setup & mocks
├── accessibility.test.ts        # Font size, theme toggle, keyboard nav
├── features.test.ts             # Feature detection
└── wasm.test.ts                 # WebAssembly integration
```

#### Test Utilities

```typescript
// Mock window.sinople global
window.sinople = {
  features: { viewTransitions: true, wasm: true },
  ajaxurl: '/wp-admin/admin-ajax.php',
  nonce: 'test-nonce',
};

// Mock localStorage
localStorage.setItem('sinople_theme', 'dark');

// Mock matchMedia
window.matchMedia = jest.fn()...
```

## Coverage Targets

### Bronze Level Requirements (Current)

- **PHP**: Target >80% coverage
- **JavaScript**: Target >80% coverage
- **Rust**: Target >80% coverage

### Checking Coverage

```bash
# PHP coverage
vendor/bin/phpunit --coverage-text

# JavaScript coverage
npm run test:coverage

# View HTML reports
open coverage/html/index.html       # PHP
open coverage/js/index.html         # JavaScript
```

## Continuous Integration

### GitHub Actions

Tests run automatically on:
- Every push to `main` or `develop`
- Every pull request
- Weekly schedule (Mondays at 9am UTC)

View: `.github/workflows/ci.yml`

### GitLab CI

Tests run in parallel across:
- 3 PHP versions (8.1, 8.2, 8.3)
- Multiple WordPress versions (6.4, 6.5, latest)
- Security scans
- Container builds

View: `.gitlab-ci.yml`

## Writing Tests

### PHP Test Example

```php
class Test_My_Feature extends SinopleTestCase {
    /**
     * Test feature works correctly
     */
    public function test_feature_works(): void {
        $post_id = $this->create_test_post();

        $result = my_feature_function($post_id);

        $this->assertTrue($result);
        $this->assertEquals('expected', get_post_meta($post_id, 'key', true));
    }
}
```

### JavaScript Test Example

```typescript
describe('My Feature', () => {
  beforeEach(() => {
    document.body.innerHTML = `<div id="test"></div>`;
  });

  test('feature works correctly', () => {
    const element = document.getElementById('test');
    myFeature(element);

    expect(element.classList.contains('active')).toBe(true);
  });
});
```

### Rust Test Example

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_feature_works() {
        let result = my_feature("input");
        assert_eq!(result, "expected");
    }
}
```

## Debugging Tests

### PHP

```bash
# Run with verbose output
vendor/bin/phpunit --verbose

# Run single test method
vendor/bin/phpunit --filter test_method_name

# Enable debugging output
vendor/bin/phpunit --debug
```

### JavaScript

```bash
# Run with verbose output
npm test -- --verbose

# Debug in Node
node --inspect-brk node_modules/.bin/jest --runInBand

# Run specific test
npm test -- -t "test name pattern"
```

### Rust

```bash
# Show println! output
cargo test -- --nocapture

# Run ignored tests
cargo test -- --ignored

# Show test execution time
cargo test -- --show-output
```

## Common Issues

### WordPress Test Suite Not Found

```bash
# Install WordPress test suite
bash bin/install-wp-tests.sh wordpress_test root '' localhost latest

# Or set custom path
export WP_TESTS_DIR=/path/to/wordpress-tests-lib
```

### Database Connection Issues

```bash
# Check MySQL/MariaDB is running
systemctl status mariadb

# Create test database manually
mysql -u root -e "CREATE DATABASE wordpress_test"
```

### Jest Configuration Issues

```bash
# Clear Jest cache
npm test -- --clearCache

# Run with no cache
npm test -- --no-cache
```

## Test Data

### Fixtures

Test data and fixtures should be placed in:
- `tests/php/fixtures/` - PHP test data
- `tests/js/__fixtures__/` - JavaScript test data

### Factories

Use WordPress factory methods in PHP tests:

```php
// Create post
$this->factory()->post->create(['post_title' => 'Test']);

// Create user
$this->factory()->user->create(['role' => 'editor']);

// Create term
$this->factory()->term->create(['taxonomy' => 'emotion']);
```

## Performance Testing

```bash
# Run with timing information
vendor/bin/phpunit --log-junit junit.xml

# Rust benchmarks
cd assets/wasm && cargo bench
```

## Accessibility Testing

For manual accessibility testing:

```bash
# Run accessibility test scripts
npm run test:a11y

# Tools used:
# - WAVE (https://wave.webaim.org/)
# - axe DevTools (browser extension)
# - NVDA/JAWS/VoiceOver screen readers
```

## Security Testing

```bash
# Run security tests
npm run test:security

# Manual security scans
just scan
just audit
```

## Best Practices

1. **Write descriptive test names** - Test names should clearly describe what is being tested
2. **One assertion per test** - Keep tests focused and atomic
3. **Use factories** - Don't create test data manually
4. **Clean up after tests** - Use `tearDown()` methods
5. **Mock external dependencies** - Don't rely on external APIs
6. **Test edge cases** - Empty inputs, null values, boundary conditions
7. **Keep tests fast** - Slow tests discourage running them frequently
8. **Test behavior, not implementation** - Focus on what, not how

## Resources

- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [WordPress Testing Handbook](https://make.wordpress.org/core/handbook/testing/)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Rust Testing Guide](https://doc.rust-lang.org/book/ch11-00-testing.html)
- [Testing Library](https://testing-library.com/)

## Contributing

When contributing tests:

1. Ensure tests pass locally before pushing
2. Add tests for new features
3. Update tests when modifying existing features
4. Aim for >80% code coverage
5. Follow existing test patterns and conventions

See `CONTRIBUTING.md` for more details.
