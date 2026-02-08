# SPDX-License-Identifier: AGPL-3.0-or-later
# Security state management
# Handles: WAF, fail2ban, headers, rate limiting

{% set site = salt['pillar.get']('socp:site', {}) %}
{% set security = site.get('security', {}) %}

include:
  - socp.security.fail2ban
  - socp.security.modsecurity
  - socp.security.headers

# CrowdSec (modern fail2ban alternative)
socp_crowdsec_pkg:
  pkg.installed:
    - name: crowdsec
    - name: crowdsec-firewall-bouncer-iptables

socp_crowdsec_service:
  service.running:
    - name: crowdsec
    - enable: True
    - watch:
      - file: /etc/crowdsec/config.yaml

# ClamAV for file scanning
{% if security.get('scan_uploads', True) %}
socp_clamav_pkg:
  pkg.installed:
    - pkgs:
      - clamav
      - clamav-daemon

socp_clamav_service:
  service.running:
    - name: clamav-daemon
    - enable: True

socp_clamav_freshclam:
  service.running:
    - name: clamav-freshclam
    - enable: True
{% endif %}

# iptables/nftables rules
/etc/nftables.d/socp-security.nft:
  file.managed:
    - source: salt://socp/security/files/nftables.nft.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - makedirs: True
    - context:
        ip_allowlist: {{ security.get('ip_allowlist', []) | json }}
        ip_blocklist: {{ security.get('ip_blocklist', []) | json }}
        geo_block: {{ security.get('geo_block', []) | json }}
        rate_limit: {{ security.get('rate_limit', {}) | json }}

# Reload nftables
socp_nftables_reload:
  cmd.run:
    - name: nft -f /etc/nftables.d/socp-security.nft
    - onchanges:
      - file: /etc/nftables.d/socp-security.nft
