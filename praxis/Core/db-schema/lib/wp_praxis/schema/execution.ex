# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Schema.Execution do
  @moduledoc """
  Schema for Execution tracking in the WP Praxis symbolic system.

  Executions represent individual symbol invocations within a workflow.
  They track the runtime state, performance metrics, and results of
  symbolic operations.

  ## Fields

  - `workflow_id` - Reference to the parent workflow
  - `symbol_id` - Reference to the symbol being executed
  - `status` - Execution status (pending, running, completed, failed, retrying)
  - `started_at` - When execution began
  - `completed_at` - When execution finished
  - `duration` - Execution time in seconds
  - `output` - JSON map of execution output
  - `error_log` - Text log of any errors encountered
  - `rollback_state` - JSON snapshot for potential rollback
  - `retry_attempt` - Current retry attempt number
  - `exit_code` - Process exit code (if applicable)
  - `metadata` - Additional execution-specific metadata
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          workflow_id: integer(),
          symbol_id: integer(),
          status: String.t(),
          started_at: NaiveDateTime.t() | nil,
          completed_at: NaiveDateTime.t() | nil,
          duration: integer() | nil,
          output: map(),
          error_log: String.t() | nil,
          rollback_state: map(),
          retry_attempt: integer(),
          exit_code: integer() | nil,
          metadata: map(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "executions" do
    field :status, :string, default: "pending"
    field :started_at, :naive_datetime
    field :completed_at, :naive_datetime
    field :duration, :integer
    field :output, :map, default: %{}
    field :error_log, :string
    field :rollback_state, :map, default: %{}
    field :retry_attempt, :integer, default: 0
    field :exit_code, :integer
    field :metadata, :map, default: %{}

    belongs_to :workflow, WpPraxis.Schema.Workflow
    belongs_to :symbol, WpPraxis.Schema.Symbol

    timestamps()
  end

  @doc """
  Validates and creates a changeset for an execution.

  ## Required Fields
  - workflow_id
  - symbol_id

  ## Optional Fields
  - status (defaults to "pending")
  - started_at
  - completed_at
  - duration
  - output (defaults to empty map)
  - error_log
  - rollback_state (defaults to empty map)
  - retry_attempt (defaults to 0)
  - exit_code
  - metadata (defaults to empty map)

  ## Validations
  - Status must be one of: pending, running, completed, failed, retrying
  - Duration must be non-negative if present
  - Retry attempt must be non-negative
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(execution, attrs) do
    execution
    |> cast(attrs, [
      :workflow_id,
      :symbol_id,
      :status,
      :started_at,
      :completed_at,
      :duration,
      :output,
      :error_log,
      :rollback_state,
      :retry_attempt,
      :exit_code,
      :metadata
    ])
    |> validate_required([:workflow_id, :symbol_id])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed", "retrying"])
    |> validate_number(:duration, greater_than_or_equal_to: 0)
    |> validate_number(:retry_attempt, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:workflow_id)
    |> foreign_key_constraint(:symbol_id)
    |> validate_completion_logic()
  end

  # Private function to validate completion logic
  defp validate_completion_logic(changeset) do
    status = get_field(changeset, :status)
    completed_at = get_field(changeset, :completed_at)

    case status do
      s when s in ["completed", "failed"] and is_nil(completed_at) ->
        add_error(changeset, :completed_at, "must be set when status is completed or failed")

      _ ->
        changeset
    end
  end

  @doc """
  Creates a new execution with the given attributes.
  """
  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> WpPraxis.Repo.insert()
  end

  @doc """
  Updates an existing execution with the given attributes.
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(execution, attrs) do
    execution
    |> changeset(attrs)
    |> WpPraxis.Repo.update()
  end

  @doc """
  Deletes an execution.
  """
  @spec delete(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def delete(execution) do
    WpPraxis.Repo.delete(execution)
  end

  @doc """
  Starts an execution by setting status to running and recording start time.
  """
  @spec start(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def start(execution) do
    update(execution, %{
      status: "running",
      started_at: NaiveDateTime.utc_now()
    })
  end

  @doc """
  Completes an execution successfully.
  """
  @spec complete(t(), map(), integer() | nil) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def complete(execution, output \\ %{}, exit_code \\ 0) do
    now = NaiveDateTime.utc_now()
    duration = calculate_duration(execution.started_at, now)

    update(execution, %{
      status: "completed",
      completed_at: now,
      duration: duration,
      output: output,
      exit_code: exit_code
    })
  end

  @doc """
  Marks an execution as failed with error information.
  """
  @spec fail(t(), String.t(), integer() | nil) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def fail(execution, error_log, exit_code \\ nil) do
    now = NaiveDateTime.utc_now()
    duration = calculate_duration(execution.started_at, now)

    update(execution, %{
      status: "failed",
      completed_at: now,
      duration: duration,
      error_log: error_log,
      exit_code: exit_code
    })
  end

  @doc """
  Marks an execution for retry.
  """
  @spec retry(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def retry(execution) do
    update(execution, %{
      status: "retrying",
      retry_attempt: execution.retry_attempt + 1
    })
  end

  @doc """
  Saves rollback state for potential rollback operations.
  """
  @spec save_rollback_state(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def save_rollback_state(execution, state) do
    update(execution, %{rollback_state: state})
  end

  # Calculate duration in seconds between two NaiveDateTime values
  defp calculate_duration(nil, _), do: nil
  defp calculate_duration(_, nil), do: nil

  defp calculate_duration(started_at, completed_at) do
    NaiveDateTime.diff(completed_at, started_at, :second)
  end
end
