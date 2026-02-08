# SPDX-License-Identifier: AGPL-3.0-or-later
# WordPress state management

{% set site = salt['pillar.get']('socp:site', {}) %}
{% set domain = site.get('domain', 'localhost') %}
{% set wordpress = site.get('wordpress', {}) %}
{% set database = site.get('database', {}) %}
{% set cache = site.get('cache', {}) %}
{% set docroot = site.get('webserver', {}).get('vhost', {}).get('root', '/var/www/' ~ domain ~ '/public') %}

# WP-CLI installation
socp_wpcli:
  file.managed:
    - name: /usr/local/bin/wp
    - source: https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    - source_hash: sha256=e9c73b1e83c6d67f7fb9c90d9f96a5e0d6f16b2d1adf2ed1ce2d1e74dd4e3ce1
    - mode: 755
    - skip_verify: True

# Document root directory
{{ docroot }}:
  file.directory:
    - user: www-data
    - group: www-data
    - mode: 755
    - makedirs: True

# wp-config.php management
{{ docroot }}/wp-config.php:
  file.managed:
    - source: salt://socp/wordpress/files/wp-config.php.jinja
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 640
    - context:
        domain: {{ domain }}
        database: {{ database | json }}
        wordpress: {{ wordpress | json }}
        cache: {{ cache | json }}
        db_name: {{ database.get('name', 'wordpress') }}
        db_user: {{ salt['pillar.get']('socp:secrets:' ~ database.get('user_ref', 'db_user'), 'wordpress') }}
        db_password: {{ salt['pillar.get']('socp:secrets:' ~ database.get('password_ref', 'db_password'), '') }}
        db_host: {{ database.get('connection', {}).get('host', 'localhost') }}
        table_prefix: {{ wordpress.get('table_prefix', 'wp_') }}

# WordPress security hardening
{{ docroot }}/.htaccess:
  file.managed:
    - source: salt://socp/wordpress/files/htaccess.jinja
    - template: jinja
    - user: www-data
    - group: www-data
    - mode: 644
    - context:
        wordpress: {{ wordpress | json }}

# Disable XML-RPC if configured
{% if wordpress.get('security', {}).get('block_xmlrpc', True) %}
{{ docroot }}/xmlrpc.php:
  file.managed:
    - contents: |
        <?php
        // XML-RPC disabled by SOCP
        http_response_code(403);
        die('XML-RPC disabled');
    - user: www-data
    - group: www-data
    - mode: 644
{% endif %}

# Object cache drop-in for Redis
{% if cache.get('object_cache', 'none') == 'redis' %}
{{ docroot }}/wp-content/object-cache.php:
  file.managed:
    - source: salt://socp/wordpress/files/object-cache-redis.php
    - user: www-data
    - group: www-data
    - mode: 644
{% endif %}

# System cron for WP-Cron
{% if wordpress.get('cron', {}).get('disable_wp_cron', True) %}
socp_wordpress_cron:
  cron.present:
    - name: cd {{ docroot }} && /usr/local/bin/wp cron event run --due-now --quiet
    - user: www-data
    - minute: '*/5'
{% endif %}

# Must-use plugins directory
{{ docroot }}/wp-content/mu-plugins:
  file.directory:
    - user: www-data
    - group: www-data
    - mode: 755
    - makedirs: True

# SOCP must-use plugin (for central management hooks)
{{ docroot }}/wp-content/mu-plugins/socp-management.php:
  file.managed:
    - source: salt://socp/wordpress/files/socp-management.php
    - user: www-data
    - group: www-data
    - mode: 644
