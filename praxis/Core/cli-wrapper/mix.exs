# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxisCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :wp_praxis_cli,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Use the main WP Praxis Ecto app
      {:wp_praxis, path: "../db-schema"},

      # CLI framework
      {:optimus, "~> 0.2"}
    ]
  end

  defp escript do
    [
      main_module: WpPraxisCli.CLI,
      name: "wp-praxis"
    ]
  end
end
