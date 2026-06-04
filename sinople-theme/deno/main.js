// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
/**
 * Sinople Deno + Fresh Main Entry Point
 *
 * This file sets up the Fresh framework for server-side rendering
 * and API routes for the Sinople WordPress theme.
 */

import { start } from "$fresh/server.ts";
import manifest from "./fresh.gen.js";

// Deno.serve for production
await start(manifest);
