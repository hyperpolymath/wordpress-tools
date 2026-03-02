# 🚀 Sinople Theme - Deployment Guide

## Quick Start with Podman

### Development Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
nano .env

# Build and start containers
podman-compose -f docker-compose.dev.yml up --build

# Access at http://localhost:8080
```

### Production Deployment

```bash
# Generate SSL certificates (if not using Let's Encrypt)
mkdir -p config/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout config/ssl/key.pem \
  -out config/ssl/cert.pem

# Generate production configs
npm run server:nginx
npm run server:apache
npm run server:caddy

# Build production containers
podman-compose -f docker-compose.prod.yml build

# Start production stack
podman-compose -f docker-compose.prod.yml up -d

# View logs
podman-compose -f docker-compose.prod.yml logs -f
```

## Container Security

### Firewall Configuration (iptables)

```bash
# Allow only necessary ports
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # SSH
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Container Network Isolation

All internal services run on isolated `sinople_internal` network with no external access except via nginx reverse proxy.

## BEAM Integration (Elixir/Erlang)

### Starting the BEAM Container

```bash
# Start RabbitMQ and BEAM containers
podman-compose -f docker-compose.dev.yml up -d rabbitmq beam

# Check BEAM logs
podman logs -f sinople-beam
```

### Message Queue Integration

WordPress posts automatically publish to RabbitMQ queue `sinople.posts` in Ecto-compatible format.

## Build System

### Install Dependencies

```bash
npm install
```

### Development Build

```bash
npm run dev
```

### Production Build

```bash
npm run build
```

### WASM Compilation

Requires Rust toolchain:

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Build WASM
cd assets/wasm
cargo build --release --target wasm32-unknown-unknown

# Optimize (requires wasm-opt)
wasm-opt -Oz -o dist/sinople.wasm target/wasm32-unknown-unknown/release/sinople_wasm.wasm
```

## Performance Optimization

### Enable Redis Cache

Already configured in docker-compose. WordPress will use Redis for object caching.

### CDN Configuration

1. Build optimized assets: `npm run build`
2. Upload `assets/css/min/` and `assets/js/dist/` to CDN
3. Update `functions.php` with CDN URLs

## Security Checklist

- [ ] Update all passwords in `.env`
- [ ] Generate strong `WORDPRESS_DB_PASSWORD` and `RABBITMQ_PASS`
- [ ] Configure SSL certificates (Let's Encrypt recommended)
- [ ] Review and adjust CSP headers in nginx config
- [ ] Enable fail2ban for brute force protection
- [ ] Set up automated backups
- [ ] Configure firewall rules
- [ ] Review container capabilities in docker-compose
- [ ] Enable AppArmor/SELinux profiles
- [ ] Scan containers for vulnerabilities: `podman scan sinople-theme:latest`

## Monitoring

### Health Checks

```bash
# Check all services
podman-compose -f docker-compose.prod.yml ps

# Manual health check
curl https://your-domain.com/health
```

### Logs

```bash
# View all logs
podman-compose logs -f

# View specific service
podman logs -f sinople-wordpress-prod
```

## Backup & Restore

### Backup

```bash
# Database backup
podman exec sinople-db-prod mysqldump -u $DB_USER -p$DB_PASSWORD sinople > backup-$(date +%Y%m%d).sql

# WordPress uploads
tar -czf uploads-$(date +%Y%m%d).tar.gz -C /var/lib/containers/storage/volumes/ wordpress_data
```

### Restore

```bash
# Restore database
podman exec -i sinople-db-prod mysql -u $DB_USER -p$DB_PASSWORD sinople < backup.sql

# Restore uploads
tar -xzf uploads.tar.gz -C /var/lib/containers/storage/volumes/
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
podman logs sinople-wordpress

# Check permissions
podman exec sinople-wordpress ls -la /var/www/html

# Verify network
podman network inspect sinople_internal
```

### WASM Not Loading

1. Check CSP headers allow `wasm-unsafe-eval`
2. Verify WASM file exists in `assets/js/dist/`
3. Check browser console for errors

### Performance Issues

1. Enable Redis caching
2. Optimize images (use WebP)
3. Enable Gzip/Brotli compression
4. Use CDN for static assets

## License

GPL-3.0 for code, CC BY 4.0 for content
