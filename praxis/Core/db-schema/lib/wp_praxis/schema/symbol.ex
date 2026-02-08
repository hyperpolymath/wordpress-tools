# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Schema.Symbol do
  @moduledoc """
  Schema for Symbol entities in the WP Praxis symbolic system.

  Symbols are declarative representations of operations that can be
  dispatched to various execution engines (Rust injectors, PowerShell,
  PHP, etc.).

  ## Fields

  - `name` - Unique identifier for the symbol
  - `type` - Symbol type (action, transform, query, etc.)
  - `context` - Execution context (wordpress, system, database, etc.)
  - `status` - Current status (active, inactive, deprecated)
  - `dispatch_target` - Target executor (rust_injector, powershell, php, etc.)
  - `parameters` - JSON map of symbol-specific parameters
  - `description` - Human-readable description of the symbol's purpose
  - `priority` - Execution priority (1-10, higher = more important)
  - `timeout` - Execution timeout in seconds
  - `retry_count` - Number of retry attempts on failure
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          type: String.t(),
          context: String.t(),
          status: String.t(),
          dispatch_target: String.t(),
          parameters: map(),
          description: String.t() | nil,
          priority: integer(),
          timeout: integer(),
          retry_count: integer(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "symbols" do
    field :name, :string
    field :type, :string
    field :context, :string
    field :status, :string, default: "active"
    field :dispatch_target, :string
    field :parameters, :map, default: %{}
    field :description, :string
    field :priority, :integer, default: 5
    field :timeout, :integer, default: 300
    field :retry_count, :integer, default: 0

    has_many :executions, WpPraxis.Schema.Execution

    timestamps()
  end

  @doc """
  Validates and creates a changeset for a symbol.

  ## Required Fields
  - name
  - type
  - context
  - dispatch_target

  ## Optional Fields
  - status (defaults to "active")
  - parameters (defaults to empty map)
  - description
  - priority (defaults to 5)
  - timeout (defaults to 300 seconds)
  - retry_count (defaults to 0)

  ## Validations
  - Name must be unique
  - Type must be one of: action, transform, query, validator, generator
  - Status must be one of: active, inactive, deprecated
  - Priority must be between 1 and 10
  - Timeout must be positive
  - Retry count must be non-negative
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(symbol, attrs) do
    symbol
    |> cast(attrs, [
      :name,
      :type,
      :context,
      :status,
      :dispatch_target,
      :parameters,
      :description,
      :priority,
      :timeout,
      :retry_count
    ])
    |> validate_required([:name, :type, :context, :dispatch_target])
    |> validate_inclusion(:type, ["action", "transform", "query", "validator", "generator"])
    |> validate_inclusion(:status, ["active", "inactive", "deprecated"])
    |> validate_number(:priority, greater_than_or_equal_to: 1, less_than_or_equal_to: 10)
    |> validate_number(:timeout, greater_than: 0)
    |> validate_number(:retry_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end

  @doc """
  Creates a new symbol with the given attributes.
  """
  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> WpPraxis.Repo.insert()
  end

  @doc """
  Updates an existing symbol with the given attributes.
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(symbol, attrs) do
    symbol
    |> changeset(attrs)
    |> WpPraxis.Repo.update()
  end

  @doc """
  Deletes a symbol.
  """
  @spec delete(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def delete(symbol) do
    WpPraxis.Repo.delete(symbol)
  end
end
