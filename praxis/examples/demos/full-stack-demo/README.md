# Full Stack Demo - Complete WP Praxis Environment

## Overview

This demo provides a complete, production-like WP Praxis environment using Docker Compose. All components run in containers with proper networking and data persistence.

## Components

- **WordPress** (port 8000): WordPress with MySQL backend
- **PostgreSQL** (port 5432): Ecto database for state management
- **Swarm Dispatcher** (port 8080): Coordinator for distributed execution
- **GraphQL API** (port 4000): Query interface for workflow data
- **Workers** (scalable): Distributed execution workers
- **Dashboard** (port 3000): Web-based monitoring UI

## Quick Start

```bash
cd /home/user/wp-praxis/examples/demos/full-stack-demo

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Scale workers to 4
docker-compose up -d --scale worker=4

# Check status
docker-compose ps
```

## Access Points

After starting:

- **WordPress**: http://localhost:8000
- **Dashboard**: http://localhost:3000
- **GraphQL Playground**: http://localhost:4000/graphql
- **Swarm API**: http://localhost:8080

## Initial Setup

### 1. WordPress Setup

Visit http://localhost:8000 and complete WordPress installation:

```
Site Title: WP Praxis Demo
Username: admin
Password: admin_password
Email: admin@example.com
```

### 2. Install WP Praxis Plugin

```bash
# Copy plugin to WordPress container
docker cp ../../../plugin/wp-praxis wp-praxis-wordpress:/var/www/html/wp-content/plugins/

# Set permissions
docker exec wp-praxis-wordpress chown -R www-data:www-data /var/www/html/wp-content/plugins/wp-praxis
```

Activate plugin in WordPress admin.

### 3. Initialize Database

```bash
# Run Ecto migrations
docker exec wp-praxis-dispatcher mix ecto.create
docker exec wp-praxis-dispatcher mix ecto.migrate
```

### 4. Load Sample Data

```bash
# Load sample workflows and baselines
docker exec wp-praxis-dispatcher node scripts/load-sample-data.js
```

## Running Demo Workflows

### Execute Simple Workflow

```bash
docker exec wp-praxis-dispatcher \
  pwsh /app/SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath /wp-praxis/examples/workflows/simple-option-update.yaml
```

### Execute Distributed Workflow

```bash
docker exec wp-praxis-dispatcher \
  pwsh /app/SymbolicEngine/core/symbolic.ps1 \
  -WorkflowPath /wp-praxis/examples/workflows/swarm-distributed.yaml \
  -SwarmDispatcher "http://localhost:8080"
```

### View Results in Dashboard

Open http://localhost:3000 to see:
- Real-time execution progress
- Performance metrics
- Baseline comparisons
- Audit reports

## Scaling Workers

Scale workers up or down based on workload:

```bash
# Scale to 8 workers
docker-compose up -d --scale worker=8

# Scale down to 2 workers
docker-compose up -d --scale worker=2

# Check worker status
curl http://localhost:8080/api/workers
```

## Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f swarm-dispatcher
docker-compose logs -f worker
```

### Health Checks

```bash
# WordPress
curl http://localhost:8000

# Swarm Dispatcher
curl http://localhost:8080/health

# PostgreSQL
docker exec wp-praxis-postgres pg_isready

# GraphQL
curl http://localhost:4000/health
```

### Metrics

Access Prometheus metrics:
```bash
curl http://localhost:8080/metrics
```

## Data Persistence

Data is persisted in Docker volumes:

```bash
# List volumes
docker volume ls | grep wp-praxis

# Backup volume
docker run --rm -v wp-praxis_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres-backup.tar.gz /data

# Restore volume
docker run --rm -v wp-praxis_postgres_data:/data -v $(pwd):/backup \
  alpine tar xzf /backup/postgres-backup.tar.gz -C /
```

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Troubleshooting

### WordPress Connection Failed

```bash
# Check MySQL status
docker exec wp-praxis-mysql mysqladmin ping -p

# View WordPress logs
docker logs wp-praxis-wordpress
```

### Workers Not Connecting

```bash
# Check dispatcher logs
docker logs wp-praxis-dispatcher

# Test network connectivity
docker exec worker-1 curl https://swarm-dispatcher:8080/health
```

### Database Migration Failed

```bash
# Reset database
docker exec wp-praxis-dispatcher mix ecto.reset
```

## Production Considerations

For production deployment:

1. **Security**: Change default passwords
2. **SSL/TLS**: Add reverse proxy with SSL
3. **Backups**: Implement automated backups
4. **Monitoring**: Add Prometheus + Grafana
5. **Logging**: Centralize logs with ELK stack
6. **Scaling**: Use Kubernetes for production scale

See `examples/docker/kubernetes/` for K8s manifests.
