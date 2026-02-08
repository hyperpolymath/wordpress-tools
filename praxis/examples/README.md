# WP Praxis Examples

## Overview

This directory contains comprehensive examples, tutorials, demonstrations, and sample data for WP Praxis. All examples are production-ready and fully tested.

## Directory Structure

```
examples/
├── workflows/               # Complete workflow manifests
├── tutorials/              # Step-by-step learning guides
├── demos/                  # Working demonstrations
├── use-cases/             # Real-world scenarios
├── testing/               # Test fixtures and scenarios
├── docker/                # Container configurations
├── quickstart/            # Quick setup scripts
├── data/                  # Sample data files
├── video-demo/           # Video demonstration scripts
└── README.md             # This file
```

## Quick Start

### Option 1: One-Command Setup

```bash
cd examples/quickstart
./quickstart.sh
```

This script will:
- Check prerequisites
- Build all components
- Setup configuration
- Create directories
- Optionally setup database
- Run example workflow
- Start dashboard

### Option 2: Docker Demo

```bash
cd examples/demos/full-stack-demo
docker-compose up -d
```

Access:
- WordPress: http://localhost:8000
- Dashboard: http://localhost:3000
- GraphQL: http://localhost:4000/graphql

### Option 3: Manual Setup

Follow [Tutorial 01: Getting Started](tutorials/01-getting-started/README.md)

## Workflow Examples

Located in `workflows/`:

1. **[simple-option-update.yaml](workflows/simple-option-update.yaml)**
   - Basic WordPress option updates
   - Demonstrates rollback
   - Beginner-friendly
   - **Use case**: Update site configuration

2. **[custom-post-type-setup.toml](workflows/custom-post-type-setup.toml)**
   - Complete CPT with taxonomies and meta boxes
   - Dependency chain demonstration
   - **Use case**: Content structure setup

3. **[multi-language-workflow.yaml](workflows/multi-language-workflow.yaml)**
   - Cross-layer execution (Rust, PHP, PowerShell, Elixir)
   - State management
   - **Use case**: Complex multi-step operations

4. **[audit-and-baseline.toml](workflows/audit-and-baseline.toml)**
   - Comprehensive auditing
   - Baseline management
   - Reporting and compliance
   - **Use case**: Governance and compliance

5. **[swarm-distributed.yaml](workflows/swarm-distributed.yaml)**
   - Distributed parallel execution
   - Load balancing
   - Auto-scaling
   - **Use case**: High-performance bulk operations

## Tutorials

Interactive learning guides in `tutorials/`:

### [01: Getting Started](tutorials/01-getting-started/README.md)
- **Duration**: 15-20 minutes
- **Level**: Beginner
- **Topics**: First workflow, basic concepts, troubleshooting

### [02: WordPress Integration](tutorials/02-wordpress-integration/README.md)
- **Duration**: 20-25 minutes
- **Level**: Intermediate
- **Topics**: Plugin installation, admin interface, REST API

### [03: Swarm Setup](tutorials/03-swarm-setup/README.md)
- **Duration**: 30 minutes
- **Level**: Advanced
- **Topics**: Distributed execution, workers, load balancing

### [04: Database Integration](tutorials/04-database-integration/README.md)
- **Duration**: 25 minutes
- **Level**: Intermediate
- **Topics**: Elixir/Ecto, PostgreSQL, GraphQL API

### [05: Custom Symbols](tutorials/05-custom-symbols/README.md)
- **Duration**: 30 minutes
- **Level**: Advanced
- **Topics**: Extending WP Praxis, custom operations

## Demonstrations

Working demos in `demos/`:

### [Full Stack Demo](demos/full-stack-demo/)
Complete environment with Docker Compose:
- WordPress + MySQL
- PostgreSQL + Ecto
- Swarm dispatcher + workers
- Dashboard + GraphQL API

### [CLI Demo](demos/cli-demo/)
Command-line usage examples:
- PowerShell scripts
- Rust injector commands
- Elixir CLI operations

### [API Demo](demos/api-demo/)
API integration examples:
- GraphQL queries and mutations
- REST API calls
- WebSocket subscriptions

### [Dashboard Demo](demos/dashboard-demo/)
Web UI walkthrough:
- Pre-configured workflows
- Visualization examples
- Interactive tutorial

## Real-World Use Cases

Practical scenarios in `use-cases/`:

### [WordPress Migration](use-cases/wordpress-migration/)
Complete site migration workflow:
- Export symbolic state
- Transform configuration
- Import to target
- Validation and rollback

### [Plugin Deployment](use-cases/plugin-deployment/)
Automated plugin configuration:
- Installation workflow
- Configuration injection
- Post-activation setup

### [Content Structure](use-cases/content-structure/)
Content architecture setup:
- Custom post types
- Taxonomies
- Relationships
- Metadata

### [Performance Optimization](use-cases/performance-optimization/)
Performance tuning workflow:
- Audit current state
- Identify bottlenecks
- Apply optimizations
- Measure improvements

### [Security Hardening](use-cases/security-hardening/)
Security workflow:
- Security audit
- Apply hardening rules
- Validate configuration
- Compliance reporting

## Testing Examples

Test fixtures and scenarios in `testing/`:

### [Test Fixtures](testing/test-fixtures/)
- Valid workflows
- Invalid workflows (negative tests)
- Edge cases
- Performance test data

### [Test Scenarios](testing/test-scenarios/)
- Unit test examples
- Integration test examples
- E2E test examples
- Performance benchmarks

