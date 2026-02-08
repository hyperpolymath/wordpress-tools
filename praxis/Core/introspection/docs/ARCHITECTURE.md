# Introspection System Architecture

## Overview

The WP Praxis Introspection System is designed as a modular, functional system for recursive analysis of symbolic workflows across multiple execution layers.

## Design Principles

1. **Functional Purity**: Immutable data structures, no side effects in core analysis
2. **Modularity**: Each component has a single, well-defined responsibility
3. **Contracts**: All public functions use Racket contracts for type safety
4. **Recursion**: Natural recursive descent through symbolic structures
5. **Traceability**: Maintain semantic context through all transformations

## Component Architecture

### 1. Core Introspection Modules

#### Symbolic Inspector (`symbolic-inspector.rkt`)

**Purpose**: Parse and analyze symbolic state structures

**Key Functions**:
- `inspect-symbolic-state`: Main entry point for state inspection
- `extract-symbol-metadata`: Extract metadata from symbols
- `infer-symbol-type`: Type inference based on context
- `validate-symbol-structure`: Structural validation
- `detect-symbolic-patterns`: Pattern detection in symbol trees

**Data Structures**:
```racket
(struct symbol-node
  (name type context metadata children)
  #:transparent)

(struct inspection-result
  (symbols metadata type-map patterns warnings statistics)
  #:transparent)
```

**Algorithm**: Recursive descent through symbol tree, building metadata maps and type information at each level.

#### Recursive Tracer (`recursive-tracer.rkt`)

**Purpose**: Trace execution flow across all WP Praxis layers

**Key Functions**:
- `trace-symbolic-execution`: Build complete execution trace
- `build-execution-dag`: Create directed acyclic graph of execution
- `detect-recursion-cycles`: Find circular dependencies
- `measure-semantic-preservation`: Quantify meaning preservation
- `identify-bottlenecks`: Find performance issues

**Layers Traced**:
1. Manifest (YAML/TOML)
2. Parser (TypeScript/Elixir)
3. Orchestrator (Elixir)
4. Symbolic Engine (PowerShell)
5. Injector (Rust)
6. WordPress Integration (PHP)

**Data Flow**:
```
Input Manifest → Parse → Orchestrate → Symbolic Ops → Inject → WP Execute
     ↓              ↓          ↓             ↓           ↓         ↓
   Trace         Trace      Trace         Trace       Trace     Trace
     ↓              ↓          ↓             ↓           ↓         ↓
                    Execution DAG (aggregated)
```

#### Semantic Analyzer (`semantic-analyzer.rkt`)

**Purpose**: Verify semantic integrity across transformations

**Key Functions**:
- `analyze-semantic-integrity`: Main analysis entry point
- `compare-layer-semantics`: Compare input/output semantics
- `detect-semantic-drift`: Find meaning loss
- `verify-symbolic-contracts`: Contract verification
- `check-type-soundness`: Type checking
- `validate-invariants`: Invariant validation

**Analysis Dimensions**:
- **Contract Violations**: Broken symbolic contracts
- **Type Errors**: Type mismatches
- **Invariant Violations**: Broken invariants (cycles, duplicates)
- **Semantic Drift**: Meaning lost in transformation

**Integrity Score**: Computed as `1.0 - (0.1 × total_issues)`, clamped to [0, 1]

#### Feedback Generator (`feedback-generator.rkt`)

**Purpose**: Generate actionable recommendations

**Key Functions**:
- `generate-feedback-report`: Main feedback generation
- `suggest-optimizations`: Performance optimizations
- `identify-antipatterns`: Anti-pattern detection
- `propose-refactorings`: Refactoring suggestions
- `prioritize-feedback`: Priority-based sorting

**Feedback Categories**:
- **Critical**: Blocking issues (cycles, contract violations)
- **High**: Important issues (performance, type errors)
- **Medium**: Quality issues (complexity, depth)
- **Low**: Style and best practices

**Anti-Patterns Detected**:
- God Symbol (>10 parameters)
- Shotgun Surgery (>5 dependencies)
- Primitive Obsession (delimited strings)

#### Meta-Evaluator (`meta-evaluator.rkt`)

**Purpose**: Self-inspection of the introspection system

**Key Functions**:
- `meta-evaluate`: Meta-level evaluation
- `self-inspect-introspection`: System self-inspection
- `meta-circular-eval`: Meta-circular evaluation
- `analyze-analysis-quality`: Quality assessment
- `evaluate-introspection-coverage`: Coverage analysis

**Quality Metrics**:
- **Completeness**: Percentage of analysis modules executed
- **Precision**: False positive rate
- **Actionability**: Percentage of feedback items with actions

### 2. I/O Modules

