# WP Praxis Symbolic Engine Dashboard

Complete real-time monitoring and control interface for the WP Praxis symbolic workflow system. Built with Bun, TypeScript, Elysia, and PostgreSQL.

## Features

### Core Dashboard
- **Real-time Statistics**: Live monitoring of workflows, executions, audits, and system metrics
- **Workflow Management**: Create, update, and monitor symbolic workflows
- **Execution Tracking**: Real-time execution status and history
- **Symbol Registry**: Browse and inspect all available symbols
- **Audit Reports**: View deviation reports and compliance scores
- **Baseline Management**: Create and manage normative baselines
- **WebSocket Updates**: Live updates via WebSocket connections
- **Dark Mode**: Full dark mode support with auto-detection

### Injector Interface
- **Manifest Upload**: Drag-and-drop YAML/TOML manifest files
- **Symbolic Injection**: Safe injection with validation and rollback
- **Diff Preview**: Preview changes before injection
- **Rollback Support**: Restore previous states from snapshots
- **Progress Tracking**: Real-time injection progress logs
- **Injection History**: Track all previous injections

## Technology Stack

- **Runtime**: Bun 1.0+
- **Framework**: Elysia (Fast web framework)
- **Database**: PostgreSQL (Ecto database integration)
- **WebSockets**: Native Bun WebSocket support
- **Frontend**: TypeScript, Chart.js
- **Styling**: Modern CSS with CSS variables for theming

## Installation

### Prerequisites

- Bun 1.0 or higher
- PostgreSQL 12+ (running Ecto database)
- Node.js 18+ (optional, for compatibility)

### Setup

1. **Install dependencies**:
   ```bash
   cd SymbolicEngine/dashboard
   bun install
   ```

2. **Configure database** (edit `dashboard-config.toml`):
   ```toml
   [database]
   host = "localhost"
   port = 5432
   database = "wp_praxis_dev"
   user = "postgres"
   password = "your_password"
   ```

3. **Configure server** (edit `dashboard-config.toml`):
   ```toml
   [server]
   host = "localhost"
   port = 3000
   env = "development"
   ```

4. **Build frontend**:
   ```bash
   bun run build:all
   ```

## Running the Dashboard

### Development Mode
```bash
bun run dev
```

The server will start with auto-reload enabled at `http://localhost:3000`

### Production Mode
```bash
bun run build
bun run start
```

### Access Points

- **Dashboard**: `http://localhost:3000/`
- **Injector**: `http://localhost:3000/injector`
- **API**: `http://localhost:3000/api`
- **WebSocket**: `ws://localhost:3000/ws`
- **Health Check**: `http://localhost:3000/api/health`

## API Endpoints

### Workflows

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/workflows` | List all workflows |
| GET | `/api/workflows/:id` | Get workflow by ID |
| POST | `/api/workflows` | Create new workflow |
| PATCH | `/api/workflows/:id` | Update workflow |
| DELETE | `/api/workflows/:id` | Delete workflow |
| GET | `/api/workflows/:id/symbols` | Get workflow symbols |

### Symbols

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/symbols` | List all symbols |
| GET | `/api/symbols/:id` | Get symbol by ID |
| GET | `/api/symbols/search?q=term` | Search symbols |

### Executions

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/executions` | List executions |
| GET | `/api/executions/:id` | Get execution by ID |
| POST | `/api/executions` | Create execution |
| PATCH | `/api/executions/:id` | Update execution |
| GET | `/api/executions/stats` | Get execution statistics |

### Audits

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/audits` | List audits |
| GET | `/api/audits/:id` | Get audit by ID |
| GET | `/api/audits/stats` | Get audit statistics |

### Baselines

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/baselines` | List baselines |
| GET | `/api/baselines/:id` | Get baseline by ID |
| GET | `/api/baselines/normative/:workflow_id` | Get normative baseline |

### Statistics

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/stats` | Get dashboard statistics |
| GET | `/api/stats/state` | Get aggregated state |

### Health

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Basic health check |
| GET | `/api/health/detailed` | Detailed health info |

### Query Parameters

**Pagination**:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

**Filtering**:
- `status`: Filter by status (workflows, executions)
- `type`: Filter by type (symbols)
- `workflow_id`: Filter by workflow ID

