# Tutorial 01: Getting Started with WP Praxis

## Overview

Welcome to WP Praxis! This tutorial will guide you through your first symbolic workflow execution. You'll learn how to:

- Set up the WP Praxis environment
- Create a simple workflow manifest
- Execute a workflow using the CLI
- Understand workflow outputs
- Troubleshoot common issues

**Time Required**: 15-20 minutes
**Difficulty**: Beginner
**Prerequisites**:
- WordPress installation (local or remote)
- Basic command line knowledge
- WP Praxis installed (see installation guide)

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Your First Workflow](#your-first-workflow)
3. [Executing the Workflow](#executing-the-workflow)
4. [Understanding the Output](#understanding-the-output)
5. [Next Steps](#next-steps)
6. [Troubleshooting](#troubleshooting)

## Environment Setup

### 1. Verify WP Praxis Installation

First, verify that all WP Praxis components are properly installed:

```bash
# Check Rust injector
/home/user/wp-praxis/wp_injector/target/release/wp_injector --version

# Check PowerShell symbolic engine
pwsh -Command "Test-Path /home/user/wp-praxis/SymbolicEngine/core/symbolic.ps1"

# Check Elixir CLI (if installed)
cd /home/user/wp-praxis/Core/cli-wrapper
mix --version
```

**Expected Output**:
- Rust injector should display version information
- PowerShell should return `True`
- Elixir should display Mix version

### 2. Set WordPress Connection

Create a configuration file for your WordPress connection:

```bash
# Create config directory
mkdir -p ~/.wp-praxis

# Create config file
cat > ~/.wp-praxis/config.yaml << 'EOF'
wordpress:
  path: "/var/www/html"
  url: "http://localhost"

outputs:
  directory: "./outputs"

logging:
  level: "info"
  file: "./wp-praxis.log"
EOF
```

**Adjust the values**:
- `path`: Path to your WordPress installation
- `url`: Your WordPress site URL

### 3. Test WordPress Connection

Test the connection using the Rust injector:

```bash
cd /home/user/wp-praxis/wp_injector
./target/release/wp_injector --test-connection
```

**Expected Output**:
```
✓ WordPress installation found at /var/www/html
✓ wp-config.php is readable
✓ Database connection successful
✓ Connection test passed
```

If you see errors, check the [Troubleshooting](#troubleshooting) section.

## Your First Workflow

Let's create a simple workflow that reads WordPress options and creates a report.

### Step 1: Create the Workflow File

Create a new file called `simple-workflow.yaml` in the tutorial directory:

```bash
cd /home/user/wp-praxis/examples/tutorials/01-getting-started
```

The workflow file is already provided for you. Let's examine it:

```yaml
# simple-workflow.yaml
version: "1.0"
metadata:
  name: "my-first-workflow"
  description: "A simple workflow to get started with WP Praxis"

config:
  wordpress:
    path: "/var/www/html"
    url: "http://localhost"

symbols:
  - name: "read_site_info"
    type: "query"
    description: "Read basic WordPress site information"
    dispatch: "rust_injector"
    context: "wordpress"
    parameters:
      operation: "get_options"
      option_names:
        - "blogname"
        - "blogdescription"
        - "siteurl"
        - "home"
        - "admin_email"
    outputs:
      - site_info

  - name: "count_posts"
    type: "query"
    description: "Count published posts"
    dispatch: "php"
    context: "wordpress"
    depends_on:
      - "read_site_info"
    parameters:
      operation: "count_posts"
      post_type: "post"
      post_status: "publish"
    outputs:
      - post_count

  - name: "generate_report"
    type: "reporting"
    description: "Generate a simple report"
    dispatch: "powershell"
    context: "wordpress"
    depends_on:
      - "read_site_info"
      - "count_posts"
    parameters:
      operation: "generate_report"
      report_type: "site_summary"
      output_format: "json"
      include_data:
        site_info: "${read_site_info.site_info}"
        post_count: "${count_posts.post_count}"
    outputs:
      - report_path

outputs:
  format: "json"
  destination: "./outputs/my-first-workflow-${timestamp}.json"
```

### Step 2: Understand the Workflow Structure

Let's break down what this workflow does:

**Metadata Section**:
```yaml
metadata:
  name: "my-first-workflow"
  description: "A simple workflow to get started with WP Praxis"
```
- Identifies your workflow
- Provides description for documentation

**Config Section**:
```yaml
config:
  wordpress:
    path: "/var/www/html"
    url: "http://localhost"
```
- Sets WordPress connection details
- Can be overridden by CLI arguments or config file

**Symbols Section**:
Each symbol represents an action or operation:

1. **read_site_info**:
   - Uses Rust injector for fast option reading
   - Retrieves basic site information
   - Outputs: `site_info`

2. **count_posts**:
   - Uses PHP for WordPress-native operations
   - Depends on `read_site_info` (sequential execution)
   - Outputs: `post_count`

3. **generate_report**:
   - Uses PowerShell for report generation
   - Depends on both previous symbols
   - References outputs: `${read_site_info.site_info}`
   - Outputs: `report_path`

**Outputs Section**:
```yaml
outputs:
  format: "json"
  destination: "./outputs/my-first-workflow-${timestamp}.json"
```
- Defines final output format and location
- `${timestamp}` is replaced with execution time

## Executing the Workflow

### Method 1: Using PowerShell Symbolic Engine (Recommended)

```bash
cd /home/user/wp-praxis

# Execute the workflow
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath "examples/tutorials/01-getting-started/simple-workflow.yaml" \
  -Verbose
```

### Method 2: Using Rust Injector Directly

```bash
cd /home/user/wp-praxis/wp_injector

./target/release/wp_injector \
  --workflow ../examples/tutorials/01-getting-started/simple-workflow.yaml \
  --execute
```

### Method 3: Using Elixir CLI (if installed)

```bash
cd /home/user/wp-praxis/Core/cli-wrapper

mix wp_praxis.execute \
  --workflow ../../examples/tutorials/01-getting-started/simple-workflow.yaml
```

### Execution Progress

During execution, you'll see output like:

```
[INFO] Loading workflow: my-first-workflow
[INFO] Validating workflow manifest...
[INFO] ✓ Workflow validation passed
[INFO] Executing symbol: read_site_info
[INFO]   Dispatching to: rust_injector
[INFO]   Context: wordpress
[INFO] ✓ Symbol completed: read_site_info (0.15s)
[INFO] Executing symbol: count_posts
[INFO]   Dispatching to: php
[INFO]   Context: wordpress
[INFO] ✓ Symbol completed: count_posts (0.08s)
[INFO] Executing symbol: generate_report
[INFO]   Dispatching to: powershell
[INFO]   Context: wordpress
[INFO] ✓ Symbol completed: generate_report (0.12s)
[INFO] Workflow completed successfully
[INFO] Total execution time: 0.35s
[INFO] Output saved to: ./outputs/my-first-workflow-2025-11-22T10-30-45.json
```

## Understanding the Output

### Output File Location

The output file is saved to:
```
/home/user/wp-praxis/outputs/my-first-workflow-2025-11-22T10-30-45.json
```

### Output File Structure

```json
{
  "workflow": {
    "name": "my-first-workflow",
    "description": "A simple workflow to get started with WP Praxis",
    "version": "1.0",
    "executed_at": "2025-11-22T10:30:45Z",
    "duration_seconds": 0.35,
    "status": "completed"
  },
  "symbols": {
    "read_site_info": {
      "status": "completed",
      "dispatch": "rust_injector",
      "duration_seconds": 0.15,
      "outputs": {
        "site_info": {
          "blogname": "My WordPress Site",
          "blogdescription": "Just another WordPress site",
          "siteurl": "http://localhost",
          "home": "http://localhost",
          "admin_email": "admin@example.com"
        }
      }
    },
    "count_posts": {
      "status": "completed",
      "dispatch": "php",
      "duration_seconds": 0.08,
      "outputs": {
        "post_count": 42
      }
    },
    "generate_report": {
      "status": "completed",
      "dispatch": "powershell",
      "duration_seconds": 0.12,
      "outputs": {
        "report_path": "./reports/site-summary-2025-11-22.json"
      }
    }
  },
  "metadata": {
    "hostname": "localhost",
    "user": "wp-praxis",
    "wp_version": "6.4.0",
    "php_version": "8.2.0"
  }
}
```

### Key Sections

1. **workflow**: Overall execution metadata
2. **symbols**: Individual symbol execution results
3. **metadata**: Environment information

## Next Steps

Congratulations! You've executed your first WP Praxis workflow. Here's what to explore next:

### 1. Modify the Workflow

Try modifying `simple-workflow.yaml`:

- Add more options to read (e.g., `posts_per_page`, `timezone_string`)
- Change the report format to `markdown`
- Add a new symbol to count pages

### 2. Explore Other Workflows

Check out these example workflows:

- [`simple-option-update.yaml`](../../workflows/simple-option-update.yaml) - Update WordPress options
- [`custom-post-type-setup.toml`](../../workflows/custom-post-type-setup.toml) - Create custom post types

### 3. Continue to Tutorial 02

Move on to [Tutorial 02: WordPress Integration](../02-wordpress-integration/README.md) to learn how to:
- Install the WP Praxis plugin
- Use the WordPress dashboard
- Upload and execute workflows from the admin panel

### 4. Read the Documentation

- [EXPLAINME.md](/home/user/wp-praxis/Docs/EXPLAINME.md) - Core concepts
- [CLAUDE.md](/home/user/wp-praxis/CLAUDE.md) - Development guide
- [STACK.md](/home/user/wp-praxis/Docs/STACK.md) - Technology stack details

## Troubleshooting

### Error: "WordPress installation not found"

**Problem**: WP Praxis cannot locate your WordPress installation.

**Solution**:
1. Verify the path in your config file:
   ```bash
   cat ~/.wp-praxis/config.yaml
   ```
2. Ensure the path points to your WordPress root directory (where `wp-config.php` is located)
3. Check file permissions:
   ```bash
   ls -la /var/www/html/wp-config.php
   ```

### Error: "Database connection failed"

**Problem**: Cannot connect to WordPress database.

**Solution**:
1. Verify WordPress is working:
   ```bash
   curl http://localhost
   ```
2. Check wp-config.php is readable:
   ```bash
   cat /var/www/html/wp-config.php | grep DB_NAME
   ```
3. Ensure database credentials are correct

### Error: "Rust injector not found"

**Problem**: Rust injector binary is missing or not compiled.

**Solution**:
1. Build the Rust injector:
   ```bash
   cd /home/user/wp-praxis/wp_injector
   cargo build --release
   ```
2. Verify the binary exists:
   ```bash
   ls -la target/release/wp_injector
   ```

### Error: "Symbol dispatch failed"

**Problem**: A symbol failed to execute.

**Solution**:
1. Check the log file:
   ```bash
   cat wp-praxis.log
   ```
2. Run with verbose output:
   ```bash
   pwsh SymbolicEngine/core/symbolic.ps1 -WorkflowPath ... -Verbose -Debug
   ```
3. Verify the dispatcher is available:
   - For `rust_injector`: Check binary exists
   - For `php`: Verify PHP CLI is installed
   - For `powershell`: Verify PowerShell scripts are present

### Workflow Execution Hangs

**Problem**: Workflow execution appears stuck.

**Solution**:
1. Check for timeout configuration in your workflow
2. Increase timeout:
   ```yaml
   config:
     execution:
       timeout: 120  # seconds
   ```
3. Check system resources (CPU, memory)
4. Look for dependency cycles in your symbols

### Permission Denied Errors

**Problem**: Cannot read/write files.

**Solution**:
1. Check file permissions:
   ```bash
   ls -la /home/user/wp-praxis/outputs/
   ```
2. Ensure output directory exists:
   ```bash
   mkdir -p /home/user/wp-praxis/outputs
   chmod 755 /home/user/wp-praxis/outputs
   ```
3. Check WordPress directory permissions:
   ```bash
   ls -la /var/www/html/
   ```

## Expected Output Example

Here's what a successful execution looks like:

```
$ pwsh SymbolicEngine/core/symbolic.ps1 -WorkflowPath examples/tutorials/01-getting-started/simple-workflow.yaml -Verbose

VERBOSE: [10:30:45] Loading workflow manifest
VERBOSE: [10:30:45] Validating YAML syntax
VERBOSE: [10:30:45] Workflow validation passed
VERBOSE: [10:30:45] Starting workflow execution: my-first-workflow
VERBOSE: [10:30:45] Executing symbol 1/3: read_site_info
VERBOSE: [10:30:45]   Dispatch target: rust_injector
VERBOSE: [10:30:45]   Operation: get_options
VERBOSE: [10:30:45]   Reading options: blogname, blogdescription, siteurl, home, admin_email
VERBOSE: [10:30:45] ✓ Symbol completed successfully (0.15s)
VERBOSE: [10:30:45] Executing symbol 2/3: count_posts
VERBOSE: [10:30:45]   Dispatch target: php
VERBOSE: [10:30:45]   Operation: count_posts
VERBOSE: [10:30:45]   Counting posts: type=post, status=publish
VERBOSE: [10:30:45] ✓ Symbol completed successfully (0.08s)
VERBOSE: [10:30:45] Executing symbol 3/3: generate_report
VERBOSE: [10:30:45]   Dispatch target: powershell
VERBOSE: [10:30:45]   Operation: generate_report
VERBOSE: [10:30:45]   Generating site summary report
VERBOSE: [10:30:45] ✓ Symbol completed successfully (0.12s)
VERBOSE: [10:30:45] Workflow completed successfully
VERBOSE: [10:30:45] Total execution time: 0.35s
VERBOSE: [10:30:45] Symbols executed: 3/3
VERBOSE: [10:30:45] Symbols failed: 0
VERBOSE: [10:30:45] Output saved to: ./outputs/my-first-workflow-2025-11-22T10-30-45.json

SUCCESS: Workflow 'my-first-workflow' completed successfully
```

## Getting Help

If you encounter issues not covered here:

1. **Check the logs**: `cat wp-praxis.log`
2. **Review documentation**: See `Docs/` directory
3. **Check examples**: See `examples/` directory
4. **GitHub Issues**: Report bugs and request features

## Summary

In this tutorial, you learned:

✓ How to set up WP Praxis environment
✓ How to create a simple workflow manifest
✓ How to execute workflows using different methods
✓ How to interpret workflow outputs
✓ How to troubleshoot common issues

**Continue your learning** with [Tutorial 02: WordPress Integration](../02-wordpress-integration/README.md)!
