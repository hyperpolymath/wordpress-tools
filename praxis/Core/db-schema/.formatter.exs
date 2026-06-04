# SPDX-License-Identifier: MPL-2.0
# Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
# SPDX-FileCopyrightText: 2025 WP Praxis Contributors

# Used by "mix format"
[
  import_deps: [:ecto, :ecto_sql],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,test}/**/*.{ex,exs}",
    "priv/*/seeds.exs"
  ],
  subdirectories: ["priv/*/migrations"],
  line_length: 98
]
