// SPDX-License-Identifier: MPL-2.0
/**
 * WP Praxis Swarm — Task Distribution Coordinator
 * Fully ported to ReScript v12
 */

module Uuid = {
  @module("uuid") external v4: unit => string = "v4"
}

module Types = {
  type nodeStatus = Online | Offline | Busy
  
  type node = {
    id: string,
    mutable status: nodeStatus,
    mutable lastHeartbeat: float,
    capabilities: array<string>,
    maxTasks: int,
    mutable activeTasks: int,
  }

  type taskStatus = Pending | Running | Completed | Failed

  type task = {
    id: string,
    mutable status: taskStatus,
    engine: string,
    prerequisites: array<string>,
  }
}

module Coordinator = {
  type t = {
    nodes: Map.t<string, Types.node>,
    taskQueue: array<Types.task>,
    completedSymbols: Set.t<string>,
  }

  let make = () => {
    {
      nodes: Map.make(),
      taskQueue: [],
      completedSymbols: Set.make(),
    }
  }

  let isTaskReady = (self: t, task: Types.task) => {
    task.status == Types.Pending &&
      task.prerequisites->Array.every(p => self.completedSymbols->Set.has(p))
  }

  let getBestNodeForTask = (self: t, task: Types.task): option<Types.node> => {
    self.nodes
    ->Map.values
    ->Iterator.toArray
    ->Array.filter(node => 
        node.status == Types.Online && 
        node.activeTasks < node.maxTasks &&
        node.capabilities->Array.includes(task.engine)
      )
    ->Array.toSorted((a, b) => 
        Float.compare(
          Int.toFloat(a.activeTasks) /. Int.toFloat(a.maxTasks),
          Int.toFloat(b.activeTasks) /. Int.toFloat(b.maxTasks)
        )
      )
    ->Array.get(0)
  }

  let assignTaskToNode = (task: Types.task, node: Types.node) => {
    task.status = Types.Running
    node.activeTasks = node.activeTasks + 1
    if node.activeTasks >= node.maxTasks {
      node.status = Types.Busy
    }
    Console.log(`Task ${task.id} assigned to node ${node.id}`)
  }

  let scheduleTasks = (self: t) => {
    let readyTasks = self.taskQueue->Array.filter(task => isTaskReady(self, task))
    
    readyTasks->Array.forEach(task => {
      switch getBestNodeForTask(self, task) {
      | Some(node) => assignTaskToNode(task, node)
      | None => ()
      }
    })
  }

  let checkNodeHeartbeats = (self: t, threshold: float) => {
    let now = Date.now()
    self.nodes->Map.forEach((node, _id) => {
      if now -. node.lastHeartbeat > threshold {
        node.status = Types.Offline
        Console.log(`Node ${node.id} marked offline due to missed heartbeat`)
      }
    })
  }
}

let coordinator = Coordinator.make()
// Integration logic for periodic scheduling would go here
