# Sinople Theme - Production Container
# Uses Chainguard Wolfi for supply chain security
# Multi-stage build for minimal attack surface

# Stage 1: Build assets
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# Install build dependencies
RUN apk add --no-cache \
    nodejs-20 \
    npm \
    git \
    curl \
    ca-certificates

WORKDIR /build

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm ci --only=production

# Copy theme files
COPY . .

# Build assets
RUN npm run build

# Stage 2: Runtime with minimal footprint
FROM cgr.dev/chainguard/wolfi-base:latest

# Install only runtime dependencies
RUN apk add --no-cache \
    php-8.3 \
    php-fpm \
    nginx \
    ca-certificates

# Create non-root user for security
RUN addgroup -g 10001 sinople && \
    adduser -D -u 10001 -G sinople sinople

# Set working directory
WORKDIR /var/www/html/wp-content/themes/sinople

# Copy built assets from builder
COPY --from=builder --chown=sinople:sinople /build/assets/css ./assets/css
COPY --from=builder --chown=sinople:sinople /build/assets/js/dist ./assets/js/dist
COPY --from=builder --chown=sinople:sinople /build/assets/fonts ./assets/fonts
COPY --from=builder --chown=sinople:sinople /build/assets/images ./assets/images

# Copy PHP theme files
COPY --chown=sinople:sinople *.php ./
COPY --chown=sinople:sinople inc ./inc
COPY --chown=sinople:sinople templates ./templates
COPY --chown=sinople:sinople semantic ./semantic

# Security: Remove unnecessary files
RUN rm -rf \
    /tmp/* \
    /var/tmp/* \
    /usr/share/doc/* \
    /usr/share/man/*

# Set restrictive permissions
RUN find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \;

# Security labels
LABEL org.opencontainers.image.title="Sinople WordPress Theme" \
      org.opencontainers.image.description="CSS-first journal theme with WCAG 2.3 AAA compliance" \
      org.opencontainers.image.vendor="Sinople" \
      org.opencontainers.image.version="0.1.0" \
      org.opencontainers.image.licenses="GPL-3.0"

# Switch to non-root user
USER sinople

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD test -f /var/www/html/wp-content/themes/sinople/style.css || exit 1

# Expose PHP-FPM port (internal only)
EXPOSE 9000

CMD ["php-fpm", "-F"]