**Example**:
```bash
GET /api/executions?page=1&limit=20&status=running&workflow_id=abc123
```

## WebSocket Events

### Client → Server

```json
{
  "type": "subscribe",
  "execution_id": "exec_123"
}
```

```json
{
  "type": "unsubscribe",
  "execution_id": "exec_123"
}
```

```json
{
  "type": "ping"
}
```

### Server → Client

**Execution Events**:
```json
{
  "type": "execution_started",
  "payload": {
    "execution_id": "exec_123",
    "workflow_id": "workflow_456",
    "timestamp": "2025-11-22T..."
  }
}
```

```json
{
  "type": "execution_completed",
  "payload": {
    "execution_id": "exec_123",
    "result": {...},
    "duration_ms": 1234
  }
}
```

**Audit Events**:
```json
{
  "type": "deviation_detected",
  "payload": {
    "deviation": {...}
  }
}
```

**Statistics Updates**:
```json
{
  "type": "stats_update",
  "payload": {
    "stats": {...}
  }
}
```

**Log Entries**:
```json
{
  "type": "log_entry",
  "payload": {
    "level": "info",
    "message": "...",
    "execution_id": "exec_123"
  }
}
```

**Heartbeat**:
```json
{
  "type": "heartbeat",
  "payload": {
    "timestamp": "..."
  }
}
```

## Configuration Reference

### Server Configuration

```toml
[server]
host = "localhost"          # Server host
port = 3000                 # Server port
env = "development"         # Environment: development, staging, production

[server.cors]
enabled = true
origins = ["http://localhost:3000"]
methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
credentials = true

[server.websocket]
enabled = true
path = "/ws"
heartbeat_interval = 30000  # Heartbeat interval in ms
max_payload = 1048576       # Max WebSocket message size (1MB)
```

### Database Configuration

```toml
[database]
host = "localhost"
port = 5432
database = "wp_praxis_dev"
user = "postgres"
password = ""
max_connections = 20
idle_timeout = 30000
connection_timeout = 5000

[database.ssl]
enabled = false
reject_unauthorized = true
```

### State Aggregation

```toml
[state]
sources = ["ecto_db", "swarm_state", "powershell_state"]

[state.ecto_db]
enabled = true
refresh_interval = 5000

[state.swarm_state]
enabled = true
endpoint = "http://localhost:8080/state"
refresh_interval = 3000

[state.powershell_state]
enabled = true
script_path = "../core/symbolic.ps1"
refresh_interval = 10000
```

### Features

```toml
[features]
real_time_updates = true
workflow_visualization = true
symbol_inspection = true
audit_reports = true
baseline_management = true
execution_tracking = true
performance_metrics = true
```

### UI Configuration

```toml
[ui]
theme = "auto"              # light, dark, auto
auto_refresh = true
refresh_interval = 5000     # Auto-refresh interval in ms
max_log_lines = 1000
chart_animation = true

[ui.colors]
primary = "#6366f1"
secondary = "#8b5cf6"
success = "#10b981"
warning = "#f59e0b"
error = "#ef4444"
info = "#3b82f6"
```

## Environment Variables

Override configuration via environment variables:

```bash
# Server
HOST=localhost
PORT=3000
NODE_ENV=production

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=wp_praxis_prod
DB_USER=postgres
DB_PASSWORD=secret

# Authentication
JWT_SECRET=your-secret-key
```

## Development

### Project Structure

```
dashboard/
├── src/                    # Backend source
│   ├── api/               # API routes and controllers
│   │   ├── controllers/   # Business logic
│   │   └── routes/        # Route handlers
│   ├── db/                # Database integration
│   │   ├── postgres-client.ts
│   │   └── state-aggregator.ts
│   ├── websocket/         # WebSocket handlers
│   │   ├── dashboard-events.ts
│   │   └── stream-handler.ts
│   ├── types/             # TypeScript types
│   ├── api-server.ts      # Main server
│   └── config-loader.ts   # Configuration loader
├── js/                    # Frontend JavaScript
│   ├── dashboard.ts       # Main dashboard
│   ├── workflow-visualizer.ts
│   └── symbol-inspector.ts
├── css/                   # Stylesheets
│   └── dashboard.css
├── injector/              # Injector interface
│   ├── js/
│   ├── css/
│   └── index.html
├── index.html             # Main dashboard HTML
├── package.json
├── tsconfig.json
└── dashboard-config.toml
```

