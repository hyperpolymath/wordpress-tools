// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * WP Praxis Dashboard — API Server Orchestrator
 * Fully ported to ReScript v12
 */

module Elysia = {
  type t
  type options<'a> = 'a
  @module("elysia") @new external make: unit => t = "Elysia"
  @send external use: (t, 'plugin) => t = "use"
  @send external get: (t, string, 'handler) => t = "get"
  @send external post: (t, string, 'handler) => t = "post"
  @send external group: (t, string, t => t) => t = "group"
  @send external listen: (t, int) => t = "listen"
}

module Cors = {
  @module("@elysiajs/cors") external cors: unit => 'plugin = "cors"
}

module Postgres = {
  type client
  @module("./db/postgres-client.res.mjs") @new
  external makeClient: 'config => client = "PostgresClient"
  @send external connect: client => promise<unit> = "connect"
}

type serverConfig = {
  port: int,
  database: JSON.t,
}

@module("./config-loader.res.mjs")
external loadConfig: unit => promise<serverConfig> = "loadConfig"

module DashboardServer = {
  type t = {
    mutable config: option<serverConfig>,
    mutable db: option<Postgres.client>,
    app: Elysia.t,
  }

  let make = () => {
    {
      config: None,
      db: None,
      app: Elysia.make(),
    }
  }

  let setupRoutes = (self: t) => {
    self.app
    ->Elysia.use(Cors.cors())
    ->Elysia.group("/api", app => {
      app
      ->Elysia.get("/health", _ => {"status": "ok", "timestamp": Date.now()})
      ->Elysia.group("/workflows", app => {
        app
        ->Elysia.get("/", _ => %raw(`[]`)) // Placeholder for workflow list
        ->Elysia.get("/:id", _ => %raw(`{}`))
      })
    })
  }

  let initialize = async (self: t) => {
    Console.log("Initializing Dashboard Server...")
    
    let config = await loadConfig()
    self.config = Some(config)
    
    let db = Postgres.makeClient(config.database)
    self.db = Some(db)
    await Postgres.connect(db)
    
    let _ = setupRoutes(self)
    
    let port = config.port
    let _ = self.app->Elysia.listen(port)
    Console.log(`Dashboard API listening on port ${Int.toString(port)}`)
  }
}

let server = DashboardServer.make()
let _ = DashboardServer.initialize(server)
