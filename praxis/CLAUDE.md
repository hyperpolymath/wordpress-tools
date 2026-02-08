# CLAUDE.md - AI Assistant Guide for WP Praxis

## Project Overview

**WP Praxis** is a modular symbolic system for WordPress workflows that combines recursive logic, metadata-driven configuration, and distributed execution across multiple programming languages. This is a meta-programming framework designed to transform WordPress development through symbolic reasoning and introspectable design patterns.

**Core Philosophy**: Preserve semantic integrity across recursive workflows by dispatching symbolic logic from declarative manifests into modular execution layers.

## Quick Reference

- **Version**: 0.1.0 (Early development)
- **License**: GNU AGPL v3 (copyleft - source disclosure required)
- **Main Branch**: `main` (mirrors master)
- **Primary Docs**: See `Docs/` directory for comprehensive documentation

## Technology Stack

This is a **deliberately polyglot** project. Each language serves a specific purpose:

| Component | Language | Purpose | Build Tool |
|-----------|----------|---------|------------|
| Manifest Format | YAML/TOML/Dhall | Declarative symbolic configuration | N/A |
| CLI Orchestration | Elixir + Ecto | Dispatching, schema reflection, state management | `mix` |
| Macro Layer | LFE (Lisp Flavored Erlang) | Symbolic macro expansion, introspection | `rebar3` |
| Execution Core | Rust | High-performance symbolic logic injection | `cargo` |
| Introspection | Racket | Recursive feedback and semantic tracing | `racket` |
| Tooling | TypeScript + Bun | Manifest hygiene, validation, transformation | `bun` |
| WordPress Integration | PHP | Plugin wrapper and engine integration | N/A |
| Symbolic Engine | PowerShell | Core symbolic operations and workflows | N/A |
| Web UI | HTML/TypeScript | Dashboard, visualizer, notebook interfaces | `bun` |

## Directory Structure

```
wp-praxis/
├── Core/                          # Core system modules
│   ├── cli-wrapper/              # Elixir CLI wrapper
│   ├── db-schema/                # Database schema (Ecto)
│   ├── dhall_yaml_bridge/        # Configuration bridge
│   ├── injectors/                # Rust injector modules
│   ├── manifest-parser/          # YAML/TOML parser
│   ├── runtime/                  # Runtime orchestration
│   └── semantic-indexer/         # Semantic indexing system
│
├── SymbolicEngine/               # Main execution engine
│   ├── core/                     # PowerShell core scripts
│   │   ├── symbolic.ps1          # Main engine entry point
│   │   ├── Run-SymbolicAudit.ps1
│   │   ├── Set-NormativeBaseline.ps1
│   │   ├── Trigger-SymbolicActions.ps1
│   │   ├── Validate-SymbolicRoles.ps1
│   │   └── Visualize-SymbolicDiff.ps1
│   ├── dashboard/                # Web dashboard
│   ├── graphql/                  # GraphQL schema
│   ├── notebook/                 # Interactive notebook
│   ├── swarm/                    # Swarm execution
│   ├── toml/                     # TOML configurations
│   ├── visualizer/               # Visualization UI
│   └── wasm/                     # WebAssembly modules
│
├── wp_injector/                  # Rust injector binary
│   ├── Cargo.toml
│   └── src/main.rs
│
├── plugin/                       # WordPress plugin
│   ├── wp-praxis.php             # Main plugin file
│   └── config/                   # Plugin configuration
│
├── engine/php/                   # PHP execution engine
│   ├── Symbol.php
│   └── symbolic-engine.php
│
├── desktop/                      # Desktop application
├── tests/                        # Test suite
├── examples/                     # Example configurations
├── Docs/                         # Comprehensive documentation
├── Aspects/                      # Quality aspects
└── Assets/                       # Logo and assets
```

## Core Concepts

### 1. Symbolic Dispatching
- The system routes execution based on **semantic tags** and **modular context**
- Symbols are declarative representations of operations
- Dispatch logic maps symbols to concrete implementations

### 2. Declarative Manifests
- YAML/TOML files define workflows, not code
- Manifests are parsed and validated before execution
- Configuration drives behavior across all layers

### 3. Preservation of Meaning
- Semantic traceability is maintained through all abstraction layers
- Introspection tools provide recursive feedback
- Design prioritizes clarity and debuggability

### 4. Modular Execution
- Components are loosely coupled
- Each layer can be tested independently
- Injectors are pluggable and extensible

## Development Guidelines

### When Working with Code

1. **Respect the Polyglot Architecture**
   - Don't try to consolidate languages - each serves a specific purpose
   - Use the appropriate language for the layer you're working on
   - Understand the role of each component before modifying

2. **Maintain Semantic Integrity**
   - Preserve meaningful variable names and comments
   - Keep symbolic representations clear and traceable
   - Document the "why" not just the "what"

