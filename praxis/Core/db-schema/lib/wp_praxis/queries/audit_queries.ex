# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Queries.AuditQueries do
  @moduledoc """
  Common query functions for Audit entities.

  Provides optimized queries for audit tracking, deviation analysis,
  and compliance reporting.
  """

  import Ecto.Query
  alias WpPraxis.Repo
  alias WpPraxis.Schema.Audit

  @doc """
  Get recent audits within the last N hours.
  """
  @spec recent_audits(integer()) :: [Audit.t()]
  def recent_audits(hours \\ 24) do
    cutoff = NaiveDateTime.utc_now() |> NaiveDateTime.add(-hours * 3600, :second)

    from(a in Audit,
      where: a.inserted_at >= ^cutoff,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits by baseline ID.
  """
  @spec by_baseline(integer()) :: [Audit.t()]
  def by_baseline(baseline_id) do
    from(a in Audit,
      where: a.baseline_id == ^baseline_id,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits by workflow ID.
  """
  @spec by_workflow(integer()) :: [Audit.t()]
  def by_workflow(workflow_id) do
    from(a in Audit,
      where: a.workflow_id == ^workflow_id,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits by status.
  """
  @spec by_status(String.t()) :: [Audit.t()]
  def by_status(status) do
    from(a in Audit,
      where: a.status == ^status,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits by severity.
  """
  @spec by_severity(String.t()) :: [Audit.t()]
  def by_severity(severity) do
    from(a in Audit,
      where: a.severity == ^severity,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits with deviations (deviation_count > 0).
  """
  @spec with_deviations() :: [Audit.t()]
  def with_deviations do
    from(a in Audit,
      where: a.deviation_count > 0,
      order_by: [desc: a.deviation_count, desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get critical and error severity audits.
  """
  @spec critical_audits() :: [Audit.t()]
  def critical_audits do
    from(a in Audit,
      where: a.severity in ["critical", "error"],
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get completed audits.
  """
  @spec completed_audits() :: [Audit.t()]
  def completed_audits do
    from(a in Audit,
      where: a.status == "completed",
      order_by: [desc: a.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Get failed audits.
  """
  @spec failed_audits() :: [Audit.t()]
  def failed_audits do
    from(a in Audit,
      where: a.status == "failed",
      order_by: [desc: a.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Get running audits.
  """
  @spec running_audits() :: [Audit.t()]
  def running_audits do
    from(a in Audit,
      where: a.status in ["pending", "running"],
      order_by: [asc: a.started_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits with baseline preloaded.
  """
  @spec with_baseline([integer()]) :: [Audit.t()]
  def with_baseline(audit_ids) do
    from(a in Audit,
      where: a.id in ^audit_ids,
      preload: [:baseline]
    )
    |> Repo.all()
  end

  @doc """
  Get audits with workflow preloaded.
  """
  @spec with_workflow([integer()]) :: [Audit.t()]
  def with_workflow(audit_ids) do
    from(a in Audit,
      where: a.id in ^audit_ids,
      preload: [:workflow]
    )
    |> Repo.all()
  end

  @doc """
  Get audit statistics.
  """
  @spec audit_stats() :: %{
          total: integer(),
          pending: integer(),
          running: integer(),
          completed: integer(),
          failed: integer(),
          with_deviations: integer(),
          critical: integer()
        }
  def audit_stats do
    total = Repo.aggregate(Audit, :count, :id)

    status_stats =
      from(a in Audit,
        group_by: a.status,
        select: {a.status, count(a.id)}
      )
      |> Repo.all()
      |> Map.new()

    with_deviations =
      from(a in Audit, where: a.deviation_count > 0, select: count(a.id))
      |> Repo.one()

    critical =
      from(a in Audit, where: a.severity in ["critical", "error"], select: count(a.id))
      |> Repo.one()

    %{
      total: total,
      pending: Map.get(status_stats, "pending", 0),
      running: Map.get(status_stats, "running", 0),
      completed: Map.get(status_stats, "completed", 0),
      failed: Map.get(status_stats, "failed", 0),
      with_deviations: with_deviations,
      critical: critical
    }
  end

  @doc """
  Get audits by audit type.
  """
  @spec by_audit_type(String.t()) :: [Audit.t()]
  def by_audit_type(audit_type) do
    from(a in Audit,
      where: a.audit_type == ^audit_type,
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get average audit duration by baseline.
  """
  @spec average_duration_by_baseline() :: [%{baseline_id: integer(), avg_duration: float()}]
  def average_duration_by_baseline do
    from(a in Audit,
      where: not is_nil(a.duration),
      group_by: a.baseline_id,
      select: %{baseline_id: a.baseline_id, avg_duration: avg(a.duration)},
      order_by: [desc: avg(a.duration)]
    )
    |> Repo.all()
  end

  @doc """
  Get audits with high deviation counts (threshold).
  """
  @spec high_deviation_audits(integer()) :: [Audit.t()]
  def high_deviation_audits(threshold \\ 10) do
    from(a in Audit,
      where: a.deviation_count >= ^threshold,
      order_by: [desc: a.deviation_count, desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get count of audits by severity.
  """
  @spec count_by_severity() :: [%{severity: String.t(), count: integer()}]
  def count_by_severity do
    from(a in Audit,
      group_by: a.severity,
      select: %{severity: a.severity, count: count(a.id)},
      order_by: [desc: count(a.id)]
    )
    |> Repo.all()
  end

  @doc """
  Get latest audit for a baseline.
  """
  @spec latest_for_baseline(integer()) :: Audit.t() | nil
  def latest_for_baseline(baseline_id) do
    from(a in Audit,
      where: a.baseline_id == ^baseline_id,
      order_by: [desc: a.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Get audits started within a date range.
  """
  @spec started_between(NaiveDateTime.t(), NaiveDateTime.t()) :: [Audit.t()]
  def started_between(start_date, end_date) do
    from(a in Audit,
      where:
        not is_nil(a.started_at) and a.started_at >= ^start_date and a.started_at <= ^end_date,
      order_by: [desc: a.started_at]
    )
    |> Repo.all()
  end

  @doc """
  Get audits completed within a date range.
  """
  @spec completed_between(NaiveDateTime.t(), NaiveDateTime.t()) :: [Audit.t()]
  def completed_between(start_date, end_date) do
    from(a in Audit,
      where:
        not is_nil(a.completed_at) and a.completed_at >= ^start_date and
          a.completed_at <= ^end_date,
      order_by: [desc: a.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Get deviation trends over time for a baseline.
  Returns audits grouped by day with deviation counts.
  """
  @spec deviation_trends(integer(), integer()) :: [%{date: Date.t(), deviation_count: integer()}]
  def deviation_trends(baseline_id, days_back \\ 30) do
    cutoff = NaiveDateTime.utc_now() |> NaiveDateTime.add(-days_back * 86400, :second)

    from(a in Audit,
      where: a.baseline_id == ^baseline_id and a.inserted_at >= ^cutoff,
      select: %{
        date: fragment("DATE(?)", a.inserted_at),
        deviation_count: sum(a.deviation_count)
      },
      group_by: fragment("DATE(?)", a.inserted_at),
      order_by: [asc: fragment("DATE(?)", a.inserted_at)]
    )
    |> Repo.all()
  end

  @doc """
  Get scheduled audits.
  """
  @spec scheduled_audits() :: [Audit.t()]
  def scheduled_audits do
    from(a in Audit,
      where: a.audit_type == "scheduled",
      order_by: [desc: a.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Count audits by baseline.
  """
  @spec count_by_baseline(integer()) :: integer()
  def count_by_baseline(baseline_id) do
    from(a in Audit, where: a.baseline_id == ^baseline_id, select: count(a.id))
    |> Repo.one()
  end
end
