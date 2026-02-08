// SPDX-License-Identifier: AGPL-3.0-or-later
// License Detection Module
// Detects licenses from multiple sources: security.txt, LICENSE files, meta tags, WordPress headers

// SPDX license patterns
const LICENSE_PATTERNS = {
  "MIT": [
    /MIT License/i,
    /Permission is hereby granted, free of charge/i,
    /SPDX-License-Identifier:\s*MIT/i,
  ],
  "GPL-2.0-or-later": [
    /GNU General Public License.*version 2/i,
    /GPL-2\.0/i,
    /SPDX-License-Identifier:\s*GPL-2\.0/i,
  ],
  "GPL-3.0-or-later": [
    /GNU General Public License.*version 3/i,
    /GPL-3\.0/i,
    /SPDX-License-Identifier:\s*GPL-3\.0/i,
  ],
  "Apache-2.0": [
    /Apache License.*Version 2\.0/i,
    /SPDX-License-Identifier:\s*Apache-2\.0/i,
  ],
  "CC-BY-4.0": [
    /Creative Commons Attribution 4\.0/i,
    /CC BY 4\.0/i,
  ],
  "CC-BY-SA-4.0": [
    /Creative Commons Attribution-ShareAlike 4\.0/i,
    /CC BY-SA 4\.0/i,
  ],
  "CC0-1.0": [
    /Creative Commons.*Public Domain/i,
    /CC0 1\.0 Universal/i,
  ],
  "Unlicense": [
    /This is free and unencumbered software released into the public domain/i,
  ],
};

// Licenses compatible with MIT OR Palimpsest-0.8
const COMPATIBLE_LICENSES = new Set([
  "MIT",
  "Apache-2.0",
  "GPL-2.0-or-later",
  "GPL-3.0-or-later",
  "CC-BY-4.0",
  "CC-BY-SA-4.0",
  "CC0-1.0",
  "Unlicense",
  "BSD-2-Clause",
  "BSD-3-Clause",
]);

// Incompatible licenses (non-commercial, proprietary, etc.)
const INCOMPATIBLE_LICENSES = new Set([
  "CC-BY-NC-4.0", // Non-commercial
  "CC-BY-ND-4.0", // No derivatives
  "Proprietary",
  "All Rights Reserved",
]);

/**
 * Detect license from a URL by checking multiple sources
 */
export async function detectLicense(url) {
  const sources = [];

  // 1. Check /.well-known/security.txt (RFC 9116)
  try {
    const securityTxt = await fetchSecurityTxt(url);
    if (securityTxt) {
      sources.push({
        location: "/.well-known/security.txt",
        content: securityTxt,
      });
    }
  } catch {
    // security.txt not found or error
  }

  // 2. Check common LICENSE file locations
  const licenseFiles = [
    "/LICENSE",
    "/LICENSE.txt",
    "/LICENSE.md",
    "/license.txt",
    "/COPYING",
  ];

  for (const path of licenseFiles) {
    try {
      const content = await fetchText(new URL(path, url).toString());
      if (content) {
        sources.push({
          location: path,
          content,
        });
      }
    } catch {
      // File not found
    }
  }

  // 3. Check HTML page for meta tags and WordPress headers
  try {
    const html = await fetchText(url);
    if (html) {
      // Check meta tags
      const metaLicense = extractMetaLicense(html);
      if (metaLicense) {
        sources.push({
          location: "HTML meta tag",
          content: metaLicense,
        });
      }

      // Check WordPress theme header (in style.css)
      const wpHeader = extractWordPressHeader(html);
      if (wpHeader) {
        sources.push({
          location: "WordPress theme header",
          content: wpHeader,
        });
      }
    }
  } catch {
    // HTML fetch failed
  }

  // 4. For WordPress themes, check style.css directly
  try {
    const styleCss = await fetchText(new URL("/style.css", url).toString());
    if (styleCss) {
      const wpLicense = extractWordPressLicense(styleCss);
      if (wpLicense) {
        sources.push({
          location: "style.css theme header",
          content: wpLicense,
        });
      }
    }
  } catch {
    // style.css not found
  }

  // Analyze all sources and determine license
  return analyzeSources(sources);
}

