<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# TEST-NEEDS.md — wordpress-tools

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| Zig FFI tests | 3 | Multiple subproject FFI layers (secured, plugin-mapper, etc.) |
| PHP unit tests | 3 | `plugin-conflict-mapper/tests/unit/test-*.php` |
| PHP integration tests | 2 | `plugin-conflict-mapper/tests/integration/test-*.php` |
| PHP validation tests | 2 | php-aegis validation suite |

## What's Covered

- [x] Zig FFI integration tests
- [x] PHP unit test framework
- [x] REST API integration tests
- [x] Cache validation tests
- [x] XSS security tests (CF7)
- [x] WordPress compatibility tests

## Still Missing (for CRG B+)

- [ ] Plugin conflict fuzzing
- [ ] Security property tests
- [ ] Performance benchmarks
- [ ] Multi-version WordPress testing
- [ ] End-to-end plugin workflow tests

## Run Tests

```bash
cd /var/mnt/eclipse/repos/wordpress-tools && bash plugin-conflict-mapper/bin/install-wp-tests.sh && cd plugin-conflict-mapper && phpunit
```
