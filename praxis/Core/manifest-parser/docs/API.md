# WP Praxis Manifest Parser - API Reference

Complete API documentation for all modules in the manifest parser.

## Core Parser Modules

### `yaml-parser`

YAML 1.2 parsing module.

#### Functions

**`(parse-file filepath)`**
- Parse YAML file to LFE data structure
- Args: `filepath` (string)
- Returns: `#(ok data)` | `#(error reason)`

**`(parse-string yaml-str)`**
- Parse YAML from string
- Args: `yaml-str` (binary)
- Returns: `#(ok data)` | `#(error reason)`

**`(parse-multi-document filepath)`**
- Parse YAML file with multiple documents
- Returns: `#(ok (list-of documents))`

**`(validate-yaml filepath)`**
- Validate YAML without full parsing
- Returns: `ok` | `#(error reason)`

---

### `toml-parser`

TOML 1.0 parsing module.

#### Functions

**`(parse-file filepath)`**
- Parse TOML file to LFE data structure
- Args: `filepath` (string)
- Returns: `#(ok data)` | `#(error reason)`

**`(parse-string toml-str)`**
- Parse TOML from string
- Args: `toml-str` (binary)
- Returns: `#(ok data)` | `#(error reason)`

**`(encode-to-toml data)`**
- Convert LFE data to TOML string
- Args: `data` (property list)
- Returns: `#(ok toml-string)` | `#(error reason)`

---

### `manifest-transformer`

Transform parsed data to canonical format.

#### Functions

**`(transform parsed-data format)`**
- Transform to canonical format
- Args: `parsed-data` (property list), `format` ('yaml | 'toml)
- Returns: `#(ok canonical-manifest)` | `#(error reason)`

**`(transform-file filepath)`**
- Auto-detect format and transform
- Returns: `#(ok canonical-manifest)` | `#(error reason)`

**`(normalize canonical-manifest)`**
- Normalize manifest (expand vars, resolve paths, sort)
- Returns: `#(ok normalized-manifest)` | `#(error reason)`

---

### `manifest-validator`

Comprehensive manifest validation.

#### Functions

**`(validate manifest)`**
- Full validation
- Returns: `ok` | `#(error (list-of errors))`

**`(validate-symbols symbols)`**
- Validate symbols list
- Returns: `ok` | `#(error errors)`

**`(check-circular-dependencies symbols)`**
- Detect circular deps
- Returns: `#(ok no-cycles)` | `#(error #(circular-dependencies cycles))`

**`(validate-schema manifest schema)`**
- Validate against schema
- Returns: `ok` | `#(error errors)`

---

## Symbolic Processing Modules

### `symbolic-macros`

Lisp-style macros for symbolic operations.

#### Macros

**`(define-symbol name options . body)`**
- Define a symbol with compile-time metadata

**`(define-workflow name options . steps)`**
- Define a workflow

**`(defcontext name config)`**
- Define an execution context

**`(defdispatch pattern executor options)`**
- Define a dispatch rule

**`(symbol-dispatch symbol params)`**
- Dispatch symbol for execution

**`(with-context context . body)`**
- Execute body in context

---

### `symbolic-introspection`

Runtime introspection and analysis.

#### Functions

**`(inspect-symbol symbol-name)`**
- Inspect symbol properties
- Returns: `#(ok info)` | `#(error reason)`

**`(inspect-workflow workflow-name)`**
- Inspect workflow
- Returns: `#(ok info)` | `#(error reason)`

**`(build-dependency-graph manifest)`**
- Build dependency graph
- Returns: graph (adjacency list)

**`(analyze-manifest-complexity manifest)`**
- Analyze complexity metrics
- Returns: `#(complexity ...)`

---

### `symbolic-optimizer`

Manifest optimization.

#### Functions

**`(optimize manifest)`**
- Apply all optimizations
- Returns: optimized manifest

**`(optimize-symbols symbols)`**
- Optimize symbols list
- Returns: optimized symbols

**`(analyze-optimization-potential manifest)`**
- Analyze potential optimizations
- Returns: `#(optimization-potential ...)`

---

## Integration Modules

### `elixir-interface`

Elixir interop layer.

#### Functions

**`(parse_file filepath)`**
- Parse file (Elixir-compatible)
- Returns: `{:ok, manifest}` | `{:error, reason}`

**`(validate_manifest manifest)`**
- Validate manifest
- Returns: `:ok` | `{:error, errors}`

**`(optimize_manifest manifest)`**
- Optimize manifest
- Returns: `{:ok, optimized}`

**`(get_symbols manifest)`**
- Extract symbols
- Returns: list of symbols

**`(check_circular_deps manifest)`**
- Check circular dependencies
- Returns: `:ok` | `{:error, {:circular_dependencies, cycles}}`

---

### `json-exporter`

JSON export/import.

#### Functions

**`(to-json data)`**
- Convert to JSON
- Returns: `#(ok json-string)` | `#(error reason)`

**`(to-json-pretty data)`**
- Convert to pretty JSON
- Returns: `#(ok pretty-json)`

