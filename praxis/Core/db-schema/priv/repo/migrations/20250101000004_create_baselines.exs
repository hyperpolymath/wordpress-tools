# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Repo.Migrations.CreateBaselines do
  use Ecto.Migration

  def change do
    create table(:baselines) do
      add :name, :string, null: false
      add :description, :text
      add :symbolic_state, :map, null: false, default: %{}
      add :version, :string, null: false, default: "1.0.0"
      add :is_active, :boolean, null: false, default: true
      add :created_by, :string
      add :metadata, :map, null: false, default: %{}
      add :baseline_type, :string, null: false, default: "system"
      add :scope, :string, null: false, default: "global"

      timestamps()
    end

    # Indexes for performance
    create unique_index(:baselines, [:name])
    create index(:baselines, [:is_active])
    create index(:baselines, [:baseline_type])
    create index(:baselines, [:scope])
    create index(:baselines, [:version])
    create index(:baselines, [:created_by])

    # Composite indexes for common queries
    create index(:baselines, [:baseline_type, :is_active])
    create index(:baselines, [:scope, :is_active])
    create index(:baselines, [:baseline_type, :scope])

    # Partial index for active baselines
    create index(:baselines, [:id], where: "is_active = true")

    # Index for baseline versioning queries
    create index(:baselines, [:name, :version])
  end
end
