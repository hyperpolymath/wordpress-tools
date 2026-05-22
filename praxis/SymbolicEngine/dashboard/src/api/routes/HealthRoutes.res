// SPDX-License-Identifier: MPL-2.0
/**
 * Health Check API Routes — Service Observability Endpoints
 * Fully ported to ReScript v12
 */

module Elysia = {
  type t
  @send external get: (t, string, 'handler) => t = "get"
  @send external group: (t, string, t => t) => t = "group"
}

module Postgres = {
  type client
  @send external healthCheck: client => promise<bool> = "healthCheck"
}

type memoryUsage = {
  rss: float,
  heapTotal: float,
  heapUsed: float,
}

@val @scope("process")
external memoryUsage: unit => memoryUsage = "memoryUsage"

@val @scope("process")
external uptime: unit => float = "uptime"

let setupHealthRoutes = (app: Elysia.t, db: Postgres.client) => {
  app->Elysia.group("/health", app => {
    app
    ->Elysia.get("/", async _ => {
        let dbOk = await Postgres.healthCheck(db)
        let mem = memoryUsage()
        
        {
          "status": dbOk ? "healthy" : "degraded",
          "database": dbOk ? "connected" : "disconnected",
          "memoryMb": Float.toInt(mem.heapUsed /. 1024.0 /. 1024.0),
          "timestamp": Date.now(),
        }
      })
    ->Elysia.get("/detailed", async _ => {
        let dbOk = await Postgres.healthCheck(db)
        let mem = memoryUsage()
        
        {
          "status": dbOk ? "healthy" : "unhealthy",
          "process": {
            "uptime": uptime(),
            "pid": %raw(`process.pid`),
            "arch": %raw(`process.arch`),
          },
          "memory": {
            "rss": mem.rss,
            "heapTotal": mem.heapTotal,
            "heapUsed": mem.heapUsed,
          },
          "database": {
            "connected": dbOk,
          }
        }
      })
  })
}