**`(from-json json-string)`**
- Parse JSON to LFE
- Returns: `#(ok data)` | `#(error reason)`

**`(export-manifest-to-file manifest filepath)`**
- Export to JSON file
- Returns: `ok` | `#(error reason)`

**`(export-json-schema)`**
- Export JSON schema definition
- Returns: `#(ok schema-json)`

---

### `cli-interface`

Command-line interface.

#### Functions

**`(main args)`**
- Main CLI entry point
- Returns: exit code

#### Commands

- `parse <file>` - Parse manifest
- `validate <file>` - Validate
- `transform <file>` - Transform
- `optimize <file>` - Optimize
- `inspect <file>` - Inspect
- `export <file> <output>` - Export to JSON
- `schema` - Output JSON schema
- `help` - Show help

---

## OTP Application

### `manifest-parser-app`

OTP application behavior.

#### Functions

**`(start start-type start-args)`**
- Start application
- Returns: `#(ok pid)` | `#(error reason)`

**`(stop state)`**
- Stop application
- Returns: `ok`

**`(health-check)`**
- Health check
- Returns: `ok` | `#(error reason)`

**`(get-statistics)`**
- Get app statistics
- Returns: statistics property list

---

### `parser-server`

Gen-server for parsing with caching.

#### API Functions

**`(parse-file filepath)`**
- Parse file through server
- Returns: `#(ok manifest)` | `#(error reason)`

**`(parse-string content format)`**
- Parse string
- Returns: `#(ok manifest)` | `#(error reason)`

**`(validate manifest)`**
- Validate manifest
- Returns: `ok` | `#(error errors)`

**`(clear-cache)`**
- Clear parse cache
- Returns: `ok`

**`(get-statistics)`**
- Get parser statistics
- Returns: statistics property list

---

### `symbol-registry`

Gen-server for global symbol registry.

#### API Functions

**`(register-symbol name metadata)`**
- Register symbol
- Returns: `ok`

**`(register-workflow name metadata)`**
- Register workflow
- Returns: `ok`

**`(lookup-symbol name)`**
- Lookup symbol
- Returns: `#(ok metadata)` | `undefined`

**`(list-symbols)`**
- List all symbols
- Returns: list of symbol names

**`(clear)`**
- Clear registry
- Returns: `ok`

---

## Data Structures

### Canonical Manifest

```lisp
(
  #(version "1.0")
  #(format yaml)
  #(metadata
    (#(name "manifest-name")
     #(version "0.1.0")
     #(author "Author")
     ...))
  #(symbols
    (#(#(name symbol1)
       #(type action)
       #(context wordpress)
       ...)
     ...))
  #(workflows
    (#(#(name workflow1)
       #(steps (...))
       ...)
     ...))
  #(contexts (...))
  #(dispatches (...))
)
```

### Symbol Definition

```lisp
(
  #(name symbol-name)
  #(type action)  ; action | query | event
  #(context wordpress)
  #(dispatch rust_injector)
  #(parameters (#(key value) ...))
  #(dependencies (dep1 dep2 ...))
  #(metadata (#(key value) ...))
  #(enabled true)
)
```

### Workflow Definition

```lisp
(
  #(name workflow-name)
  #(description "Description")
  #(steps
    (#(#(symbol symbol1)
       #(parameters (...))
       #(continue-on-error false)
       ...)
     ...))
  #(parallel false)
  #(error-handling stop)
  #(metadata (...))
)
```

---

## Error Handling

All functions return tuples:

**Success**: `#(ok result)`
**Error**: `#(error reason)`

Error reasons are structured:

```lisp
#(error
  #(type reason-type
    #(details (...))
    #(stacktrace ...)))
```

Common error types:
- `file-read-error`
- `parse-error`
- `validation-error`
- `circular-dependencies`
- `missing-field`
- `invalid-type`

---

## Examples

### Parse and Validate

```lisp
(case (manifest-transformer:transform-file "manifest.yaml")
  ((tuple 'ok manifest)
   (case (manifest-validator:validate manifest)
     ('ok
      (io:format "Valid manifest!~n"))
     ((tuple 'error errors)
      (io:format "Validation errors: ~p~n" (list errors)))))
  ((tuple 'error reason)
   (io:format "Parse error: ~p~n" (list reason))))
```

### Optimize and Export

```lisp
(let* ((manifest (load-manifest "manifest.yaml"))
       (optimized (symbolic-optimizer:optimize manifest)))
  (json-exporter:export-manifest-to-file optimized "optimized.json"))
```

### Register Symbols

```lisp
(symbol-registry:register-symbol
  'my-symbol
  '(#(type action)
    #(context wordpress)))

(case (symbol-registry:lookup-symbol 'my-symbol)
  ((tuple 'ok metadata)
   (io:format "Found: ~p~n" (list metadata)))
  ('undefined
   (io:format "Not found~n")))
```

---

For usage examples, see [README.md](../README.md) and [examples/](../examples/).
