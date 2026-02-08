# WP Praxis - Frequently Asked Questions

## General Questions

### What is WP Praxis?

WP Praxis is a modular symbolic system for WordPress that allows you to define workflows declaratively using YAML/TOML manifests and execute them across multiple programming languages. It combines recursive logic, metadata-driven configuration, and distributed execution.

### Why multiple programming languages?

Each language serves a specific purpose:
- **Rust**: High-performance operations (database access, bulk processing)
- **PowerShell**: Symbolic operations and workflows
- **PHP**: WordPress-native integration
- **Elixir**: Orchestration and state management
- **TypeScript**: Dashboard, swarm coordination

This polyglot approach allows each component to leverage the best tool for its specific job.

### Is WP Praxis production-ready?

WP Praxis is in early development (version 0.1.0). Core functionality is stable, but APIs may change. Use in production with caution and thorough testing.

### What's the license?

GNU AGPL v3 (copyleft). This means:
- You can use it freely
- You must disclose source code if you serve it over a network
- Modifications must also be AGPL v3
- See LICENSE file for full details

## Installation & Setup

### What are the minimum requirements?

**For Docker (recommended)**:
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM
- 10GB disk space

**For manual installation**:
- Rust 1.70+
- PowerShell 7.3+
- PHP 7.4+ (8.0+ recommended)
- Elixir 1.14+
- Bun 1.0+
- PostgreSQL 13+ (optional, for state management)

### Do I need all languages installed?

For basic usage, you need:
- PowerShell (core engine)
- PHP (WordPress integration)
- Rust (injector)

For advanced features:
- Elixir (database/state management)
- TypeScript/Bun (swarm/dashboard)

### Can I run WP Praxis on Windows?

Yes! WP Praxis supports:
- Windows (PowerShell native, WSL recommended for full stack)
- Linux (recommended for production)
- macOS (fully supported)

### How do I update WP Praxis?

```bash
cd /home/user/wp-praxis
git pull origin main

# Rebuild components
cd wp_injector && cargo build --release
cd ../Core/cli-wrapper && mix deps.get && mix compile
cd ../SymbolicEngine/swarm && bun install
cd ../dashboard && bun install
```

## Workflows

### How do I create a workflow?

1. Create a YAML or TOML file
2. Define metadata, config, and symbols
3. Validate: `pwsh symbolic.ps1 -WorkflowPath <file> -ValidateOnly`
4. Execute: `pwsh symbolic.ps1 -WorkflowPath <file>`

See [Tutorial 01](tutorials/01-getting-started/README.md) for details.

### What's the difference between YAML and TOML?

Both are supported equally. Choose based on preference:
- **YAML**: More compact, better for complex nested structures
- **TOML**: More explicit, better for simple configurations

### Can workflows call other workflows?

Not directly in v0.1.0, but you can:
- Use symbol composition
- Create reusable symbol libraries
- Execute multiple workflows sequentially

Workflow composition is planned for v0.2.0.

### How do I handle sensitive data (passwords, API keys)?

1. **Environment variables**: Reference in workflows as `${env.VAR_NAME}`
2. **Separate config files**: Keep sensitive data in `.gitignore`d files
3. **WordPress constants**: Use `wp-config.php` constants
4. **Never commit**: Never commit sensitive data to version control

### What's the maximum workflow size?

No hard limit, but consider:
- Keep workflows focused (< 20 symbols)
- Split large workflows into multiple files
- Use swarm for parallelization
- Memory limits depend on system resources

## Execution

### What happens if a symbol fails?

1. Execution stops at the failed symbol
2. Dependent symbols are skipped
3. Rollback is triggered (if enabled)
4. Error is logged and reported
5. Workflow status set to "failed"

### How does rollback work?

Rollback strategies:
- **restore_from_baseline**: Restore entire state from baseline
- **reverse_operations**: Undo operations in reverse order
- **custom**: Custom rollback logic per symbol

Configure in workflow:
```yaml
rollback:
  on_error: "automatic"
  strategy: "restore_from_baseline"
```

### Can I pause/resume workflows?

Not in v0.1.0. Workflows run to completion or failure. Checkpoint/resume is planned for v0.2.0.

### How do I debug a failing workflow?

1. **Verbose logging**: Run with `-Verbose` flag
2. **Check logs**: Review `wp-praxis.log`
3. **Validate first**: Use `-ValidateOnly`
4. **Test symbols individually**: Create minimal test workflows
5. **Check dependencies**: Verify all required services are running

## WordPress Integration

### Does WP Praxis work with multisite?

Yes, with considerations:
- Specify site ID in context
- Some operations may need to loop through sites
- Network-level operations require special permissions

Multisite features are being expanded in future versions.

### Can I use WP Praxis with managed WordPress hosts?

It depends on the host:
- **VPS/Dedicated**: Full support
- **Shared hosting**: Limited (depends on access)
- **Managed WordPress**: Limited (depends on restrictions)

Best results with hosts that allow SSH access and custom software.

### Will WP Praxis modify my database directly?

WP Praxis can modify the database through:
1. **WordPress functions** (PHP dispatcher) - safest, uses WP API
2. **Direct SQL** (Rust injector) - faster, requires caution

We recommend using WordPress functions when possible for safety and compatibility.

### Can I use WP Praxis with page builders?