3. **Follow Layer Boundaries**
   - CLI layer (Elixir) handles orchestration and dispatch
   - Injectors (Rust) handle performance-critical operations
   - Macros (LFE) handle symbolic transformation
   - Engine (PowerShell) handles core symbolic operations
   - Plugin (PHP) handles WordPress integration

4. **Configuration Over Code**
   - Prefer adding configuration options to hardcoding behavior
   - Extend manifests schemas thoughtfully
   - Validate configuration changes rigorously

### Code Style Conventions

**Rust** (`wp_injector/`, `Core/injectors/`):
- Use `cargo fmt` for formatting
- Run `cargo clippy` for linting
- Follow Rust 2021 edition idioms
- Use `serde` for config parsing
- Use `clap` for CLI argument handling

**Elixir** (`Core/cli-wrapper/`, `Core/db-schema/`):
- Follow Elixir style guide
- Use `mix format`
- Document public functions with `@doc`
- Use Ecto for database operations

**PowerShell** (`SymbolicEngine/core/`):
- Use PascalCase for function names (Verb-Noun pattern)
- Use clear, descriptive parameter names
- Include comment-based help for functions
- Handle errors gracefully with try/catch

**PHP** (`plugin/`, `engine/php/`):
- Follow WordPress coding standards
- Use proper WordPress hooks (actions/filters)
- Sanitize and validate all inputs
- Use WordPress nonce verification for security

**TypeScript** (`SymbolicEngine/dashboard/`, `SymbolicEngine/swarm/`):
- Use Bun for runtime and tooling
- Follow TypeScript strict mode conventions
- Prefer explicit types over `any`
- Use modern ES modules

### Common Tasks

#### Building Components

```bash
# Build Rust injector
cd wp_injector
cargo build --release

# Build/Test Elixir CLI
cd Core/cli-wrapper
mix deps.get
mix compile
mix test

# Build TypeScript components
cd SymbolicEngine/swarm
bun install
bun build

# Run PowerShell engine
pwsh SymbolicEngine/core/symbolic.ps1
```

#### Testing

```bash
# Run test suite
pwsh tests/run-tests.ps1

# Test Rust injector
cd wp_injector
cargo test

# Test Elixir components
cd Core/cli-wrapper
mix test
```

#### Working with Manifests

- Main project manifest: `manifest.yml`
- Plugin workflow configs: `plugin/config/workflow.toml` and `plugin/config/workflow.yaml`
- Example configurations: `examples/sample-workflow.toml`
- Test manifests: `tests/test-symbols.toml`

When modifying manifests:
1. Validate YAML/TOML syntax
2. Check against schema if available
3. Test with example workflows
4. Update documentation if schema changes

### Documentation Standards

**When creating or updating documentation:**

1. **Place documentation appropriately**:
   - Architecture and design: `Docs/`
   - Component-specific: Within component directory
   - Examples: `examples/`
   - API docs: Inline with code

2. **Reference existing docs**:
   - `Docs/EXPLAINME.md` - Deep dive into concepts
   - `Docs/REQUIREMENTS.md` - Project requirements
   - `Docs/STACK.md` - Technology stack details
   - `Docs/philosophy.md` - Design philosophy
   - `Docs/UML/` - Architecture diagrams

3. **Keep CLAUDE.md updated**:
   - Add new components or layers
   - Document new patterns or conventions
   - Update common tasks section

### WordPress Plugin Development

**Important considerations when working on `plugin/wp-praxis.php`:**

1. **WordPress Compatibility**
   - Target PHP 7.4+ (WordPress minimum)
   - Use WordPress coding standards
   - Test with multiple WP versions

2. **Security First**
   - Sanitize all inputs (`sanitize_text_field`, `wp_kses`, etc.)
   - Validate and escape outputs
   - Use WordPress nonces for forms
   - Follow WordPress security best practices

3. **Hook System**
   - Use appropriate WordPress hooks (actions/filters)
   - Document hook priorities
   - Prefix custom hooks with `wp_praxis_`

4. **Integration Points**
   - Plugin hooks into WordPress `init` action
   - Dispatches symbolic workflows from WP context
   - Bridges WordPress data to symbolic engine

### Performance Considerations

1. **Rust Injectors**
   - Optimize for performance-critical paths
   - Profile before optimizing
   - Use appropriate data structures
   - Consider memory usage in recursive operations

2. **Database Operations**
   - Use Ecto efficiently (avoid N+1 queries)
   - Index appropriately
   - Consider caching for frequently accessed data

3. **Symbolic Operations**
   - Be mindful of recursion depth
   - Consider lazy evaluation where appropriate
   - Profile symbolic dispatch overhead

### Security Guidelines

1. **Input Validation**
   - Validate all manifest inputs
   - Sanitize file paths
   - Verify symbolic operation permissions

2. **Execution Safety**
   - Sandbox execution where possible
   - Validate before execution
   - Limit resource consumption

3. **WordPress Security**
   - Follow WordPress security best practices
   - Use prepared statements for database queries
   - Implement proper capability checks

4. **License Compliance**
   - Project is AGPL v3 - all network-served code must be open source
   - Document dependencies and their licenses
   - Ensure compatibility with AGPL requirements

