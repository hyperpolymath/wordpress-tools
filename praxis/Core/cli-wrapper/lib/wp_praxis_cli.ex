# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxisCli.CLI do
  @moduledoc """
  Command-line interface for WP Praxis symbolic workflows.

  This is the orchestration layer that:
  - Parses YAML/TOML manifests
  - Validates with wp_praxis_core (Rust)
  - Dispatches to appropriate executors
  - Manages state via Ecto schemas

  ## Usage

      # Parse and validate a manifest
      wp-praxis validate manifest.yml

      # Execute a workflow
      wp-praxis run manifest.yml

      # Inject symbols into WordPress database
      wp-praxis inject manifest.yml --db mysql://...

      # Interactive mode
      wp-praxis interactive
  """

  alias WpPraxis.Schemas.{Manifest, Symbol, Workflow, Execution}
  alias WpPraxisCli.{Dispatcher, Validator, Injector}

  @doc """
  Main entry point for escript.
  """
  def main(args) do
    # Ensure applications are started
    {:ok, _} = Application.ensure_all_started(:wp_praxis)

    # Parse CLI arguments
    case parse_args(args) do
      {:ok, command, opts} ->
        execute_command(command, opts)

      {:error, message} ->
        IO.puts(:stderr, "Error: #{message}")
        print_usage()
        System.halt(1)
    end
  end

  defp parse_args(args) do
    cli_spec = build_cli_spec()

    case Optimus.parse(cli_spec, args) do
      {:ok, parsed} ->
        command = parsed.args[:command]
        {:ok, command, parsed}

      {:error, reason} ->
        {:error, Optimus.error_reason(reason)}
    end
  end

  defp build_cli_spec do
    Optimus.new!(
      name: "wp-praxis",
      description: "WP Praxis symbolic workflow orchestrator",
      version: "0.1.0",
      author: "WP Praxis Contributors",
      about: "Modular symbolic system for WordPress workflows",
      allow_unknown_args: false,
      parse_double_dash: true,
      subcommands: [
        validate: [
          name: "validate",
          about: "Validate a manifest file",
          args: [
            manifest: [
              value_name: "MANIFEST",
              help: "Path to manifest file (YAML or TOML)",
              required: true,
              parser: :string
            ]
          ],
          flags: [
            strict: [
              short: "-s",
              long: "--strict",
              help: "Enable strict validation mode",
              multiple: false
            ]
          ]
        ],
        run: [
          name: "run",
          about: "Execute a symbolic workflow",
          args: [
            manifest: [
              value_name: "MANIFEST",
              help: "Path to manifest file",
              required: true,
              parser: :string
            ]
          ],
          options: [
            dry_run: [
              short: "-d",
              long: "--dry-run",
              help: "Simulate execution without applying changes",
              required: false,
              parser: :boolean,
              default: false
            ]
          ]
        ],
        inject: [
          name: "inject",
          about: "Inject symbols into WordPress database",
          args: [
            manifest: [
              value_name: "MANIFEST",
              help: "Path to manifest file",
              required: true,
              parser: :string
            ]
          ],
          options: [
            database: [
              short: "-D",
              long: "--database",
              help: "Database connection string",
              required: true,
              parser: :string
            ],
            rollback: [
              short: "-r",
              long: "--rollback",
              help: "Enable rollback on error",
              required: false,
              parser: :boolean,
              default: true
            ]
          ]
        ],
        interactive: [
          name: "interactive",
          about: "Start interactive REPL mode"
        ]
      ]
    )
  end

  defp execute_command(command, opts) do
    case command do
      :validate ->
        validate_manifest(opts)

      :run ->
        run_workflow(opts)

      :inject ->
        inject_symbols(opts)

      :interactive ->
        start_interactive()

      nil ->
        print_usage()
    end
  end

  defp validate_manifest(opts) do
    manifest_path = opts.args[:manifest]
    strict = opts.flags[:strict] || false

    IO.puts("Validating manifest: #{manifest_path}")

    case Validator.validate_file(manifest_path, strict: strict) do
      {:ok, result} ->
        IO.puts("✓ Manifest is valid")
        IO.puts("  Name: #{result.name}")
        IO.puts("  Version: #{result.version}")
        IO.puts("  Symbols: #{length(result.symbols)}")

        unless Enum.empty?(result.warnings) do
          IO.puts("\nWarnings:")
          Enum.each(result.warnings, fn warning ->
            IO.puts("  ⚠  #{warning}")
          end)
        end

        System.halt(0)

      {:error, errors} ->
        IO.puts(:stderr, "✗ Validation failed:")
        Enum.each(errors, fn error ->
          IO.puts(:stderr, "  ✗ #{error}")
        end)
        System.halt(1)
    end
  end

  defp run_workflow(opts) do
    manifest_path = opts.args[:manifest]
    dry_run = opts.options[:dry_run]

    IO.puts("Executing workflow: #{manifest_path}")
    if dry_run, do: IO.puts("(DRY RUN - no changes will be applied)")

    case Dispatcher.dispatch_workflow(manifest_path, dry_run: dry_run) do
      {:ok, execution} ->
        IO.puts("✓ Workflow executed successfully")
        IO.puts("  Execution ID: #{execution.id}")
        IO.puts("  Status: #{execution.status}")
        IO.puts("  Symbols processed: #{execution.symbols_count}")
        System.halt(0)

      {:error, reason} ->
        IO.puts(:stderr, "✗ Workflow failed: #{reason}")
        System.halt(1)
    end
  end

  defp inject_symbols(opts) do
    manifest_path = opts.args[:manifest]
    database = opts.options[:database]
    rollback = opts.options[:rollback]

    IO.puts("Injecting symbols from: #{manifest_path}")
    IO.puts("Target database: #{obscure_connection_string(database)}")

    case Injector.inject(manifest_path, database, rollback: rollback) do
      {:ok, result} ->
        IO.puts("✓ Injection successful")
        IO.puts("  Symbols injected: #{result.injected_count}")
        IO.puts("  Rollbacks available: #{result.rollback_count}")
        System.halt(0)

      {:error, reason} ->
        IO.puts(:stderr, "✗ Injection failed: #{reason}")
        if rollback do
          IO.puts(:stderr, "  Rolling back changes...")
        end
        System.halt(1)
    end
  end

  defp start_interactive do
    IO.puts("WP Praxis Interactive Mode")
    IO.puts("Type 'help' for available commands, 'exit' to quit")
    IO.puts("")

    interactive_loop()
  end

  defp interactive_loop do
    prompt = IO.gets("wp-praxis> ")

    case String.trim(prompt) do
      "exit" ->
        IO.puts("Goodbye!")
        System.halt(0)

      "help" ->
        print_interactive_help()
        interactive_loop()

      "" ->
        interactive_loop()

      command ->
        # Parse and execute interactive command
        execute_interactive_command(command)
        interactive_loop()
    end
  end

  defp execute_interactive_command(input) do
    parts = String.split(input, " ", parts: 2)
    {cmd, args} = case parts do
      [cmd] -> {cmd, ""}
      [cmd, args] -> {cmd, args}
    end

    case cmd do
      "validate" ->
        if args != "" do
          case Validator.validate_file(String.trim(args)) do
            {:ok, result} ->
              IO.puts("✓ Manifest valid: #{result.name} v#{result.version}")
              if length(result.warnings) > 0 do
                IO.puts("  Warnings:")
                Enum.each(result.warnings, &IO.puts("    - #{&1}"))
              end
            {:error, reason} ->
              IO.puts("✗ Validation failed: #{reason}")
          end
        else
          IO.puts("Usage: validate <manifest_path>")
        end

      "run" ->
        if args != "" do
          path = String.trim(args)
          case Validator.validate_file(path) do
            {:ok, manifest} ->
              IO.puts("Executing workflow: #{manifest.name}")
              case Dispatcher.run(manifest) do
                {:ok, execution} ->
                  IO.puts("✓ Execution completed: #{execution.id}")
                {:error, reason} ->
                  IO.puts("✗ Execution failed: #{reason}")
              end
            {:error, reason} ->
              IO.puts("✗ Manifest invalid: #{reason}")
          end
        else
          IO.puts("Usage: run <manifest_path>")
        end

      "list" ->
        case String.trim(args) do
          "workflows" ->
            IO.puts("Registered workflows:")
            # Query from Ecto repo if available
            IO.puts("  (none registered)")

          "symbols" ->
            IO.puts("Known symbols:")
            IO.puts("  (none loaded)")

          _ ->
            IO.puts("Usage: list workflows | list symbols")
        end

      "status" ->
        IO.puts("WP Praxis Status:")
        IO.puts("  Version: 0.1.0")
        IO.puts("  Backend: Elixir/OTP")
        IO.puts("  Rust core: #{if rust_core_available?(), do: "available", else: "not found"}")

      _ ->
        IO.puts("Unknown command: #{cmd}")
        IO.puts("Type 'help' for available commands")
    end
  end

  defp rust_core_available? do
    System.find_executable("wp-praxis-core") != nil ||
      File.exists?(System.get_env("WP_PRAXIS_CORE_BIN", ""))
  end

  defp print_usage do
    IO.puts("""
    WP Praxis - Symbolic Workflow Orchestrator

    Usage:
      wp-praxis validate <manifest>           Validate a manifest file
      wp-praxis run <manifest> [--dry-run]    Execute a workflow
      wp-praxis inject <manifest> --database <db>  Inject into database
      wp-praxis interactive                   Start interactive mode

    For detailed help:
      wp-praxis --help
      wp-praxis <command> --help
    """)
  end

  defp print_interactive_help do
    IO.puts("""
    Interactive Commands:
      validate <file>    Validate a manifest
      run <file>         Execute a workflow
      list workflows     List all workflows
      list symbols       List all symbols
      help               Show this help
      exit               Exit interactive mode
    """)
  end

  defp obscure_connection_string(conn_string) do
    # Hide password in connection string for display
    Regex.replace(~r/:([^@]+)@/, conn_string, ":***@")
  end
end