/**
 * Fetch /.well-known/security.txt
 */
async function fetchSecurityTxt(url) {
  const securityUrl = new URL("/.well-known/security.txt", url).toString();
  return await fetchText(securityUrl);
}

/**
 * Fetch text content from URL
 */
async function fetchText(url) {
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": "Sinople-Theme-Extractor/1.0 (+https://github.com/Hyperpolymath/wp-sinople-theme)",
      },
    });

    if (!response.ok) {
      return null;
    }

    return await response.text();
  } catch {
    return null;
  }
}

/**
 * Extract license from HTML meta tags
 */
function extractMetaLicense(html) {
  const metaRegex = /<meta\s+name=["']license["']\s+content=["']([^"']+)["']/i;
  const match = html.match(metaRegex);
  return match ? match[1] : null;
}

/**
 * Extract WordPress theme header from HTML
 */
function extractWordPressHeader(html) {
  // Look for WordPress theme info in comments or inline styles
  const wpRegex = /Theme Name:([^\n]+)|License:([^\n]+)/gi;
  const matches = html.match(wpRegex);
  return matches ? matches.join("\n") : null;
}

/**
 * Extract license from WordPress style.css theme header
 */
function extractWordPressLicense(styleCss) {
  // WordPress theme headers are in the first comment block
  const headerRegex = /\/\*\s*([\s\S]*?)\*\//;
  const match = styleCss.match(headerRegex);

  if (!match) return null;

  const header = match[1];
  const licenseRegex = /License:\s*(.+)/i;
  const licenseMatch = header.match(licenseRegex);

  return licenseMatch ? licenseMatch[1].trim() : null;
}

/**
 * Analyze sources and determine license type
 */
function analyzeSources(sources) {
  if (sources.length === 0) {
    return {
      detected: false,
      type: null,
      compatible: false,
      sources: [],
    };
  }

  // Check each source against known license patterns
  const detections = [];

  for (const source of sources) {
    for (const [licenseType, patterns] of Object.entries(LICENSE_PATTERNS)) {
      let matchCount = 0;

      for (const pattern of patterns) {
        if (pattern.test(source.content)) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        const confidence = matchCount / patterns.length;
        detections.push({
          location: source.location,
          content: source.content,
          type: licenseType,
          confidence,
        });
      }
    }
  }

  if (detections.length === 0) {
    return {
      detected: false,
      type: null,
      compatible: false,
      sources: sources.map(s => ({
        location: s.location,
        content: s.content.substring(0, 200), // Truncate
        confidence: 0.0,
      })),
    };
  }

  // Sort by confidence and take the highest
  detections.sort((a, b) => b.confidence - a.confidence);
  const bestMatch = detections[0];

  return {
    detected: true,
    type: bestMatch.type,
    compatible: COMPATIBLE_LICENSES.has(bestMatch.type),
    sources: detections.map(d => ({
      location: d.location,
      content: d.content.substring(0, 200), // Truncate for readability
      confidence: d.confidence,
    })),
  };
}

/**
 * Check if a license is compatible with extraction
 */
export function isLicenseCompatible(licenseType) {
  if (!licenseType) return false;
  return COMPATIBLE_LICENSES.has(licenseType);
}

/**
 * Format license info for human-readable output
 */
export function formatLicenseInfo(info) {
  if (!info.detected) {
    return "❌ No license detected\nFound sources:\n" +
      info.sources.map(s => `  - ${s.location}`).join("\n");
  }

  const compatEmoji = info.compatible ? "✅" : "⚠️";
  const compatText = info.compatible
    ? "Compatible with extraction"
    : "Incompatible - extraction not allowed";

  return `
${compatEmoji} License: ${info.type}
${compatText}

Sources (${info.sources.length}):
${info.sources.map(s =>
  `  - ${s.location} (confidence: ${(s.confidence * 100).toFixed(0)}%)`
).join("\n")}
  `.trim();
}
