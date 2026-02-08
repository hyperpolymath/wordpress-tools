# Tutorial 05: Creating Custom Symbols

## Overview

Learn how to extend WP Praxis by creating custom symbol types and dispatchers.

**Time Required**: 30 minutes
**Difficulty**: Advanced
**Prerequisites**: Knowledge of Rust, PHP, PowerShell, or TypeScript

## Custom Symbol Types

Symbols can be dispatched to different execution layers. Let's create a custom symbol for each layer.

## Example 1: Custom Rust Injector Symbol

### Step 1: Define the Symbol Operation

Create `/home/user/wp-praxis/wp_injector/src/operations/custom_backup.rs`:

```rust
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Deserialize)]
pub struct CustomBackupParams {
    pub backup_path: PathBuf,
    pub include_uploads: bool,
    pub include_database: bool,
    pub compression: String,
}

#[derive(Debug, Serialize)]
pub struct CustomBackupResult {
    pub backup_file: String,
    pub backup_size: u64,
    pub files_backed_up: usize,
    pub duration_ms: u64,
}

pub fn execute_custom_backup(params: CustomBackupParams) -> Result<CustomBackupResult, String> {
    let start_time = std::time::Instant::now();

    // Your custom backup logic here
    let backup_file = create_backup_archive(&params)?;
    let backup_size = get_file_size(&backup_file)?;
    let files_count = count_files_in_archive(&backup_file)?;

    Ok(CustomBackupResult {
        backup_file: backup_file.to_string_lossy().to_string(),
        backup_size,
        files_backed_up: files_count,
        duration_ms: start_time.elapsed().as_millis() as u64,
    })
}

fn create_backup_archive(params: &CustomBackupParams) -> Result<PathBuf, String> {
    // Implementation details
    unimplemented!()
}

fn get_file_size(path: &PathBuf) -> Result<u64, String> {
    std::fs::metadata(path)
        .map(|m| m.len())
        .map_err(|e| format!("Failed to get file size: {}", e))
}

fn count_files_in_archive(path: &PathBuf) -> Result<usize, String> {
    // Implementation details
    unimplemented!()
}
```

### Step 2: Register the Operation

Edit `/home/user/wp-praxis/wp_injector/src/main.rs`:

```rust
mod operations;
use operations::custom_backup::{execute_custom_backup, CustomBackupParams};

fn dispatch_operation(operation: &str, params_json: &str) -> Result<String, String> {
    match operation {
        "custom_backup" => {
            let params: CustomBackupParams = serde_json::from_str(params_json)
                .map_err(|e| format!("Invalid params: {}", e))?;
            let result = execute_custom_backup(params)?;
            serde_json::to_string(&result)
                .map_err(|e| format!("Failed to serialize result: {}", e))
        },
        // ... other operations
        _ => Err(format!("Unknown operation: {}", operation))
    }
}
```

### Step 3: Use in Workflow

```yaml
symbols:
  - name: "create_custom_backup"
    type: "action"
    dispatch: "rust_injector"
    context: "wordpress"
    parameters:
      operation: "custom_backup"
      backup_path: "./backups/"
      include_uploads: true
      include_database: true
      compression: "gzip"
    outputs:
      - backup_file
      - backup_size
```

## Example 2: Custom PHP Symbol

### Step 1: Create PHP Function

Create `/home/user/wp-praxis/engine/php/custom-operations.php`:

```php
<?php

namespace WpPraxis\CustomOperations;

class CustomMailer {

    /**
     * Send custom notification email with template
     */
    public static function send_templated_email($params) {
        $template = $params['template'] ?? 'default';
        $recipients = $params['recipients'] ?? [];
        $data = $params['data'] ?? [];

        // Load template
        $template_path = WP_PRAXIS_PATH . "/templates/email/{$template}.php";
        if (!file_exists($template_path)) {
            return [
                'success' => false,
                'error' => "Template not found: {$template}"
            ];
        }

        // Render template
        ob_start();
        extract($data);
        include $template_path;
        $message = ob_get_clean();

        // Send emails
        $sent_count = 0;
        foreach ($recipients as $recipient) {
            if (wp_mail($recipient, $data['subject'], $message)) {
                $sent_count++;
            }
        }

        return [
            'success' => true,
            'emails_sent' => $sent_count,
            'template_used' => $template
        ];
    }
}
```

