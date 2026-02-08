# Tutorial 02: WordPress Integration

## Overview

Learn how to install and use the WP Praxis WordPress plugin to execute symbolic workflows directly from your WordPress admin panel.

**Time Required**: 20-25 minutes
**Difficulty**: Intermediate
**Prerequisites**:
- Completed Tutorial 01
- WordPress admin access
- WP Praxis plugin files

## Table of Contents

1. [Plugin Installation](#plugin-installation)
2. [Plugin Configuration](#plugin-configuration)
3. [Uploading Workflows](#uploading-workflows)
4. [Executing Workflows from WordPress](#executing-workflows-from-wordpress)
5. [Viewing Results](#viewing-results)
6. [Dashboard Features](#dashboard-features)

## Plugin Installation

### Step 1: Copy Plugin Files

The WP Praxis plugin is located in the `plugin/` directory.

```bash
# Copy plugin to WordPress plugins directory
cp -r /home/user/wp-praxis/plugin/wp-praxis /var/www/html/wp-content/plugins/

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content/plugins/wp-praxis
chmod -R 755 /var/www/html/wp-content/plugins/wp-praxis
```

### Step 2: Activate the Plugin

1. Log in to WordPress admin: `http://localhost/wp-admin`
2. Navigate to **Plugins** → **Installed Plugins**
3. Find "WP Praxis" in the list
4. Click **Activate**

**Expected Result**: You'll see a success message: "Plugin activated."

### Step 3: Verify Installation

After activation, you should see a new menu item in the WordPress admin sidebar:

- **WP Praxis** (with submenu items):
  - Dashboard
  - Workflows
  - Baselines
  - Audit Reports
  - Settings

## Plugin Configuration

### Step 1: Configure Settings

Navigate to **WP Praxis** → **Settings**

#### General Settings

```
Symbolic Engine Path: /home/user/wp-praxis/SymbolicEngine/core/symbolic.ps1
Rust Injector Path: /home/user/wp-praxis/wp_injector/target/release/wp_injector
Output Directory: /home/user/wp-praxis/outputs
```

#### Execution Settings

```
Default Timeout: 120 seconds
Max Parallel Symbols: 5
Enable Rollback: Yes
Preserve Baselines: Yes
```

#### Security Settings

```
Allowed Users: Administrator
Require Nonce Verification: Yes
Enable Audit Logging: Yes
```

Click **Save Settings**.

### Step 2: Test Connection

In the Settings page, click **Test Connection** button.

**Expected Output**:
```
✓ PowerShell Symbolic Engine: Found
✓ Rust Injector: Found
✓ Output Directory: Writable
✓ WordPress Integration: Working
✓ All systems operational
```

## Uploading Workflows

### Step 1: Navigate to Workflows

Go to **WP Praxis** → **Workflows** → **Add New**

### Step 2: Upload Workflow File

**Option A: Upload YAML/TOML File**

1. Click **Choose File**
2. Select a workflow file (e.g., `simple-option-update.yaml`)
3. Click **Upload Workflow**

**Option B: Paste Workflow Content**

1. Click the **Paste Content** tab
2. Paste your YAML/TOML workflow content
3. Enter a workflow name
4. Click **Save Workflow**

### Step 3: View Uploaded Workflow

After upload, you'll see the workflow in the list:

| Workflow Name | Type | Symbols | Status | Actions |
|---------------|------|---------|--------|---------|
| simple-option-update | YAML | 7 | Ready | Execute \| Edit \| Delete |

## Executing Workflows from WordPress

### Step 1: Execute a Workflow

From the Workflows list:

1. Click **Execute** next to your workflow
2. Review the execution plan
3. (Optional) Override configuration values
4. Click **Start Execution**

### Step 2: Monitor Execution

You'll be redirected to the execution monitor page showing:

- **Progress Bar**: Overall completion
- **Symbol Status**: Each symbol's execution state
- **Live Log**: Real-time execution output
- **Performance Metrics**: Execution times

**Example Progress**:
```
Executing: simple-option-update
Progress: 3/7 symbols (43%)

✓ create_baseline (0.15s)
✓ update_site_title (0.08s)
✓ update_site_description (0.06s)
→ update_posts_per_page (running...)
○ verify_changes (pending)
○ create_post_baseline (pending)
○ generate_diff_report (pending)
```

### Step 3: Execution Complete

When complete, you'll see:

```
✓ Workflow Completed Successfully
Duration: 1.2 seconds
Symbols Executed: 7/7
Symbols Failed: 0
Output: /outputs/simple-option-update-2025-11-22.json
```

**Actions Available**:
- **View Output**: See JSON output
- **View Report**: See visual diff report
- **View Baseline**: Compare before/after
- **Download Results**: Download all artifacts

## Viewing Results

### Dashboard Overview

Navigate to **WP Praxis** → **Dashboard** to see:

#### Recent Executions

| Workflow | Executed | Duration | Status | Actions |
|----------|----------|----------|--------|---------|
| simple-option-update | 2 min ago | 1.2s | ✓ Success | View Results |
| custom-post-type-setup | 1 hour ago | 3.4s | ✓ Success | View Results |

#### Statistics

```
Total Executions: 47
Success Rate: 95.7%
Avg Duration: 2.1s
Total Symbols Executed: 234
```

#### Recent Baselines

```
Baseline: pre_option_update
Created: 2025-11-22 10:30:45
Items: 234 options, 42 posts
Actions: View | Compare | Restore
```

### Viewing Detailed Results

Click **View Results** on any execution to see:

1. **Execution Summary**: Overview and metadata
2. **Symbol Details**: Each symbol's execution info
3. **Outputs**: All symbol outputs
4. **Visual Diff**: Before/after comparison (if applicable)
5. **Audit Log**: Complete audit trail

### Example: Visual Diff Report

When viewing a workflow with baselines:

**Changes Detected**: 3 options modified

| Option Name | Before | After |
|-------------|--------|-------|
| blogname | "WordPress Site" | "My Awesome WordPress Site" |
| blogdescription | "Just another site" | "Just another WordPress site powered by WP Praxis" |
| posts_per_page | "10" | "15" |

**Charts Available**:
- Option Changes Pie Chart
- Execution Timeline
- Performance Comparison

## Dashboard Features

### 1. Quick Execute

From the dashboard, use the **Quick Execute** widget:

1. Select a saved workflow from dropdown
2. Click **Execute Now**
3. Monitor in real-time

### 2. Baseline Management

Navigate to **WP Praxis** → **Baselines**

**Available Actions**:
- **Create Baseline**: Create snapshot of current state
- **Compare Baselines**: Visual diff between two baselines
- **Restore from Baseline**: Rollback to previous state
- **Export Baseline**: Download for backup
- **Set Normative**: Mark as reference baseline

### 3. Audit Reports

Navigate to **WP Praxis** → **Audit Reports**

View comprehensive audit reports:

```
Audit Report: comprehensive_audit_2025-11-22
Created: 2025-11-22 14:30:00
Baseline Before: pre_audit
Baseline After: post_audit

Summary:
- Options Changed: 12
- Posts Modified: 0
- Users Modified: 0
- Anomalies Found: 2
- Integrity Status: ✓ Passed
- Compliance Score: 94.5%

Actions: View Report | Download PDF | Export JSON
```

### 4. Settings & Configuration

**Workflow Settings**:
- Default execution timeout
- Rollback behavior
- Notification preferences

**Security Settings**:
- Role-based access control
- Audit logging
- Workflow approval requirements

**Advanced Settings**:
- Database connection (Ecto)
- Swarm configuration
- Performance tuning

## Example Workflow: Site Setup

Let's create a workflow using the WordPress interface:

### Step 1: Create New Workflow

**WP Praxis** → **Workflows** → **Add New**

### Step 2: Paste This Content

```yaml
version: "1.0"
metadata:
  name: "site-setup-from-admin"
  description: "Complete site setup from WordPress admin"

symbols:
  - name: "update_settings"
    type: "action"
    dispatch: "rust_injector"
    context: "wordpress"
    parameters:
      operation: "batch_update_options"
      updates:
        - option_name: "blogname"
          option_value: "My New Site"
        - option_name: "timezone_string"
          option_value: "America/New_York"

  - name: "create_sample_page"
    type: "action"
    dispatch: "php"
    context: "wordpress"
    depends_on: ["update_settings"]
    parameters:
      operation: "create_post"
      post_type: "page"
      post_title: "Welcome"
      post_content: "Welcome to my site!"
      post_status: "publish"

outputs:
  format: "json"
  destination: "./outputs/site-setup-${timestamp}.json"
```

### Step 3: Save and Execute

1. Click **Save Workflow**
2. Click **Execute Now**
3. Watch it run in real-time!

## Advanced Features

### Scheduled Workflows

Set up recurring workflows:

1. Edit a workflow
2. Click **Schedule** tab
3. Set schedule:
   ```
   Schedule Type: Recurring
   Frequency: Daily
   Time: 02:00 AM
   Timezone: America/New_York
   ```
4. Save schedule

### Workflow Templates

Save workflows as templates for reuse:

1. Edit a workflow
2. Click **Save as Template**
3. Enter template name and description
4. Template appears in **Templates** library

### Rollback from Dashboard

If something goes wrong:

1. **WP Praxis** → **Baselines**
2. Find the baseline before changes
3. Click **Restore**
4. Confirm restoration
5. Watch rollback execute

## Integration with WordPress Actions

The plugin adds WordPress action hooks you can use:

```php
// Before workflow execution
add_action('wp_praxis_before_workflow', function($workflow_name) {
    error_log("Starting workflow: $workflow_name");
});

// After workflow execution
add_action('wp_praxis_after_workflow', function($workflow_name, $result) {
    if ($result['status'] === 'completed') {
        // Send notification
        wp_mail('admin@example.com', 'Workflow Complete', 'Success!');
    }
});

// On workflow failure
add_action('wp_praxis_workflow_failed', function($workflow_name, $error) {
    error_log("Workflow failed: $workflow_name - $error");
});
```

## REST API Access

Access workflows via WordPress REST API:

```bash
# List workflows
curl -X GET "http://localhost/wp-json/wp-praxis/v1/workflows" \
  --user "admin:password"

# Execute workflow
curl -X POST "http://localhost/wp-json/wp-praxis/v1/workflows/123/execute" \
  --user "admin:password"

# Get execution status
curl -X GET "http://localhost/wp-json/wp-praxis/v1/executions/456" \
  --user "admin:password"
```

## Troubleshooting

### Plugin Activation Error

**Error**: "Plugin could not be activated because it triggered a fatal error."

**Solution**:
1. Check PHP error log: `tail -f /var/log/php/error.log`
2. Ensure PHP version >= 7.4
3. Check file permissions
4. Verify wp-config.php is writable

### Workflow Upload Failed

**Error**: "Failed to parse workflow file"

**Solution**:
1. Validate YAML/TOML syntax
2. Check file encoding (UTF-8)
3. Ensure no BOM markers
4. Try pasting content instead of uploading

### Execution Hangs

**Problem**: Workflow execution appears stuck

**Solution**:
1. Check PHP max_execution_time
2. Increase timeout in settings
3. Check system resources
4. Review workflow for infinite loops

## Next Steps

Continue to [Tutorial 03: Swarm Setup](../03-swarm-setup/README.md) to learn about distributed execution!
