# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Repo.Migrations.CreateAudits do
  use Ecto.Migration

  def change do
    create table(:audits) do
      add :baseline_id, references(:baselines, on_delete: :restrict), null: false
      add :workflow_id, references(:workflows, on_delete: :nilify_all)
      add :audit_type, :string, null: false, default: "manual"
      add :status, :string, null: false, default: "pending"
      add :deviations, {:array, :map}, null: false, default: []
      add :severity, :string, null: false, default: "info"
      add :deviation_count, :integer, null: false, default: 0
      add :passed_checks, :integer, null: false, default: 0
      add :failed_checks, :integer, null: false, default: 0
      add :recommendations, {:array, :map}, null: false, default: []
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :duration, :integer
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    # Foreign key indexes
    create index(:audits, [:baseline_id])
    create index(:audits, [:workflow_id])

    # Status and type indexes
    create index(:audits, [:status])
    create index(:audits, [:audit_type])
    create index(:audits, [:severity])

    # Timing indexes
    create index(:audits, [:started_at])
    create index(:audits, [:completed_at])
    create index(:audits, [:inserted_at])

    # Composite indexes for common queries
    create index(:audits, [:baseline_id, :status])
    create index(:audits, [:baseline_id, :inserted_at])
    create index(:audits, [:workflow_id, :status])
    create index(:audits, [:severity, :inserted_at])
    create index(:audits, [:audit_type, :status])

    # Partial indexes for specific query patterns
    create index(:audits, [:id], where: "status IN ('pending', 'running')")
    create index(:audits, [:id], where: "severity IN ('error', 'critical')")
    create index(:audits, [:id], where: "deviation_count > 0")

    # Index for recent failed audits
    create index(:audits, [:baseline_id, :inserted_at],
             where: "status = 'failed' OR severity IN ('error', 'critical')"
           )
  end
end
