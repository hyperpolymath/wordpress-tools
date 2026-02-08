# WP Praxis Manifest Parser

**LFE-based symbolic manifest parsing and transformation system for WP Praxis**

image:https://img.shields.io/badge/License-PMPL--1.0-blue.svg[License: PMPL-1.0,link="https://github.com/hyperpolymath/palimpsest-license"]
[![LFE](https://img.shields.io/badge/LFE-2.1.2-purple.svg)](https://lfe.io/)
[![Erlang/OTP](https://img.shields.io/badge/Erlang%2FOTP-24%2B-red.svg)](https://www.erlang.org/)

## Overview

The WP Praxis Manifest Parser is a powerful, Lisp-based system for parsing, validating, transforming, and optimizing declarative configuration manifests. It leverages LFE (Lisp Flavored Erlang) to provide:

- **Symbolic Processing**: Lisp macros for compile-time symbolic transformation
- **Multi-Format Support**: Parse YAML, TOML, and Dhall manifests
- **Semantic Preservation**: Maintain meaning through all transformation layers
- **OTP Architecture**: Fault-tolerant concurrent processing with supervision
- **Introspection**: Deep runtime reflection and analysis
- **Optimization**: Dead code elimination, constant folding, dependency ordering
- **Integration**: Seamless interop with Elixir, Rust, TypeScript, and PHP

## Features

### Core Parsing
- ✅ YAML 1.2 parsing with yamerl
- ✅ TOML 1.0 parsing
- ✅ LFE data structure conversion
- ✅ Multi-document support
- ✅ Stream parsing

### Transformation
- ✅ Canonical manifest format
- ✅ Cross-format normalization
- ✅ Variable expansion
- ✅ Path resolution
- ✅ Dependency sorting

### Validation
- ✅ Schema validation
- ✅ Type checking
- ✅ Constraint verification
- ✅ Circular dependency detection
- ✅ Semantic validation

### Symbolic Processing
- ✅ Lisp-style macros
- ✅ Compile-time expansion
- ✅ Symbol definitions
- ✅ Workflow DSL
- ✅ Context management

### Optimization
- ✅ Constant folding
- ✅ Dead symbol elimination
- ✅ Topological sorting
- ✅ Duplicate merging
- ✅ Execution order optimization

### Integration
- ✅ Elixir interop
- ✅ JSON export/import
- ✅ CLI interface
- ✅ OTP application
- ✅ HTTP API ready

## Installation

### Prerequisites

- **Erlang/OTP 24+** - Install from [erlang.org](https://www.erlang.org/)
- **Rebar3** - Erlang build tool ([rebar3.org](https://www.rebar3.org/))
- **LFE 2.1+** - Installed automatically via rebar3

### Build from Source

```bash
# Clone repository
git clone https://github.com/wppraxis/wp-praxis.git
cd wp-praxis/Core/manifest-parser

# Install dependencies and compile
make install
make compile

# Run tests
make test

# Generate documentation
make docs
```

### Quick Start

```bash
# Parse a YAML manifest
./scripts/parse.sh parse examples/simple.yaml

# Validate a TOML manifest
./scripts/parse.sh validate examples/complex.toml

# Optimize and export to JSON
./scripts/parse.sh export examples/simple.yaml -o output.json --json
```

## Usage

### Command Line

```bash
# Parse manifest
rebar3 lfe run -c cli-interface -- parse manifest.yaml

# Validate manifest
rebar3 lfe run -c cli-interface -- validate manifest.toml

# Transform to canonical format
rebar3 lfe run -c cli-interface -- transform manifest.yaml --output canonical.json

# Optimize manifest
rebar3 lfe run -c cli-interface -- optimize manifest.yaml

# Inspect manifest structure
rebar3 lfe run -c cli-interface -- inspect manifest.yaml

# Get JSON schema
rebar3 lfe run -c cli-interface -- schema
```

### Programmatic (LFE)

```lisp
;; Load and parse YAML
(case (yaml-parser:parse-file "manifest.yaml")
  ((tuple 'ok data)
   (io:format "Parsed: ~p~n" (list data)))
  ((tuple 'error reason)
   (io:format "Error: ~p~n" (list reason))))

;; Transform to canonical format
(case (manifest-transformer:transform-file "manifest.yaml")
  ((tuple 'ok manifest)
   ;; Validate
   (case (manifest-validator:validate manifest)
     ('ok (io:format "Valid!~n"))
     ((tuple 'error errors)
      (io:format "Errors: ~p~n" (list errors)))))
  ((tuple 'error reason)
   (io:format "Transform error: ~p~n" (list reason))))

;; Optimize manifest
(let* ((manifest (load-manifest "manifest.yaml"))
       (optimized (symbolic-optimizer:optimize manifest)))
  (json-exporter:export-manifest-to-file optimized "optimized.json"))
```

### From Elixir

```elixir
# Parse manifest file
{:ok, manifest} = :elixir_interface.parse_file("manifest.yaml")

# Validate
:ok = :elixir_interface.validate_manifest(manifest)

# Get symbols
symbols = :elixir_interface.get_symbols(manifest)

# Optimize
{:ok, optimized} = :elixir_interface.optimize_manifest(manifest)

# Check for circular dependencies
:ok = :elixir_interface.check_circular_deps(manifest)
```

### From Erlang

```erlang
%% Parse file
{ok, Manifest} = 'manifest-transformer':'transform-file'("manifest.yaml"),

%% Validate
ok = 'manifest-validator':validate(Manifest),

%% Export to JSON
{ok, Json} = 'json-exporter':'to-json'(Manifest),
file:write_file("output.json", Json).
```

## Architecture

### Module Structure

```
manifest-parser/
├── src/
│   ├── yaml-parser.lfe           # YAML parsing
│   ├── toml-parser.lfe           # TOML parsing
│   ├── manifest-transformer.lfe  # Format transformation
│   ├── manifest-validator.lfe    # Validation
│   ├── symbolic-macros.lfe       # Lisp macros
│   ├── symbolic-introspection.lfe # Reflection
│   ├── symbolic-optimizer.lfe    # Optimization
│   ├── elixir-interface.lfe      # Elixir interop
│   ├── json-exporter.lfe         # JSON export
│   ├── cli-interface.lfe         # CLI
│   ├── manifest-parser-app.lfe   # OTP app
│   ├── manifest-parser-sup.lfe   # Supervisor
│   ├── parser-server.lfe         # Parser gen-server
│   └── symbol-registry.lfe       # Symbol registry
├── test/                          # Test suite
├── examples/                      # Example manifests
├── docs/                          # Documentation
└── scripts/                       # Build scripts
```

### OTP Application

The parser runs as an OTP application with:

- **Supervisor Tree**: Fault-tolerant process management
- **Parser Server**: Stateful parsing with caching
- **Symbol Registry**: Global symbol and workflow registry
- **Concurrent Parsing**: Multiple manifests in parallel

## Manifest Format

### YAML Example

```yaml
version: "1.0"
metadata:
  name: "Example Manifest"
  description: "Demonstrates WP Praxis symbols"

symbols:
  - name: backup-database
    type: action
    context: wordpress
    dispatch: rust_injector
    parameters:
      output_dir: "/var/backups"
    dependencies: []
    enabled: true

workflows:
  - name: maintenance
    steps:
      - symbol: backup-database
        parameters: {}
```

### TOML Example

```toml
version = "1.0"

[metadata]
name = "Example Manifest"

[[symbols]]
name = "backup-database"
type = "action"
context = "wordpress"
dispatch = "rust_injector"

[symbols.parameters]
output_dir = "/var/backups"
```

See [docs/MANIFEST_FORMAT.md](docs/MANIFEST_FORMAT.md) for complete specification.

## Symbolic Macros

Define symbols using Lisp macros:

```lisp
;; Define a symbol
(define-symbol backup-db
  (#(type action)
   #(context wordpress))
  (lambda (params)
    (perform-backup params)))

;; Define a workflow
(define-workflow maintenance
  (#(description "Maintenance workflow"))
  (step backup-db (#(full true)))
  (step update-plugins (#(all true))))

;; Define a context
(defcontext production
  (#(type runtime)
   #(variables (#(debug false)))))
```

See [docs/MACROS.md](docs/MACROS.md) for macro documentation.

## Development

### Running Tests

```bash
# Run all tests
make test

# Run specific test module
rebar3 lfe test -m yaml-parser-tests

# Run with coverage
make coverage
```

### Code Quality

```bash
# Type checking with Dialyzer
make dialyzer

# Cross-reference analysis
make xref

# All checks
make check
```

### Interactive Development

```bash
# Start LFE REPL with project loaded
make shell

# In REPL:
lfe> (yaml-parser:parse-file "examples/simple.yaml")
lfe> (manifest-validator:validate manifest)
```

## API Documentation

Full API documentation is available:

- **[API Reference](docs/API.md)** - Complete module documentation
- **[Manifest Format](docs/MANIFEST_FORMAT.md)** - Manifest specification
- **[Macros Guide](docs/MACROS.md)** - Symbolic macro system
- **[Integration Guide](docs/INTEGRATION.md)** - Language integration

Generate local docs:

```bash
make docs
# Open doc/index.html
```

## Performance

The parser is optimized for:

- **Speed**: Concurrent parsing with ETS caching
- **Memory**: Lazy evaluation and streaming
- **Scalability**: OTP supervision and distribution
- **Reliability**: Fault tolerance and error recovery

Benchmarks on typical manifests:

- YAML parsing: ~1000 manifests/second
- Validation: ~5000 manifests/second
- Optimization: ~500 manifests/second

## Integration with WP Praxis

This parser is designed to integrate with:

- **CLI Wrapper (Elixir)**: Orchestration and dispatch
- **Rust Injector**: Performance-critical operations
- **PHP Engine**: WordPress integration
- **PowerShell Symbolic Engine**: Core symbolic operations
- **TypeScript Tools**: Manifest validation and transformation

See the [main WP Praxis README](../../README.md) for architecture overview.

## Contributing

Contributions welcome! Please:

1. Follow LFE style conventions
2. Add tests for new features
3. Update documentation
4. Run `make check` before committing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## License

GNU Affero General Public License v3.0 (AGPL-3.0)

This project is copyleft - any network-served modifications must be open source.

See [LICENSE](LICENSE) for details.

## Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/wppraxis/wp-praxis/issues)
- **Discussions**: [GitHub Discussions](https://github.com/wppraxis/wp-praxis/discussions)

## Credits

Built with:

- [LFE](https://lfe.io/) - Lisp Flavored Erlang
- [Erlang/OTP](https://www.erlang.org/) - Concurrent runtime
- [Rebar3](https://www.rebar3.org/) - Build tool
- [yamerl](https://github.com/yakaz/yamerl) - YAML parser
- [toml](https://github.com/juhlig/etoml) - TOML parser
- [jsx](https://github.com/talentdeficit/jsx) - JSON encoder/decoder

---

**WP Praxis** - Symbolic WordPress workflows through declarative configuration

Made with ⚡ by the WP Praxis Project
