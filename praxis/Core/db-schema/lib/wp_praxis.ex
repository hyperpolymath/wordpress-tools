# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis do
  @moduledoc """
  WpPraxis - Modular Symbolic System for WordPress Workflows

  This module provides the core database schema and state management
  for the WP Praxis symbolic workflow system.

  ## Overview

  WpPraxis maintains state for:
  - Symbols: Declarative operation definitions
  - Workflows: Collections of symbols and execution plans
  - Executions: Runtime tracking of workflow execution
  - Baselines: Normative states for symbolic auditing
  - Audits: Deviation tracking from baselines

  ## Usage

  Most interactions should go through the schema modules and query modules:

      # Working with symbols
      alias WpPraxis.Schema.Symbol
      alias WpPraxis.Queries.SymbolQueries

      # Create a symbol
      {:ok, symbol} = Symbol.create(%{
        name: "my_operation",
        type: "action",
        context: "wordpress"
      })

      # Query symbols
      active_symbols = SymbolQueries.active_symbols()
  """

  @doc """
  Returns the version of the WpPraxis system.
  """
  def version, do: "0.1.0"
end
