# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Queries.WorkflowQueries do
  @moduledoc """
  Common query functions for Workflow entities.

  Provides optimized queries for workflow execution tracking,
  history, and performance analysis.
  """

  import Ecto.Query
  alias WpPraxis.Repo
  alias WpPraxis.Schema.Workflow

  @doc """
  Get all active workflows (pending or running).
  """
  @spec active_workflows() :: [Workflow.t()]
  def active_workflows do
    from(w in Workflow,
      where: w.status in ["pending", "running"],
      order_by: [desc: w.started_at, asc: w.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get workflows by status.
  """
  @spec by_status(String.t()) :: [Workflow.t()]
  def by_status(status) do
    from(w in Workflow,
      where: w.status == ^status,
      order_by: [desc: w.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get completed workflows.
  """
  @spec completed_workflows() :: [Workflow.t()]
  def completed_workflows do
    from(w in Workflow,
      where: w.status in ["completed", "failed"],
      order_by: [desc: w.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Get recently completed workflows within the last N hours.
  """
  @spec recently_completed(integer()) :: [Workflow.t()]
  def recently_completed(hours \\ 24) do
    cutoff = NaiveDateTime.utc_now() |> NaiveDateTime.add(-hours * 3600, :second)

    from(w in Workflow,
      where: w.status in ["completed", "failed"] and w.completed_at >= ^cutoff,
      order_by: [desc: w.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Get failed workflows.
  """
  @spec failed_workflows() :: [Workflow.t()]
  def failed_workflows do
    from(w in Workflow,
      where: w.status == "failed",
      order_by: [desc: w.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Find a workflow by name.
  """
  @spec find_by_name(String.t()) :: Workflow.t() | nil
  def find_by_name(name) do
    Repo.get_by(Workflow, name: name)
  end

  @doc """
  Find a workflow by name, raising if not found.
  """
  @spec find_by_name!(String.t()) :: Workflow.t()
  def find_by_name!(name) do
    Repo.get_by!(Workflow, name: name)
  end

  @doc """
  Get workflows by manifest path.
  """
  @spec by_manifest_path(String.t()) :: [Workflow.t()]
  def by_manifest_path(manifest_path) do
    from(w in Workflow,
      where: w.manifest_path == ^manifest_path,
      order_by: [desc: w.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get workflow execution history (completed workflows ordered by completion time).
  """
  @spec execution_history(integer()) :: [Workflow.t()]
  def execution_history(limit \\ 100) do
    from(w in Workflow,
      where: w.status in ["completed", "failed"],
      order_by: [desc: w.completed_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Get workflows with their executions (preload association).
  """
  @spec with_executions([integer()]) :: [Workflow.t()]
  def with_executions(workflow_ids) do
    from(w in Workflow,
      where: w.id in ^workflow_ids,
      preload: [:executions]
    )
    |> Repo.all()
  end

  @doc """
  Get workflows with their audits (preload association).
  """
  @spec with_audits([integer()]) :: [Workflow.t()]
  def with_audits(workflow_ids) do
    from(w in Workflow,
      where: w.id in ^workflow_ids,
      preload: [:audits]
    )
    |> Repo.all()
  end

  @doc """
  Get long-running workflows (duration > threshold in seconds).
  """
  @spec long_running(integer()) :: [Workflow.t()]
  def long_running(threshold_seconds \\ 3600) do
    from(w in Workflow,
      where: w.status in ["completed", "failed"] and w.duration > ^threshold_seconds,
      order_by: [desc: w.duration]
    )
    |> Repo.all()
  end

  @doc """
  Get currently running workflows.
  """
  @spec running_workflows() :: [Workflow.t()]
  def running_workflows do
    from(w in Workflow,
      where: w.status == "running",
      order_by: [asc: w.started_at]
    )
    |> Repo.all()
  end

  @doc """
  Search workflows by name pattern.
  """
  @spec search_by_name(String.t()) :: [Workflow.t()]
  def search_by_name(pattern) do
    like_pattern = "%#{pattern}%"

    from(w in Workflow,
      where: ilike(w.name, ^like_pattern),
      order_by: [desc: w.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Count workflows by status.
  """
  @spec count_by_status(String.t()) :: integer()
  def count_by_status(status) do
    from(w in Workflow, where: w.status == ^status, select: count(w.id))
    |> Repo.one()
  end

  @doc """
  Get workflow statistics.
  """
  @spec workflow_stats() :: %{
          total: integer(),
          pending: integer(),
          running: integer(),
          completed: integer(),
          failed: integer(),
          paused: integer()
        }
  def workflow_stats do
    stats =
      from(w in Workflow,
        group_by: w.status,
        select: {w.status, count(w.id)}
      )
      |> Repo.all()
      |> Map.new()

    %{
      total: Repo.aggregate(Workflow, :count, :id),
      pending: Map.get(stats, "pending", 0),
      running: Map.get(stats, "running", 0),
      completed: Map.get(stats, "completed", 0),
      failed: Map.get(stats, "failed", 0),
      paused: Map.get(stats, "paused", 0)
    }
  end

  @doc """
  Get average workflow duration by status.
  """
  @spec average_duration_by_status() :: [%{status: String.t(), avg_duration: float()}]
  def average_duration_by_status do
    from(w in Workflow,
      where: not is_nil(w.duration),
      group_by: w.status,
      select: %{status: w.status, avg_duration: avg(w.duration)},
      order_by: [desc: avg(w.duration)]
    )
    |> Repo.all()
  end

  @doc """
  Get workflows started within a date range.
  """
  @spec started_between(NaiveDateTime.t(), NaiveDateTime.t()) :: [Workflow.t()]
  def started_between(start_date, end_date) do
    from(w in Workflow,
      where:
        not is_nil(w.started_at) and w.started_at >= ^start_date and w.started_at <= ^end_date,
      order_by: [desc: w.started_at]
    )
    |> Repo.all()
  end

  @doc """
  Get workflows completed within a date range.
  """
  @spec completed_between(NaiveDateTime.t(), NaiveDateTime.t()) :: [Workflow.t()]
  def completed_between(start_date, end_date) do
    from(w in Workflow,
      where:
        not is_nil(w.completed_at) and w.completed_at >= ^start_date and
          w.completed_at <= ^end_date,
      order_by: [desc: w.completed_at]
    )
    |> Repo.all()
  end

  @doc """
  Get paused workflows.
  """
  @spec paused_workflows() :: [Workflow.t()]
  def paused_workflows do
    from(w in Workflow,
      where: w.status == "paused",
      order_by: [desc: w.updated_at]
    )
    |> Repo.all()
  end

  @doc """
  Get workflows that have never been started.
  """
  @spec never_started() :: [Workflow.t()]
  def never_started do
    from(w in Workflow,
      where: is_nil(w.started_at),
      order_by: [asc: w.inserted_at]
    )
    |> Repo.all()
  end
end
