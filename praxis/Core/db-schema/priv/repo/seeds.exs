# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

# Script for populating the database with initial data.
# You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     WpPraxis.Repo.insert!(%WpPraxis.Schema.Symbol{...})
#
# We recommend using the create functions provided by the schemas
# as they include proper validation and error handling.

alias WpPraxis.Schema.Symbol
alias WpPraxis.Schema.Baseline

# Create some example symbols
IO.puts("Creating example symbols...")

{:ok, _} =
  Symbol.create(%{
    name: "wordpress_init",
    type: "action",
    context: "wordpress",
    dispatch_target: "php",
    description: "Initialize WordPress environment",
    priority: 10
  })

{:ok, _} =
  Symbol.create(%{
    name: "plugin_activate",
    type: "action",
    context: "wordpress",
    dispatch_target: "php",
    description: "Activate a WordPress plugin",
    priority: 7,
    parameters: %{
      plugin_slug: "example-plugin"
    }
  })

{:ok, _} =
  Symbol.create(%{
    name: "database_backup",
    type: "action",
    context: "system",
    dispatch_target: "rust_injector",
    description: "Backup WordPress database",
    priority: 9,
    timeout: 600
  })

{:ok, _} =
  Symbol.create(%{
    name: "validate_permissions",
    type: "validator",
    context: "system",
    dispatch_target: "powershell",
    description: "Validate file system permissions",
    priority: 5
  })

{:ok, _} =
  Symbol.create(%{
    name: "transform_config",
    type: "transform",
    context: "wordpress",
    dispatch_target: "php",
    description: "Transform WordPress configuration",
    priority: 6
  })

IO.puts("Created 5 example symbols")

# Create an example baseline
IO.puts("Creating example baseline...")

{:ok, _} =
  Baseline.create(%{
    name: "initial_system_baseline",
    description: "Initial system state baseline",
    symbolic_state: %{
      wordpress_version: "6.4.0",
      php_version: "8.2",
      active_symbols: ["wordpress_init", "plugin_activate"],
      system_status: "healthy"
    },
    baseline_type: "system",
    scope: "global",
    is_active: true
  })

IO.puts("Created initial baseline")

IO.puts("\nSeeding completed successfully!")
IO.puts("You can now query the database:")
IO.puts("  iex> WpPraxis.Queries.SymbolQueries.active_symbols()")
