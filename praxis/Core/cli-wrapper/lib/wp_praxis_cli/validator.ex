# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxisCli.Validator do
  @moduledoc """
  Validates manifests using wp_praxis_core (Rust) via Port.

  This module acts as a bridge between Elixir and the Rust
  validation engine.
  """

  @rust_binary System.get_env("WP_PRAXIS_CORE_BIN", "wp-praxis-core")

  @doc """
  Validate a manifest file.

  Returns `{:ok, result}` or `{:error, errors}`.
  """
  def validate_file(path, opts \\ []) do
    strict = Keyword.get(opts, :strict, false)

    case call_rust_validator(path, strict) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Call Rust wp_praxis_core validator via Port.
  """
  defp call_rust_validator(path, strict) do
    args = ["validate", path]
    args = if strict, do: args ++ ["--strict"], else: args

    case find_rust_binary() do
      {:ok, binary_path} ->
        port = Port.open({:spawn_executable, binary_path}, [
          :binary,
          :exit_status,
          args: args,
          env: [{'RUST_BACKTRACE', '1'}]
        ])

        receive_port_response(port, "")

      {:error, :not_found} ->
        # Fall back to Elixir-based validation
        validate_with_elixir(path, strict)
    end
  end

  defp find_rust_binary do
    binary = @rust_binary

    cond do
      File.exists?(binary) ->
        {:ok, binary}

      System.find_executable(binary) ->
        {:ok, System.find_executable(binary)}

      File.exists?(Path.join([File.cwd!(), "target", "release", "wp-praxis-core"])) ->
        {:ok, Path.join([File.cwd!(), "target", "release", "wp-praxis-core"])}

      true ->
        {:error, :not_found}
    end
  end

  defp receive_port_response(port, acc) do
    receive do
      {^port, {:data, data}} ->
        receive_port_response(port, acc <> data)

      {^port, {:exit_status, 0}} ->
        parse_json_response(acc)

      {^port, {:exit_status, code}} ->
        {:error, "Validator exited with code #{code}: #{acc}"}
    after
      30_000 ->
        Port.close(port)
        {:error, "Validator timeout"}
    end
  end

  defp parse_json_response(json_string) do
    case Jason.decode(json_string) do
      {:ok, %{"name" => name, "version" => version} = data} ->
        {:ok, %{
          name: name,
          version: version,
          symbols: Map.get(data, "symbols", []),
          warnings: Map.get(data, "warnings", []),
          errors: Map.get(data, "errors", [])
        }}

      {:ok, %{"error" => error}} ->
        {:error, error}

      {:error, reason} ->
        {:error, "Failed to parse validator response: #{inspect(reason)}"}
    end
  end

  @doc """
  Fallback validation using pure Elixir when Rust binary unavailable.
  """
  defp validate_with_elixir(path, _strict) do
    case File.read(path) do
      {:ok, content} ->
        parse_manifest(path, content)

      {:error, reason} ->
        {:error, "Could not read file: #{inspect(reason)}"}
    end
  end

  defp parse_manifest(path, content) do
    ext = Path.extname(path)

    case ext do
      ".json" ->
        case Jason.decode(content) do
          {:ok, data} -> {:ok, normalize_manifest(data)}
          {:error, reason} -> {:error, "Invalid JSON: #{inspect(reason)}"}
        end

      ".yaml" ->
        case YamlElixir.read_from_string(content) do
          {:ok, data} -> {:ok, normalize_manifest(data)}
          {:error, reason} -> {:error, "Invalid YAML: #{inspect(reason)}"}
        end

      _ ->
        {:error, "Unsupported manifest format: #{ext}"}
    end
  end

  defp normalize_manifest(data) when is_map(data) do
    %{
      name: Map.get(data, "name", "unknown"),
      version: Map.get(data, "version", "0.0.0"),
      symbols: Map.get(data, "symbols", []),
      warnings: []
    }
  end
end
