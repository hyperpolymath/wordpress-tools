# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

# IEx configuration for WpPraxis database schema
# This file is loaded when you run `iex -S mix`

# Import common aliases for easier console usage
alias WpPraxis.Repo

# Schema aliases
alias WpPraxis.Schema.Symbol
alias WpPraxis.Schema.Workflow
alias WpPraxis.Schema.Execution
alias WpPraxis.Schema.Baseline
alias WpPraxis.Schema.Audit

# Query aliases
alias WpPraxis.Queries.SymbolQueries
alias WpPraxis.Queries.WorkflowQueries
alias WpPraxis.Queries.AuditQueries

# Import Ecto.Query for building custom queries
import Ecto.Query

# Print welcome message
IO.puts """

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   WP Praxis Database Schema - Interactive Console            ║
║                                                               ║
║   Available aliases:                                          ║
║     - Repo                                                    ║
║     - Symbol, Workflow, Execution, Baseline, Audit            ║
║     - SymbolQueries, WorkflowQueries, AuditQueries            ║
║                                                               ║
║   Quick examples:                                             ║
║     SymbolQueries.active_symbols()                            ║
║     WorkflowQueries.workflow_stats()                          ║
║     AuditQueries.recent_audits(24)                            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

"""
