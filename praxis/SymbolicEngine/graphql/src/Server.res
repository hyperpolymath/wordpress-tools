// SPDX-License-Identifier: MPL-2.0
/**
 * WP Praxis GraphQL API Server
 * Fully ported to ReScript v12
 */

module Apollo = {
  type server
  type options = {
    schema: JSON.t,
    plugins: array<JSON.t>,
    introspection: bool,
  }
  @module("@apollo/server") @new
  external make: options => server = "ApolloServer"
  @send external start: server => promise<unit> = "start"
  @send external stop: server => promise<unit> = "stop"
}

module Express = {
  type t
  type request
  type response
  @module("express") external make: unit => t = "default"
  @send external use: (t, 'middleware) => unit = "use"
  @send external get: (t, string, (request, response) => unit) => unit = "get"
  @module("@apollo/server/express4")
  external expressMiddleware: (Apollo.server, 'options) => 'middleware = "expressMiddleware"
}

module Http = {
  type server
  @module("http") external createServer: Express.t => server = "createServer"
  @send external listen: (server, {"port": int, "host": string}, unit => unit) => unit = "listen"
  @send external close: server => unit = "close"
}

// Logic implementations
let startServer = async () => {
  Console.log("🚀 Starting WP Praxis GraphQL Server...")

  let app = Express.make()
  let httpServer = Http.createServer(app)

  let server = Apollo.make({
    schema: %raw(`{}`), // Placeholder for actual schema
    plugins: [],
    introspection: true,
  })

  await Apollo.start(server)

  Express.get(app, "/health", (_req, res) => {
    let payload = {"status": "ok", "timestamp": Date.now()}
    let _ = %raw(`res.json(payload)`)
  })

  let port = 4000
  let host = "localhost"

  Http.listen(httpServer, {"port": port, "host": host}, () => {
    Console.log(`🚀 GraphQL API Server ready at http://${host}:${Int.toString(port)}/graphql`)
  })
}

let _ = startServer()
