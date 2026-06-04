<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# CLAUDE.md

Repository-specific guidance for AI agents working in this repo. See the org-wide standard guidance in standards/.

### TypeScript Exemptions (Approved)

The hyperpolymath "no new TypeScript" policy has the following approved exemptions in this repo. These are *not* policy violations — they are documented carve-outs.

| Path | Files | Rationale | Unblock condition |
|---|---|---|---|
| `praxis/SymbolicEngine/**/*.ts` | 38 | praxis/SymbolicEngine — GraphQL service + dashboard frontend; depends on Node ecosystem (Apollo, GraphQL.js, Vue/React); migration scoped to a separate AffineScript Node-target + GraphQL-bindings milestone. | AffineScript Node-target codegen (affinescript#35) + GraphQL/Apollo bindings. |

Adding to this list requires explicit user approval and an unblock condition. New TypeScript files outside this list are blocked by the RSR antipattern check.
