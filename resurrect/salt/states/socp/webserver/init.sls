# SPDX-License-Identifier: AGPL-3.0-or-later
# Web server state management
# Supports: nginx, apache, litespeed, openlitespeed

{% set site = salt['pillar.get']('socp:site', {}) %}
{% set webserver = site.get('webserver', {}) %}
{% set ws_type = webserver.get('type', 'nginx') %}

# Include the appropriate web server module
include:
{% if ws_type == 'nginx' %}
  - socp.webserver.nginx
{% elif ws_type == 'apache' %}
  - socp.webserver.apache
{% elif ws_type in ['litespeed', 'openlitespeed'] %}
  - socp.webserver.litespeed
{% endif %}

# Common web server configuration
socp_webserver_ssl_dhparam:
  cmd.run:
    - name: openssl dhparam -out /etc/ssl/dhparam.pem 4096
    - creates: /etc/ssl/dhparam.pem
    - unless: test -f /etc/ssl/dhparam.pem

# TLS configuration directory
socp_webserver_ssl_config_dir:
  file.directory:
    - name: /etc/ssl/socp
    - user: root
    - group: root
    - mode: 750
    - makedirs: True

# Common security headers template
/etc/socp/security-headers.conf:
  file.managed:
    - source: salt://socp/webserver/files/security-headers.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - context:
        headers: {{ webserver.get('headers', []) | json }}
        ssl: {{ webserver.get('ssl', {}) | json }}
