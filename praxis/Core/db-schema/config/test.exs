# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

import Config

# Configure the database for testing
config :wp_praxis, WpPraxis.Repo,
  database: "wp_praxis_test#{System.get_env("MIX_TEST_PARTITION")}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  log: false

# Print only warnings and errors during test
config :logger, level: :warning

# Reduce bcrypt rounds for faster tests (if using authentication)
# config :bcrypt_elixir, :log_rounds, 4
