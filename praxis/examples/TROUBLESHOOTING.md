# WP Praxis Troubleshooting Guide

## Quick Diagnostics

Run these commands to check system health:

```bash
# Check all components
cd /home/user/wp-praxis

# 1. Rust injector
./wp_injector/target/release/wp_injector --version

# 2. PowerShell symbolic engine
pwsh -Command "Test-Path SymbolicEngine/core/symbolic.ps1"

# 3. Elixir CLI
cd Core/cli-wrapper && mix --version

# 4. TypeScript (Bun)
bun --version

# 5. WordPress connection (if configured)
./wp_injector/target/release/wp_injector --test-connection

# 6. Database connection (if configured)
psql -U wp_praxis wp_praxis_dev -c "SELECT version();"
```

---

## Installation Issues

### Error: "cargo: command not found"

**Problem**: Rust is not installed

**Solution**:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### Error: "pwsh: command not found"

**Problem**: PowerShell is not installed

**Solution**:
```bash
# Ubuntu/Debian
wget https://github.com/PowerShell/PowerShell/releases/download/v7.3.9/powershell_7.3.9-1.deb_amd64.deb
sudo dpkg -i powershell_7.3.9-1.deb_amd64.deb

# Or use snap
sudo snap install powershell --classic
```

### Error: "mix: command not found"

**Problem**: Elixir is not installed

**Solution**:
```bash
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt-get update
sudo apt-get install elixir
```

### Error: "bun: command not found"

**Problem**: Bun is not installed

**Solution**:
```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
```

---

## Build Issues

### Rust Build Fails: "linker 'cc' not found"

**Problem**: Missing C compiler

**Solution**:
```bash
sudo apt-get install build-essential
```

### Rust Build Fails: "could not find OpenSSL"

**Problem**: Missing OpenSSL development files

**Solution**:
```bash
sudo apt-get install libssl-dev pkg-config
```

### Elixir Deps Fail: "Could not compile dependency"

**Problem**: Missing Erlang or incompatible version

**Solution**:
```bash
# Install Erlang 25+
sudo apt-get install esl-erlang
mix local.hex --force
mix local.rebar --force
mix deps.clean --all
mix deps.get
```

### TypeScript Build Fails: "Cannot find module"

**Problem**: Dependencies not installed

**Solution**:
```bash
cd SymbolicEngine/swarm
rm -rf node_modules
bun install
```

---

## Workflow Issues

### Error: "Workflow validation failed: Invalid YAML syntax"

**Problem**: YAML syntax error

**Solution**:
1. Check indentation (use spaces, not tabs)
2. Ensure proper quoting of special characters
3. Validate with online tool: yamllint.com
4. Check for duplicate keys

**Common YAML mistakes**:
```yaml
# ❌ Wrong - tab indentation
symbols:
	- name: "test"

# ✅ Correct - space indentation
symbols:
  - name: "test"

# ❌ Wrong - missing quotes
description: This has a: colon

# ✅ Correct - quoted string
description: "This has a: colon"
```

### Error: "Unknown symbol type"

**Problem**: Invalid symbol type

**Solution**: Use only these types:
- `action`
- `query`
- `audit`
- `validation`
- `reporting`
- `notification`
- `swarm`
- `state`
- `aggregation`

### Error: "Circular dependency detected"

**Problem**: Symbol dependencies form a cycle

**Solution**:
```yaml
# ❌ Wrong - circular dependency
symbols:
  - name: "symbol_a"
    depends_on: ["symbol_b"]
  - name: "symbol_b"
    depends_on: ["symbol_a"]

# ✅ Correct - linear dependency
symbols:
  - name: "symbol_a"
  - name: "symbol_b"
    depends_on: ["symbol_a"]
```

### Error: "Symbol reference not found"

**Problem**: Referenced output doesn't exist

**Solution**:
```yaml
# Ensure symbol name matches
- name: "read_options"
  outputs:
    - option_values  # Define output

- name: "use_options"
  depends_on: ["read_options"]
  parameters:
    data: "${read_options.option_values}"  # Reference output
```

---

## Execution Issues

### Workflow Hangs / No Output

**Problem**: Execution stuck or silent failure

**Diagnosis**:
```bash
# Run with verbose output
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath path/to/workflow.yaml \
  -Verbose -Debug

# Check logs
tail -f wp-praxis.log
```

**Common Causes**:
1. **Timeout too low**: Increase in workflow config
2. **Resource limits**: Check CPU/memory
3. **Deadlock**: Check for circular waits
4. **Network issue**: Verify connectivity

### Symbol Execution Fails: "Dispatcher not found"

**Problem**: Cannot execute symbol

**Diagnosis**:
```bash
# Check dispatcher availability
which pwsh  # PowerShell
which php   # PHP
./wp_injector/target/release/wp_injector --version  # Rust

# Check if in PATH
echo $PATH
```

**Solution**:
- Ensure dispatcher binary exists
- Add to PATH if needed
- Use absolute paths in config

