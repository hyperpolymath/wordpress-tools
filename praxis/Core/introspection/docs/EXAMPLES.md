# Usage Examples

## Basic Usage

### 1. Simple Introspection

```bash
wp-introspect -m examples/sample-workflow.toml
```

**Output**:
```
{
  symbols: [list: 3 items]
  metadata: {hash: 3 keys}
  statistics: {
    total-symbols: 3
    max-depth: 2
    ...
  }
}
```

### 2. Generate HTML Report

```bash
wp-introspect -m workflow.toml -f html -o report.html
```

Opens a styled HTML report with:
- Summary statistics
- Issue breakdown by priority
- Recommendations
- Optimization opportunities

### 3. JSON Output for Automation

```bash
wp-introspect -m workflow.toml -f json | jq '.feedback.summary'
```

```json
{
  "total-items": 5,
  "critical": 1,
  "high": 2,
  "medium": 2,
  "low": 0
}
```

## Interactive REPL

### Session Example

```
$ racket repl/interactive.rkt
=== WP Praxis Introspection REPL ===

introspect> load examples/sample-workflow.toml
Loading examples/sample-workflow.toml...
✓ Loaded successfully

introspect> symbols
Found 3 symbols:
  - validate_user (action)
  - process_payment (action)
  - send_notification (filter)

introspect> symbol validate_user
{
  name: "validate_user"
  type: "action"
  context: "wordpress"
  metadata: {
    dispatch: "rust_injector"
    priority: 10
  }
}

introspect> deps process_payment
Dependencies of process_payment:
  - validate_user

introspect> analyze
Analyzing...
✓ Analysis complete
{
  integrity-score: 0.9
  contract-violations: []
  type-errors: []
  ...
}

introspect> feedback
Generating feedback...
=== Feedback Report ===
[MEDIUM] High symbol count
Manifest contains 3 symbols. Consider breaking into smaller modules.
```

## Programmatic Usage

