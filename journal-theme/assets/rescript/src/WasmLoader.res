/**
 * WASM Loader Module
 *
 * Loads and initializes WebAssembly module
 * for performance-critical operations.
 *
 * @package Sinople
 * @since 0.1.0
 */

@val external console: {..} = "console"

// WASM module instance
type wasmExports = {
  calculate_reading_time: (. string) => int,
  sanitize_html: (. string) => string,
  hash_password: (. string) => string,
}

type wasmModule = {exports: wasmExports}

// Check if WebAssembly is supported
let isSupported = (): bool => {
  %raw(`typeof WebAssembly !== 'undefined' && typeof WebAssembly.instantiate === 'function'`)
}

// Get WASM module path
let getWasmPath = (): string => {
  // Try to get from sinople config
  let path: option<string> = %raw(`
    window.sinople?.themeUri
      ? window.sinople.themeUri + '/assets/js/dist/sinople.wasm'
      : null
  `)

  switch path {
  | Some(p) => p
  | None => "/wp-content/themes/sinople/assets/js/dist/sinople.wasm"
  }
}

// Load WASM module
let load = async (): promise<unit> => {
  if !isSupported() {
    console["warn"]("WebAssembly not supported")
    Promise.resolve()
  } else {
    let wasmPath = getWasmPath()

    // Fetch and instantiate WASM module
    let _ = await %raw(`
      (async () => {
        try {
          const response = await fetch(wasmPath);
          if (!response.ok) {
            throw new Error('Failed to fetch WASM module: ' + response.status);
          }

          const wasmBuffer = await response.arrayBuffer();
          const wasmModule = await WebAssembly.instantiate(wasmBuffer, {
            env: {
              // Memory for string operations
              memory: new WebAssembly.Memory({ initial: 256, maximum: 512 }),
              // Logging from WASM
              console_log: (ptr, len) => {
                // Handle logging from WASM if needed
              }
            }
          });

          // Store module globally for use
          window.sinople = window.sinople || {};
          window.sinople.wasm = wasmModule.instance.exports;

          return wasmModule;
        } catch (error) {
          console.warn('WASM loading failed:', error);
          throw error;
        }
      })()
    `)

    Promise.resolve()
  }
}

// Calculate reading time using WASM if available
let calculateReadingTime = (content: string): int => {
  let wasmResult: option<int> = %raw(`
    window.sinople?.wasm?.calculate_reading_time
      ? window.sinople.wasm.calculate_reading_time(content)
      : null
  `)

  switch wasmResult {
  | Some(time) => time
  | None => {
      // Fallback: JS implementation
      let wordCount = content->String.split(" ")->Array.length
      Int.fromFloat(Math.ceil(Float.fromInt(wordCount) /. 200.0))
    }
  }
}

// Sanitize HTML using WASM if available
let sanitizeHtml = (html: string): string => {
  let wasmResult: option<string> = %raw(`
    window.sinople?.wasm?.sanitize_html
      ? window.sinople.wasm.sanitize_html(html)
      : null
  `)

  switch wasmResult {
  | Some(sanitized) => sanitized
  | None => {
      // Fallback: basic JS sanitization
      let _ = %raw(`
        const div = document.createElement('div');
        div.textContent = html;
        return div.innerHTML;
      `)
      html
    }
  }
}

// Hash password using WASM if available
let hashPassword = async (password: string): promise<string> => {
  let wasmResult: option<string> = %raw(`
    window.sinople?.wasm?.hash_password
      ? window.sinople.wasm.hash_password(password)
      : null
  `)

  switch wasmResult {
  | Some(hash) => hash
  | None => {
      // Fallback: Web Crypto API
      let hash: string = await %raw(`
        (async () => {
          const encoder = new TextEncoder();
          const data = encoder.encode(password);
          const hashBuffer = await crypto.subtle.digest('SHA-256', data);
          const hashArray = Array.from(new Uint8Array(hashBuffer));
          return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
        })()
      `)
      hash
    }
  }
}
