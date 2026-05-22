// SPDX-License-Identifier: MPL-2.0
/**
 * Praxis API Routes — Central Routing Manifest
 * Fully ported to ReScript v12
 */

open Types
open AuditController
open BaselineController
open ExecutionController
open SymbolController
open WorkflowController

module Elysia = {
  type t
  type context<'q, 'p, 'b> = {
    query: 'q,
    params: 'p,
    body: 'b,
  }
  @send external get: (t, string, context<'q, 'p, 'b> => promise<'res>) => t = "get"
  @send external post: (t, string, context<'q, 'p, 'b> => promise<'res>) => t = "post"
  @send external patch: (t, string, context<'q, 'p, 'b> => promise<'res>) => t = "patch"
  @send external delete: (t, string, context<'q, 'p, 'b> => promise<'res>) => t = "delete"
  @send external group: (t, string, t => t) => t = "group"
}

let setupAuditRoutes = (app: Elysia.t, controller: AuditController.t) => {
  app->Elysia.group("/audits", app => {
    app
    ->Elysia.get("/", async _ctx => {
        let workflowId = %raw(`ctx.query.workflow_id`)
        await AuditController.list(controller, workflowId)
      })
    ->Elysia.get("/stats", async _ => {
        await AuditController.getStats(controller)
      })
  })
}

let setupBaselineRoutes = (app: Elysia.t, controller: BaselineController.t) => {
  app->Elysia.group("/baselines", app => {
    app
    ->Elysia.get("/", async _ctx => {
        let workflowId = %raw(`ctx.query.workflow_id`)
        await BaselineController.list(controller, workflowId)
      })
    ->Elysia.get("/normative/:workflow_id", async _ctx => {
        let workflowId = %raw(`ctx.params.workflow_id`)
        await BaselineController.getNormative(controller, workflowId)
      })
  })
}

let setupExecutionRoutes = (app: Elysia.t, controller: ExecutionController.t) => {
  app->Elysia.group("/executions", app => {
    app
    ->Elysia.get("/", async _ctx => {
        let status = %raw(`ctx.query.status`)
        await ExecutionController.list(controller, status)
      })
    ->Elysia.get("/stats", async _ => {
        await ExecutionController.getStats(controller)
      })
  })
}

let setupSymbolRoutes = (app: Elysia.t, controller: SymbolController.t) => {
  app->Elysia.group("/symbols", app => {
    app
    ->Elysia.get("/", async _ => {
        await SymbolController.list(controller, None)
      })
    ->Elysia.get("/search", async _ctx => {
        let q = %raw(`ctx.query.q`)
        let type_ = %raw(`ctx.query.type`)
        await SymbolController.search(controller, q, type_)
      })
  })
}

let setupWorkflowRoutes = (app: Elysia.t, controller: WorkflowController.t) => {
  app->Elysia.group("/workflows", app => {
    app
    ->Elysia.get("/", async _ctx => {
        let status = %raw(`ctx.query.status`)
        await WorkflowController.list(controller, status)
      })
    ->Elysia.post("/", async _ctx => {
        let name = %raw(`ctx.body.name`)
        let path = %raw(`ctx.body.manifest_path`)
        await WorkflowController.create(controller, name, path)
      })
    ->Elysia.get("/:id/symbols", async _ctx => {
        let id = %raw(`ctx.params.id`)
        await WorkflowController.getSymbols(controller, id)
      })
  })
}
