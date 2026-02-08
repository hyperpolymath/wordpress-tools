import { describe, test, expect, beforeEach, mock } from "bun:test";
import { Worker } from "../src/worker";
import { Symbol, SymbolType } from "../src/types";

describe("Worker", () => {
  let worker: Worker;

  beforeEach(() => {
    worker = new Worker({ id: "worker-1", maxTasks: 5 });
  });

  describe("Worker Lifecycle", () => {
    test("should initialize worker", () => {
      expect(worker.getId()).toBe("worker-1");
      expect(worker.getStatus()).toBe("idle");
    });

    test("should start worker", async () => {
      await worker.start();
      expect(worker.getStatus()).toBe("running");
    });

    test("should stop worker", async () => {
      await worker.start();
      await worker.stop();
      expect(worker.getStatus()).toBe("stopped");
    });

    test("should pause and resume worker", async () => {
      await worker.start();
      await worker.pause();
      expect(worker.getStatus()).toBe("paused");

      await worker.resume();
      expect(worker.getStatus()).toBe("running");
    });
  });

  describe("Task Execution", () => {
    test("should execute assigned symbol", async () => {
      const symbol: Symbol = {
        name: "worker_task",
        type: SymbolType.Action,
        context: "test",
        dispatch: "worker_executor",
        parameters: {},
      };

      await worker.start();
      const result = await worker.execute(symbol);

      expect(result.success).toBe(true);
      expect(result.workerId).toBe("worker-1");
    });

    test("should reject task when stopped", async () => {
      const symbol: Symbol = {
        name: "rejected_task",
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      };

      await expect(worker.execute(symbol)).rejects.toThrow("Worker not running");
    });

    test("should track concurrent tasks", async () => {
      await worker.start();

      const symbols = Array.from({ length: 3 }, (_, i) => ({
        name: `task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "slow_executor",
        parameters: {},
      }));

      const promises = symbols.map((s) => worker.execute(s));

      // Check concurrent task count
      expect(worker.getActiveTasks()).toBe(3);

      await Promise.all(promises);
      expect(worker.getActiveTasks()).toBe(0);
    });

    test("should respect max concurrent tasks", async () => {
      worker = new Worker({ id: "worker-limited", maxTasks: 2 });
      await worker.start();

      const symbols = Array.from({ length: 5 }, (_, i) => ({
        name: `task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      }));

      const executionPromises = symbols.map((s) => worker.execute(s));

      // Some tasks should be queued
      expect(worker.getQueuedTasks()).toBeGreaterThan(0);

      await Promise.all(executionPromises);
      expect(worker.getQueuedTasks()).toBe(0);
    });
  });

  describe("Worker Statistics", () => {
    test("should track execution statistics", async () => {
      await worker.start();

      const symbols = Array.from({ length: 3 }, (_, i) => ({
        name: `stat_task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      }));

      for (const symbol of symbols) {
        await worker.execute(symbol);
      }

      const stats = worker.getStatistics();
      expect(stats.tasksCompleted).toBe(3);
      expect(stats.tasksSucceeded).toBe(3);
      expect(stats.tasksFailed).toBe(0);
    });

    test("should calculate average execution time", async () => {
      await worker.start();

      const symbol: Symbol = {
        name: "timed_task",
        type: SymbolType.Action,
        context: "test",
        dispatch: "timed_executor",
        parameters: {},
      };

      await worker.execute(symbol);
      await worker.execute(symbol);

      const stats = worker.getStatistics();
      expect(stats.averageExecutionTime).toBeGreaterThan(0);
    });

    test("should track failure rate", async () => {
      await worker.start();

      // Execute some failing tasks
      const failingSymbol: Symbol = {
        name: "failing_task",
        type: SymbolType.Action,
        context: "test",
        dispatch: "failing_executor",
        parameters: {},
      };

      for (let i = 0; i < 3; i++) {
        try {
          await worker.execute(failingSymbol);
        } catch (e) {
          // Expected
        }
      }

      const stats = worker.getStatistics();
      expect(stats.tasksFailed).toBe(3);
      expect(stats.failureRate).toBe(1.0);
    });
  });

  describe("Worker Health", () => {
    test("should report healthy status", () => {
      expect(worker.isHealthy()).toBe(true);
    });

    test("should report unhealthy on high failure rate", async () => {
      await worker.start();

      // Simulate many failures
      for (let i = 0; i < 10; i++) {
        try {
          await worker.execute({
            name: `fail_${i}`,
            type: SymbolType.Action,
            context: "test",
            dispatch: "failing_executor",
            parameters: {},
          });
        } catch (e) {
          // Expected
        }
      }

      expect(worker.isHealthy()).toBe(false);
    });

    test("should perform health check", async () => {
      const healthCheck = await worker.healthCheck();
      expect(healthCheck.healthy).toBe(true);
      expect(healthCheck.workerId).toBe("worker-1");
    });
  });

  describe("Worker Communication", () => {
    test("should send heartbeat", () => {
      const heartbeatReceived = mock(() => {});
      worker.on("heartbeat", heartbeatReceived);

      worker.sendHeartbeat();
      expect(heartbeatReceived).toHaveBeenCalled();
    });

    test("should receive messages", () => {
      const messageHandler = mock(() => {});
      worker.on("message", messageHandler);

      worker.receiveMessage({ type: "command", payload: "test" });
      expect(messageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ type: "command" })
      );
    });
  });
});
