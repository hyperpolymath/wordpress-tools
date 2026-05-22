// SPDX-License-Identifier: MPL-2.0
/**
 * Config Loader — Dashboard Specification Ingestion
 * Fully ported to ReScript v12
 */

module Path = {
  @module("path") external join: (string, string) => string = "join"
  @module("path") external dirname: string => string = "dirname"
}

module Fs = {
  @module("fs") external readFileSync: (string, string) => string = "readFileSync"
  @module("fs") external existsSync: string => bool = "existsSync"
}

// Simple TOML parser implementation
let parseSimpleTOML = (content: string): JSON.t => {
  let result = Dict.make()
  let currentSection = ref(result)
  
  let lines = String.split(content, "\n")
  lines->Array.forEach(line => {
    let trimmed = String.trim(line)
    if String.startsWith(trimmed, "#") || trimmed == "" {
      () // Skip comments and empty lines
    } else if String.startsWith(trimmed, "[") && String.endsWith(trimmed, "]") {
      let sectionName = String.substring(trimmed, ~start=1, ~end=String.length(trimmed) - 1)
      let section = Dict.make()
      Dict.set(result, sectionName, JSON.Encode.object(section))
      currentSection := section
    } else {
      let parts = String.split(trimmed, "=")
      if Array.length(parts) == 2 {
        let key = String.trim(Belt.Array.getExn(parts, 0))
        let value = String.trim(Belt.Array.getExn(parts, 1))
        
        // Basic type inference
        let jsonValue = if String.startsWith(value, "\"") && String.endsWith(value, "\"") {
          JSON.Encode.string(String.substring(value, ~start=1, ~end=String.length(value) - 1))
        } else if value == "true" {
          JSON.Encode.bool(true)
        } else if value == "false" {
          JSON.Encode.bool(false)
        } else {
          switch Int.fromString(value) {
          | Some(n) => JSON.Encode.int(n)
          | None => JSON.Encode.string(value)
          }
        }
        Dict.set(currentSection.contents, key, jsonValue)
      }
    }
  })
  
  JSON.Encode.object(result)
}

let loadConfig = async (~configPath: option<string>=?): JSON.t => {
  let path = switch configPath {
  | Some(p) => p
  | None => Path.join(%raw(`import.meta.dirname`), "../dashboard-config.toml")
  }
  
  if Fs.existsSync(path) {
    let content = Fs.readFileSync(path, "utf-8")
    parseSimpleTOML(content)
  } else {
    // Return default config as JSON
    Obj.magic({
      "server": {"port": 4000, "host": "localhost"},
      "database": {"host": "localhost", "port": 5432},
    })
  }
}
