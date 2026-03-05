// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * JWT Authentication for Praxis GraphQL
 * Fully ported to ReScript v12
 */

module Types = {
  type authUser = {
    id: string,
    username: string,
    roles: array<string>,
    permissions: array<string>,
  }
}

module Jwt = {
  @module("jsonwebtoken")
  external verify: (string, string) => JSON.t = "verify"

  @module("jsonwebtoken")
  external sign: (JSON.t, string, {"expiresIn": string}) => string = "sign"
}

module Node = {
  module Http = {
    type incomingMessage = {headers: {"authorization": option<string>}}
  }
}

let jwtSecret = switch %raw(`process.env.JWT_SECRET`) {
| s if %raw(`typeof s === 'string'`) => (s :> string)
| _ => "wp-praxis-secret-change-in-production"
}

let jwtExpiresIn = switch %raw(`process.env.JWT_EXPIRES_IN`) {
| s if %raw(`typeof s === 'string'`) => (s :> string)
| _ => "24h"
}

let extractToken = (req: Node.Http.incomingMessage): option<string> => {
  switch req.headers["authorization"] {
  | None => None
  | Some(authHeader) =>
    if String.startsWith(authHeader, "Bearer ") {
      Some(String.substring(authHeader, ~start=7, ~end=String.length(authHeader)))
    } else {
      Some(authHeader)
    }
  }
}

let verifyToken = async (token: string): option<Types.authUser> => {
  try {
    let decoded = Jwt.verify(token, jwtSecret)
    let dict = JSON.Decode.object(decoded)->Option.getExn

    Some({
      id: switch (Dict.get(dict, "id"), Dict.get(dict, "sub")) {
      | (Some(id), _) => JSON.Decode.string(id)->Option.getOr("")
      | (_, Some(sub)) => JSON.Decode.string(sub)->Option.getOr("")
      | _ => ""
      },
      username: Dict.get(dict, "username")
      ->Option.flatMap(JSON.Decode.string)
      ->Option.getOr(""),
      roles: Dict.get(dict, "roles")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Array.map(v => JSON.Decode.string(v)->Option.getOr("")),
      permissions: Dict.get(dict, "permissions")
      ->Option.flatMap(JSON.Decode.array)
      ->Option.getOr([])
      ->Array.map(v => JSON.Decode.string(v)->Option.getOr("")),
    })
  } catch {
  | _ => None
  }
}

let generateToken = (user: Types.authUser): string => {
  let payload = JSON.Encode.object(
    Dict.fromArray([
      ("sub", JSON.Encode.string(user.id)),
      ("username", JSON.Encode.string(user.username)),
      ("roles", JSON.Encode.array(user.roles->Array.map(JSON.Encode.string))),
      ("permissions", JSON.Encode.array(user.permissions->Array.map(JSON.Encode.string))),
    ]),
  )

  Jwt.sign(payload, jwtSecret, {"expiresIn": jwtExpiresIn})
}