### Step 2: Register in Engine

Edit `/home/user/wp-praxis/engine/php/symbolic-engine.php`:

```php
require_once 'custom-operations.php';

function wp_praxis_execute_symbol($symbol) {
    $operation = $symbol['parameters']['operation'] ?? '';

    switch ($operation) {
        case 'send_templated_email':
            return \WpPraxis\CustomOperations\CustomMailer::send_templated_email(
                $symbol['parameters']
            );
        // ... other operations
        default:
            return ['error' => "Unknown operation: {$operation}"];
    }
}
```

### Step 3: Use in Workflow

```yaml
symbols:
  - name: "notify_admins"
    type: "notification"
    dispatch: "php"
    context: "wordpress"
    parameters:
      operation: "send_templated_email"
      template: "workflow_complete"
      recipients:
        - "admin@example.com"
        - "ops@example.com"
      data:
        subject: "Workflow Completed"
        workflow_name: "${workflow.name}"
        status: "${workflow.status}"
    outputs:
      - emails_sent
```

## Example 3: Custom PowerShell Symbol

### Step 1: Create PowerShell Function

Create `/home/user/wp-praxis/SymbolicEngine/core/Custom-DatabaseOptimizer.ps1`:

```powershell
function Optimize-CustomDatabase {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Parameters
    )

    $optimization_level = $Parameters.optimization_level ?? "standard"
    $tables = $Parameters.tables ?? @()

    $results = @{
        tables_optimized = @()
        space_recovered = 0
        duration_ms = 0
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    foreach ($table in $tables) {
        Write-Verbose "Optimizing table: $table"

        # Custom optimization logic
        $before_size = Get-TableSize -TableName $table
        Invoke-TableOptimization -TableName $table -Level $optimization_level
        $after_size = Get-TableSize -TableName $table

        $space_saved = $before_size - $after_size
        $results.space_recovered += $space_saved
        $results.tables_optimized += $table

        Write-Verbose "  Saved: $space_saved bytes"
    }

    $stopwatch.Stop()
    $results.duration_ms = $stopwatch.ElapsedMilliseconds

    return $results
}

function Get-TableSize {
    param([string]$TableName)
    # Implementation
    return 1024 * 1024  # Example: 1MB
}

function Invoke-TableOptimization {
    param(
        [string]$TableName,
        [string]$Level
    )
    # Implementation
}

Export-ModuleMember -Function Optimize-CustomDatabase
```

### Step 2: Register in Symbolic Engine

Edit `/home/user/wp-praxis/SymbolicEngine/core/symbolic.ps1`:

```powershell
# Load custom modules
. "$PSScriptRoot/Custom-DatabaseOptimizer.ps1"

function Invoke-SymbolicOperation {
    param($Symbol)

    $operation = $Symbol.parameters.operation

    switch ($operation) {
        "optimize_custom_database" {
            return Optimize-CustomDatabase -Parameters $Symbol.parameters
        }
        # ... other operations
        default {
            throw "Unknown operation: $operation"
        }
    }
}
```

### Step 3: Use in Workflow

```yaml
symbols:
  - name: "optimize_database"
    type: "optimization"
    dispatch: "powershell"
    context: "wordpress"
    parameters:
      operation: "optimize_custom_database"
      optimization_level: "aggressive"
      tables:
        - "wp_options"
        - "wp_postmeta"
        - "wp_usermeta"
    outputs:
      - tables_optimized
      - space_recovered
```

## Example 4: Custom TypeScript Symbol (Swarm)

### Step 1: Create TypeScript Handler

Create `/home/user/wp-praxis/SymbolicEngine/swarm/src/handlers/custom-analytics.ts`:

