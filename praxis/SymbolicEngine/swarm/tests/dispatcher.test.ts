import { describe, test, expect, beforeEach, mock } from "bun:test";
import { Dispatcher } from "../src/dispatcher";
import { Symbol, SymbolType } from "../src/types";

describe("Dispatcher", () => {
  let dispatcher: Dispatcher;

  beforeEach(() => {
    dispatcher = new Dispatcher();
  });

  describe("Symbol Routing", () => {
    test("should route symbol to correct executor", () => {
      const symbol: Symbol = {
        name: "test_symbol",
        type: SymbolType.Action,
        context: "wordpress",
        dispatch: "rust_injector",
        parameters: {},
      };

      const route = dispatcher.getRoute(symbol);
      expect(route.executor).toBe("rust_injector");
      expect(route.valid).toBe(true);
    });

    test("should reject invalid executor", () => {
      const symbol: Symbol = {
        name: "invalid_symbol",
        type: SymbolType.Action,
        context: "test",
        dispatch: "nonexistent_executor",
        parameters: {},
      };

      const route = dispatcher.getRoute(symbol);
      expect(route.valid).toBe(false);
      expect(route.error).toContain("Unknown executor");
    });

    test("should handle multiple dispatch targets", () => {
      const symbols: Symbol[] = [
        {
          name: "symbol1",
          type: SymbolType.Action,
          context: "test",
          dispatch: "rust_injector",
          parameters: {},
        },
        {
          name: "symbol2",
          type: SymbolType.Query,
          context: "test",
          dispatch: "php_engine",
          parameters: {},
        },
      ];

      const routes = dispatcher.routeMany(symbols);
      expect(routes.rust_injector).toHaveLength(1);
      expect(routes.php_engine).toHaveLength(1);
    });
  });

  describe("Dispatch Execution", () => {
    test("should execute symbol dispatch", async () => {
      const symbol: Symbol = {
        name: "exec_test",
        type: SymbolType.Action,
        context: "test",
        dispatch: "mock_executor",
        parameters: { key: "value" },
      };

      const mockExecutor = mock(() => Promise.resolve({ success: true, data: "executed" }));
      dispatcher.registerExecutor("mock_executor", mockExecutor);

      const result = await dispatcher.dispatch(symbol);
      expect(result.success).toBe(true);
      expect(result.data).toBe("executed");
      expect(mockExecutor).toHaveBeenCalledTimes(1);
    });

    test("should handle dispatch failures", async () => {
      const symbol: Symbol = {
        name: "failing_symbol",
        type: SymbolType.Action,
        context: "test",
        dispatch: "failing_executor",
        parameters: {},
      };

      const failingExecutor = mock(() => Promise.reject(new Error("Execution failed")));
      dispatcher.registerExecutor("failing_executor", failingExecutor);

      await expect(dispatcher.dispatch(symbol)).rejects.toThrow("Execution failed");
    });

    test("should timeout long-running dispatches", async () => {
      const symbol: Symbol = {
        name: "slow_symbol",
        type: SymbolType.Action,
        context: "test",
        dispatch: "slow_executor",
        parameters: {},
        timeout: 100,
      };

      const slowExecutor = mock(() => new Promise((resolve) => setTimeout(resolve, 1000)));
      dispatcher.registerExecutor("slow_executor", slowExecutor);

      await expect(dispatcher.dispatch(symbol)).rejects.toThrow("timeout");
    });
  });

  describe("Batch Dispatching", () => {
    test("should batch dispatch multiple symbols", async () => {
      const symbols: Symbol[] = Array.from({ length: 5 }, (_, i) => ({
        name: `symbol_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "batch_executor",
        parameters: {},
      }));

      const mockExecutor = mock(() => Promise.resolve({ success: true }));
      dispatcher.registerExecutor("batch_executor", mockExecutor);

      const results = await dispatcher.dispatchBatch(symbols);
      expect(results).toHaveLength(5);
      expect(results.every((r) => r.success)).toBe(true);
      expect(mockExecutor).toHaveBeenCalledTimes(5);
    });

    test("should handle partial batch failures", async () => {
      const symbols: Symbol[] = [
        { name: "symbol1", type: SymbolType.Action, context: "test", dispatch: "executor", parameters: {} },
        { name: "symbol2", type: SymbolType.Action, context: "test", dispatch: "executor", parameters: {} },
        { name: "symbol3", type: SymbolType.Action, context: "test", dispatch: "executor", parameters: {} },
      ];

      let callCount = 0;
      const partialFailExecutor = mock(() => {
        callCount++;
        if (callCount === 2) {
          return Promise.reject(new Error("Failed"));
        }
        return Promise.resolve({ success: true });
      });

      dispatcher.registerExecutor("executor", partialFailExecutor);

      const results = await dispatcher.dispatchBatch(symbols, { failFast: false });
      expect(results[0].success).toBe(true);
      expect(results[1].success).toBe(false);
      expect(results[2].success).toBe(true);
    });

    test("should respect max concurrent dispatches", async () => {
      const symbols: Symbol[] = Array.from({ length: 10 }, (_, i) => ({
        name: `symbol_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "concurrent_executor",
        parameters: {},
      }));

      let concurrentCount = 0;
      let maxConcurrent = 0;

      const concurrentExecutor = mock(async () => {
        concurrentCount++;
        maxConcurrent = Math.max(maxConcurrent, concurrentCount);
        await new Promise((resolve) => setTimeout(resolve, 10));
        concurrentCount--;
        return { success: true };
      });

      dispatcher.registerExecutor("concurrent_executor", concurrentExecutor);
      dispatcher.setMaxConcurrent(3);

      await dispatcher.dispatchBatch(symbols);
      expect(maxConcurrent).toBeLessThanOrEqual(3);
    });
  });

  describe("Dispatcher Configuration", () => {
    test("should load configuration", () => {
      const config = {
        maxConcurrent: 10,
        timeout: 5000,
        retries: 3,
      };

      dispatcher.configure(config);
      expect(dispatcher.getConfig()).toEqual(config);
    });

    test("should validate configuration", () => {
      const invalidConfig = {
        maxConcurrent: -1,
        timeout: "invalid",
      };

      expect(() => dispatcher.configure(invalidConfig as any)).toThrow("Invalid configuration");
    });
  });

  describe("Event Handling", () => {
    test("should emit dispatch events", async () => {
      const events: string[] = [];

      dispatcher.on("dispatch:start", (symbol) => events.push(`start:${symbol.name}`));
      dispatcher.on("dispatch:complete", (symbol) => events.push(`complete:${symbol.name}`));

      const symbol: Symbol = {
        name: "event_test",
        type: SymbolType.Action,
        context: "test",
        dispatch: "event_executor",
        parameters: {},
      };

      const mockExecutor = mock(() => Promise.resolve({ success: true }));
      dispatcher.registerExecutor("event_executor", mockExecutor);

      await dispatcher.dispatch(symbol);

      expect(events).toContain("start:event_test");
      expect(events).toContain("complete:event_test");
    });

    test("should emit error events on failure", async () => {
      let errorCaught = false;

      dispatcher.on("dispatch:error", () => {
        errorCaught = true;
      });

      const symbol: Symbol = {
        name: "error_test",
        type: SymbolType.Action,
        context: "test",
        dispatch: "error_executor",
        parameters: {},
      };

      const errorExecutor = mock(() => Promise.reject(new Error("Test error")));
      dispatcher.registerExecutor("error_executor", errorExecutor);

      await expect(dispatcher.dispatch(symbol)).rejects.toThrow();
      expect(errorCaught).toBe(true);
    });
  });
});
