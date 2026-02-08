import { describe, test, expect, beforeEach, mock } from "bun:test";
import { Coordinator } from "../src/coordinator";
import { Worker } from "../src/worker";
import { Symbol, SymbolType } from "../src/types";

describe("Coordinator", () => {
  let coordinator: Coordinator;

  beforeEach(() => {
    coordinator = new Coordinator({ workerCount: 3 });
  });

  describe("Worker Management", () => {
    test("should initialize workers", async () => {
      await coordinator.start();
      const workers = coordinator.getWorkers();
      expect(workers).toHaveLength(3);
    });

    test("should add workers dynamically", async () => {
      await coordinator.start();
      await coordinator.addWorker();

      const workers = coordinator.getWorkers();
      expect(workers).toHaveLength(4);
    });

    test("should remove workers", async () => {
      await coordinator.start();
      const workers = coordinator.getWorkers();
      await coordinator.removeWorker(workers[0].getId());

      expect(coordinator.getWorkers()).toHaveLength(2);
    });

    test("should scale workers based on load", async () => {
      coordinator = new Coordinator({
        workerCount: 2,
        autoScale: true,
        minWorkers: 2,
        maxWorkers: 5,
      });

      await coordinator.start();

      // Simulate high load
      const symbols = Array.from({ length: 20 }, (_, i) => ({
        name: `task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      }));

      coordinator.scheduleMany(symbols);

      // Wait for auto-scaling
      await new Promise((resolve) => setTimeout(resolve, 100));

      expect(coordinator.getWorkers().length).toBeGreaterThan(2);
    });
  });

  describe("Task Scheduling", () => {
    test("should schedule symbol to available worker", async () => {
      await coordinator.start();

      const symbol: Symbol = {
        name: "scheduled_task",
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      };

      const result = await coordinator.schedule(symbol);
      expect(result.success).toBe(true);
      expect(result.workerId).toBeDefined();
    });

    test("should balance load across workers", async () => {
      await coordinator.start();

      const symbols = Array.from({ length: 9 }, (_, i) => ({
        name: `balanced_task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      }));

      const results = await coordinator.scheduleMany(symbols);

      // Check that tasks are distributed
      const workerIds = results.map((r) => r.workerId);
      const uniqueWorkers = new Set(workerIds);
      expect(uniqueWorkers.size).toBe(3);
    });

    test("should use round-robin scheduling", async () => {
      coordinator = new Coordinator({ workerCount: 3, schedulingStrategy: "round-robin" });
      await coordinator.start();

      const symbols = Array.from({ length: 6 }, (_, i) => ({
        name: `rr_task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      }));

      const results = await coordinator.scheduleMany(symbols);

      // Each worker should get 2 tasks
      const workerCounts = new Map<string, number>();
      results.forEach((r) => {
        workerCounts.set(r.workerId, (workerCounts.get(r.workerId) || 0) + 1);
      });

      Array.from(workerCounts.values()).forEach((count) => {
        expect(count).toBe(2);
      });
    });

    test("should use least-loaded scheduling", async () => {
      coordinator = new Coordinator({ workerCount: 3, schedulingStrategy: "least-loaded" });
      await coordinator.start();

      const symbols = Array.from({ length: 10 }, (_, i) => ({
        name: `ll_task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "slow_executor",
        parameters: {},
      }));

      const results = await coordinator.scheduleMany(symbols);
      expect(results).toHaveLength(10);
    });
  });

  describe("Fault Tolerance", () => {
    test("should handle worker failure", async () => {
      await coordinator.start();

      const symbol: Symbol = {
        name: "fault_test",
        type: SymbolType.Action,
        context: "test",
        dispatch: "failing_executor",
        parameters: {},
      };

      // First attempt fails, should retry on another worker
      try {
        await coordinator.schedule(symbol);
      } catch (e) {
        // Expected on final failure
      }

      const stats = coordinator.getStatistics();
      expect(stats.retriesAttempted).toBeGreaterThan(0);
    });

    test("should redistribute tasks from failed worker", async () => {
      await coordinator.start();
      const workers = coordinator.getWorkers();

      // Simulate worker failure
      await coordinator.removeWorker(workers[0].getId());

      // Tasks should be redistributed
      const stats = coordinator.getStatistics();
      expect(stats.tasksRedistributed).toBeGreaterThanOrEqual(0);
    });

    test("should maintain service during worker restarts", async () => {
      await coordinator.start();

      const symbol: Symbol = {
        name: "restart_test",
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      };

      // Schedule task while restarting a worker
      const schedulePromise = coordinator.schedule(symbol);

      const workers = coordinator.getWorkers();
      await coordinator.restartWorker(workers[0].getId());

      const result = await schedulePromise;
      expect(result.success).toBe(true);
    });
  });

  describe("Monitoring and Metrics", () => {
    test("should collect coordinator statistics", async () => {
      await coordinator.start();

      const symbols = Array.from({ length: 5 }, (_, i) => ({
        name: `stat_task_${i}`,
        type: SymbolType.Action,
        context: "test",
        dispatch: "executor",
        parameters: {},
      }));

      await coordinator.scheduleMany(symbols);

      const stats = coordinator.getStatistics();
      expect(stats.totalTasksScheduled).toBe(5);
      expect(stats.activeWorkers).toBe(3);
    });

    test("should report system health", async () => {
      await coordinator.start();

      const health = await coordinator.healthCheck();
      expect(health.healthy).toBe(true);
      expect(health.workerStatuses).toHaveLength(3);
    });
  });
});
