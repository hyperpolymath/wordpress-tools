# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

defmodule WpPraxis.Schema.SymbolTest do
  use WpPraxis.DataCase

  alias WpPraxis.Schema.Symbol

  describe "symbol creation" do
    test "creates a symbol with valid attributes" do
      attrs = %{
        name: "test_symbol",
        type: "action",
        context: "wordpress",
        dispatch_target: "php"
      }

      assert {:ok, symbol} = Symbol.create(attrs)
      assert symbol.name == "test_symbol"
      assert symbol.type == "action"
      assert symbol.context == "wordpress"
      assert symbol.dispatch_target == "php"
      assert symbol.status == "active"
      assert symbol.priority == 5
    end

    test "requires name" do
      attrs = %{
        type: "action",
        context: "wordpress",
        dispatch_target: "php"
      }

      assert {:error, changeset} = Symbol.create(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "requires unique name" do
      attrs = %{
        name: "duplicate_symbol",
        type: "action",
        context: "wordpress",
        dispatch_target: "php"
      }

      assert {:ok, _} = Symbol.create(attrs)
      assert {:error, changeset} = Symbol.create(attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "validates type inclusion" do
      attrs = %{
        name: "test_symbol",
        type: "invalid_type",
        context: "wordpress",
        dispatch_target: "php"
      }

      assert {:error, changeset} = Symbol.create(attrs)
      assert "is invalid" in errors_on(changeset).type
    end

    test "validates priority range" do
      attrs = %{
        name: "test_symbol",
        type: "action",
        context: "wordpress",
        dispatch_target: "php",
        priority: 11
      }

      assert {:error, changeset} = Symbol.create(attrs)
      assert "must be less than or equal to 10" in errors_on(changeset).priority
    end
  end

  describe "symbol updates" do
    test "updates a symbol with valid attributes" do
      {:ok, symbol} =
        Symbol.create(%{
          name: "test_symbol",
          type: "action",
          context: "wordpress",
          dispatch_target: "php"
        })

      assert {:ok, updated} = Symbol.update(symbol, %{priority: 8})
      assert updated.priority == 8
      assert updated.name == "test_symbol"
    end

    test "updates symbol status" do
      {:ok, symbol} =
        Symbol.create(%{
          name: "test_symbol",
          type: "action",
          context: "wordpress",
          dispatch_target: "php"
        })

      assert {:ok, updated} = Symbol.update(symbol, %{status: "inactive"})
      assert updated.status == "inactive"
    end
  end

  describe "symbol deletion" do
    test "deletes a symbol" do
      {:ok, symbol} =
        Symbol.create(%{
          name: "test_symbol",
          type: "action",
          context: "wordpress",
          dispatch_target: "php"
        })

      assert {:ok, _} = Symbol.delete(symbol)
      assert is_nil(Repo.get(Symbol, symbol.id))
    end
  end
end
