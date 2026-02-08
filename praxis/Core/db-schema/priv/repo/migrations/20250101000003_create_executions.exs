# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Repo.Migrations.CreateExecutions do
  use Ecto.Migration

  def change do
    create table(:executions) do
      add :workflow_id, references(:workflows, on_delete: :delete_all), null: false
      add :symbol_id, references(:symbols, on_delete: :restrict), null: false
      add :status, :string, null: false, default: "pending"
      add :started_at, :naive_datetime
      add :completed_at, :naive_datetime
      add :duration, :integer
      add :output, :map, null: false, default: %{}
      add :error_log, :text
      add :rollback_state, :map, null: false, default: %{}
      add :retry_attempt, :integer, null: false, default: 0
      add :exit_code, :integer
      add :metadata, :map, null: false, default: %{}

      timestamps()
    end

    # Foreign key indexes
    create index(:executions, [:workflow_id])
    create index(:executions, [:symbol_id])

    # Status and timing indexes
    create index(:executions, [:status])
    create index(:executions, [:started_at])
    create index(:executions, [:completed_at])
    create index(:executions, [:retry_attempt])

    # Composite indexes for common queries
    create index(:executions, [:workflow_id, :status])
    create index(:executions, [:workflow_id, :started_at])
    create index(:executions, [:symbol_id, :status])
    create index(:executions, [:status, :started_at])

    # Partial index for active executions
    create index(:executions, [:id], where: "status IN ('pending', 'running', 'retrying')")

    # Index for failed executions that might need retry
    create index(:executions, [:id], where: "status = 'failed' AND retry_attempt < 3")
  end
end
