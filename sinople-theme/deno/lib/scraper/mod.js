// SPDX-License-Identifier: AGPL-3.0-or-later
// Web Scraper Module
// Extracts design patterns, structure, and assets from websites

import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.43/deno-dom-wasm.ts";
import { detectLicense } from "../license-detector/mod.js";

/**
 * Main extraction function
 */
export async function extractWebsite(url) {
  console.log(`🔍 Extracting website: ${url}`);

  // 1. Detect license
  console.log("  📜 Detecting license...");
  const license = await detectLicense(url);

  if (!license.compatible) {
    throw new Error(
      `License incompatible: ${license.type || "Unknown"}. Cannot extract.`
    );
  }

  console.log(`  ✅ License OK: ${license.type}`);

  // 2. Fetch HTML
  console.log("  📥 Fetching HTML...");
  const response = await fetch(url, {
    headers: {
      "User-Agent": "Sinople-Theme-Extractor/1.0",
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch ${url}: ${response.status}`);
  }

  const rawHTML = await response.text();

  // 3. Parse DOM
  console.log("  🌳 Parsing DOM structure...");
  const domStructure = await analyzeDOMStructure(rawHTML);

  // 4. Extract CSS
  console.log("  🎨 Extracting CSS...");
  const rawCSS = await extractCSS(rawHTML, url);

  // 5. Extract design tokens from CSS
  console.log("  🎯 Analyzing design tokens...");
  const designTokens = await extractDesignTokens(rawCSS);

  // 6. Extract assets
  console.log("  🖼️  Cataloging assets...");
  const assets = await extractAssets(rawHTML, url);

  console.log("  ✨ Extraction complete!");

  return {
    url,
    license,
    domStructure,
    designTokens,
    assets,
    rawHTML,
    rawCSS,
    extractedAt: new Date().toISOString(),
  };
}

/**
 * Analyze DOM structure
 */
async function analyzeDOMStructure(html) {
  const doc = new DOMParser().parseFromString(html, "text/html");

  if (!doc) {
    throw new Error("Failed to parse HTML");
  }

  // Extract main structural elements
  const header = doc.querySelector("header");
  const nav = doc.querySelector("nav");
  const main = doc.querySelector("main") || doc.querySelector("#main") || doc.querySelector(".main");
  const aside = doc.querySelector("aside") || doc.querySelector(".sidebar");
  const footer = doc.querySelector("footer");

  // Extract semantic tags
  const semanticTags = extractSemanticTags(doc);

  // Extract ARIA landmarks
  const ariaLandmarks = extractARIALandmarks(doc);

  // Extract microformats
  const microformats = extractMicroformats(doc);

  return {
    hierarchy: {
      header: header ? extractElement(header) : null,
      navigation: nav ? extractElement(nav) : null,
      main: main ? extractElement(main) : null,
      sidebar: aside ? extractElement(aside) : null,
      footer: footer ? extractElement(footer) : null,
    },
    semanticTags,
    ariaLandmarks,
    microformats,
  };
}

/**
 * Extract element node recursively
 */
function extractElement(el) {
  const attributes = {};

  // Extract all attributes
  for (const attr of el.attributes) {
    attributes[attr.name] = attr.value;
  }

  return {
    tag: el.tagName.toLowerCase(),
    classes: Array.from(el.classList),
    id: el.id || undefined,
    attributes,
    children: Array.from(el.children).map(child => extractElement(child)),
    textContent: el.textContent?.trim().substring(0, 100), // Truncate long text
  };
}

/**
 * Extract all semantic HTML5 tags used
 */
function extractSemanticTags(doc) {
  const semanticElements = [
    "article",
    "aside",
    "details",
    "figcaption",
    "figure",
    "footer",
    "header",
    "main",
    "mark",
    "nav",
    "section",
    "summary",
    "time",
  ];

  const found = [];

  for (const tag of semanticElements) {
    const elements = doc.querySelectorAll(tag);
    if (elements.length > 0) {
      found.push(tag);
    }
  }

  return found;
}

/**
 * Extract ARIA landmarks
 */
function extractARIALandmarks(doc) {
  const landmarks = [];

  const elementsWithRole = doc.querySelectorAll("[role]");

  for (const el of elementsWithRole) {
    const role = el.getAttribute("role");
    const label = el.getAttribute("aria-label") || el.getAttribute("aria-labelledby") || "";

    if (role) {
      landmarks.push({ role, label });
    }
  }

  return landmarks;
}

/**
 * Extract microformats (h-entry, h-card, etc.)
 */
function extractMicroformats(doc) {
  const microformats = [];

  // Look for microformats2 classes (h-entry, h-card, etc.)
  const mfElements = doc.querySelectorAll("[class*='h-']");

  for (const el of mfElements) {
    const classes = Array.from(el.classList);
    const mfClass = classes.find(c => c.startsWith("h-"));

    if (mfClass) {
      const properties = {};

      // Extract property classes (p-name, u-url, dt-published, etc.)
      const propElements = el.querySelectorAll("[class*='p-'], [class*='u-'], [class*='dt-'], [class*='e-']");

      for (const propEl of propElements) {
        const propClasses = Array.from(propEl.classList);
        const propClass = propClasses.find(c =>
          c.startsWith("p-") || c.startsWith("u-") || c.startsWith("dt-") || c.startsWith("e-")
        );

        if (propClass) {
          properties[propClass] = propEl.textContent?.trim();
        }
      }

      microformats.push({
        type: mfClass,
        properties,
      });
    }
  }

  return microformats;
}

/**
 * Extract CSS from HTML (inline, style tags, linked stylesheets)
 */
async function extractCSS(html, baseUrl) {
  const cssFiles = [];

  // Parse HTML to find <link rel="stylesheet"> tags
  const linkRegex = /<link[^>]+rel=["']stylesheet["'][^>]*href=["']([^"']+)["']/gi;
  const matches = html.matchAll(linkRegex);

  for (const match of matches) {
    const href = match[1];
    const absoluteUrl = new URL(href, baseUrl).toString();

    try {
      const response = await fetch(absoluteUrl);
      if (response.ok) {
        const css = await response.text();
        cssFiles.push(css);
      }
    } catch {
      // Failed to fetch CSS file
    }
  }

  // Extract inline <style> tags
  const styleRegex = /<style[^>]*>([\s\S]*?)<\/style>/gi;
  const styleMatches = html.matchAll(styleRegex);

  for (const match of styleMatches) {
    cssFiles.push(match[1]);
  }

  return cssFiles;
}

/**
 * Extract design tokens from CSS
 */
async function extractDesignTokens(cssFiles) {
  const allCSS = cssFiles.join("\n");

  // Extract colors (hex, rgb, rgba, hsl)
  const colorRegex = /#[0-9a-fA-F]{3,6}|rgba?\([^)]+\)|hsla?\([^)]+\)/g;
  const colors = Array.from(new Set(allCSS.match(colorRegex) || []));

  // Extract font families
  const fontFamilyRegex = /font-family:\s*([^;]+);/gi;
  const fontFamilies = Array.from(new Set(
    Array.from(allCSS.matchAll(fontFamilyRegex)).map(m => m[1].trim())
  ));

  // Extract font sizes
  const fontSizeRegex = /font-size:\s*([^;]+);/gi;
  const fontSizes = Array.from(new Set(
    Array.from(allCSS.matchAll(fontSizeRegex)).map(m => m[1].trim())
  ));

  // Extract breakpoints from media queries
  const mediaRegex = /@media[^{]+\(min-width:\s*([^)]+)\)/gi;
  const breakpoints = Array.from(allCSS.matchAll(mediaRegex)).map(m => m[1].trim());

  return {
    colors: categorizeColors(colors),
    typography: {
      families: fontFamilies,
      sizes: {
        base: "1rem", // Default
        scale: detectModularScale(fontSizes),
      },
      lineHeights: [1.5, 1.6, 1.75], // Common values
      weights: [400, 500, 600, 700], // Common weights
    },
    spacing: {
      scale: [0.25, 0.5, 1, 1.5, 2, 3, 4, 6, 8, 12, 16], // Common rem scale
    },
    breakpoints: {
      mobile: breakpoints[0],
      tablet: breakpoints[1],
      desktop: breakpoints[2],
    },
    layout: {
      maxWidth: "1200px", // Common default
      gridColumns: 12,
      gridGap: "1rem",
    },
  };
}

/**
 * Categorize colors into primary, secondary, text, background, accent
 */
function categorizeColors(colors) {
  // Simple heuristic categorization (can be improved with ML)
  return {
    primary: colors.slice(0, 3),
    secondary: colors.slice(3, 6),
    text: colors.filter(c => c.includes("#000") || c.includes("#333") || c.includes("rgb(0")),
    background: colors.filter(c => c.includes("#fff") || c.includes("#f") || c.includes("rgb(255")),
    accent: colors.slice(6, 10),
  };
}

/**
 * Detect modular scale from font sizes
 */
function detectModularScale(sizes) {
  // Convert to rem values and extract scale
  const remSizes = sizes
    .filter(s => s.includes("rem") || s.includes("px"))
    .map(s => {
      if (s.includes("rem")) {
        return parseFloat(s);
      } else {
        // Convert px to rem (assuming 16px = 1rem)
        return parseFloat(s) / 16;
      }
    })
    .filter(n => !isNaN(n))
    .sort((a, b) => a - b);

  return Array.from(new Set(remSizes));
}

/**
 * Extract assets (images, fonts, scripts)
 */
async function extractAssets(html, baseUrl) {
  // Extract images
  const imgRegex = /<img[^>]+src=["']([^"']+)["'][^>]*alt=["']([^"']*)["']/gi;
  const images = Array.from(html.matchAll(imgRegex)).map(match => ({
    url: new URL(match[1], baseUrl).toString(),
    alt: match[2],
    purpose: determineImagePurpose(match[1], match[2]),
    dimensions: undefined,
  }));

  // Extract fonts (Google Fonts, etc.)
  const fontLinkRegex = /<link[^>]+href=["']([^"']*fonts[^"']*)["']/gi;
  const fontMatches = Array.from(html.matchAll(fontLinkRegex));

  const fonts = fontMatches.map(match => ({
    family: extractFontFamily(match[1]),
    weights: [400, 700], // Common default weights
    source: match[1].includes("fonts.googleapis.com") ? "google-fonts" : "cdn",
  }));

  // Extract scripts
  const scriptRegex = /<script[^>]+src=["']([^"']+)["']/gi;
  const scripts = Array.from(html.matchAll(scriptRegex)).map(match => ({
    url: new URL(match[1], baseUrl).toString(),
    purpose: determineScriptPurpose(match[1]),
  }));

  return {
    images,
    fonts,
    scripts,
  };
}

function determineImagePurpose(src, alt) {
  const lowerSrc = src.toLowerCase();
  const lowerAlt = alt.toLowerCase();

  if (lowerSrc.includes("logo") || lowerAlt.includes("logo")) return "logo";
  if (lowerSrc.includes("icon") || lowerAlt.includes("icon")) return "icon";
  if (lowerSrc.includes("background") || lowerSrc.includes("bg")) return "background";

  return "content";
}

function extractFontFamily(url) {
  const familyMatch = url.match(/family=([^:&]+)/);
  return familyMatch ? familyMatch[1].replace(/\+/g, " ") : "Unknown";
}

function determineScriptPurpose(src) {
  const lowerSrc = src.toLowerCase();

  if (lowerSrc.includes("jquery")) return "jQuery library";
  if (lowerSrc.includes("analytics")) return "Analytics";
  if (lowerSrc.includes("react")) return "React framework";
  if (lowerSrc.includes("vue")) return "Vue framework";

  return "Unknown";
}