### Error: "Operation timed out"

**Problem**: Symbol execution exceeded timeout

**Solution**:
```yaml
# Increase timeout
config:
  execution:
    timeout: 300  # 5 minutes

# Or per-symbol
symbols:
  - name: "slow_operation"
    timeout: 600  # 10 minutes
```

### Error: "Permission denied"

**Problem**: Insufficient permissions

**Solution**:
```bash
# Check file permissions
ls -la /var/www/html/wp-config.php

# Fix WordPress permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Fix output directory
mkdir -p outputs
chmod 755 outputs
```

---

## WordPress Integration Issues

### Error: "WordPress installation not found"

**Problem**: Cannot locate WordPress

**Solution**:
```bash
# Verify WordPress path
ls -la /var/www/html/wp-config.php

# Update config
nano ~/.wp-praxis/config.yaml
# Set correct path:
wordpress:
  path: "/var/www/html"
```

### Error: "Database connection failed"

**Problem**: Cannot connect to WordPress database

**Diagnosis**:
```bash
# Check wp-config.php
cat /var/www/html/wp-config.php | grep DB_

# Test MySQL connection
mysql -u wordpress_user -p -h localhost wordpress_db
```

**Solution**:
1. Verify credentials in wp-config.php
2. Ensure MySQL is running
3. Check firewall rules
4. Test connection manually

### Error: "WordPress function not found"

**Problem**: PHP symbol trying to use unavailable function

**Solution**:
```php
// Check if function exists before use
if (function_exists('wp_insert_post')) {
    wp_insert_post($post_data);
} else {
    // Fallback or error
}
```

### Plugin Activation Failed

**Problem**: WP Praxis plugin cannot activate

**Diagnosis**:
```bash
# Check PHP error log
tail -f /var/log/php/error.log

# Check WordPress debug log
tail -f /var/www/html/wp-content/debug.log
```

**Common Issues**:
1. **PHP version**: Requires PHP 7.4+
2. **Missing extensions**: Install php-mysql, php-xml
3. **File permissions**: Fix ownership and permissions
4. **Memory limit**: Increase in php.ini

---

## Database Issues

### PostgreSQL Connection Failed

**Problem**: Cannot connect to PostgreSQL

**Diagnosis**:
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U wp_praxis -d wp_praxis_dev -h localhost
```

**Solution**:
```bash
# Start PostgreSQL
sudo systemctl start postgresql

# Check listen address in postgresql.conf
sudo nano /etc/postgresql/15/main/postgresql.conf
# Ensure: listen_addresses = 'localhost'

# Check pg_hba.conf
sudo nano /etc/postgresql/15/main/pg_hba.conf
# Add: local   all   wp_praxis   md5
```

### Error: "Ecto.Migration.Error"

**Problem**: Database migration failed

**Solution**:
```bash
cd Core/cli-wrapper

# Check migration status
mix ecto.migrations

# Rollback and retry
mix ecto.rollback
mix ecto.migrate

# If corrupt, reset (WARNING: destroys data)
mix ecto.drop
mix ecto.create
mix ecto.migrate
```

### Error: "Database locked"

**Problem**: SQLite or locked tables (if using SQLite in dev)

**Solution**:
```bash
# Find processes using database
lsof | grep wp_praxis

# Kill stuck processes
kill -9 <PID>

# For PostgreSQL, check for locks
psql -U wp_praxis wp_praxis_dev
SELECT * FROM pg_locks;
```

---

## Swarm / Distributed Execution Issues

### Workers Not Connecting to Dispatcher

**Problem**: Workers cannot reach dispatcher

**Diagnosis**:
```bash
# Check dispatcher is running
curl http://localhost:8080/health

# Check from worker machine
curl https://dispatcher-host:8080/health

# Check firewall
sudo ufw status
```

**Solution**:
```bash
# Open port on dispatcher
sudo ufw allow 8080/tcp

# Check dispatcher binding
# Ensure dispatcher binds to 0.0.0.0, not 127.0.0.1

# Verify network connectivity
ping dispatcher-host
```

### Error: "No workers available"

**Problem**: Dispatcher has no registered workers

**Diagnosis**:
```bash
# Check worker status
curl http://localhost:8080/api/workers

# Check worker logs
docker logs <worker-container>
```

**Solution**:
1. Start workers: `bun run src/worker.ts`
2. Check worker capabilities match requirements
3. Verify worker registration timeout
4. Check network connectivity

### Load Balancing Not Working

**Problem**: Tasks not distributed evenly

**Diagnosis**:
```bash
# Check worker load
curl http://localhost:8080/api/workers | jq

