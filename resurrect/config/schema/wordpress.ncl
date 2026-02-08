# SPDX-License-Identifier: AGPL-3.0-or-later
# WordPress configuration schema

{
  AutoUpdatePolicy = [| 'disabled, 'minor, 'major |],

  PluginState = [| 'active, 'inactive, 'must_use, 'drop_in |],

  PluginsConfig = {
    must_use
      | Array String
      | default = []
      | doc "Must-use plugins (always active)",
    active
      | Array String
      | default = []
      | doc "Actively enabled plugins",
    inactive
      | Array String
      | default = []
      | doc "Installed but disabled plugins",
    blocklist
      | Array String
      | default = []
      | doc "Plugins that must never be installed",
  },

  ThemesConfig = {
    active
      | String
      | doc "Currently active theme slug",
    installed
      | Array String
      | default = []
      | doc "Other installed themes",
    parent
      | String
      | optional
      | doc "Parent theme (if using child theme)",
  },

  CronConfig = {
    disable_wp_cron
      | Bool
      | default = true
      | doc "Disable WP-Cron (use system cron instead)",
    system_cron_interval
      | String
      | default = "*/5 * * * *"
      | doc "System cron schedule for wp-cron.php",
  },

  DebugConfig = {
    wp_debug
      | Bool
      | default = false,
    wp_debug_log
      | Bool
      | default = false,
    wp_debug_display
      | Bool
      | default = false,
    script_debug
      | Bool
      | default = false,
    savequeries
      | Bool
      | default = false,
  },

  SecurityConfig = {
    disallow_file_edit
      | Bool
      | default = true
      | doc "Disable plugin/theme editor in admin",
    disallow_file_mods
      | Bool
      | default = false
      | doc "Disable all file modifications (updates too)",
    force_ssl_admin
      | Bool
      | default = true,
    block_xmlrpc
      | Bool
      | default = true
      | doc "Block XML-RPC (unless needed for Jetpack/mobile apps)",
    limit_revisions
      | Number
      | default = 10
      | doc "Max post revisions to keep",
  },

  PerformanceConfig = {
    concatenate_scripts
      | Bool
      | default = true,
    compress_scripts
      | Bool
      | default = true,
    compress_css
      | Bool
      | default = true,
    disable_emojis
      | Bool
      | default = true,
    disable_embeds
      | Bool
      | default = false,
  },

  MultisiteConfig = {
    enabled
      | Bool
      | default = false,
    subdomain_install
      | Bool
      | default = false
      | doc "true = subdomains, false = subdirectories",
    domain_current_site
      | String
      | optional,
    path_current_site
      | String
      | default = "/",
    site_id_current_site
      | Number
      | default = 1,
    blog_id_current_site
      | Number
      | default = 1,
  },

  Config = {
    # Multisite
    multisite
      | MultisiteConfig
      | default = {}
      | doc "Multisite configuration",

    # Updates
    auto_update_core
      | AutoUpdatePolicy
      | default = 'minor,
    auto_update_plugins
      | Bool
      | default = false,
    auto_update_themes
      | Bool
      | default = false,

    # Plugins and themes
    plugins
      | PluginsConfig
      | default = {},
    themes
      | ThemesConfig
      | optional,

    # Cron
    cron
      | CronConfig
      | default = {},

    # Debug
    debug
      | DebugConfig
      | default = {},

    # Security
    security
      | SecurityConfig
      | default = {},

    # Performance
    performance
      | PerformanceConfig
      | default = {},

    # Content settings
    blog_public
      | Bool
      | default = true
      | doc "Allow search engines to index",
    permalink_structure
      | String
      | default = "/%postname%/",
    uploads_path
      | String
      | default = "wp-content/uploads",

    # Memory
    wp_memory_limit
      | String
      | default = "256M",
    wp_max_memory_limit
      | String
      | default = "512M"
      | doc "Memory limit for admin operations",

    # Table prefix
    table_prefix
      | String
      | default = "wp_",

    # Language
    wplang
      | String
      | default = "",
  },
}
