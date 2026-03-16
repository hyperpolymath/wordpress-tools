# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

# Start the repository in test mode
ExUnit.start()

# Setup the database sandbox for concurrent testing
Ecto.Adapters.SQL.Sandbox.mode(WpPraxis.Repo, :manual)
