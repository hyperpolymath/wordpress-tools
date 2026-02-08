# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows) do
      add :name, :string, null: false
      add :description, :text
      add :manifest_path, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :execution_log, {:array, :map}, null: false, default: []
      add :metadata, :map, null: false, default: %{}
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :duration, :integer

      timestamps()
    end

    # Indexes for performance
    create unique_index(:workflows, [:name])
    create index(:workflows, [:status])
    create index(:workflows, [:manifest_path])
    create index(:workflows, [:started_at])
    create index(:workflows, [:completed_at])

    # Composite indexes for common queries
    create index(:workflows, [:status, :started_at])
    create index(:workflows, [:status, :completed_at])

    # Partial index for active workflows
    create index(:workflows, [:id], where: "status IN ('pending', 'running')")
  end
end
