#!/usr/bin/env -S deno run --allow-net --allow-write --allow-read
// SPDX-License-Identifier: AGPL-3.0-or-later

// Theme Extraction CLI Tool
// Usage: ./cli/extract-theme.js --url <URL> --output <FILE>

import { parseArgs } from "https://deno.land/std@0.208.0/cli/parse_args.ts";
import { extractWebsite } from "../deno/lib/scraper/mod.js";
import { formatLicenseInfo } from "../deno/lib/license-detector/mod.js";

const HELP_TEXT = `
Theme Extraction Tool - Sinople WordPress Theme

USAGE:
  ./cli/extract-theme.js --url <URL> --output <FILE> [--format <FORMAT>]

OPTIONS:
  --url <URL>         URL of the website to extract
  --output <FILE>     Output file path
  --format <FORMAT>   Output format: json (default), cue, nix
  --help              Show this help message

EXAMPLES:
  # Extract Twenty Twenty-Four theme
  ./cli/extract-theme.js \\
    --url https://wordpress.org/themes/twentytwentyfour/ \\
    --output ./extracted/twentytwentyfour.json

  # Extract with Cue schema output
  ./cli/extract-theme.js \\
    --url https://indieweb.org \\
    --output ./extracted/indieweb.cue \\
    --format cue

  # Extract IndieWeb theme
  ./cli/extract-theme.js \\
    --url https://github.com/raamdev/independent-publisher \\
    --output ./extracted/independent-publisher.json

LICENSE COMPATIBILITY:
  Only extracts from compatible licenses:
  ✅ MIT, Apache-2.0, GPL-2.0, GPL-3.0, CC-BY-4.0, CC0, etc.
  ❌ Non-commercial (CC-BY-NC), No-derivatives (CC-BY-ND), Proprietary

LEARN MORE:
  https://github.com/Hyperpolymath/wp-sinople-theme/THEME_TRANSPILATION_ARCHITECTURE.md
`;

async function main() {
  const args = parseArgs(Deno.args);

  if (args.help || !args.url || !args.output) {
    console.log(HELP_TEXT);
    Deno.exit(args.help ? 0 : 1);
  }

  const format = args.format || "json";

  console.log("\n🎨 Sinople Theme Extraction Tool\n");
  console.log(`URL: ${args.url}`);
  console.log(`Output: ${args.output}`);
  console.log(`Format: ${format}\n`);

  try {
    // Extract website
    const result = await extractWebsite(args.url);

    // Display license info
    console.log("\n📜 License Information:");
    console.log(formatLicenseInfo(result.license));

    // Display extraction summary
    console.log("\n📊 Extraction Summary:");
    console.log(`  Colors: ${result.designTokens.colors.primary.length} primary`);
    console.log(`  Typography: ${result.designTokens.typography.families.length} font families`);
    console.log(`  Semantic tags: ${result.domStructure.semanticTags.length} types`);
    console.log(`  ARIA landmarks: ${result.domStructure.ariaLandmarks.length}`);
    console.log(`  Microformats: ${result.domStructure.microformats.length}`);
    console.log(`  Images: ${result.assets.images.length}`);
    console.log(`  Fonts: ${result.assets.fonts.length}`);
    console.log(`  Scripts: ${result.assets.scripts.length}`);

    // Save output
    let output;

    if (format === "json") {
      output = JSON.stringify(result, null, 2);
    } else if (format === "cue") {
      output = convertToCue(result);
    } else if (format === "nix") {
      output = convertToNix(result);
    } else {
      throw new Error(`Unknown format: ${format}`);
    }

    await Deno.writeTextFile(args.output, output);

    console.log(`\n✅ Extraction complete: ${args.output}`);
    console.log("\n🚀 Next steps:");
    console.log("  1. Review the extracted schema");
    console.log("  2. Run transpiler: cabal run transpiler -- --schema " + args.output);
    console.log("  3. Generate ReScript theme components");
    console.log("  4. Provide feedback to improve extraction\n");
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}\n`);
    Deno.exit(1);
  }
}

/**
 * Convert extraction result to Cue schema
 */
function convertToCue(result) {
  return `// Auto-generated Cue schema
// Extracted from: ${result.url}
// Date: ${result.extractedAt}

package theme

theme: {
  metadata: {
    sourceURL: "${result.url}"
    extractedDate: "${result.extractedAt}"
    license: "${result.license.type || "Unknown"}"
  }

  designTokens: {
    colors: {
      primary: ${JSON.stringify(result.designTokens.colors.primary)}
      secondary: ${JSON.stringify(result.designTokens.colors.secondary)}
      text: ${JSON.stringify(result.designTokens.colors.text)}
      background: ${JSON.stringify(result.designTokens.colors.background)}
    }

    typography: {
      families: ${JSON.stringify(result.designTokens.typography.families)}
      baseFontSize: "${result.designTokens.typography.sizes.base}"
      scale: ${JSON.stringify(result.designTokens.typography.sizes.scale)}
    }

    spacing: {
      scale: ${JSON.stringify(result.designTokens.spacing.scale)}
    }
  }

  structure: {
    header: ${result.domStructure.hierarchy.header ? "present" : "missing"}
    navigation: ${result.domStructure.hierarchy.navigation ? "present" : "missing"}
    main: ${result.domStructure.hierarchy.main ? "present" : "missing"}
    footer: ${result.domStructure.hierarchy.footer ? "present" : "missing"}
  }

  accessibility: {
    semanticTags: ${JSON.stringify(result.domStructure.semanticTags)}
    ariaLandmarks: ${result.domStructure.ariaLandmarks.length}
    microformats: ${result.domStructure.microformats.length}
  }
}
`;
}

/**
 * Convert extraction result to Nix expression
 */
function convertToNix(result) {
  return `# Auto-generated Nix schema
# Extracted from: ${result.url}
# Date: ${result.extractedAt}

{ pkgs ? import <nixpkgs> {} }:

{
  theme = {
    metadata = {
      sourceURL = "${result.url}";
      extractedDate = "${result.extractedAt}";
      license = "${result.license.type || "Unknown"}";
    };

    designTokens = {
      colors = {
        primary = ${JSON.stringify(result.designTokens.colors.primary)};
        secondary = ${JSON.stringify(result.designTokens.colors.secondary)};
        text = ${JSON.stringify(result.designTokens.colors.text)};
        background = ${JSON.stringify(result.designTokens.colors.background)};
      };

      typography = {
        families = ${JSON.stringify(result.designTokens.typography.families)};
        baseFontSize = "${result.designTokens.typography.sizes.base}";
        scale = ${JSON.stringify(result.designTokens.typography.sizes.scale)};
      };

      spacing = {
        scale = ${JSON.stringify(result.designTokens.spacing.scale)};
      };
    };

    structure = {
      hasHeader = ${result.domStructure.hierarchy.header ? "true" : "false"};
      hasNavigation = ${result.domStructure.hierarchy.navigation ? "true" : "false"};
      hasMain = ${result.domStructure.hierarchy.main ? "true" : "false"};
      hasFooter = ${result.domStructure.hierarchy.footer ? "true" : "false"};
    };

    accessibility = {
      semanticTags = ${JSON.stringify(result.domStructure.semanticTags)};
      ariaLandmarkCount = ${result.domStructure.ariaLandmarks.length};
      microformatCount = ${result.domStructure.microformats.length};
    };
  };
}
`;
}

if (import.meta.main) {
  main();
}
