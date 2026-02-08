# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Queries.SymbolQueries do
  @moduledoc """
  Common query functions for Symbol entities.

  Provides optimized queries for frequently accessed symbol data
  and patterns used throughout the WP Praxis system.
  """

  import Ecto.Query
  alias WpPraxis.Repo
  alias WpPraxis.Schema.Symbol

  @doc """
  Get all active symbols.
  """
  @spec active_symbols() :: [Symbol.t()]
  def active_symbols do
    from(s in Symbol, where: s.status == "active", order_by: [desc: s.priority])
    |> Repo.all()
  end

  @doc """
  Get symbols by type.
  """
  @spec by_type(String.t()) :: [Symbol.t()]
  def by_type(type) do
    from(s in Symbol, where: s.type == ^type, order_by: [asc: s.name])
    |> Repo.all()
  end

  @doc """
  Get symbols by context.
  """
  @spec by_context(String.t()) :: [Symbol.t()]
  def by_context(context) do
    from(s in Symbol, where: s.context == ^context, order_by: [desc: s.priority])
    |> Repo.all()
  end

  @doc """
  Get symbols by dispatch target.
  """
  @spec by_dispatch_target(String.t()) :: [Symbol.t()]
  def by_dispatch_target(dispatch_target) do
    from(s in Symbol, where: s.dispatch_target == ^dispatch_target, order_by: [asc: s.name])
    |> Repo.all()
  end

  @doc """
  Get symbols by type and context (common query pattern).
  """
  @spec by_type_and_context(String.t(), String.t()) :: [Symbol.t()]
  def by_type_and_context(type, context) do
    from(s in Symbol,
      where: s.type == ^type and s.context == ^context,
      order_by: [desc: s.priority]
    )
    |> Repo.all()
  end

  @doc """
  Get symbols by status and type.
  """
  @spec by_status_and_type(String.t(), String.t()) :: [Symbol.t()]
  def by_status_and_type(status, type) do
    from(s in Symbol,
      where: s.status == ^status and s.type == ^type,
      order_by: [desc: s.priority, asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  Find a symbol by name.
  """
  @spec find_by_name(String.t()) :: Symbol.t() | nil
  def find_by_name(name) do
    Repo.get_by(Symbol, name: name)
  end

  @doc """
  Find a symbol by name, raising if not found.
  """
  @spec find_by_name!(String.t()) :: Symbol.t()
  def find_by_name!(name) do
    Repo.get_by!(Symbol, name: name)
  end

  @doc """
  Get high priority symbols (priority >= 7).
  """
  @spec high_priority_symbols() :: [Symbol.t()]
  def high_priority_symbols do
    from(s in Symbol,
      where: s.priority >= 7 and s.status == "active",
      order_by: [desc: s.priority, asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  Search symbols by name pattern.
  """
  @spec search_by_name(String.t()) :: [Symbol.t()]
  def search_by_name(pattern) do
    like_pattern = "%#{pattern}%"

    from(s in Symbol,
      where: ilike(s.name, ^like_pattern),
      order_by: [asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  Count symbols by status.
  """
  @spec count_by_status(String.t()) :: integer()
  def count_by_status(status) do
    from(s in Symbol, where: s.status == ^status, select: count(s.id))
    |> Repo.one()
  end

  @doc """
  Get symbols with executions (preload association).
  """
  @spec with_executions([integer()]) :: [Symbol.t()]
  def with_executions(symbol_ids) do
    from(s in Symbol,
      where: s.id in ^symbol_ids,
      preload: [:executions]
    )
    |> Repo.all()
  end

  @doc """
  Get recently updated symbols within the last N hours.
  """
  @spec recently_updated(integer()) :: [Symbol.t()]
  def recently_updated(hours \\ 24) do
    cutoff = NaiveDateTime.utc_now() |> NaiveDateTime.add(-hours * 3600, :second)

    from(s in Symbol,
      where: s.updated_at >= ^cutoff,
      order_by: [desc: s.updated_at]
    )
    |> Repo.all()
  end

  @doc """
  Get symbols that have never been executed.
  """
  @spec never_executed() :: [Symbol.t()]
  def never_executed do
    from(s in Symbol,
      left_join: e in assoc(s, :executions),
      where: is_nil(e.id),
      order_by: [asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  Get symbols that support retry (retry_count > 0).
  """
  @spec retriable_symbols() :: [Symbol.t()]
  def retriable_symbols do
    from(s in Symbol,
      where: s.retry_count > 0 and s.status == "active",
      order_by: [desc: s.priority]
    )
    |> Repo.all()
  end

  @doc """
  Get all unique symbol types in the system.
  """
  @spec all_types() :: [String.t()]
  def all_types do
    from(s in Symbol, distinct: true, select: s.type, order_by: [asc: s.type])
    |> Repo.all()
  end

  @doc """
  Get all unique contexts in the system.
  """
  @spec all_contexts() :: [String.t()]
  def all_contexts do
    from(s in Symbol, distinct: true, select: s.context, order_by: [asc: s.context])
    |> Repo.all()
  end

  @doc """
  Get symbol statistics grouped by type.
  """
  @spec stats_by_type() :: [%{type: String.t(), count: integer()}]
  def stats_by_type do
    from(s in Symbol,
      group_by: s.type,
      select: %{type: s.type, count: count(s.id)},
      order_by: [desc: count(s.id)]
    )
    |> Repo.all()
  end
end
