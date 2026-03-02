/**
 * Sinople Theme - Main ReScript Entry Point
 *
 * Type-safe module for progressive enhancement,
 * accessibility features, and modern browser APIs.
 *
 * @package Sinople
 * @since 0.1.0
 */

// Global bindings
@val external document: Dom.document = "document"
@val external window: Dom.window = "window"
@val external console: {..} = "console"

// Sinople configuration type
type sinopleFeatures = {
  mutable wasm: bool,
  mutable serviceWorker: bool,
  mutable viewTransitions: bool,
  mutable prefersReducedMotion: bool,
  mutable intersectionObserver: bool,
  mutable resizeObserver: bool,
  mutable containerQueries: bool,
  mutable hasSelector: bool,
  mutable webCrypto: bool,
  mutable webGPU: bool,
  mutable webRTC: bool,
  mutable fileSystemAccess: bool,
  mutable webShare: bool,
}

type sinopleEndpoints = {
  void: string,
  ndjson: string,
  capnproto: string,
}

type sinopleConfig = {
  ajaxUrl: string,
  nonce: string,
  themeUri: string,
  homeUrl: string,
  isRTL: bool,
  i18n: Dict.t<string>,
  mutable features: sinopleFeatures,
  endpoints: sinopleEndpoints,
}

@val @scope("window") external sinople: option<sinopleConfig> = "sinople"

// DOM helpers
module Dom = {
  @val @scope("document") external getElementById: string => Nullable.t<Dom.element> = "getElementById"
  @val @scope("document") external querySelector: string => Nullable.t<Dom.element> = "querySelector"
  @val @scope("document") external querySelectorAll: string => array<Dom.element> = "querySelectorAll"
  @val @scope("document") external documentElement: Dom.element = "documentElement"
  @get external readyState: Dom.document => string = "readyState"

  @send external addEventListener: (Dom.document, string, 'event => unit) => unit = "addEventListener"
  @send external addElementEventListener: (Dom.element, string, 'event => unit) => unit = "addEventListener"
  @send external classList: Dom.element => {..} = "classList"
  @send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
  @send external setStyle: (Dom.element, string, string) => unit = "setProperty"
  @get external style: Dom.element => {..} = "style"
  @get external dataset: Dom.element => {..} = "dataset"
}

// CSS support check
@val @scope("CSS") external cssSupports: string => bool = "supports"

// Initialize theme functionality
let init = async () => {
  switch sinople {
  | None => console["error"]("Sinople: Configuration object not found")
  | Some(config) => {
      console["log"]("🌿 Sinople theme initializing...")

      // Initialize accessibility features (critical)
      Accessibility.init()

      // Initialize View Transitions API if supported
      if config.features.viewTransitions {
        ViewTransitions.init()
      }

      // Load WASM module if supported
      if config.features.wasm {
        try {
          await WasmLoader.load()
          console["log"]("✓ WASM module loaded")
        } catch {
        | _ => console["warn"]("WASM module failed to load")
        }
      }

      // Initialize web components
      WebComponents.init()

      // Feature detection
      detectFeatures()

      console["log"]("✓ Sinople theme initialized")
    }
  }
}

// Detect and add feature classes to HTML element
let detectFeatures = () => {
  let html = Dom.documentElement

  // Feature detection using raw JS for browser APIs
  let hasIntersectionObserver = %raw(`'IntersectionObserver' in window`)
  let hasResizeObserver = %raw(`'ResizeObserver' in window`)
  let hasContainerQueries = cssSupports("container-type: inline-size")
  let hasHasSelector = cssSupports("selector(:has(*))")
  let hasViewTransitions = %raw(`'startViewTransition' in document`)
  let hasWebCrypto = %raw(`typeof window.crypto?.subtle?.generateKey === 'function'`)
  let hasWebGPU = %raw(`'gpu' in navigator`)
  let hasWebRTC = %raw(`'RTCPeerConnection' in window`)
  let hasFileSystemAccess = %raw(`'showOpenFilePicker' in window`)
  let hasWebShare = %raw(`'share' in navigator`)

  // Add classes to HTML element
  let addFeatureClass = (name: string, supported: bool) => {
    if supported {
      let _ = %raw(`html.classList.add('has-' + name)`)
    }
  }

  addFeatureClass("intersection-observer", hasIntersectionObserver)
  addFeatureClass("resize-observer", hasResizeObserver)
  addFeatureClass("container-queries", hasContainerQueries)
  addFeatureClass("has-selector", hasHasSelector)
  addFeatureClass("view-transitions", hasViewTransitions)
  addFeatureClass("web-crypto", hasWebCrypto)
  addFeatureClass("web-gpu", hasWebGPU)
  addFeatureClass("web-rtc", hasWebRTC)
  addFeatureClass("file-system-access", hasFileSystemAccess)
  addFeatureClass("web-share", hasWebShare)

  // Update global features object
  switch sinople {
  | None => ()
  | Some(config) => {
      config.features.intersectionObserver = hasIntersectionObserver
      config.features.resizeObserver = hasResizeObserver
      config.features.containerQueries = hasContainerQueries
      config.features.hasSelector = hasHasSelector
      config.features.viewTransitions = hasViewTransitions
      config.features.webCrypto = hasWebCrypto
      config.features.webGPU = hasWebGPU
      config.features.webRTC = hasWebRTC
      config.features.fileSystemAccess = hasFileSystemAccess
      config.features.webShare = hasWebShare
    }
  }
}

// Initialize when DOM is ready
let _ = {
  let readyState = %raw(`document.readyState`)
  if readyState == "loading" {
    Dom.addEventListener(document, "DOMContentLoaded", _ => {
      let _ = init()
    })
  } else {
    let _ = init()
  }
}
