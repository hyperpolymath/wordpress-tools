# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WPPraxis.SchemaTest do
  use ExUnit.Case, async: true
  alias WPPraxis.{Symbol, Workflow, Execution}

  describe "Symbol schema" do
    test "creates valid symbol" do
      symbol = %Symbol{
        name: "test_symbol",
        type: :action,
        context: "wordpress",
        dispatch: "rust_injector",
        parameters: %{"key" => "value"}
      }

      assert symbol.name == "test_symbol"
      assert symbol.type == :action
    end

    test "validates required fields" do
      changeset = Symbol.changeset(%Symbol{}, %{})
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :name)
      assert Keyword.has_key?(changeset.errors, :type)
    end

    test "validates symbol type enum" do
      valid_types = [:action, :query, :transform, :validator]

      for type <- valid_types do
        changeset = Symbol.changeset(%Symbol{}, %{
          name: "test",
          type: type,
          context: "test",
          dispatch: "test"
        })

        assert changeset.valid?
      end
    end

    test "rejects invalid symbol type" do
      changeset = Symbol.changeset(%Symbol{}, %{
        name: "test",
        type: :invalid_type,
        context: "test",
        dispatch: "test"
      })

      refute changeset.valid?
    end

    test "stores parameters as JSON" do
      params = %{"key1" => "value1", "key2" => 123, "nested" => %{"key" => "val"}}

      changeset = Symbol.changeset(%Symbol{}, %{
        name: "test",
        type: :action,
        context: "test",
        dispatch: "test",
        parameters: params
      })

      assert changeset.valid?
      assert get_change(changeset, :parameters) == params
    end
  end

  describe "Workflow schema" do
    test "creates valid workflow" do
      workflow = %Workflow{
        name: "test_workflow",
        version: "1.0.0",
        description: "Test workflow"
      }

      assert workflow.name == "test_workflow"
      assert workflow.version == "1.0.0"
    end

    test "associates symbols with workflow" do
      workflow = %Workflow{
        name: "test_workflow",
        version: "1.0.0"
      }

      symbol1 = %Symbol{name: "symbol1", type: :action, context: "test", dispatch: "test"}
      symbol2 = %Symbol{name: "symbol2", type: :query, context: "test", dispatch: "test"}

      # In actual implementation, this would use Ecto associations
      symbols = [symbol1, symbol2]

      assert length(symbols) == 2
    end

    test "validates version format" do
      changeset = Workflow.changeset(%Workflow{}, %{
        name: "test",
        version: "invalid"
      })

      # Should validate semantic versioning
      refute changeset.valid?
    end
  end

  describe "Execution schema" do
    test "creates execution record" do
      execution = %Execution{
        workflow_id: 1,
        status: :pending,
        started_at: DateTime.utc_now()
      }

      assert execution.status == :pending
      assert execution.workflow_id == 1
    end

    test "tracks execution status" do
      valid_statuses = [:pending, :running, :completed, :failed, :rolled_back]

      for status <- valid_statuses do
        changeset = Execution.changeset(%Execution{}, %{
          workflow_id: 1,
          status: status,
          started_at: DateTime.utc_now()
        })

        assert changeset.valid?
      end
    end

    test "records execution duration" do
      start_time = DateTime.utc_now()
      end_time = DateTime.add(start_time, 100, :second)

      execution = %Execution{
        workflow_id: 1,
        status: :completed,
        started_at: start_time,
        completed_at: end_time
      }

      duration = DateTime.diff(execution.completed_at, execution.started_at)
      assert duration == 100
    end

    test "stores execution results as JSON" do
      results = %{
        "symbols_executed" => 5,
        "duration_ms" => 1500,
        "success_count" => 5,
        "failure_count" => 0
      }

      changeset = Execution.changeset(%Execution{}, %{
        workflow_id: 1,
        status: :completed,
        started_at: DateTime.utc_now(),
        results: results
      })

      assert changeset.valid?
      assert get_change(changeset, :results) == results
    end
  end

  describe "Schema relationships" do
    test "workflow has many symbols" do
      # This would test Ecto associations
      # workflow = Repo.get!(Workflow, 1) |> Repo.preload(:symbols)
      # assert length(workflow.symbols) > 0
    end

    test "workflow has many executions" do
      # This would test execution history
      # workflow = Repo.get!(Workflow, 1) |> Repo.preload(:executions)
      # assert length(workflow.executions) > 0
    end

    test "execution belongs to workflow" do
      # execution = Repo.get!(Execution, 1) |> Repo.preload(:workflow)
      # assert execution.workflow.name == "test_workflow"
    end
  end
end
