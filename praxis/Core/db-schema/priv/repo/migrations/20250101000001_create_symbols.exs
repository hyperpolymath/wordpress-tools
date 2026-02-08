# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Repo.Migrations.CreateSymbols do
  use Ecto.Migration

  def change do
    create table(:symbols) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :context, :string, null: false
      add :status, :string, null: false, default: "active"
      add :dispatch_target, :string, null: false
      add :parameters, :map, null: false, default: %{}
      add :description, :text
      add :priority, :integer, null: false, default: 5
      add :timeout, :integer, null: false, default: 300
      add :retry_count, :integer, null: false, default: 0

      timestamps()
    end

    # Indexes for performance
    create unique_index(:symbols, [:name])
    create index(:symbols, [:type])
    create index(:symbols, [:context])
    create index(:symbols, [:status])
    create index(:symbols, [:dispatch_target])
    create index(:symbols, [:priority])

    # Composite indexes for common queries
    create index(:symbols, [:type, :context])
    create index(:symbols, [:status, :type])
    create index(:symbols, [:context, :status])
  end
end
