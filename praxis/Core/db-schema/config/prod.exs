# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

import Config

# Configure the database for production
# You should configure the database URL via environment variables
# in production, for example:
#
#     DATABASE_URL=ecto://USER:PASS@HOST/DATABASE
#
# You can also use a socket connection:
#
#     SOCKET=/path/to/socket

config :wp_praxis, WpPraxis.Repo,
  # Use runtime configuration from environment variables
  # ssl: true will be enforced by default if connecting to a remote database
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  queue_target: 5000,
  queue_interval: 1000

# Configure production logging
config :logger, level: :info

# Note: The actual database configuration in production should be done
# in config/runtime.exs which is loaded at runtime and can access
# environment variables securely.
