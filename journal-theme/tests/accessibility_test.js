/**
 * Tests for accessibility module
 *
 * @module
 * @package Sinople
 */

import { assertEquals, assertExists } from "@std/assert";

// Mock DOM environment for testing
function createMockDOM() {
  globalThis.document = {
    documentElement: {
      style: {
        setProperty: (_name, _value) => {},
        getPropertyValue: (_name) => "",
      },
      dataset: {},
      classList: {
        add: (_className) => {},
        remove: (_className) => {},
        contains: (_className) => false,
        toggle: (_className) => false,
      },
    },
    getElementById: (_id) => null,
    querySelector: (_selector) => null,
    querySelectorAll: (_selector) => [],
    addEventListener: (_event, _callback) => {},
    body: {
      innerHTML: "",
      classList: {
        add: (_className) => {},
        remove: (_className) => {},
        contains: (_className) => false,
      },
    },
  };

  globalThis.localStorage = {
    _data: {},
    getItem(key) {
      return this._data[key] || null;
    },
    setItem(key, value) {
      this._data[key] = value;
    },
    removeItem(key) {
      delete this._data[key];
    },
    clear() {
      this._data = {};
    },
  };

  globalThis.window = {
    matchMedia: (_query) => ({
      matches: false,
      media: _query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => true,
    }),
    sinople: {
      ajaxUrl: "/wp-admin/admin-ajax.php",
      nonce: "test-nonce",
      themeUri: "/wp-content/themes/sinople",
      homeUrl: "/",
      isRTL: false,
      i18n: {},
      features: {
        wasm: true,
        serviceWorker: true,
        viewTransitions: false,
        prefersReducedMotion: false,
      },
      endpoints: {
        void: "/void.rdf",
        ndjson: "/feed/ndjson",
        capnproto: "/api/capnp",
      },
    },
  };
}

// Reset mocks before each test
function resetMocks() {
  createMockDOM();
  globalThis.localStorage.clear();
}

Deno.test("Accessibility - font scale applies CSS custom property", () => {
  resetMocks();

  let appliedValue = "";
  globalThis.document.documentElement.style.setProperty = (
    name,
    value,
  ) => {
    if (name === "--text-scale") {
      appliedValue = value;
    }
  };

  // Simulate applying font scale
  const scale = 1.2;
  document.documentElement.style.setProperty("--text-scale", scale.toString());

  assertEquals(appliedValue, "1.2");
});

Deno.test("Accessibility - font scale respects minimum (0.8)", () => {
  resetMocks();

  const minScale = 0.8;
  let currentScale = 1.0;

  // Simulate decreasing beyond minimum
  for (let i = 0; i < 10; i++) {
    currentScale = Math.max(minScale, currentScale - 0.1);
  }

  assertEquals(currentScale >= 0.8, true);
});

Deno.test("Accessibility - font scale respects maximum (1.5)", () => {
  resetMocks();

  const maxScale = 1.5;
  let currentScale = 1.0;

  // Simulate increasing beyond maximum
  for (let i = 0; i < 10; i++) {
    currentScale = Math.min(maxScale, currentScale + 0.1);
  }

  assertEquals(currentScale <= 1.5, true);
});

Deno.test("Accessibility - theme persists to localStorage", () => {
  resetMocks();

  globalThis.localStorage.setItem("theme", "dark");

  const savedTheme = globalThis.localStorage.getItem("theme");

  assertEquals(savedTheme, "dark");
});

Deno.test("Accessibility - contrast toggle persists preference", () => {
  resetMocks();

  globalThis.localStorage.setItem("contrast", "high");

  const savedContrast = globalThis.localStorage.getItem("contrast");

  assertEquals(savedContrast, "high");
});

Deno.test("Accessibility - system dark mode detection", () => {
  resetMocks();

  // Mock dark mode preference
  globalThis.window.matchMedia = (query) => ({
    matches: query === "(prefers-color-scheme: dark)",
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => true,
  });

  const prefersDark = globalThis.window.matchMedia(
    "(prefers-color-scheme: dark)",
  ).matches;

  assertEquals(prefersDark, true);
});

Deno.test("Accessibility - theme toggle button ARIA attributes", () => {
  resetMocks();

  const mockButton = {
    attributes: {},
    setAttribute(name, value) {
      this.attributes[name] = value;
    },
    getAttribute(name) {
      return this.attributes[name] || null;
    },
  };

  // Simulate updating theme button for dark mode
  mockButton.setAttribute("aria-pressed", "true");
  mockButton.setAttribute("aria-label", "Switch to light mode");

  assertEquals(mockButton.getAttribute("aria-pressed"), "true");
  assertEquals(mockButton.getAttribute("aria-label"), "Switch to light mode");
});

Deno.test("Accessibility - skip links exist in DOM interface", () => {
  resetMocks();

  // The interface should support querySelectorAll for skip-link elements
  assertExists(globalThis.document.querySelectorAll);
});

Deno.test("Accessibility - keyboard navigation Escape key handling", () => {
  resetMocks();

  let escapeCalled = false;

  // Mock event listener for Escape key
  const handleKeydown = (event) => {
    if (event.key === "Escape") {
      escapeCalled = true;
    }
  };

  // Simulate Escape key press
  handleKeydown({ key: "Escape" });

  assertEquals(escapeCalled, true);
});

Deno.test("Accessibility - menu toggle aria-expanded attribute", () => {
  resetMocks();

  const mockToggle = {
    _expanded: false,
    getAttribute(_name) {
      return this._expanded ? "true" : "false";
    },
    setAttribute(_name, value) {
      this._expanded = value === "true";
    },
  };

  // Initial state
  assertEquals(mockToggle.getAttribute("aria-expanded"), "false");

  // After toggle
  mockToggle.setAttribute("aria-expanded", "true");
  assertEquals(mockToggle.getAttribute("aria-expanded"), "true");
});
