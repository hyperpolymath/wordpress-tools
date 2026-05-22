# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

# Start the repository in test mode
ExUnit.start()

# Setup the database sandbox for concurrent testing
Ecto.Adapters.SQL.Sandbox.mode(WpPraxis.Repo, :manual)
