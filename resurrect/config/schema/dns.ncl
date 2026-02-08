# SPDX-License-Identifier: AGPL-3.0-or-later
# DNS configuration schema

{
  RecordType = [| 'A, 'AAAA, 'CNAME, 'MX, 'TXT, 'NS, 'SRV, 'CAA, 'PTR, 'ALIAS, 'DNAME |],

  DnsRecord = {
    type
      | RecordType,
    name
      | String
      | doc "Record name (@ for apex, or subdomain)",
    value
      | String
      | doc "Record value",
    ttl
      | Number
      | default = 3600,
    priority
      | Number
      | optional
      | doc "Priority for MX/SRV records",
    weight
      | Number
      | optional
      | doc "Weight for SRV records",
    port
      | Number
      | optional
      | doc "Port for SRV records",
    proxied
      | Bool
      | optional
      | doc "Cloudflare proxy status",
  },

  CaaRecord = {
    flags
      | Number
      | default = 0,
    tag
      | [| 'issue, 'issuewild, 'iodef |],
    value
      | String,
  },

  DnssecConfig = {
    enabled
      | Bool
      | default = true,
    algorithm
      | [| 'ECDSAP256SHA256, 'ECDSAP384SHA384, 'ED25519 |]
      | default = 'ECDSAP256SHA256,
    key_rotation_days
      | Number
      | default = 365,
  },

  MailAuthConfig = {
    spf
      | String
      | optional
      | doc "SPF record value (e.g., 'v=spf1 include:_spf.google.com ~all')",
    dkim_selector
      | String
      | optional
      | doc "DKIM selector name",
    dkim_key_ref
      | String
      | optional
      | doc "Reference to DKIM public key in secrets",
    dmarc
      | String
      | optional
      | doc "DMARC policy (e.g., 'v=DMARC1; p=reject; rua=mailto:...')",
    bimi
      | String
      | optional
      | doc "BIMI record for brand logo",
    mta_sts
      | Bool
      | default = false
      | doc "Enable MTA-STS for mail security",
  },

  HiddenPrimaryConfig = {
    enabled
      | Bool
      | default = true
      | doc "Use hidden primary DNS architecture",
    primary_server
      | String
      | optional
      | doc "Hidden primary server address",
    secondary_servers
      | Array String
      | default = []
      | doc "Public secondary DNS servers (receive AXFR)",
    notify
      | Bool
      | default = true
      | doc "Send NOTIFY to secondaries on changes",
    axfr_acl
      | Array String
      | default = []
      | doc "IPs allowed to perform zone transfers",
    tsig_key_ref
      | String
      | optional
      | doc "Reference to TSIG key for secure transfers",
  },

  Config = {
    # Zone settings
    zone
      | String
      | optional
      | doc "DNS zone (usually same as domain)",

    # Records
    records
      | Array DnsRecord
      | default = [],

    # CAA records (Certificate Authority Authorization)
    caa
      | Array CaaRecord
      | default = [
          { tag = 'issue, value = "letsencrypt.org" },
          { tag = 'issuewild, value = "letsencrypt.org" },
        ],

    # DNSSEC
    dnssec
      | DnssecConfig
      | default = {},

    # Mail authentication (SPF, DKIM, DMARC)
    mail_auth
      | MailAuthConfig
      | default = {},

    # Hidden primary DNS
    hidden_primary
      | HiddenPrimaryConfig
      | default = {},

    # Provider settings (for API-managed DNS)
    provider
      | [| 'powerdns, 'cloudflare, 'route53, 'bunny, 'manual |]
      | default = 'powerdns,

    api_key_ref
      | String
      | optional
      | doc "Reference to DNS API key in secrets",

    zone_id_ref
      | String
      | optional
      | doc "Reference to zone ID in secrets",

    # Verification records (for services)
    verification_records
      | Array DnsRecord
      | default = []
      | doc "Google/Bing/service verification TXT records",
  },
}