#### JSON Reader (`io/json-reader.rkt`)

- Read/write JSON files
- Parse JSON strings
- Validate JSON structure
- Extract nested fields

#### TOML Reader (`io/toml-reader.rkt`)

- Simple TOML parser
- Section hierarchy support
- Type inference (string, number, boolean, array)
- Manifest validation

#### Database Connector (`io/database-connector.rkt`)

- PostgreSQL connection via Racket `db` library
- Query symbolic state from Ecto schemas
- Execution history retrieval
- Layer statistics aggregation

#### Log Parser (`io/log-parser.rkt`)

- Multi-format log parsing (PowerShell, Elixir, Rust, PHP)
- Timestamp extraction and normalization
- Log level classification
- Error and warning detection

### 3. Visualization & Reporting

#### Graph Generator (`viz/graph-generator.rkt`)

- DOT format generation for GraphViz
- Dependency graph visualization
- Execution DAG rendering
- Layer flow diagrams

#### Tree Printer (`viz/tree-printer.rkt`)

- Pretty-print hierarchical data
- Symbol tree visualization
- Dependency tree traversal
- Tree statistics

#### HTML Reporter (`reports/html-reporter.rkt`)

- Complete HTML report generation
- CSS styling
- Tabular data presentation
- Priority color coding

#### JSON Reporter (`reports/json-reporter.rkt`)

- JSON serialization
- Machine-readable output
- API integration support

### 4. Analysis Algorithms

#### Pattern Matcher (`analysis/pattern-matcher.rkt`)

- Pattern matching on symbolic structures
- Wildcard support
- Instance extraction
- Common pattern library

#### Type Checker (`analysis/type-checker.rkt`)

- Type inference
- Type compatibility checking
- Schema validation
- Error reporting

#### Dependency Analyzer (`analysis/dependency-analyzer.rkt`)

- Dependency graph construction
- Cycle detection (DFS-based)
- Topological sorting
- Root/leaf identification

#### Performance Profiler (`analysis/performance-profiler.rkt`)

- Execution profiling
- Bottleneck detection
- Percentile calculations
- Layer performance analysis

## Data Flow

### Introspection Workflow

```
1. Load Manifest
   ├─→ Read TOML/YAML file
   └─→ Parse into jsexpr

2. Inspect State
   ├─→ Extract symbols
   ├─→ Build metadata map
   ├─→ Infer types
   ├─→ Detect patterns
   └─→ Compute statistics

3. Trace Execution (optional)
   ├─→ Collect trace data
   ├─→ Build execution DAG
   ├─→ Detect cycles
   └─→ Measure preservation

4. Analyze Semantics (optional)
   ├─→ Verify contracts
   ├─→ Check types
   ├─→ Validate invariants
   └─→ Detect drift

5. Generate Feedback (optional)
   ├─→ Analyze state
   ├─→ Analyze trace
   ├─→ Analyze semantics
   ├─→ Suggest optimizations
   ├─→ Identify anti-patterns
   └─→ Prioritize items

6. Meta-Evaluate (optional)
   ├─→ Assess coverage
   ├─→ Assess quality
   ├─→ Check consistency
   └─→ Generate meta-feedback

7. Output Results
   ├─→ Text (tree printer)
   ├─→ JSON (machine-readable)
   ├─→ HTML (human-readable)
   └─→ DOT (graph visualization)
```

## Extension Points

### Adding New Analysis

1. Create module in `src/analysis/`
2. Implement analysis function with contract
3. Export function in module
4. Import in `main.rkt`
5. Add to introspection workflow
6. Add tests in `tests/`

### Adding New Input Format

1. Create parser in `src/io/`
2. Implement reader function
3. Convert to standard jsexpr format
4. Add validation
5. Export reader
6. Update main.rkt

### Adding New Output Format

1. Create reporter in `src/reports/`
2. Implement format function
3. Handle all result types
4. Add to CLI options
5. Export reporter

## Performance Considerations

- **Lazy Evaluation**: Use `stream` for large datasets
- **Memoization**: Cache expensive computations
- **Parallel Analysis**: Use `future` for independent analyses
- **Incremental Updates**: Only re-analyze changed symbols

## Error Handling

- All public functions use `with-handlers` for graceful degradation
- Contracts provide compile-time type checking
- Validation warnings collected, not thrown
- Introspection continues even with partial failures

## Testing Strategy

- **Unit Tests**: Each module has corresponding test file
- **Integration Tests**: End-to-end workflow tests
- **Property Tests**: QuickCheck-style property tests
- **Performance Tests**: Benchmark critical paths

## Security Considerations

- No arbitrary code execution
- File access limited to specified paths
- Database queries parameterized
- Input validation on all external data
