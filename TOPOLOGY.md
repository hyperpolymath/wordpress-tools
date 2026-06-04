<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# wordpress-tools — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              OPERATOR / ADMIN           │
                        │        (WordPress Dashboard / CLI)      │
                        └───────────────────┬─────────────────────┘
                                            │ Signal / Control
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           WORDPRESS TOOLING HUB         │
                        │                                         │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ secured/  │  │  praxis/          │  │
                        │  │ (Hardening)│ │  (Framework)      │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        │        │                 │              │
                        │  ┌─────▼─────┐  ┌────────▼──────────┐  │
                        │  │ conflict- │  │  sinople-theme/   │  │
                        │  │ mapper/   │  │  (Frontend)       │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │           TARGET ECOSYSTEM              │
                        │      (WordPress Core, Plugins, DB)      │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  Best Practices       0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE TOOLING
  secured/ (Hardening)              ████████░░  80%    Security defaults active
  praxis/ (Framework)               ██████░░░░  60%    Best practices active
  plugin-conflict-mapper            ████░░░░░░  40%    Initial detection stubs
  sinople-theme/                    ██████████ 100%    Production theme stable

UTILITIES
  resurrect/ (Recovery)             ██████░░░░  60%    Restore logic active
  project-wharf/                    ████░░░░░░  40%    Deployment stubs active

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build tasks
  .machine_readable/                ██████████ 100%    STATE tracking active
  0-AI-MANIFEST.a2ml                ██████████ 100%    AI entry point verified

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ███████░░░  ~70%   Stable toolset, Plugins refining
```

## Key Dependencies

```
WordPress Core ───► praxis/ Framework ──► secured/ Hardening ──► Audit
     │                    │                   │
     ▼                    ▼                   ▼
 Plugins Set ─────► Conflict Mapper ────► sinople-theme
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