### Example 1: Basic Introspection

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Load and introspect
(define results
  (introspect-workflow "workflow.toml"
                       #:trace? #t
                       #:analyze? #t
                       #:feedback? #t))

;; Check for critical issues
(define feedback (hash-ref results 'feedback))
(define summary (hash-ref feedback 'summary))
(define critical-count (hash-ref summary 'critical))

(when (> critical-count 0)
  (displayln "⚠ Critical issues found!")
  (define items (hash-ref feedback 'feedback-items))
  (for ([item items])
    (when (equal? (hash-ref item 'priority) 'critical)
      (displayln (hash-ref item 'title)))))
```

### Example 2: Custom Analysis

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Load state
(define state
  (inspect-symbolic-state
   (read-toml-file "workflow.toml")))

;; Find all WordPress symbols
(define wp-symbols
  (find-symbols-by-predicate
   (hash-ref state 'symbols)
   (λ (sym)
     (and (hash? sym)
          (equal? (hash-ref sym 'context #f) "wordpress")))))

(displayln (format "Found ~a WordPress symbols" (length wp-symbols)))

;; Analyze dependencies
(define deps (analyze-dependencies wp-symbols))
(displayln (format "Max dependency depth: ~a"
                   (hash-ref deps 'max-depth)))
```

### Example 3: Performance Analysis

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Trace execution
(define trace (trace-execution "workflow.toml"))

;; Get bottlenecks
(define bottlenecks (hash-ref trace 'bottlenecks))

(displayln "Performance Bottlenecks:")
(for ([b bottlenecks])
  (displayln (format "  ~a in ~a: ~a ms"
                     (hash-ref b 'operation)
                     (hash-ref b 'layer)
                     (hash-ref b 'duration-ms))))

;; Check preservation score
(define score (hash-ref trace 'preservation-score))
(if (< score 0.7)
    (displayln "⚠ Low semantic preservation!")
    (displayln "✓ Good semantic preservation"))
```

### Example 4: Generate Dependency Graph

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Load state
(define state
  (inspect-symbolic-state
   (read-toml-file "workflow.toml")))

;; Generate DOT graph
(define dot-str
  (generate-dependency-graph
   (hash-ref state 'symbols)))

;; Save and render
(save-dot-file dot-str "deps.dot")
(render-graph dot-str "deps" "png")

(displayln "Dependency graph saved to deps.png")
```

## Integration Examples

### From PowerShell

```powershell
# workflow.ps1

# Call introspection
$result = racket /path/to/introspection/integration/powershell-bridge.rkt `
                 workflow.toml

# Parse JSON result
$data = $result | ConvertFrom-Json

# Check for errors
if ($data.analysis.'contract-violations'.Count -gt 0) {
    Write-Error "Contract violations detected"
    exit 1
}

Write-Host "Introspection passed ✓"
```

### From Elixir

```elixir
defmodule WPPraxis.Introspection do
  def analyze(manifest_path) do
    # Start Racket port
    port = Port.open(
      {:spawn, "racket integration/elixir-port.rkt"},
      [:binary, packet: 4]
    )

    # Send command
    command = %{
      command: "introspect",
      manifest: manifest_path
    }

    Port.command(port, Jason.encode!(command))

    # Receive result
    receive do
      {^port, {:data, data}} ->
        Jason.decode!(data)
    after
      5000 -> {:error, :timeout}
    end
  end
end

# Usage
result = WPPraxis.Introspection.analyze("workflow.toml")
IO.inspect(result["feedback"]["summary"])
```

### Via HTTP API

```bash
# Start server
racket integration/http-server.rkt --port 8080

# POST request
curl -X POST http://localhost:8080/introspect \
  -H "Content-Type: application/json" \
  -d '{
    "manifest": "workflow.toml",
    "options": {
      "trace": true,
      "analyze": true
    }
  }'
```

## Advanced Examples

### Example: Custom Pattern Detection

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Define custom pattern
(define payment-pattern
  (make-hash '((type . "action")
               (context . "wordpress")
               (tags . ("payment")))))

;; Find matches
(define state (inspect-symbolic-state (read-toml-file "workflow.toml")))
(define symbols (hash-ref state 'symbols))

(define payment-symbols
  (filter (λ (sym)
            (pattern-matches? sym payment-pattern))
          symbols))

(displayln (format "Found ~a payment symbols" (length payment-symbols)))
```

### Example: Meta-Evaluation

```racket
#lang racket/base

(require wp-praxis-introspection)

;; Run full introspection
(define results
  (introspect-workflow "workflow.toml"
                       #:trace? #t
                       #:analyze? #t
                       #:feedback? #t))

;; Meta-evaluate the introspection itself
(define meta-results (meta-evaluate results))

;; Check coverage
(define coverage (hash-ref meta-results 'coverage))
(for ([metric coverage])
  (displayln (format "~a coverage: ~a%"
                     (coverage-metric-aspect metric)
                     (coverage-metric-percentage metric))))

;; Check quality
(define quality (hash-ref meta-results 'quality))
(for ([metric quality])
  (displayln (format "~a quality: ~a"
                     (quality-metric-dimension metric)
                     (quality-metric-score metric))))
```

### Example: Continuous Monitoring

```racket
#lang racket/base

(require wp-praxis-introspection
         db)

;; Connect to database
(define conn
  (connect-database
   (make-db-config #:database "wp_praxis")))

;; Monitor recent workflows
(define recent-workflows (get-workflow-runs conn 10))

(for ([workflow recent-workflows])
  (define wf-id (hash-ref workflow 'id))
  (define stats (get-layer-statistics conn wf-id))

  ;; Check for performance issues
  (for ([layer-stat stats])
    (define avg-duration (hash-ref layer-stat 'avg_duration))
    (when (> avg-duration 100) ;; 100ms threshold
      (displayln (format "⚠ Slow layer: ~a (~a ms)"
                         (hash-ref layer-stat 'layer)
                         avg-duration)))))

(disconnect-database conn)
```

## Testing Examples

### Unit Test Example

```racket
#lang racket/base

(require rackunit
         wp-praxis-introspection)

(test-case "Symbol type inference"
  (define sym (make-hash '((name . "test")
                           (type . "action")
                           (context . "wordpress"))))

  (define node (symbol-node "test" "action" "wordpress" (hash) '()))

  (check-equal? (infer-symbol-type node) 'action))

(test-case "Dependency cycle detection"
  (define dep-graph
    (make-hash '(("A" . ("B"))
                 ("B" . ("C"))
                 ("C" . ("A")))))

  (define cycles (find-dependency-cycles dep-graph))

  (check-true (not (null? cycles))))
```
