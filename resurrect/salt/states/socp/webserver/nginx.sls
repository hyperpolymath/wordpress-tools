# SPDX-License-Identifier: AGPL-3.0-or-later
# nginx web server state

{% set site = salt['pillar.get']('socp:site', {}) %}
{% set domain = site.get('domain', 'localhost') %}
{% set webserver = site.get('webserver', {}) %}
{% set ssl = webserver.get('ssl', {}) %}
{% set vhost = webserver.get('vhost', {}) %}

# Ensure nginx is installed
socp_nginx_pkg:
  pkg.installed:
    - name: nginx

# Ensure nginx is running
socp_nginx_service:
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nginx/sites-available/{{ domain }}.conf
      - file: /etc/nginx/conf.d/socp-*.conf

# nginx main configuration
/etc/nginx/nginx.conf:
  file.managed:
    - source: salt://socp/webserver/files/nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        http2: {{ webserver.get('http2', True) }}
        http3: {{ webserver.get('http3', False) }}
        gzip: {{ webserver.get('gzip', True) }}
        brotli: {{ webserver.get('brotli', True) }}
        worker_connections: {{ webserver.get('worker_connections', 1024) }}
        keepalive_timeout: {{ webserver.get('keepalive_timeout', 65) }}

# Site-specific vhost
/etc/nginx/sites-available/{{ domain }}.conf:
  file.managed:
    - source: salt://socp/webserver/files/nginx-vhost.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        domain: {{ domain }}
        ssl: {{ ssl | json }}
        vhost: {{ vhost | json }}
        client_max_body_size: {{ webserver.get('client_max_body_size', '64M') }}
        php_version: {{ site.get('php', {}).get('version', '8.3') }}

# Enable site
/etc/nginx/sites-enabled/{{ domain }}.conf:
  file.symlink:
    - target: /etc/nginx/sites-available/{{ domain }}.conf
    - require:
      - file: /etc/nginx/sites-available/{{ domain }}.conf

# SOCP common includes
/etc/nginx/conf.d/socp-security.conf:
  file.managed:
    - source: salt://socp/webserver/files/nginx-security.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
        security: {{ site.get('security', {}) | json }}

# SSL certificate management (Let's Encrypt)
{% if ssl.get('provider', 'letsencrypt') == 'letsencrypt' %}
socp_certbot_pkg:
  pkg.installed:
    - name: certbot
    - name: python3-certbot-nginx

socp_certbot_obtain:
  cmd.run:
    - name: certbot certonly --nginx -d {{ domain }} --non-interactive --agree-tos --email {{ salt['pillar.get']('socp:admin_email', 'admin@example.com') }}
    - unless: test -f /etc/letsencrypt/live/{{ domain }}/fullchain.pem
    - require:
      - pkg: socp_certbot_pkg

socp_certbot_renewal:
  cron.present:
    - name: certbot renew --quiet --deploy-hook "systemctl reload nginx"
    - user: root
    - hour: 3
    - minute: 30
{% endif %}
