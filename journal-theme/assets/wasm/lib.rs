/**
 * WebAssembly Module for Sinople Theme
 *
 * Performance-critical operations compiled to WASM
 * for client-side acceleration.
 */

use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};

#[wasm_bindgen]
extern "C" {
    #[wasm_bindgen(js_namespace = console)]
    fn log(s: &str);
}

#[wasm_bindgen]
pub fn init() {
    log("Sinople WASM module initialized");
}

/// Calculate reading time for text content
#[wasm_bindgen]
pub fn calculate_reading_time(text: &str, words_per_minute: u32) -> f32 {
    let word_count = text.split_whitespace().count() as u32;
    word_count as f32 / words_per_minute as f32
}

/// Parse and validate structured data
#[derive(Serialize, Deserialize)]
pub struct StructuredData {
    pub context: String,
    pub data_type: String,
    pub properties: JsValue,
}

#[wasm_bindgen]
pub fn validate_structured_data(json: &str) -> Result<bool, JsValue> {
    match serde_json::from_str::<serde_json::Value>(json) {
        Ok(data) => {
            // Basic validation
            Ok(data.is_object())
        }
        Err(e) => Err(JsValue::from_str(&format!("Invalid JSON: {}", e))),
    }
}

/// Text transformation utilities
#[wasm_bindgen]
pub fn sanitize_html(html: &str) -> String {
    // Basic HTML sanitization (would use ammonia crate in production)
    html.replace("<script", "&lt;script")
        .replace("</script", "&lt;/script")
        .replace("javascript:", "")
}

/// Performance timing utilities
#[wasm_bindgen]
pub struct PerformanceMetrics {
    start_time: f64,
}

#[wasm_bindgen]
impl PerformanceMetrics {
    #[wasm_bindgen(constructor)]
    pub fn new() -> PerformanceMetrics {
        PerformanceMetrics {
            start_time: js_sys::Date::now(),
        }
    }

    pub fn elapsed(&self) -> f64 {
        js_sys::Date::now() - self.start_time
    }
}
