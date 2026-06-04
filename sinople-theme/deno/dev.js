// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
/**
 * Development Server for Sinople Deno + Fresh
 */

import dev from "$fresh/dev.ts";
import config from "./fresh.config.js";

await dev(import.meta.url, "./main.js", config);
