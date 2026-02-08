# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Schema.Workflow do
  @moduledoc """
  Schema for Workflow entities in the WP Praxis symbolic system.

  Workflows represent collections of symbols organized into execution plans.
  They are typically defined in YAML/TOML manifest files and parsed into
  database records for execution tracking.

  ## Fields

  - `name` - Unique workflow identifier
  - `description` - Human-readable workflow description
  - `manifest_path` - Path to the YAML/TOML manifest file
  - `status` - Workflow status (pending, running, completed, failed, paused)
  - `execution_log` - JSON array of execution events and state transitions
  - `metadata` - JSON map of workflow-specific metadata
  - `started_at` - When the workflow execution began
  - `completed_at` - When the workflow execution finished
  - `duration` - Total execution time in seconds
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          description: String.t() | nil,
          manifest_path: String.t(),
          status: String.t(),
          execution_log: list(),
          metadata: map(),
          started_at: NaiveDateTime.t() | nil,
          completed_at: NaiveDateTime.t() | nil,
          duration: integer() | nil,
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "workflows" do
    field :name, :string
    field :description, :string
    field :manifest_path, :string
    field :status, :string, default: "pending"
    field :execution_log, {:array, :map}, default: []
    field :metadata, :map, default: %{}
    field :started_at, :naive_datetime
    field :completed_at, :naive_datetime
    field :duration, :integer

    has_many :executions, WpPraxis.Schema.Execution
    has_many :audits, WpPraxis.Schema.Audit

    timestamps()
  end

  @doc """
  Validates and creates a changeset for a workflow.

  ## Required Fields
  - name
  - manifest_path

  ## Optional Fields
  - description
  - status (defaults to "pending")
  - execution_log (defaults to empty list)
  - metadata (defaults to empty map)
  - started_at
  - completed_at
  - duration

  ## Validations
  - Name must be unique
  - Status must be one of: pending, running, completed, failed, paused
  - Duration must be non-negative if present
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [
      :name,
      :description,
      :manifest_path,
      :status,
      :execution_log,
      :metadata,
      :started_at,
      :completed_at,
      :duration
    ])
    |> validate_required([:name, :manifest_path])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed", "paused"])
    |> validate_number(:duration, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
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
  Creates a new workflow with the given attributes.
  """
  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> WpPraxis.Repo.insert()
  end

  @doc """
  Updates an existing workflow with the given attributes.
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(workflow, attrs) do
    workflow
    |> changeset(attrs)
    |> WpPraxis.Repo.update()
  end

  @doc """
  Deletes a workflow.
  """
  @spec delete(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def delete(workflow) do
    WpPraxis.Repo.delete(workflow)
  end

  @doc """
  Starts a workflow by setting status to running and recording the start time.
  """
  @spec start(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def start(workflow) do
    update(workflow, %{
      status: "running",
      started_at: NaiveDateTime.utc_now()
    })
  end

  @doc """
  Completes a workflow by setting status and recording completion time.
  """
  @spec complete(t(), String.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def complete(workflow, final_status \\ "completed") when final_status in ["completed", "failed"] do
    now = NaiveDateTime.utc_now()
    duration = calculate_duration(workflow.started_at, now)

    update(workflow, %{
      status: final_status,
      completed_at: now,
      duration: duration
    })
  end

  @doc """
  Appends an entry to the workflow's execution log.
  """
  @spec log_event(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def log_event(workflow, event) do
    event_with_timestamp = Map.put(event, :timestamp, NaiveDateTime.utc_now())
    updated_log = workflow.execution_log ++ [event_with_timestamp]

    update(workflow, %{execution_log: updated_log})
  end

  # Calculate duration in seconds between two NaiveDateTime values
  defp calculate_duration(nil, _), do: nil
  defp calculate_duration(_, nil), do: nil

  defp calculate_duration(started_at, completed_at) do
    NaiveDateTime.diff(completed_at, started_at, :second)
  end
end