## Important Patterns

### 1. Symbolic Dispatch Pattern

```yaml
# Example manifest structure
symbols:
  - name: example_operation
    type: action
    context: wordpress
    dispatch: rust_injector
    parameters:
      key: value
```

The system:
1. Parses the manifest (manifest-parser)
2. Validates symbols and context
3. Dispatches to appropriate executor
4. Provides introspection feedback

### 2. Layer Communication

```
Manifest (YAML/TOML)
    ↓
Parser (TypeScript/Elixir)
    ↓
CLI Orchestrator (Elixir)
    ↓
Symbolic Engine (PowerShell)
    ↓
Injector (Rust) ←→ WordPress (PHP)
    ↓
Introspection (Racket)
```

### 3. Configuration Precedence

1. Command-line arguments (highest priority)
2. Environment variables
3. Local config files (`.toml`, `.yaml`)
4. Default manifest (`manifest.yml`)
5. Hardcoded defaults (lowest priority)

## Common Pitfalls

1. **Don't Mix Layer Concerns**
   - Keep WordPress logic in PHP
   - Keep performance-critical code in Rust
   - Keep orchestration in Elixir
   - Keep symbolic operations in PowerShell/LFE

2. **Don't Break Semantic Traceability**
   - Always maintain clear naming
   - Document symbol transformations
   - Preserve context through layers

3. **Don't Ignore Configuration**
   - Validate manifest changes
   - Test configuration edge cases
   - Document configuration options

4. **Don't Skip Testing**
   - Test each layer independently
   - Test integration between layers
   - Validate symbolic dispatch correctness

## Testing Strategy

1. **Unit Tests**
   - Rust: `cargo test`
   - Elixir: `mix test`
   - TypeScript: `bun test`

2. **Integration Tests**
   - Use `tests/run-tests.ps1`
   - Test symbolic dispatch end-to-end
   - Verify manifest parsing and execution

3. **WordPress Testing**
   - Test plugin activation/deactivation
   - Verify WordPress hooks fire correctly
   - Test with different WordPress versions

## Debugging Tips

1. **Enable Verbose Logging**
   - Check PowerShell verbose output
   - Enable Rust debug logging
   - Use Elixir logger

2. **Introspection Tools**
   - Use Racket introspection for recursive debugging
   - Trace symbolic dispatch flow
   - Visualize with dashboard tools

3. **Manifest Validation**
   - Validate YAML/TOML syntax first
   - Check schema compliance
   - Test with minimal manifests

## Resources

### Essential Reading
- `Docs/EXPLAINME.md` - Core concepts and design rationale
- `Docs/REQUIREMENTS.md` - What the system must do
- `Docs/STACK.md` - Detailed technology breakdown
- `Docs/philosophy.md` - Why things are designed this way

### Architecture Diagrams
- `Docs/UML/component-diagram.md`
- `Docs/UML/data-flow-diagram.md`
- `Docs/UML/entity-relationship-diagram.md`
- `Docs/UML/sequence-diagram.md`
- `Docs/UML/state-machine-diagram.md`

### UI Documentation
- `Docs/UI/desktop-ui.md`
- `Docs/UI/plugin-ui.md`

### Quality Aspects
- `Aspects/dependability/`
- `Aspects/performance/`
- `Aspects/security/`
- `Aspects/versatility/`

## Version Control

**Current Development**:
- Branch pattern: `claude/create-*` for Claude-generated work
- Main branch: `main` (stable)
- Always commit with descriptive messages
- Push to feature branches, not main directly

**Commit Message Format**:
```
<type>: <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Questions to Ask

**Before making changes, consider:**

1. **Which layer does this belong in?**
   - Is this orchestration (Elixir)?
   - Is this performance-critical (Rust)?
   - Is this symbolic manipulation (LFE/PowerShell)?
   - Is this WordPress integration (PHP)?

2. **How does this preserve semantic integrity?**
   - Is the meaning clear and traceable?
   - Can this be introspected?
   - Does this maintain the symbolic contract?

3. **Is this configuration or code?**
   - Should this be in a manifest?
   - Does this need to be runtime-configurable?
   - Is this a policy or a mechanism?

4. **What are the security implications?**
   - Does this validate inputs?
   - Does this execute arbitrary code?
   - Does this respect WordPress capabilities?

## Getting Help

1. Review existing documentation in `Docs/`
2. Check code examples in `examples/`
3. Look at test cases in `tests/`
4. Review similar implementations in the codebase
5. Consult architecture diagrams in `Docs/UML/`

## Project Goals

**Remember the three core principles:**

1. **Symbolic Dispatching**: Route based on semantic tags and modular context
2. **Preservation of Meaning**: Maintain semantic traceability through abstraction
3. **User Empowerment**: Enable developers to configure complex workflows declaratively

Every change should support these goals.

---

**Last Updated**: 2025-11-21
**Version**: 1.0.0
**Maintainer**: WP Praxis Project
