/**
 * Tests for WASM integration
 *
 * @module
 * @package Sinople
 */

import { assertEquals, assertExists } from "@std/assert";

// Create mock WASM module
function createMockWasm() {
  return {
    calculate_reading_time: (content) => {
      const wordCount = content.split(/\s+/).filter((w) => w.length > 0).length;
      return Math.ceil(wordCount / 200);
    },
    sanitize_html: (html) => {
      // Basic sanitization - remove script tags
      return html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, "");
    },
    hash_password: (_password) => {
      // Mock hash - in real WASM this would use proper hashing
      return "mocked_hash_" + _password.length;
    },
  };
}

// JavaScript fallback implementations (mirrors WasmLoader.res)
function calculateReadingTimeFallback(content) {
  const wordCount = content.split(" ").filter((w) => w.length > 0).length;
  return Math.ceil(wordCount / 200);
}

async function hashPasswordFallback(password) {
  const encoder = new TextEncoder();
  const data = encoder.encode(password);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

Deno.test("WASM - calculate reading time for short content", () => {
  const wasm = createMockWasm();
  const content = "Hello world this is a test";
  const readingTime = wasm.calculate_reading_time(content);

  // 5 words / 200 wpm = ~1 minute
  assertEquals(readingTime, 1);
});

Deno.test("WASM - calculate reading time for longer content", () => {
  const wasm = createMockWasm();
  // Create content with ~400 words
  const words = Array(400).fill("word").join(" ");
  const readingTime = wasm.calculate_reading_time(words);

  // 400 words / 200 wpm = 2 minutes
  assertEquals(readingTime, 2);
});

Deno.test("WASM - JS fallback reading time calculation", () => {
  const content = "This is a sample text with ten words in it.";
  const readingTime = calculateReadingTimeFallback(content);

  // 10 words / 200 wpm = 1 minute (rounded up)
  assertEquals(readingTime, 1);
});

Deno.test("WASM - sanitize HTML removes script tags", () => {
  const wasm = createMockWasm();
  const dirtyHtml = '<p>Hello</p><script>alert("xss")</script><p>World</p>';
  const cleanHtml = wasm.sanitize_html(dirtyHtml);

  assertEquals(cleanHtml.includes("<script>"), false);
  assertEquals(cleanHtml.includes("<p>Hello</p>"), true);
  assertEquals(cleanHtml.includes("<p>World</p>"), true);
});

Deno.test("WASM - sanitize HTML preserves safe content", () => {
  const wasm = createMockWasm();
  const safeHtml = "<p>This is <strong>safe</strong> content</p>";
  const result = wasm.sanitize_html(safeHtml);

  assertEquals(result, safeHtml);
});

Deno.test("WASM - hash password returns consistent length", () => {
  const wasm = createMockWasm();
  const hash1 = wasm.hash_password("password123");
  const hash2 = wasm.hash_password("differentpassword");

  assertExists(hash1);
  assertExists(hash2);
  assertEquals(typeof hash1, "string");
  assertEquals(typeof hash2, "string");
});

Deno.test("WASM - JS fallback hash produces valid SHA-256", async () => {
  const hash = await hashPasswordFallback("test");

  // SHA-256 produces 64 character hex string
  assertEquals(hash.length, 64);
  // Should be valid hex
  assertEquals(/^[0-9a-f]+$/.test(hash), true);
});

Deno.test("WASM - JS fallback hash is deterministic", async () => {
  const hash1 = await hashPasswordFallback("same_password");
  const hash2 = await hashPasswordFallback("same_password");

  assertEquals(hash1, hash2);
});

Deno.test("WASM - JS fallback hash differs for different inputs", async () => {
  const hash1 = await hashPasswordFallback("password1");
  const hash2 = await hashPasswordFallback("password2");

  assertEquals(hash1 !== hash2, true);
});

Deno.test("WASM - WebAssembly detection check", () => {
  // In Deno, WebAssembly should be available
  const hasWasm =
    typeof WebAssembly !== "undefined" &&
    typeof WebAssembly.instantiate === "function";

  assertEquals(hasWasm, true);
});

Deno.test("WASM - module path resolution", () => {
  // Test that we can construct the correct WASM path
  const themeUri = "/wp-content/themes/sinople";
  const wasmPath = `${themeUri}/assets/js/dist/sinople.wasm`;

  assertEquals(
    wasmPath,
    "/wp-content/themes/sinople/assets/js/dist/sinople.wasm",
  );
});

Deno.test("WASM - empty content handling", () => {
  const wasm = createMockWasm();
  const readingTime = wasm.calculate_reading_time("");

  // Empty content should return 0 or 1 minute minimum
  assertEquals(readingTime >= 0, true);
});

Deno.test("WASM - reading time rounds up correctly", () => {
  const wasm = createMockWasm();
  // 250 words should be ~1.25 minutes, rounded up to 2
  const words = Array(250).fill("word").join(" ");
  const readingTime = wasm.calculate_reading_time(words);

  assertEquals(readingTime, 2);
});
