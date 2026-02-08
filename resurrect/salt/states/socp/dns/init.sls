# SPDX-License-Identifier: AGPL-3.0-or-later
# DNS state management
# Manages hidden primary DNS with PowerDNS

{% set site = salt['pillar.get']('socp:site', {}) %}
{% set domain = site.get('domain', 'localhost') %}
{% set dns = site.get('dns', {}) %}
{% set hidden_primary = dns.get('hidden_primary', {}) %}

# PowerDNS Authoritative Server (on control plane only)
{% if grains.get('socp_role', '') == 'control_plane' %}

socp_pdns_pkg:
  pkg.installed:
    - pkgs:
      - pdns-server
      - pdns-backend-sqlite3

socp_pdns_service:
  service.running:
    - name: pdns
    - enable: True
    - watch:
      - file: /etc/powerdns/pdns.conf

/etc/powerdns/pdns.conf:
  file.managed:
    - source: salt://socp/dns/files/pdns.conf.jinja
    - template: jinja
    - user: root
    - group: pdns
    - mode: 640
    - context:
        hidden_primary: {{ hidden_primary | json }}
        dnssec: {{ dns.get('dnssec', {}) | json }}

# PowerDNS API for zone management
socp_pdns_api_key:
  file.managed:
    - name: /etc/powerdns/api-key
    - contents: {{ salt['pillar.get']('socp:secrets:pdns_api_key', 'changeme') }}
    - user: root
    - group: pdns
    - mode: 640

{% endif %}

# Zone record management via API
{% for record in dns.get('records', []) %}
socp_dns_record_{{ record.get('name', '@') }}_{{ record.get('type', 'A') }}:
  module.run:
    - name: http.query
    - url: http://127.0.0.1:8081/api/v1/servers/localhost/zones/{{ domain }}.
    - method: PATCH
    - header_dict:
        X-API-Key: {{ salt['pillar.get']('socp:secrets:pdns_api_key', 'changeme') }}
        Content-Type: application/json
    - data: |
        {
          "rrsets": [{
            "name": "{{ record.get('name', '@') }}.{{ domain }}.",
            "type": "{{ record.get('type', 'A') }}",
            "ttl": {{ record.get('ttl', 3600) }},
            "changetype": "REPLACE",
            "records": [{"content": "{{ record.get('value', '') }}", "disabled": false}]
          }]
        }
{% endfor %}

# DNSSEC signing
{% if dns.get('dnssec', {}).get('enabled', True) %}
socp_dnssec_enable:
  cmd.run:
    - name: pdnsutil secure-zone {{ domain }}
    - unless: pdnsutil show-zone {{ domain }} | grep -q "Zone is actively secured"
    - require:
      - service: socp_pdns_service

socp_dnssec_rectify:
  cmd.run:
    - name: pdnsutil rectify-zone {{ domain }}
    - onchanges:
      - cmd: socp_dnssec_enable
{% endif %}
