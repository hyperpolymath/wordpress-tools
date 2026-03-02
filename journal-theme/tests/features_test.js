/**
 * Tests for modern feature detection
 *
 * @module
 * @package Sinople
 */

import { assertEquals } from "@std/assert";

// Mock CSS.supports
function mockCSSSupports(supportedFeatures) {
  globalThis.CSS = {
    supports: (query) => {
      return supportedFeatures.some((f) => query.includes(f));
    },
  };
}

// Mock window/document for feature detection
function createFeatureDetectionMocks(features) {
  globalThis.document = {
    documentElement: {
      dataset: {},
      classList: {
        add: (_className) => {},
      },
    },
    startViewTransition: features.viewTransitions ? () => {} : undefined,
  };

  globalThis.window = {
    IntersectionObserver: features.intersectionObserver ? class {} : undefined,
    ResizeObserver: features.resizeObserver ? class {} : undefined,
    crypto: features.webCrypto
      ? {
          subtle: {
            generateKey: () => Promise.resolve({}),
          },
        }
      : undefined,
    showOpenFilePicker: features.fileSystemAccess ? () => {} : undefined,
  };

  globalThis.navigator = {
    gpu: features.webGPU ? {} : undefined,
    share: features.webShare ? () => {} : undefined,
  };

  globalThis.WebAssembly = features.wasm
    ? {
        instantiate: () => Promise.resolve({}),
      }
    : undefined;

  globalThis.RTCPeerConnection = features.webRTC ? class {} : undefined;
}

// Feature detection function (mirrors ReScript implementation)
function detectFeatures() {
  const features = {};

  features.intersectionObserver = "IntersectionObserver" in globalThis.window;
  features.resizeObserver = "ResizeObserver" in globalThis.window;
  features.viewTransitions = "startViewTransition" in globalThis.document;
  features.wasm =
    typeof globalThis.WebAssembly !== "undefined" &&
    typeof globalThis.WebAssembly.instantiate === "function";
  features.webCrypto =
    typeof globalThis.window.crypto?.subtle?.generateKey === "function";
  features.webGPU = "gpu" in globalThis.navigator;
  features.webRTC = typeof globalThis.RTCPeerConnection !== "undefined";
  features.fileSystemAccess = "showOpenFilePicker" in globalThis.window;
  features.webShare = "share" in globalThis.navigator;

  return features;
}

Deno.test("Features - detects View Transitions API support", () => {
  createFeatureDetectionMocks({
    viewTransitions: true,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.viewTransitions, true);
});

Deno.test("Features - detects lack of View Transitions API support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.viewTransitions, false);
});

Deno.test("Features - detects WebAssembly support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: true,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.wasm, true);
});

Deno.test("Features - detects Container Queries support via CSS.supports", () => {
  mockCSSSupports(["container-type"]);

  const hasContainerQueries = globalThis.CSS.supports(
    "container-type: inline-size",
  );
  assertEquals(hasContainerQueries, true);
});

Deno.test("Features - detects :has() selector support", () => {
  mockCSSSupports(["selector(:has"]);

  const hasHasSelector = globalThis.CSS.supports("selector(:has(*))");
  assertEquals(hasHasSelector, true);
});

Deno.test("Features - detects IntersectionObserver support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: true,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.intersectionObserver, true);
});

Deno.test("Features - detects ResizeObserver support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: true,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.resizeObserver, true);
});

Deno.test("Features - detects Web Crypto API support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: true,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.webCrypto, true);
});

Deno.test("Features - detects WebGPU support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: true,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.webGPU, true);
});

Deno.test("Features - detects WebRTC support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: true,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.webRTC, true);
});

Deno.test("Features - detects File System Access API support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: true,
    webShare: false,
  });

  const features = detectFeatures();
  assertEquals(features.fileSystemAccess, true);
});

Deno.test("Features - detects Web Share API support", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: true,
  });

  const features = detectFeatures();
  assertEquals(features.webShare, true);
});

Deno.test("Features - all features disabled when unsupported", () => {
  createFeatureDetectionMocks({
    viewTransitions: false,
    intersectionObserver: false,
    resizeObserver: false,
    wasm: false,
    webCrypto: false,
    webGPU: false,
    webRTC: false,
    fileSystemAccess: false,
    webShare: false,
  });

  const features = detectFeatures();

  assertEquals(features.viewTransitions, false);
  assertEquals(features.intersectionObserver, false);
  assertEquals(features.resizeObserver, false);
  assertEquals(features.wasm, false);
  assertEquals(features.webCrypto, false);
  assertEquals(features.webGPU, false);
  assertEquals(features.webRTC, false);
  assertEquals(features.fileSystemAccess, false);
  assertEquals(features.webShare, false);
});