```typescript
import { SymbolParameters, SymbolResult } from '../types';

export interface CustomAnalyticsParams extends SymbolParameters {
  data_source: string;
  metrics: string[];
  aggregation_period: string;
}

export interface CustomAnalyticsResult extends SymbolResult {
  metrics_calculated: Record<string, number>;
  insights: string[];
  recommendations: string[];
}

export async function executeCustomAnalytics(
  params: CustomAnalyticsParams
): Promise<CustomAnalyticsResult> {
  const startTime = Date.now();

  // Load data
  const data = await loadDataSource(params.data_source);

  // Calculate metrics
  const metrics: Record<string, number> = {};
  for (const metric of params.metrics) {
    metrics[metric] = await calculateMetric(data, metric, params.aggregation_period);
  }

  // Generate insights
  const insights = generateInsights(metrics);
  const recommendations = generateRecommendations(metrics);

  return {
    success: true,
    metrics_calculated: metrics,
    insights,
    recommendations,
    duration_ms: Date.now() - startTime
  };
}

async function loadDataSource(source: string): Promise<any[]> {
  // Implementation
  return [];
}

async function calculateMetric(
  data: any[],
  metric: string,
  period: string
): Promise<number> {
  // Implementation
  return 0;
}

function generateInsights(metrics: Record<string, number>): string[] {
  // Implementation
  return [];
}

function generateRecommendations(metrics: Record<string, number>): string[] {
  // Implementation
  return [];
}
```

### Step 2: Register Handler

Edit `/home/user/wp-praxis/SymbolicEngine/swarm/src/worker.ts`:

```typescript
import { executeCustomAnalytics } from './handlers/custom-analytics';

async function executeSymbol(symbol: Symbol): Promise<SymbolResult> {
  const operation = symbol.parameters.operation;

  switch (operation) {
    case 'custom_analytics':
      return await executeCustomAnalytics(symbol.parameters);
    // ... other operations
    default:
      throw new Error(`Unknown operation: ${operation}`);
  }
}
```

### Step 3: Use in Workflow

```yaml
symbols:
  - name: "analyze_performance"
    type: "analysis"
    dispatch: "typescript"
    context: "swarm"
    execution:
      swarm_enabled: true
    parameters:
      operation: "custom_analytics"
      data_source: "./data/performance-logs.json"
      metrics:
        - "average_response_time"
        - "error_rate"
        - "throughput"
      aggregation_period: "1h"
    outputs:
      - metrics_calculated
      - insights
      - recommendations
```

## Testing Custom Symbols

### Unit Test (Rust)

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_custom_backup() {
        let params = CustomBackupParams {
            backup_path: PathBuf::from("./test-backups"),
            include_uploads: true,
            include_database: true,
            compression: "gzip".to_string(),
        };

        let result = execute_custom_backup(params);
        assert!(result.is_ok());

        let backup_result = result.unwrap();
        assert!(backup_result.backup_size > 0);
        assert!(backup_result.files_backed_up > 0);
    }
}
```

### Integration Test (Workflow)

Create `test-custom-symbols.yaml`:

```yaml
version: "1.0"
metadata:
  name: "test-custom-symbols"

symbols:
  - name: "test_custom_backup"
    type: "action"
    dispatch: "rust_injector"
    parameters:
      operation: "custom_backup"
      backup_path: "./test-backups/"
      include_uploads: false
      include_database: false
      compression: "none"

  - name: "verify_backup"
    type: "validation"
    dispatch: "powershell"
    depends_on: ["test_custom_backup"]
    parameters:
      operation: "verify_file_exists"
      file_path: "${test_custom_backup.backup_file}"
```

Run test:

```bash
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath test-custom-symbols.yaml \
  -Verbose
```

## Best Practices

1. **Type Safety**: Use strong typing in all languages
2. **Error Handling**: Always handle errors gracefully
3. **Validation**: Validate parameters before execution
4. **Logging**: Log important operations
5. **Testing**: Write unit and integration tests
6. **Documentation**: Document parameters and outputs

## Complete Example

See `/home/user/wp-praxis/examples/use-cases/custom-symbols/` for a complete working example of custom symbols across all layers.

## Summary

You now know how to:
✓ Create custom Rust injector operations
✓ Create custom PHP symbols
✓ Create custom PowerShell functions
✓ Create custom TypeScript handlers
✓ Test custom symbols
✓ Use custom symbols in workflows