# Monitor in dashboard
open http://localhost:3000
```

**Solution**:
- Adjust `max_concurrent` on workers
- Change load balancing strategy
- Monitor worker health
- Scale workers appropriately

### Error: "Worker health check failed"

**Problem**: Worker marked as unhealthy

**Diagnosis**:
```bash
# Check worker resources
top
free -h
df -h
```

**Solution**:
- Increase worker resources
- Reduce `max_concurrent`
- Fix underlying issue (CPU, memory, disk)
- Restart worker

---

## Performance Issues

### Slow Workflow Execution

**Problem**: Workflow takes longer than expected

**Diagnosis**:
```bash
# Enable timing
pwsh SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath path/to/workflow.yaml \
  -Verbose

# Check symbol timings in output
```

**Optimization**:
1. **Use Rust for bulk operations**: Faster than PHP
2. **Enable parallelization**: Use swarm for independent symbols
3. **Reduce symbol count**: Combine related operations
4. **Optimize database queries**: Add indexes, use prepared statements
5. **Cache results**: Avoid redundant operations

### High Memory Usage

**Problem**: WP Praxis consuming too much memory

**Solution**:
```bash
# Monitor memory
top -p $(pgrep -f symbolic)

# Reduce batch sizes
# In workflow, smaller batch sizes:
parameters:
  batch_size: 100  # Instead of 1000

# Increase PHP memory limit
# In php.ini:
memory_limit = 256M
```

### Database Performance Degradation

**Problem**: Database queries getting slower

**Solution**:
```sql
-- PostgreSQL: Analyze and vacuum
ANALYZE;
VACUUM FULL;

-- Add indexes
CREATE INDEX idx_workflow_status ON workflow_executions(status);
CREATE INDEX idx_symbol_workflow ON symbol_executions(workflow_id);

-- Check slow queries
SELECT * FROM pg_stat_statements ORDER BY total_time DESC;
```

---

## Docker Issues

### Error: "Cannot connect to Docker daemon"

**Problem**: Docker not running

**Solution**:
```bash
# Start Docker
sudo systemctl start docker

# Add user to docker group (avoid sudo)
sudo usermod -aG docker $USER
# Log out and back in
```

### Container Won't Start

**Problem**: Docker container fails to start

**Diagnosis**:
```bash
# Check logs
docker logs <container-name>

# Check status
docker ps -a

# Inspect container
docker inspect <container-name>
```

**Common Issues**:
1. **Port conflict**: Port already in use
2. **Volume issues**: Permission or mounting problems
3. **Resource limits**: Insufficient memory/CPU
4. **Image issues**: Rebuild image

**Solutions**:
```bash
# Change port
# In docker-compose.yml:
ports:
  - "8001:80"  # Instead of 8000

# Fix volumes
docker volume ls
docker volume rm <volume-name>

# Rebuild image
docker-compose build --no-cache

# Increase resources
# In Docker Desktop: Settings > Resources
```

### Error: "Network not found"

**Problem**: Docker network issue

**Solution**:
```bash
# Recreate network
docker network rm wp-praxis-network
docker network create wp-praxis-network

# Or let docker-compose handle it
docker-compose down
docker-compose up -d
```

---

## Common Error Messages

### "Error: EADDRINUSE: Address already in use"

**Problem**: Port already in use

**Solution**:
```bash
# Find process using port
sudo lsof -i :8080

# Kill process
kill -9 <PID>

# Or use different port
```

### "Error: Cannot find module"

**Problem**: Node/Bun module not found

**Solution**:
```bash
# Reinstall dependencies
rm -rf node_modules
bun install

# Or npm
rm -rf node_modules package-lock.json
npm install
```

### "Error: EACCES: permission denied"

**Problem**: Insufficient file permissions

**Solution**:
```bash
# Fix ownership
sudo chown -R $USER:$USER /path/to/directory

# Fix permissions
chmod -R 755 /path/to/directory
```

---

## Getting More Help

### Enable Debug Logging

```bash
# PowerShell
pwsh -Command "Set-PSDebug -Trace 2"

# Rust (set environment variable)
export RUST_LOG=debug
./wp_injector/target/release/wp_injector

# Elixir
export MIX_ENV=dev
export ELIXIR_LOG_LEVEL=debug
```

### Collect Diagnostic Information

```bash
# System info
uname -a
lsb_release -a

# WP Praxis versions
git log -1 --oneline
./wp_injector/target/release/wp_injector --version
pwsh --version
php --version
mix --version
bun --version

# Resource usage
free -h
df -h
top -bn1 | head -20

# Network
netstat -tuln
ss -tuln
```

### Report a Bug

Include:
1. WP Praxis version (`git log -1`)
2. OS and version
3. Error message (full stack trace)
4. Steps to reproduce
5. Workflow file (if applicable)
6. Relevant logs
7. Expected vs actual behavior

**Submit to**: https://github.com/wp-praxis/wp-praxis/issues

---

## Still Need Help?

1. **Check Documentation**: `/Docs/`
2. **Review Examples**: `/examples/`
3. **Search Issues**: GitHub Issues
4. **Ask Community**: GitHub Discussions
5. **FAQ**: [FAQ.md](FAQ.md)