### Development Workflow

1. **Start development server**:
   ```bash
   bun run dev
   ```

2. **Watch and rebuild frontend**:
   ```bash
   bun run build:frontend --watch
   ```

3. **Run linter**:
   ```bash
   bun run lint
   ```

4. **Format code**:
   ```bash
   bun run format
   ```

### Adding New Features

#### Add a new API endpoint:

1. Create controller in `src/api/controllers/`
2. Create route in `src/api/routes/`
3. Register route in `src/api-server.ts`

#### Add a new view:

1. Add section in `index.html`
2. Add styles in `css/dashboard.css`
3. Add logic in `js/dashboard.ts`

## Testing

### Manual Testing

1. **Test WebSocket connection**:
   ```javascript
   const ws = new WebSocket('ws://localhost:3000/ws');
   ws.onmessage = (e) => console.log(JSON.parse(e.data));
   ```

2. **Test API endpoints**:
   ```bash
   curl http://localhost:3000/api/health
   curl http://localhost:3000/api/stats
   ```

### Database Testing

Ensure PostgreSQL is running and Ecto migrations are applied:

```bash
# Check database connection
psql -h localhost -U postgres -d wp_praxis_dev -c "SELECT 1"
```

## Deployment

### Production Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Configure production database credentials
- [ ] Set strong `JWT_SECRET`
- [ ] Enable SSL for database connection
- [ ] Configure CORS origins for production domain
- [ ] Build frontend assets: `bun run build:all`
- [ ] Set up process manager (PM2, systemd)
- [ ] Configure reverse proxy (nginx, Caddy)
- [ ] Set up SSL/TLS certificates
- [ ] Configure firewall rules
- [ ] Set up monitoring and logging

### systemd Service

Create `/etc/systemd/system/wp-praxis-dashboard.service`:

```ini
[Unit]
Description=WP Praxis Dashboard
After=network.target postgresql.service

[Service]
Type=simple
User=wp-praxis
WorkingDirectory=/opt/wp-praxis/SymbolicEngine/dashboard
ExecStart=/usr/local/bin/bun run start
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable wp-praxis-dashboard
sudo systemctl start wp-praxis-dashboard
```

### Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name dashboard.wppraxis.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /ws {
        proxy_pass http://localhost:3000/ws;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -h localhost -U postgres -c "SELECT version()"

# Check database exists
psql -h localhost -U postgres -l | grep wp_praxis
```

### WebSocket Connection Fails

- Check firewall allows WebSocket connections
- Verify reverse proxy WebSocket configuration
- Check browser console for errors
- Ensure `websocket.enabled = true` in config

### High Memory Usage

- Reduce `max_connections` in database config
- Lower `cache.max_size` in config
- Disable unnecessary state sources
- Reduce `ui.refresh_interval`

### Performance Issues

- Enable database connection pooling
- Enable caching: `cache.enabled = true`
- Reduce WebSocket heartbeat interval
- Optimize database queries with indexes

## Security

### Best Practices

- **Never commit secrets**: Use environment variables
- **Use strong passwords**: For database and JWT secrets
- **Enable SSL/TLS**: For production deployments
- **Restrict CORS**: Limit allowed origins
- **Validate inputs**: All API endpoints validate inputs
- **Use prepared statements**: Prevents SQL injection
- **Implement authentication**: Enable auth for production

### Authentication (Future)

Set in `dashboard-config.toml`:

```toml
[auth]
enabled = true
jwt_secret = "your-secret-key"
jwt_expiry = 3600
session_timeout = 86400
```

## License

AGPL-3.0 - See main project LICENSE file

## Contributing

See main project CLAUDE.md for development guidelines

## Support

- Documentation: See `Docs/` directory in main project
- Issues: Report via project issue tracker
- Architecture: See `Docs/UML/` for diagrams

## Changelog

### v0.1.0 (2025-11-22)

- Initial dashboard implementation
- Real-time WebSocket updates
- Complete REST API
- Injector interface
- Dark mode support
- PostgreSQL integration
- State aggregation from multiple sources