## Docker Examples

Container configurations in `docker/`:

- **Dockerfile.complete**: All-in-one container
- **docker-compose.yml**: Multi-container setup
- **kubernetes/**: K8s manifests for production

## Sample Data

Pre-built data files in `data/`:

- **sample-symbols.json**: 50+ example symbols
- **sample-workflows.json**: 20+ example workflows
- **sample-baselines.json**: Example baselines
- **sample-audit-reports.json**: Example audit outputs

## Video Demo

Demonstration scripts in `video-demo/`:

- **DEMO_SCRIPT.md**: Complete demo walkthrough
- Screenshots and command examples
- Step-by-step presentation guide

## Usage Patterns

### Execute a Workflow

```bash
# Using PowerShell
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath examples/workflows/simple-option-update.yaml \
  -Verbose

# Using Elixir CLI
cd Core/cli-wrapper
mix wp_praxis.execute \
  --workflow ../../examples/workflows/simple-option-update.yaml

# Using Docker
docker run -v $(pwd):/wp-praxis wp-praxis \
  execute --workflow examples/workflows/simple-option-update.yaml
```

### Run Tests

```bash
# Run all tests
pwsh tests/run-tests.ps1

# Run specific test
pwsh tests/run-tests.ps1 -TestFile examples/testing/test-scenarios/unit-tests.ps1
```

### Start Dashboard

```bash
cd SymbolicEngine/dashboard
bun install
bun run dev
# Open http://localhost:3000
```

## Common Tasks

### Create a New Workflow

1. Copy a template:
   ```bash
   cp examples/workflows/simple-option-update.yaml my-workflow.yaml
   ```

2. Edit the workflow:
   ```yaml
   metadata:
     name: "my-workflow"
     description: "My custom workflow"

   symbols:
     - name: "my_symbol"
       type: "action"
       dispatch: "rust_injector"
       # ... configuration
   ```

3. Validate:
   ```bash
   pwsh SymbolicEngine/core/symbolic.ps1 \
     -WorkflowPath my-workflow.yaml \
     -ValidateOnly
   ```

4. Execute:
   ```bash
   pwsh SymbolicEngine/core/symbolic.ps1 \
     -WorkflowPath my-workflow.yaml
   ```

### Create a Baseline

```bash
pwsh SymbolicEngine/core/Set-NormativeBaseline.ps1 \
  -BaselineName "my_baseline" \
  -IncludeOptions \
  -IncludePosts
```

### Run an Audit

```bash
pwsh SymbolicEngine/core/Run-SymbolicAudit.ps1 \
  -AuditType comprehensive \
  -BaselineBefore "before_changes" \
  -BaselineAfter "after_changes"
```

### Compare Baselines

```bash
pwsh SymbolicEngine/core/Visualize-SymbolicDiff.ps1 \
  -BaselineBefore "baseline_1" \
  -BaselineAfter "baseline_2" \
  -OutputFormat html
```

## Learning Path

### Beginner Path
1. Read [CLAUDE.md](../CLAUDE.md) - Project overview
2. Follow [Tutorial 01](tutorials/01-getting-started/README.md)
3. Execute [simple-option-update.yaml](workflows/simple-option-update.yaml)
4. Explore [Dashboard Demo](demos/dashboard-demo/)

### Intermediate Path
1. Complete Beginner Path
2. Follow [Tutorial 02](tutorials/02-wordpress-integration/README.md)
3. Execute [custom-post-type-setup.toml](workflows/custom-post-type-setup.toml)
4. Follow [Tutorial 04](tutorials/04-database-integration/README.md)
5. Explore [Use Cases](use-cases/)

### Advanced Path
1. Complete Intermediate Path
2. Follow [Tutorial 03](tutorials/03-swarm-setup/README.md)
3. Execute [swarm-distributed.yaml](workflows/swarm-distributed.yaml)
4. Follow [Tutorial 05](tutorials/05-custom-symbols/README.md)
5. Review [Full Stack Demo](demos/full-stack-demo/)
6. Deploy to production with [Docker/Kubernetes](docker/)

## Troubleshooting

### Common Issues

**Workflow Validation Failed**
- Check YAML/TOML syntax
- Verify symbol names are unique
- Ensure dependency chains are acyclic

**Execution Timeout**
- Increase timeout in workflow config
- Check system resources
- Review symbol operations

**Database Connection Error**
- Verify PostgreSQL is running
- Check connection string in config
- Run migrations: `mix ecto.migrate`

**Swarm Workers Not Connecting**
- Check network connectivity
- Verify dispatcher URL
- Review worker logs

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

## Contributing Examples

To contribute a new example:

1. Create the example in appropriate directory
2. Include comprehensive README
3. Add test cases
4. Update this index
5. Submit pull request

## Resources

- **Documentation**: [/Docs](/Docs)
- **Main README**: [/README.md](/README.md)
- **Architecture**: [/Docs/UML](/Docs/UML)
- **API Reference**: [/Docs/API.md](/Docs/API.md)

## Support

- **Issues**: [GitHub Issues](https://github.com/wp-praxis/wp-praxis/issues)
- **Discussions**: [GitHub Discussions](https://github.com/wp-praxis/wp-praxis/discussions)
- **Documentation**: [/Docs](/Docs)

## License

WP Praxis is licensed under GNU AGPL v3. See [LICENSE](../LICENSE) for details.

---

**Last Updated**: 2025-11-22
**Examples Version**: 1.0.0
