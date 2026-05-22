# SPDX-License-Identifier: MPL-2.0
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Repo do
  use Ecto.Repo,
    otp_app: :wp_praxis,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository configuration from the environment.

  This allows runtime configuration of database connections.
  """
  def init(_type, config) do
    {:ok, config}
  end
end
