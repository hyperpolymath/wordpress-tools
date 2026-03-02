defmodule Sinople.MixProject do
  use Mix.Project

  def project do
    [
      app: :sinople,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Sinople.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # JSON handling
      {:jason, "~> 1.4"},

      # RabbitMQ client
      {:amqp, "~> 3.3"},

      # FlatBuffers (if available)
      {:flatbuffers, "~> 0.1", optional: true},

      # HTTP client for NDJSON streaming
      {:req, "~> 0.4"},
      {:mint, "~> 1.5"},

      # Streaming
      {:gen_stage, "~> 1.2"},
      {:flow, "~> 1.2"},

      # Development and testing
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
