// SPDX-License-Identifier: MPL-2.0
/**
 * Stream Handler — Real-Time Execution Observability
 * Fully ported to ReScript v12
 */

module StreamHandler = {
  type t = {
    activeStreams: Map.t<string, Set.t<DashboardEvents.WebSocket.t>>,
    events: DashboardEvents.DashboardEvents.t,
  }

  let make = (events: DashboardEvents.DashboardEvents.t) => {
    {
      activeStreams: Map.make(),
      events: events,
    }
  }

  let subscribe = (self: t, executionId: string, ws: DashboardEvents.WebSocket.t) => {
    let subscribers = switch self.activeStreams->Map.get(executionId) {
    | Some(s) => s
    | None => {
        let s = Set.make()
        self.activeStreams->Map.set(executionId, s)
        s
      }
    }
    subscribers->Set.add(ws)
  }

  let streamLog = (self: t, executionId: string, level: string, message: string) => {
    switch self.activeStreams->Map.get(executionId) {
    | None => ()
    | Some(subscribers) =>
      subscribers->Set.forEach(ws => {
        try {
          DashboardEvents.DashboardEvents.sendToClient(
            ws,
            "log_entry",
            Obj.magic({
              "execution_id": executionId,
              "level": level,
              "message": message,
              "timestamp": Date.now()->Float.toString,
            }),
          )
        } catch {
        | _ => {
            let _ = subscribers->Set.delete(ws)
          }
        }
      })
    }
  }
}
