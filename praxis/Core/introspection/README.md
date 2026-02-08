# WP Praxis Introspection System

A comprehensive recursive introspection and semantic feedback system for WP Praxis symbolic workflows, implemented in Racket.

## Overview

The WP Praxis Introspection System provides deep analysis of symbolic workflows across all execution layers (YAML → Elixir → Rust → PHP → PowerShell), offering:

- **Symbolic State Inspection**: Parse and analyze symbolic structures
- **Recursive Execution Tracing**: Build execution DAGs and detect cycles
- **Semantic Integrity Analysis**: Verify contracts, types, and invariants
- **Actionable Feedback**: Generate recommendations and identify anti-patterns
- **Meta-Evaluation**: Self-inspection and quality assessment

## Features

### Core Capabilities

- ✅ **Multi-Layer Tracing**: Track execution through all WP Praxis layers
- ✅ **Dependency Analysis**: Build dependency graphs, detect cycles, topological sorting
- ✅ **Performance Profiling**: Identify bottlenecks and performance issues
- ✅ **Type Checking**: Infer and validate symbolic types
- ✅ **Contract Verification**: Ensure symbolic contracts are satisfied
- ✅ **Pattern Detection**: Identify common patterns and anti-patterns
- ✅ **Semantic Preservation**: Measure meaning preservation across layers

### Input/Output

- **Input Formats**: TOML, YAML, JSON
- **Output Formats**: Text, JSON, HTML, GraphViz DOT
- **Data Sources**: Manifest files, execution logs, PostgreSQL database

### Interfaces

- **CLI**: Command-line interface for batch processing
- **REPL**: Interactive exploration and analysis
- **HTTP API**: Web service integration (via http-server)
- **Integration**: PowerShell, Elixir, and programmatic access

## Installation

### Prerequisites

- Racket 8.0 or later
- PostgreSQL (optional, for database integration)
- GraphViz (optional, for graph visualization)

### Install from Source

```bash
cd /home/user/wp-praxis/Core/introspection
raco pkg install
```

### Install Dependencies

```bash
raco pkg install db-lib web-server-lib graph plot-lib
```

## Quick Start

### Command Line

```bash
# Basic introspection
wp-introspect -m manifest.toml

# Generate HTML report
wp-introspect -m manifest.toml -f html -o report.html

# JSON output
wp-introspect -m manifest.toml -f json -o results.json

# Verbose mode
wp-introspect -m manifest.toml -v
```

### Interactive REPL

```bash
racket repl/interactive.rkt
```

```racket
introspect> load examples/sample-workflow.toml
introspect> symbols
introspect> analyze
introspect> feedback
```

### Programmatic Use

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Load and introspect
(define results (introspect-workflow "manifest.toml"
                                     #:trace? #t
                                     #:analyze? #t
                                     #:feedback? #t))

;; Access components
(define state (hash-ref results 'state))
(define trace (hash-ref results 'trace))
(define analysis (hash-ref results 'analysis))
(define feedback (hash-ref results 'feedback))

;; Generate report
(generate-html-report results)
```

## Architecture

### Module Structure

```
introspection/
├── main.rkt                    # Main entry point
├── info.rkt                    # Package metadata
├── src/                        # Source modules
│   ├── symbolic-inspector.rkt  # Symbolic state inspection
│   ├── recursive-tracer.rkt    # Execution tracing
│   ├── semantic-analyzer.rkt   # Semantic integrity
│   ├── feedback-generator.rkt  # Feedback generation
│   ├── meta-evaluator.rkt      # Meta-evaluation
│   ├── io/                     # I/O modules
│   ├── viz/                    # Visualization
│   ├── reports/                # Reporting
│   └── analysis/               # Analysis algorithms
├── cli/                        # CLI interface
├── repl/                       # Interactive REPL
├── config/                     # Configuration
├── integration/                # Integration bridges
├── tests/                      # Test suite
├── docs/                       # Documentation
└── examples/                   # Example data
```

### Layer Flow

```
Manifest (TOML/YAML)
    ↓ [Parser]
Symbolic State
    ↓ [Inspector]
Symbol Tree + Metadata
    ↓ [Tracer]
Execution DAG
    ↓ [Analyzer]
Semantic Analysis
    ↓ [Feedback Generator]
Actionable Recommendations
    ↓ [Meta-Evaluator]
Quality Assessment
```

## Usage Examples

### Inspect Symbolic State

```bash
wp-introspect -m workflow.toml
```

### Trace Execution

```bash
wp-introspect -m workflow.toml trace
```

### Analyze Semantics

```bash
wp-introspect -m workflow.toml analyze
```

### Validate Manifest

```bash
wp-introspect -m workflow.toml validate
```

### Generate Reports

```bash
# HTML report
wp-introspect -m workflow.toml -f html -o report.html

# JSON for machine consumption
wp-introspect -m workflow.toml -f json | jq .

# GraphViz dependency graph
racket -e '(require wp-praxis-introspection)
           (define state (introspect-state (read-toml-file "workflow.toml")))
           (save-dot-file (generate-dependency-graph (hash-ref state 'symbols))
                         "deps.dot")'
dot -Tpng deps.dot -o deps.png
```

## Configuration

Edit `config/default-config.toml`:

```toml
[analysis]
depth = "full"
enable_trace = true
enable_semantic_analysis = true
enable_feedback = true

[performance]
bottleneck_threshold_multiplier = 2.0
max_dependency_depth = 10

[semantic]
preservation_threshold = 0.7
type_checking_enabled = true
```

## Integration

### From PowerShell

```powershell
# Call via bridge script
racket integration/powershell-bridge.rkt manifest.toml
```

### From Elixir

```elixir
# Use Erlang port protocol
{:ok, port} = Port.open({:spawn, "racket integration/elixir-port.rkt"}, [:binary])
Port.command(port, Jason.encode!(%{command: "introspect", manifest: "workflow.toml"}))
```

### Via HTTP API

```bash
# Start server
racket integration/http-server.rkt --port 8080

# Query
curl -X POST http://localhost:8080/introspect \
  -H "Content-Type: application/json" \
  -d '{"manifest": "workflow.toml"}'
```

## API Reference

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed API documentation.

### Core Functions

- `introspect-workflow` - Full workflow introspection
- `inspect-symbolic-state` - Inspect symbolic state
- `trace-symbolic-execution` - Trace execution
- `analyze-semantic-integrity` - Analyze semantics
- `generate-feedback-report` - Generate feedback
- `meta-evaluate` - Meta-level evaluation

### Analysis Functions

- `detect-symbolic-patterns` - Pattern detection
- `verify-symbolic-contracts` - Contract verification
- `check-type-soundness` - Type checking
- `find-dependency-cycles` - Cycle detection
- `identify-bottlenecks` - Performance profiling

## Testing

```bash
# Run all tests
raco test tests/

# Run specific test
racket tests/symbolic-inspector-test.rkt
```

## Contributing

1. Follow Racket style guide
2. Use contracts for all public functions
3. Add tests for new features
4. Update documentation

## License

GNU AGPL v3 - See LICENSE file

## Support

- Documentation: [docs/](docs/)
- Issues: File in main WP Praxis repository
- Examples: [examples/](examples/)

## Version

**0.1.0** - Early development

Last updated: 2025-11-22
