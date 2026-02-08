# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

import Config

# Configure the database for development
config :wp_praxis, WpPraxis.Repo,
  database: "wp_praxis_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  stacktrace: true,
  log: :info

# Enable database query logging in development
config :logger, :console,
  format: "[$level] $message\n",
  metadata: [:request_id]

# Set log level for development
config :logger, level: :debug
