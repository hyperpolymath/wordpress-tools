// SPDX-License-Identifier: MPL-2.0
/**
 * PostgreSQL Client — Ecto Database Bridge
 * Fully ported to ReScript v12
 */

module Types = {
  type sql
  type queryResult<'a> = array<'a>
}

@module("postgres")
external makeSql: JSON.t => Types.sql = "default"

module PostgresClient = {
  type t = {
    mutable sql: option<Types.sql>,
    mutable connected: bool,
    config: JSON.t,
  }

  @send
  external querySql: (Types.sql, string) => promise<Types.queryResult<JSON.t>> = "unsafe"

  let make = (config: JSON.t) => {
    {
      sql: None,
      connected: false,
      config: config,
    }
  }

  let connect = async (self: t) => {
    try {
      let sql = makeSql(self.config)
      self.sql = Some(sql)
      // Perform simple SELECT 1 heartbeat
      let _ = await sql->querySql("SELECT 1 as connected")
      self.connected = true
      Console.log("Postgres connected successfully")
    } catch {
    | _ =>
      Console.error("DB Connection failure")
      failwith("Database connection failed")
    }
  }

  let healthCheck = async (self: t): bool => {
    switch self.sql {
    | None => false
    | Some(sql) =>
      try {
        let _ = await sql->querySql("SELECT 1")
        true
      } catch {
      | _ => false
      }
    }
  }

  let getWorkflows = async (self: t, _limit: int, _offset: int) => {
    switch self.sql {
    | None => failwith("Not connected")
    | Some(sql) =>
      await sql->querySql("SELECT * FROM workflows ORDER BY updated_at DESC")
    }
  }

  let getSymbolsByWorkflow = async (self: t, workflowId: string) => {
    switch self.sql {
    | None => failwith("Not connected")
    | Some(sql) =>
      await sql->querySql(`SELECT s.* FROM symbols s JOIN workflow_symbols ws ON s.id = ws.symbol_id WHERE ws.workflow_id = '${workflowId}'`)
    }
  }
}
