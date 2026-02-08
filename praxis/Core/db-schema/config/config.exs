# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

import Config

# Configure the WpPraxis application
config :wp_praxis,
  ecto_repos: [WpPraxis.Repo]

# Configure the database repository
config :wp_praxis, WpPraxis.Repo,
  migration_timestamps: [type: :naive_datetime],
  pool_size: 10

# Configure Jason as the JSON library
config :wp_praxis, :json_library, Jason

# Configure Ecto to use Jason for JSON encoding/decoding
config :ecto, :json_library, Jason

# Import environment specific config
import_config "#{config_env()}.exs"