Yes, but limitations apply:
- Page builder data is in post meta
- Some builders use proprietary formats
- Symbolic operations work with underlying data
- Builder-specific features may not be accessible

## Performance

### How fast is WP Praxis?

Performance varies by operation:
- **Simple option update**: < 0.1s
- **Bulk post creation (100 posts)**: 1-2s with Rust
- **Comprehensive audit**: 1-5s depending on site size
- **Distributed execution**: 2-5x faster with 4 workers

See [performance benchmarks](../Aspects/performance/).

### Does WP Praxis slow down WordPress?

No. WP Praxis:
- Runs as separate process
- Doesn't load on every request
- Only active during workflow execution
- Plugin adds minimal overhead

### How many workers should I use?

Guidelines:
- **Start with**: 2-4 workers
- **Max practical**: 8-10 workers for most workloads
- **Scaling**: Add workers if CPU utilization < 60%
- **Bottleneck**: Beyond a point, database becomes bottleneck

Monitor worker utilization in dashboard.

### Can I run WP Praxis on a small VPS?

Yes, minimum specs:
- 1 CPU core
- 2GB RAM
- 10GB disk
- Network connectivity

Performance will be limited, but functional for small sites.

## Security

### Is WP Praxis secure?

Security considerations:
- **Input validation**: All inputs are validated
- **SQL injection**: Prepared statements used
- **File access**: Sandboxed to WordPress directory
- **Permissions**: Respects WordPress capabilities
- **AGPL requirement**: All network-served modifications must be disclosed

Always follow security best practices.

### Can WP Praxis be used maliciously?

Like any powerful tool, it requires responsible use:
- Limit user access (admin only recommended)
- Use role-based access control
- Audit all workflow executions
- Review workflows before execution
- Keep WP Praxis updated

### Should I expose the swarm dispatcher publicly?

**No.** The swarm dispatcher should:
- Run on internal network
- Be behind firewall
- Use authentication (if exposed)
- Use HTTPS/TLS for communication

Never expose dispatcher to public internet without proper security.

## Database & State

### Why PostgreSQL?

PostgreSQL provides:
- JSONB for flexible schema
- Excellent Elixir/Ecto support
- ACID compliance
- Strong querying capabilities
- Open source

### Can I use MySQL instead of PostgreSQL?

Currently, no. Ecto is configured for PostgreSQL. MySQL support may come in future versions.

### How much disk space do baselines use?

Depends on site size:
- **Small site** (< 100 posts): 1-5 MB per baseline
- **Medium site** (100-1000 posts): 5-50 MB per baseline
- **Large site** (1000+ posts): 50-500 MB per baseline

Baselines are compressed to save space.

### How long should I keep baselines?

Recommendations:
- **Keep forever**: Normative baselines
- **30 days**: Regular operation baselines
- **7 days**: Temporary test baselines
- **Archive**: Important milestones

Configure retention in workflow config.

## Troubleshooting

### Workflow validation fails with "Unknown symbol type"

**Cause**: Invalid symbol type in workflow
**Solution**: Check symbol type is one of: action, query, audit, validation, reporting, notification, swarm, state

### "Dispatcher not found" error

**Cause**: Swarm dispatcher not running or wrong URL
**Solution**:
1. Check dispatcher is running: `curl http://localhost:8080/health`
2. Verify URL in workflow or CLI args
3. Check network connectivity

### Database connection failed

**Cause**: PostgreSQL not running or wrong credentials
**Solution**:
1. Check PostgreSQL: `sudo systemctl status postgresql`
2. Verify connection string in config
3. Test connection: `psql -U wp_praxis wp_praxis_dev`
4. Run migrations: `mix ecto.migrate`

### Worker not connecting to dispatcher

**Cause**: Network issue or dispatcher not ready
**Solution**:
1. Check dispatcher logs
2. Test connectivity: `curl https://dispatcher:8080/health`
3. Verify worker capabilities match requirements
4. Check firewall rules

For more troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Development

### How do I contribute?

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### How do I add a custom symbol type?

See [Tutorial 05: Custom Symbols](tutorials/05-custom-symbols/README.md) for complete guide.

### Can I add support for another language?

Yes! Requirements:
1. Implement symbol dispatch interface
2. Add to dispatcher routing
3. Document usage
4. Provide examples
5. Submit PR

### Where should I report bugs?

GitHub Issues: https://github.com/wp-praxis/wp-praxis/issues

Include:
- WP Praxis version
- OS and environment
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs

## Roadmap

### What's coming in future versions?

**v0.2.0**:
- Workflow composition
- Checkpoint/resume
- Enhanced swarm features
- Improved dashboard

**v0.3.0**:
- LFE macro layer integration
- Racket introspection tools
- Dhall config validation
- WebAssembly modules

**v1.0.0**:
- Stable APIs
- Production hardening
- Comprehensive documentation
- Certification program

See [ROADMAP.md](../ROADMAP.md) for details.

### Will there be a hosted version?

Potentially. AGPL license allows commercial hosting, but requires source disclosure. Contact maintainers for partnership opportunities.

### Is professional support available?

Not currently. Community support via GitHub Discussions. Professional support may be offered in future.

---

**Have a question not answered here?**

- Check [Documentation](../Docs/)
- Search [GitHub Discussions](https://github.com/wp-praxis/wp-praxis/discussions)
- Open an [Issue](https://github.com/wp-praxis/wp-praxis/issues)
