// SPDX-License-Identifier: MPL-2.0
/**
 * Development Server for Sinople Deno + Fresh
 */

import dev from "$fresh/dev.ts";
import config from "./fresh.config.js";

await dev(import.meta.url, "./main.js", config);
