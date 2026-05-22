# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Application do
  @moduledoc """
  The WpPraxis Application for database schema and state management.

  This application manages the Ecto repository and provides database
  access for the symbolic workflow system.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      WpPraxis.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WpPraxis.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
