# SPDX-License-Identifier: AGPL-3.0-or-later
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
