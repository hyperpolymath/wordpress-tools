# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Schema.Baseline do
  @moduledoc """
  Schema for Baseline entities in the WP Praxis symbolic system.

  Baselines represent normative states of the symbolic system that can be
  used for auditing and deviation detection. They capture expected
  configurations, states, and behaviors at a point in time.

  ## Fields

  - `name` - Unique baseline identifier
  - `description` - Human-readable description of the baseline's purpose
  - `symbolic_state` - JSON snapshot of the symbolic system state
  - `version` - Baseline version number for tracking changes
  - `is_active` - Whether this baseline is currently active for auditing
  - `created_by` - User or system that created the baseline
  - `metadata` - Additional baseline-specific metadata
  - `baseline_type` - Type of baseline (system, workflow, component, custom)
  - `scope` - Scope of the baseline (global, workflow-specific, symbol-specific)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          name: String.t(),
          description: String.t() | nil,
          symbolic_state: map(),
          version: String.t(),
          is_active: boolean(),
          created_by: String.t() | nil,
          metadata: map(),
          baseline_type: String.t(),
          scope: String.t(),
          inserted_at: NaiveDateTime.t() | nil,
          updated_at: NaiveDateTime.t() | nil
        }

  schema "baselines" do
    field :name, :string
    field :description, :string
    field :symbolic_state, :map, default: %{}
    field :version, :string, default: "1.0.0"
    field :is_active, :boolean, default: true
    field :created_by, :string
    field :metadata, :map, default: %{}
    field :baseline_type, :string, default: "system"
    field :scope, :string, default: "global"

    has_many :audits, WpPraxis.Schema.Audit

    timestamps()
  end

  @doc """
  Validates and creates a changeset for a baseline.

  ## Required Fields
  - name
  - symbolic_state

  ## Optional Fields
  - description
  - version (defaults to "1.0.0")
  - is_active (defaults to true)
  - created_by
  - metadata (defaults to empty map)
  - baseline_type (defaults to "system")
  - scope (defaults to "global")

  ## Validations
  - Name must be unique
  - Baseline type must be one of: system, workflow, component, custom
  - Scope must be one of: global, workflow, symbol, component
  - Version must follow semantic versioning pattern
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(baseline, attrs) do
    baseline
    |> cast(attrs, [
      :name,
      :description,
      :symbolic_state,
      :version,
      :is_active,
      :created_by,
      :metadata,
      :baseline_type,
      :scope
    ])
    |> validate_required([:name, :symbolic_state])
    |> validate_inclusion(:baseline_type, ["system", "workflow", "component", "custom"])
    |> validate_inclusion(:scope, ["global", "workflow", "symbol", "component"])
    |> validate_format(:version, ~r/^\d+\.\d+\.\d+$/, message: "must be semantic version (e.g., 1.0.0)")
    |> unique_constraint(:name)
  end

  @doc """
  Creates a new baseline with the given attributes.
  """
  @spec create(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> WpPraxis.Repo.insert()
  end

  @doc """
  Updates an existing baseline with the given attributes.
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def update(baseline, attrs) do
    baseline
    |> changeset(attrs)
    |> WpPraxis.Repo.update()
  end

  @doc """
  Deletes a baseline.
  """
  @spec delete(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def delete(baseline) do
    WpPraxis.Repo.delete(baseline)
  end

  @doc """
  Activates a baseline and optionally deactivates all other baselines of the same type.
  """
  @spec activate(t(), boolean()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def activate(baseline, deactivate_others \\ true) do
    import Ecto.Query

    WpPraxis.Repo.transaction(fn ->
      # Deactivate other baselines if requested
      if deactivate_others do
        from(b in __MODULE__,
          where: b.baseline_type == ^baseline.baseline_type and b.id != ^baseline.id
        )
        |> WpPraxis.Repo.update_all(set: [is_active: false])
      end

      # Activate this baseline
      case update(baseline, %{is_active: true}) do
        {:ok, updated} -> updated
        {:error, changeset} -> WpPraxis.Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Deactivates a baseline.
  """
  @spec deactivate(t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def deactivate(baseline) do
    update(baseline, %{is_active: false})
  end

  @doc """
  Creates a new version of an existing baseline.
  """
  @spec create_version(t(), map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create_version(baseline, updates) do
    new_version = increment_version(baseline.version)

    new_attrs =
      Map.merge(
        %{
          name: baseline.name,
          description: baseline.description,
          symbolic_state: baseline.symbolic_state,
          baseline_type: baseline.baseline_type,
          scope: baseline.scope,
          metadata: baseline.metadata,
          version: new_version,
          is_active: false
        },
        updates
      )

    create(new_attrs)
  end

  # Increment semantic version (e.g., "1.2.3" -> "1.2.4")
  defp increment_version(version) do
    case String.split(version, ".") do
      [major, minor, patch] ->
        new_patch = String.to_integer(patch) + 1
        "#{major}.#{minor}.#{new_patch}"

      _ ->
        "1.0.0"
    end
  end
end
