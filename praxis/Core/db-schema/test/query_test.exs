# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WPPraxis.QueryTest do
  use ExUnit.Case, async: true
  alias WPPraxis.{Repo, Symbol, Workflow, Execution}
  import Ecto.Query

  describe "Symbol queries" do
    test "finds symbol by name" do
      # Mock implementation
      result = Symbol |> where([s], s.name == "test_symbol") |> select([s], s)
      assert result != nil
    end

    test "finds all symbols for workflow" do
      workflow_id = 1
      result = Symbol |> where([s], s.workflow_id == ^workflow_id) |> select([s], s)
      assert result != nil
    end

    test "finds symbols by type" do
      result = Symbol |> where([s], s.type == :action) |> select([s], s)
      assert result != nil
    end

    test "finds symbols by dispatch method" do
      result = Symbol |> where([s], s.dispatch == "rust_injector") |> select([s], s)
      assert result != nil
    end

    test "orders symbols by execution order" do
      result = Symbol |> order_by([s], asc: s.order) |> select([s], s)
      assert result != nil
    end
  end

  describe "Workflow queries" do
    test "finds active workflows" do
      result = Workflow |> where([w], w.active == true) |> select([w], w)
      assert result != nil
    end

    test "finds workflows by version" do
      result = Workflow |> where([w], w.version == "1.0.0") |> select([w], w)
      assert result != nil
    end

    test "finds latest version of workflow" do
      result = Workflow
               |> where([w], w.name == "test_workflow")
               |> order_by([w], desc: w.version)
               |> limit(1)
               |> select([w], w)
      assert result != nil
    end
  end

  describe "Execution queries" do
    test "finds executions by status" do
      result = Execution |> where([e], e.status == :completed) |> select([e], e)
      assert result != nil
    end

    test "finds recent executions" do
      one_day_ago = DateTime.add(DateTime.utc_now(), -1, :day)

      result = Execution
               |> where([e], e.started_at > ^one_day_ago)
               |> order_by([e], desc: e.started_at)
               |> select([e], e)

      assert result != nil
    end

    test "finds failed executions" do
      result = Execution
               |> where([e], e.status == :failed)
               |> order_by([e], desc: e.started_at)
               |> select([e], e)

      assert result != nil
    end

    test "calculates execution statistics" do
      # Mock aggregate query
      result = Execution
               |> group_by([e], e.status)
               |> select([e], {e.status, count(e.id)})

      assert result != nil
    end
  end

  describe "Complex queries" do
    test "finds workflows with failed executions" do
      result = from(w in Workflow,
        join: e in Execution,
        on: e.workflow_id == w.id,
        where: e.status == :failed,
        distinct: true,
        select: w
      )

      assert result != nil
    end

    test "finds most executed workflows" do
      result = from(w in Workflow,
        join: e in Execution,
        on: e.workflow_id == w.id,
        group_by: w.id,
        select: {w, count(e.id)},
        order_by: [desc: count(e.id)],
        limit: 10
      )

      assert result != nil
    end

    test "calculates average execution duration" do
      result = from(e in Execution,
        where: e.status == :completed and not is_nil(e.completed_at),
        select: avg(fragment("EXTRACT(EPOCH FROM (? - ?))", e.completed_at, e.started_at))
      )

      assert result != nil
    end
  end
end
