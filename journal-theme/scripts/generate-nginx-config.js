#!/usr/bin/env -S deno run --allow-read --allow-write --allow-env

/**
 * Generate optimized Nginx configuration
 * with security headers and caching rules
 *
 * @module
 */

import { join, dirname } from "@std/path";
import { ensureDir } from "@std/fs";

const config = {
  serverName: Deno.env.get("SERVER_NAME") || "localhost",
  sslCert: Deno.env.get("SSL_CERT") || "/etc/nginx/ssl/cert.pem",
  sslKey: Deno.env.get("SSL_KEY") || "/etc/nginx/ssl/key.pem",
  enableHTTP2: Deno.env.get("ENABLE_HTTP2") !== "false",
  enableHTTP3: Deno.env.get("ENABLE_HTTP3") === "true",
};

const nginxConfig = `
# Nginx configuration for Sinople theme (production)
# Auto-generated - do not edit manually

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

# Load dynamic modules
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging with additional security info
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main buffer=32k flush=5s;

    # Performance optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100;
    reset_timedout_connection on;
    client_body_timeout 12;
    send_timeout 10;
    types_hash_max_size 2048;
    client_max_body_size 64M;
    server_tokens off;

    # Buffer sizes
    client_body_buffer_size 128k;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 16k;
    output_buffers 1 32k;
    postpone_output 1460;

    # Open file cache
    open_file_cache max=10000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_disable "msie6";
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/x-javascript
        application/xml
        application/xml+rss
        application/xhtml+xml
        application/x-font-ttf
        application/x-font-opentype
        application/vnd.ms-fontobject
        image/svg+xml
        image/x-icon
        application/rss+xml
        application/atom+xml;

    # SSL/TLS configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 valid=300s;
    resolver_timeout 5s;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_status 429;
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    limit_conn addr 10;

    # HTTP to HTTPS redirect
    server {
        listen 80;
        listen [::]:80;
        server_name ${config.serverName};

        # ACME challenge for Let's Encrypt
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl${config.enableHTTP2 ? " http2" : ""};
        listen [::]:443 ssl${config.enableHTTP2 ? " http2" : ""};
        ${config.enableHTTP3 ? "listen 443 quic reuseport;" : ""}
        ${config.enableHTTP3 ? "listen [::]:443 quic reuseport;" : ""}

        server_name ${config.serverName};
        root /var/www/html;
        index index.php index.html;

        # SSL certificates
        ssl_certificate ${config.sslCert};
        ssl_certificate_key ${config.sslKey};

        ${config.enableHTTP3 ? "# HTTP/3\n        add_header Alt-Svc 'h3=\":443\"; ma=86400' always;" : ""}

        # Security headers
        include /etc/nginx/security-headers.conf;

        # Rate limiting
        limit_req zone=general burst=20 nodelay;

        # Deny access to hidden files
        location ~ /\\. {
            deny all;
            access_log off;
            log_not_found off;
        }

        # WordPress permalinks
        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        # PHP handling
        location ~ \\.php$ {
            limit_req zone=api burst=10 nodelay;

            try_files $uri =404;
            fastcgi_split_path_info ^(.+\\.php)(/.+)$;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_param PATH_INFO $fastcgi_path_info;
            fastcgi_param HTTPS on;

            fastcgi_hide_header X-Powered-By;
            fastcgi_buffer_size 128k;
            fastcgi_buffers 4 256k;
            fastcgi_busy_buffers_size 256k;
            fastcgi_read_timeout 300;
        }

        # Cache static assets aggressively
        location ~* \\.(jpg|jpeg|png|gif|ico|webp|avif)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Vary "Accept";
            access_log off;
        }

        location ~* \\.(css|js|woff2|woff|ttf|otf|eot|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            access_log off;
        }

        location ~* \\.(wasm)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            add_header Content-Type "application/wasm";
            access_log off;
        }

        # Deny access to sensitive files
        location ~* (wp-config\\.php|readme\\.html|license\\.txt|\\.git) {
            deny all;
        }

        # VoID endpoint
        location = /void.rdf {
            try_files $uri /index.php?void=1;
        }

        # NDJSON feed
        location = /feed/ndjson {
            try_files $uri /index.php?ndjson=1;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\\n";
            add_header Content-Type text/plain;
        }
    }
}
`;

const securityHeaders = `
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()" always;
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; media-src 'self'; object-src 'none'; frame-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests; block-all-mixed-content" always;
add_header Cross-Origin-Embedder-Policy "require-corp" always;
add_header Cross-Origin-Opener-Policy "same-origin" always;
add_header Cross-Origin-Resource-Policy "same-origin" always;
add_header Expect-CT "max-age=86400, enforce" always;
`;

async function main() {
  const scriptDir = dirname(new URL(import.meta.url).pathname);
  const configDir = join(scriptDir, "..", "config");

  // Ensure config directory exists
  await ensureDir(configDir);

  // Write Nginx configuration
  const nginxPath = join(configDir, "nginx-prod.conf");
  await Deno.writeTextFile(nginxPath, nginxConfig.trim());
  console.log(`\u2713 Nginx configuration generated: ${nginxPath}`);

  // Write security headers
  const secHeadersPath = join(configDir, "security-headers.conf");
  await Deno.writeTextFile(secHeadersPath, securityHeaders.trim());
  console.log(`\u2713 Security headers configuration generated: ${secHeadersPath}`);
}

// Run main
if (import.meta.main) {
  main();
}
