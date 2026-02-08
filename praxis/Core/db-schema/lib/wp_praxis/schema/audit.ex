# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Schema.Audit do
  @moduledoc """
  Schema for Audit entities in the WP Praxis symbolic system.

  Audits track deviations from normative baselines and provide a record
  of system state divergence. They are used for compliance tracking,
  debugging, and symbolic introspection.

  ## Fields

  - `baseline_id` - Reference to the baseline being audited against
  - `workflow_id` - Optional reference to a workflow that triggered the audit
  - `audit_type` - Type of audit (scheduled, triggered, manual, continuous)
  - `status` - Audit status (pending, running, completed, failed)
  - `deviations` - JSON array of detected deviations
  - `severity` - Overall severity (info, warning, error, critical)
  - `deviation_count` - Total number of deviations found
  - `passed_checks` - Number of checks that passed
  - `failed_checks` - Number of checks that failed
  - `recommendations` - JSON array of recommended remediation actions
  - `started_at` - When the audit began
  - `completed_at` - When the audit finished
  - `duration` - Audit execution time in seconds
  - `metadata` - Additional audit-specific metadata
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          baseline_id: integer(),
          workflow_id: integer() | nil,
          audit_type: String.t(),
          status: String.t(),
          deviations: list(),
          severity: String.t(),
          deviation_count: integer(),
          passed_checks: integer(),
          failed_checks: integer(),
          recommendations: list(),
          started_at: NaiveDateTime.t() | nil,
          completed_at: NaiveDateTime.t() | nil,
          duration: integer() | nil,
          metadata: map(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "audits" do
    field :audit_type, :string, default: "manual"
    field :status, :string, default: "pending"
    field :deviations, {:array, :map}, default: []
    field :severity, :string, default: "info"
    field :deviation_count, :integer, default: 0
    field :passed_checks, :integer, default: 0
    field :failed_checks, :integer, default: 0
    field :recommendations, {:array, :map}, default: []
    field :started_at, :naive_datetime
    field :completed_at, :naive_datetime
    field :duration, :integer
    field :metadata, :map, default: %{}

    belongs_to :baseline, WpPraxis.Schema.Baseline
    belongs_to :workflow, WpPraxis.Schema.Workflow

    timestamps()
  end

  @doc """
  Validates and creates a changeset for an audit.

  ## Required Fields
  - baseline_id

  ## Optional Fields
  - workflow_id
  - audit_type (defaults to "manual")
  - status (defaults to "pending")
  - deviations (defaults to empty list)
  - severity (defaults to "info")
  - deviation_count (defaults to 0)
  - passed_checks (defaults to 0)
  - failed_checks (defaults to 0)
  - recommendations (defaults to empty list)
  - started_at
  - completed_at
  - duration
  - metadata (defaults to empty map)

  ## Validations
  - Baseline must exist
  - Audit type must be one of: scheduled, triggered, manual, continuous
  - Status must be one of: pending, running, completed, failed
  - Severity must be one of: info, warning, error, critical
  - Counts must be non-negative
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(audit, attrs) do
    audit
    |> cast(attrs, [
      :baseline_id,
      :workflow_id,
      :audit_type,
      :status,
      :deviations,
      :severity,
      :deviation_count,
      :passed_checks,
      :failed_checks,
      :recommendations,
      :started_at,
      :completed_at,
      :duration,
      :metadata
    ])
    |> validate_required([:baseline_id])
    |> validate_inclusion(:audit_type, ["scheduled", "triggered", "manual", "continuous"])
    |> validate_inclusion(:status, ["pending", "running", "completed", "failed"])
    |> validate_inclusion(:severity, ["info", "warning", "error", "critical"])
    |> validate_number(:deviation_count, greater_than_or_equal_to: 0)
    |> validate_number(:passed_checks, greater_than_or_equal_to: 0)
    |> validate_number(:failed_checks, greater_than_or_equal_to: 0)
    |> validate_number(:duration, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:baseline_id)
    |> foreign_key_constraint(:workflow_id)
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
  Creates a new audit with the given attributes.
  """
  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> WpPraxis.Repo.insert()
  end

  @doc """
  Updates an existing audit with the given attributes.
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(audit, attrs) do
    audit
    |> changeset(attrs)
    |> WpPraxis.Repo.update()
  end

  @doc """
  Deletes an audit.
  """
  @spec delete(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def delete(audit) do
    WpPraxis.Repo.delete(audit)
  end

  @doc """
  Starts an audit by setting status to running and recording start time.
  """
  @spec start(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def start(audit) do
    update(audit, %{
      status: "running",
      started_at: NaiveDateTime.utc_now()
    })
  end

  @doc """
  Completes an audit with results.
  """
  @spec complete(t(), list(), list()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def complete(audit, deviations, recommendations \\ []) do
    now = NaiveDateTime.utc_now()
    duration = calculate_duration(audit.started_at, now)

    # Calculate severity based on deviations
    severity = determine_severity(deviations)

    # Count deviation types
    deviation_count = length(deviations)
    failed_checks = Enum.count(deviations, fn d -> d["status"] == "failed" end)
    passed_checks = Enum.count(deviations, fn d -> d["status"] == "passed" end)

    update(audit, %{
      status: "completed",
      completed_at: now,
      duration: duration,
      deviations: deviations,
      recommendations: recommendations,
      severity: severity,
      deviation_count: deviation_count,
      passed_checks: passed_checks,
      failed_checks: failed_checks
    })
  end

  @doc """
  Marks an audit as failed with error information.
  """
  @spec fail(t(), String.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def fail(audit, error_message) do
    now = NaiveDateTime.utc_now()
    duration = calculate_duration(audit.started_at, now)

    update(audit, %{
      status: "failed",
      completed_at: now,
      duration: duration,
      metadata: Map.put(audit.metadata, :error, error_message)
    })
  end

  @doc """
  Adds a deviation to an audit.
  """
  @spec add_deviation(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def add_deviation(audit, deviation) do
    updated_deviations = audit.deviations ++ [deviation]

    update(audit, %{
      deviations: updated_deviations,
      deviation_count: length(updated_deviations)
    })
  end

  # Calculate duration in seconds between two NaiveDateTime values
  defp calculate_duration(nil, _), do: nil
  defp calculate_duration(_, nil), do: nil

  defp calculate_duration(started_at, completed_at) do
    NaiveDateTime.diff(completed_at, started_at, :second)
  end

  # Determine overall severity based on deviations
  defp determine_severity([]), do: "info"

  defp determine_severity(deviations) do
    severities = Enum.map(deviations, fn d -> Map.get(d, "severity", "info") end)

    cond do
      "critical" in severities -> "critical"
      "error" in severities -> "error"
      "warning" in severities -> "warning"
      true -> "info"
    end
  end
end
