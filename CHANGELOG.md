<!--
SPDX-License-Identifier: MPL-2.0
SPDX-FileCopyrightText: 2026 Jonathan D.A. Jewell (hyperpolymath)
-->

# Changelog

All notable changes to `wordpress-tools` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat(crg): add crg-grade and crg-badge justfile recipes
- feat: add stapeln.toml container definition
- feat: add UX Justfile with doctor, tour, help-me, assail recipes
- feat: deploy UX Manifesto infrastructure
- feat: add CLADE.a2ml — clade taxonomy declaration
- feat: add mirror.yml workflow for GitLab/Bitbucket mirroring
- feat: consolidate 5 WordPress repos into wordpress-tools monorepo

### Fixed

- fix(ci): sync hypatia-scan.yml to canonical (413: env.HOME+Phase-2+SARIF) (#22)
- fix(ci): build Hypatia escript from repo root (estate dogfood drift)
- fix(ci): rsr-antipattern.yml duplicate heredoc (#19)
- fix: set correct Groove capability type (was: custom)
- fix(scorecard): enforce granular permissions and add fuzzing placeholder
- fix(ci): Resolve workflow-linter self-matching and metadata issues
- fix: resolve panic-attack security findings in sinople theme
- fix: correct email jonathan.jewell → j.d.a.jewell
- fix: global AGPL-3.0-or-later → PMPL-1.0-or-later replacement
- fix: SPDX headers (AGPL→PMPL), email, author name

### Changed

- refactor: migrate 6SCM → 6A2 (.scm → .a2ml format)

### Documentation

- docs: record tech-debt audit findings (2026-05-26) (#28)
- docs(claude): add CLAUDE.md with TypeScript Exemptions table (#17)
- docs: add TEST-NEEDS.md (CRG C)
- docs: add EXPLAINME.adoc — prove-it file backing README claims
- docs: add 0-AI-MANIFEST.a2ml (RSR compliance)

### CI

- ci: fix nonexistent actions/upload-artifact SHA pin (#21)
- ci(antipattern): fix top-level dir matching + benchmarks/lsp/bench filename allowlists (#16)
- ci(antipattern): TS check reads .claude/CLAUDE.md exemption table (#15)
- ci(antipattern): broaden TS allowlist (cli/, mod.ts, lsp-server, *vscode*, deno-*) (#14)
- ci(antipattern): allowlist legit TS bridge/adapter paths (#13)

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
