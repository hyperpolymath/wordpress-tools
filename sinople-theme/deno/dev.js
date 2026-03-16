// SPDX-License-Identifier: PMPL-1.0-or-later
/**
 * Development Server for Sinople Deno + Fresh
 */

import dev from "$fresh/dev.ts";
import config from "./fresh.config.js";

await dev(import.meta.url, "./main.js", config);
