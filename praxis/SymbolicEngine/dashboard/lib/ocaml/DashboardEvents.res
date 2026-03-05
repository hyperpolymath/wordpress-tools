// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Dashboard Events — Real-Time WebSocket Broadcasting
 * Fully ported to ReScript v12
 */

module WebSocket = {
  type t
  @send external send: (t, string) => unit = "send"
}

module DashboardEvents = {
  type t = {
    connections: Set.t<WebSocket.t>,
    mutable heartbeatInterval: option<float>,
  }

  let make = () => {
    {
      connections: Set.make(),
      heartbeatInterval: None,
    }
  }

  let createMessage = (type_: string, payload: JSON.t): JSON.t => {
    Obj.magic({
      "type": type_,
      "payload": payload,
      "timestamp": Date.now()->Float.toString,
    })
  }

  let sendToClient = (ws: WebSocket.t, type_: string, payload: JSON.t) => {
    let message = createMessage(type_, payload)
    ws->WebSocket.send(JSON.stringify(message))
  }

  let broadcast = (self: t, type_: string, payload: JSON.t) => {
    let message = createMessage(type_, payload)
    let messageStr = JSON.stringify(message)

    self.connections->Set.forEach(ws => {
      try {
        ws->WebSocket.send(messageStr)
      } catch {
      | _ => {
          let _ = self.connections->Set.delete(ws)
        }
      }
    })
  }

  let broadcastExecutionProgress = (self: t, executionId: string, progress: float, message: option<string>) => {
    self->broadcast("execution_progress", Obj.magic({
      "execution_id": executionId,
      "progress": progress,
      "message": message,
      "timestamp": Date.now()->Float.toString,
    }))
  }
}
