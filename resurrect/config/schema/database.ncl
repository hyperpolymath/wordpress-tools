# SPDX-License-Identifier: AGPL-3.0-or-later
# Database configuration schema

{
  DatabaseType = [| 'mariadb, 'mysql, 'postgresql |],

  ConnectionConfig = {
    host
      | String
      | default = "localhost",
    port
      | Number
      | default = 3306,
    socket
      | String
      | optional
      | doc "Unix socket path (preferred over TCP)",
    charset
      | String
      | default = "utf8mb4",
    collation
      | String
      | default = "utf8mb4_unicode_ci",
  },

  PoolingConfig = {
    enabled
      | Bool
      | default = true,
    min_connections
      | Number
      | default = 2,
    max_connections
      | Number
      | default = 10,
    idle_timeout
      | Number
      | default = 300
      | doc "Seconds before idle connection is closed",
    max_lifetime
      | Number
      | default = 3600
      | doc "Max seconds a connection can live",
  },

  ReplicationConfig = {
    enabled
      | Bool
      | default = false,
    role
      | [| 'primary, 'replica, 'standalone |]
      | default = 'standalone,
    replicas
      | Array String
      | default = []
      | doc "Replica hostnames (for read splitting)",
    read_from_replica
      | Bool
      | default = true
      | doc "Route read queries to replicas",
  },

  BackupConfig = {
    enabled
      | Bool
      | default = true,
    schedule
      | String
      | default = "0 3 * * *"
      | doc "Cron schedule for backups",
    retention_days
      | Number
      | default = 30,
    type
      | [| 'mysqldump, 'mariabackup, 'xtrabackup |]
      | default = 'mariabackup,
    destination
      | String
      | default = "/var/backups/mysql",
    compress
      | Bool
      | default = true,
    encrypt
      | Bool
      | default = true,
  },

  TuningConfig = {
    innodb_buffer_pool_size
      | String
      | optional
      | doc "InnoDB buffer pool (e.g., '1G', '4G')",
    innodb_log_file_size
      | String
      | optional,
    max_connections
      | Number
      | default = 151,
    query_cache_type
      | [| 'OFF, 'ON, 'DEMAND |]
      | default = 'OFF
      | doc "Query cache (deprecated in MySQL 8+)",
    slow_query_log
      | Bool
      | default = true,
    long_query_time
      | Number
      | default = 2
      | doc "Seconds threshold for slow query log",
    tmp_table_size
      | String
      | default = "64M",
    max_heap_table_size
      | String
      | default = "64M",
  },

  Config = {
    type
      | DatabaseType
      | default = 'mariadb,

    version
      | String
      | default = "11.4"
      | doc "Database version",

    # Database name (actual credentials in pillars)
    name
      | String
      | doc "Database name",

    # User reference (actual password in pillars)
    user_ref
      | String
      | doc "Reference to username in secrets",

    password_ref
      | String
      | doc "Reference to password in secrets",

    # Connection
    connection
      | ConnectionConfig
      | default = {},

    # Pooling
    pool
      | PoolingConfig
      | default = {},

    # Replication
    replication
      | ReplicationConfig
      | default = {},

    # Backup
    backup
      | BackupConfig
      | default = {},

    # Performance tuning
    tuning
      | TuningConfig
      | default = {},

    # Monitoring
    slow_query_analysis
      | Bool
      | default = true,
    performance_schema
      | Bool
      | default = true,
  },
}
