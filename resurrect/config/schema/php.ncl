# SPDX-License-Identifier: AGPL-3.0-or-later
# PHP configuration schema

{
  OpcacheConfig = {
    enable
      | Bool
      | default = true,
    memory
      | Number
      | default = 128
      | doc "Memory in MB",
    max_accelerated_files
      | Number
      | default = 10000,
    validate_timestamps
      | Bool
      | default = true
      | doc "Check file timestamps (disable in production for performance)",
    revalidate_freq
      | Number
      | default = 2
      | doc "How often to check for changes (seconds)",
    jit
      | Bool
      | default = false
      | doc "Enable JIT compilation (PHP 8.0+)",
    jit_buffer_size
      | String
      | default = "100M"
      | doc "JIT buffer size",
  },

  SessionConfig = {
    handler
      | [| 'files, 'redis, 'memcached |]
      | default = 'files,
    save_path
      | String
      | optional
      | doc "Session save path (e.g., tcp://redis:6379 for Redis)",
    gc_maxlifetime
      | Number
      | default = 1440,
    cookie_secure
      | Bool
      | default = true,
    cookie_httponly
      | Bool
      | default = true,
    cookie_samesite
      | [| 'Strict, 'Lax, 'None |]
      | default = 'Lax,
  },

  PoolConfig = {
    pm
      | [| 'dynamic, 'static, 'ondemand |]
      | default = 'dynamic
      | doc "Process manager type",
    max_children
      | Number
      | default = 5,
    start_servers
      | Number
      | default = 2,
    min_spare_servers
      | Number
      | default = 1,
    max_spare_servers
      | Number
      | default = 3,
    max_requests
      | Number
      | default = 500
      | doc "Requests before worker restart (prevents memory leaks)",
  },

  Config = {
    version
      | String
      | default = "8.3"
      | doc "PHP version (8.1, 8.2, 8.3)",

    # Memory and execution limits
    memory_limit
      | String
      | default = "256M",
    max_execution_time
      | Number
      | default = 30,
    max_input_time
      | Number
      | default = 60,
    max_input_vars
      | Number
      | default = 1000,

    # Upload settings
    upload_max_filesize
      | String
      | default = "64M",
    post_max_size
      | String
      | default = "64M",
    max_file_uploads
      | Number
      | default = 20,

    # Error handling
    display_errors
      | Bool
      | default = false,
    log_errors
      | Bool
      | default = true,
    error_reporting
      | String
      | default = "E_ALL & ~E_DEPRECATED & ~E_STRICT",
    error_log
      | String
      | optional,

    # Timezone
    timezone
      | String
      | default = "UTC",

    # Security
    expose_php
      | Bool
      | default = false,
    allow_url_fopen
      | Bool
      | default = true,
    allow_url_include
      | Bool
      | default = false,
    open_basedir
      | String
      | optional
      | doc "Restrict file operations to these paths",
    disable_functions
      | Array String
      | default = ["exec", "passthru", "shell_exec", "system", "proc_open", "popen"]
      | doc "Disabled functions for security",

    # OPcache
    opcache
      | OpcacheConfig
      | default = {},

    # Session
    session
      | SessionConfig
      | default = {},

    # FPM Pool
    pool
      | PoolConfig
      | default = {},

    # Extensions
    extensions
      | Array String
      | default = []
      | doc "Additional extensions to enable",
  },
}
