# Theme Transpilation Architecture

**Status**: 🚧 **Work in Progress** 🚧
**Version**: 0.1.0-alpha
**Last Updated**: 2025-11-23

---

## Vision

Build a **self-learning theme generation system** that can:

1. **Analyze** any WordPress theme (or website) and extract its design patterns
2. **Validate** licensing to ensure legal compliance
3. **Transform** the design using schema-based transpilation
4. **Generate** ReScript/WASM-powered themes with Sinople's semantic features
5. **Learn** from user feedback to improve extraction/generation over time

### Ultimate Goal

Enable users to:
- Recreate **every WordPress official theme** (2003-present) with modern stack
- Import **IndieWeb themes** (Independent Publisher, Doubleloop, etc.)
- **Extract any website design** (with proper licensing) and convert to Sinople format
- **Train ML models** to automatically generate themes from descriptions or screenshots

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Web Scraper + Analyzer                      │
│  (Deno-based, respects robots.txt, checks licensing)            │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ├─► License Detection (security.txt, LICENSE, meta)
                 ├─► DOM Structure Extraction (HTML hierarchy)
                 ├─► CSS Analysis (design tokens, colors, typography)
                 └─► Asset Catalog (images, fonts, scripts)
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Cue/Nix Schema Generator                      │
│  (Converts extracted data to structured schema)                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              Haskell Transpiler (Schema → ReScript)              │
│  (Type-safe transformation with validation)                     │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│           ReScript Theme Generator + WASM Integration            │
│  (Produces Sinople-compatible theme with semantic features)     │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              Feedback Collection System                          │
│  (JSON/YAML/Web UI/API - feeds into ML training)                │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│        ML Training Pipeline (LSM + Julia/Logtalk)                │
│  (Supervised learning for automated theme generation)           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Component 1: Web Scraper + Analyzer

### Technology Stack
- **Deno**: HTTP client with fetch API
- **TypeScript/ReScript**: Type-safe scraping logic
- **Deno DOM**: HTML parsing (https://deno.land/x/deno_dom)
- **CSS Parser**: PostCSS or similar

### Responsibilities

#### 1.1 License Detection
```typescript
// Checks multiple sources for license information
interface LicenseInfo {
  detected: boolean;
  type: string | null;  // MIT, GPL-2.0, CC-BY-SA, etc.
  compatible: boolean;  // Compatible with dual MIT/Palimpsest?
  sources: Array<{
    location: string;  // security.txt, LICENSE file, meta tag
    content: string;
    confidence: number;  // 0.0-1.0
  }>;
}

async function detectLicense(url: string): Promise<LicenseInfo> {
  // 1. Check /.well-known/security.txt (RFC 9116)
  // 2. Check /LICENSE, /LICENSE.txt, /LICENSE.md
  // 3. Check HTML meta tags (<meta name="license" content="...">)
  // 4. Check WordPress theme headers (style.css)
  // 5. Use SPDX license detector library
}
```

**Allowed Licenses** (for extraction):
- MIT
- Apache 2.0
- GPL-2.0-or-later
- GPL-3.0-or-later
- CC-BY-4.0, CC-BY-SA-4.0
- Public Domain (CC0, Unlicense)

**Rejected Licenses**:
- CC-BY-NC (non-commercial)
- Proprietary/All Rights Reserved
- Unknown/No license

#### 1.2 DOM Structure Extraction

```typescript
interface DOMStructure {
  hierarchy: {
    header: ElementNode;
    navigation: ElementNode;
    main: ElementNode;
    sidebar?: ElementNode;
    footer: ElementNode;
  };
  semanticTags: string[];  // article, section, aside, nav, etc.
  ariaLandmarks: Array<{role: string; label: string}>;
  microformats: Array<{type: string; properties: Record<string, any>}>;
}

interface ElementNode {
  tag: string;
  classes: string[];
  id?: string;
  attributes: Record<string, string>;
  children: ElementNode[];
  textContent?: string;
}
```

#### 1.3 CSS Analysis

```typescript
interface DesignTokens {
  colors: {
    primary: string[];
    secondary: string[];
    text: string[];
    background: string[];
    accent: string[];
  };
  typography: {
    families: string[];
    sizes: {base: string; scale: number[]};
    lineHeights: number[];
    weights: number[];
  };
  spacing: {
    scale: number[];  // 0.25rem, 0.5rem, 1rem, 1.5rem, etc.
  };
  breakpoints: {
    mobile: string;
    tablet: string;
    desktop: string;
  };
  layout: {
    maxWidth: string;
    gridColumns: number;
    gridGap: string;
  };
}

async function extractDesignTokens(cssText: string): Promise<DesignTokens>
```

**WCAG AAA Validation**:
- Check all color combinations for 7:1 contrast ratio
- Flag violations in feedback system
- Suggest accessible alternatives

#### 1.4 Asset Catalog

```typescript
interface AssetCatalog {
  images: Array<{
    url: string;
    alt: string;
    purpose: 'logo' | 'icon' | 'background' | 'content';
    dimensions?: {width: number; height: number};
  }>;
  fonts: Array<{
    family: string;
    weights: number[];
    source: 'google-fonts' | 'local' | 'cdn';
    license: string;
  }>;
  scripts: Array<{
    url: string;
    purpose: string;
    license: string;
  }>;
}
```

---

## Component 2: Cue Schema Generator

### Why Cue?

[Cue](https://cuelang.org/) provides:
- Type-safe schema definitions
- Validation built-in
- JSON/YAML export
- Excellent for configuration management

### Theme Schema Structure

```cue
// theme-schema.cue
#Theme: {
  metadata: {
    name: string
    version: string & =~"^[0-9]+\\.[0-9]+\\.[0-9]+$"
    author: string
    license: "MIT" | "GPL-2.0" | "GPL-3.0" | "Apache-2.0"
    sourceURL: string
    extractedDate: string
  }

  designTokens: {
    colors: {
      primary: string & =~"^#[0-9a-fA-F]{6}$"
      secondary: string & =~"^#[0-9a-fA-F]{6}$"
      text: string & =~"^#[0-9a-fA-F]{6}$"
      background: string & =~"^#[0-9a-fA-F]{6}$"
      // ... more colors
    }

    typography: {
      baseFontSize: string & =~"^[0-9]+(px|rem|em)$"
      fontFamily: string
      lineHeight: number & >=1.0 & <=2.0
      scale: [...number]
    }

    spacing: {
      scale: [...number]  // Must be positive
      maxWidth: string
    }

    breakpoints: {
      mobile: string & =~"^[0-9]+(px|em|rem)$"
      tablet: string & =~"^[0-9]+(px|em|rem)$"
      desktop: string & =~"^[0-9]+(px|em|rem)$"
    }
  }

  structure: {
    header: #ComponentStructure
    navigation: #ComponentStructure
    main: #ComponentStructure
    sidebar?: #ComponentStructure
    footer: #ComponentStructure
  }

  templates: {
    index: #TemplateStructure
    single: #TemplateStructure
    archive: #TemplateStructure
    page: #TemplateStructure
    search: #TemplateStructure
    404: #TemplateStructure
  }

  customPostTypes?: [...#CustomPostType]

  accessibility: {
    wcagLevel: "A" | "AA" | "AAA"
    contrastChecked: bool
    keyboardNavigable: bool
    screenReaderOptimized: bool
  }
}

#ComponentStructure: {
  tag: string
  classes: [...string]
  attributes: [string]: string
  children: [...#ComponentStructure]
}

#TemplateStructure: {
  layout: string
  components: [...string]
  hooks: [...string]
}

#CustomPostType: {
  name: string
  slug: string
  supports: [...string]
  taxonomies: [...string]
}
```

### Alternative: Nix Schema

For those preferring Nix:

```nix
# theme-schema.nix
{ pkgs ? import <nixpkgs> {} }:

{
  theme = {
    metadata = {
      name = "Twenty Twenty-Four";
      version = "1.0.0";
      author = "WordPress.org";
      license = "GPL-2.0-or-later";
      sourceURL = "https://wordpress.org/themes/twentytwentyfour/";
    };

    designTokens = {
      colors = {
        primary = "#000000";
        secondary = "#FFFFFF";
        # ...
      };
      # ...
    };

    structure = {
      header = {
        tag = "header";
        classes = [ "site-header" ];
        children = [ /* ... */ ];
      };
      # ...
    };
  };
}
```

---

## Component 3: Haskell Transpiler

### Why Haskell?

- **Type safety**: Strong static typing ensures correctness
- **Functional purity**: Predictable transformations
- **Pattern matching**: Easy to handle complex schema structures
- **WASM compilation**: Can compile to WASM with Asterius

### Architecture

```haskell
-- src/Transpiler/Main.hs
module Transpiler.Main where

import qualified Data.Aeson as JSON
import qualified Data.Text as T
import qualified Transpiler.Schema as Schema
import qualified Transpiler.ReScript as ReScript
import qualified Transpiler.WordPress as WordPress

-- Main pipeline
transpileTheme :: FilePath -> IO (Either Error ThemeOutput)
transpileTheme schemaPath = do
  -- 1. Load Cue/Nix schema
  schema <- Schema.load schemaPath

  -- 2. Validate schema
  validated <- Schema.validate schema

  -- 3. Generate ReScript components
  rescriptComponents <- ReScript.generateComponents validated

  -- 4. Generate WordPress PHP templates
  wpTemplates <- WordPress.generateTemplates validated

  -- 5. Generate CSS from design tokens
  css <- CSS.generateFromTokens (Schema.designTokens validated)

  -- 6. Combine into theme package
  pure $ ThemeOutput {
    rescript = rescriptComponents,
    wordpress = wpTemplates,
    css = css,
    metadata = Schema.metadata validated
  }

-- Example: Convert design tokens to ReScript
data DesignTokens = DesignTokens {
  colors :: ColorPalette,
  typography :: Typography,
  spacing :: SpacingScale
}

generateReScriptModule :: DesignTokens -> T.Text
generateReScriptModule tokens =
  T.unlines [
    "// Auto-generated from theme schema",
    "module DesignTokens = {",
    "  module Colors = {",
    generateColorBindings (colors tokens),
    "  }",
    "  module Typography = {",
    generateTypographyBindings (typography tokens),
    "  }",
    "}"
  ]

generateColorBindings :: ColorPalette -> T.Text
generateColorBindings palette =
  T.unlines $ map (\(name, hex) ->
    T.concat ["    let ", name, " = \"", hex, "\""]
  ) (toList palette)
```

### Type Definitions

```haskell
-- src/Transpiler/Schema.hs
module Transpiler.Schema where

import Data.Aeson (FromJSON, ToJSON)
import GHC.Generics (Generic)

data ThemeSchema = ThemeSchema {
  metadata :: Metadata,
  designTokens :: DesignTokens,
  structure :: ComponentStructure,
  templates :: Templates,
  customPostTypes :: Maybe [CustomPostType],
  accessibility :: AccessibilityConfig
} deriving (Show, Eq, Generic)

instance FromJSON ThemeSchema
instance ToJSON ThemeSchema

data Metadata = Metadata {
  name :: Text,
  version :: Version,
  author :: Text,
  license :: License,
  sourceURL :: Text,
  extractedDate :: UTCTime
} deriving (Show, Eq, Generic)

data License = MIT | GPL2 | GPL3 | Apache2 | CCBY4
  deriving (Show, Eq, Generic, FromJSON, ToJSON)
```

### ReScript Code Generation

```haskell
-- src/Transpiler/ReScript.hs
module Transpiler.ReScript where

generateComponents :: ThemeSchema -> IO [ReScriptModule]
generateComponents schema = do
  let tokens = designTokens schema
      struct = structure schema

  pure [
    generateDesignTokensModule tokens,
    generateLayoutModule struct,
    generateComponentsModule struct,
    generateTemplatesModule (templates schema)
  ]

data ReScriptModule = ReScriptModule {
  moduleName :: Text,
  moduleContent :: Text,
  filePath :: FilePath
}

generateDesignTokensModule :: DesignTokens -> ReScriptModule
generateDesignTokensModule tokens = ReScriptModule {
  moduleName = "DesignTokens",
  moduleContent = renderTemplate tokensTemplate tokens,
  filePath = "src/generated/DesignTokens.res"
}
```

---

## Component 4: CSS/HTML Design Extraction

### CSS Parser

```typescript
// deno/lib/css-parser.ts
import { parse } from "https://esm.sh/postcss@8.4.31";

interface CSSRule {
  selector: string;
  properties: Record<string, string>;
}

export async function extractCSSRules(cssText: string): Promise<CSSRule[]> {
  const ast = parse(cssText);
  const rules: CSSRule[] = [];

  ast.walkRules((rule) => {
    const properties: Record<string, string> = {};
    rule.walkDecls((decl) => {
      properties[decl.prop] = decl.value;
    });

    rules.push({
      selector: rule.selector,
      properties
    });
  });

  return rules;
}

export function detectDesignSystem(rules: CSSRule[]): DesignTokens {
  // 1. Extract color palette (all color values)
  const colors = new Set<string>();

  // 2. Extract typography (font-family, font-size, line-height)
  const typography = {
    families: new Set<string>(),
    sizes: new Set<string>(),
    lineHeights: new Set<string>(),
  };

  // 3. Extract spacing (margin, padding values)
  const spacing = new Set<string>();

  for (const rule of rules) {
    for (const [prop, value] of Object.entries(rule.properties)) {
      // Color extraction
      if (prop.includes('color') || prop.includes('background')) {
        extractColors(value).forEach(c => colors.add(c));
      }

      // Typography
      if (prop === 'font-family') {
        typography.families.add(value);
      }
      if (prop === 'font-size') {
        typography.sizes.add(value);
      }
      if (prop === 'line-height') {
        typography.lineHeights.add(value);
      }

      // Spacing
      if (prop === 'margin' || prop === 'padding') {
        extractSpacing(value).forEach(s => spacing.add(s));
      }
    }
  }

  return {
    colors: categorizeColors(Array.from(colors)),
    typography: {
      families: Array.from(typography.families),
      sizes: detectModularScale(Array.from(typography.sizes)),
      lineHeights: Array.from(typography.lineHeights).map(Number),
    },
    spacing: {
      scale: detectSpacingScale(Array.from(spacing)),
    },
  };
}
```

### DOM Structure Analyzer

```typescript
// deno/lib/dom-analyzer.ts
import { DOMParser } from "https://deno.land/x/deno_dom/deno-dom-wasm.ts";

export async function analyzeDOMStructure(html: string): Promise<DOMStructure> {
  const doc = new DOMParser().parseFromString(html, "text/html");

  if (!doc) {
    throw new Error("Failed to parse HTML");
  }

  return {
    hierarchy: {
      header: extractElement(doc.querySelector('header')),
      navigation: extractElement(doc.querySelector('nav')),
      main: extractElement(doc.querySelector('main') || doc.querySelector('#main')),
      sidebar: extractElement(doc.querySelector('aside') || doc.querySelector('.sidebar')),
      footer: extractElement(doc.querySelector('footer')),
    },
    semanticTags: extractSemanticTags(doc),
    ariaLandmarks: extractARIALandmarks(doc),
    microformats: extractMicroformats(doc),
  };
}

function extractElement(el: Element | null): ElementNode | null {
  if (!el) return null;

  return {
    tag: el.tagName.toLowerCase(),
    classes: Array.from(el.classList),
    id: el.id || undefined,
    attributes: extractAttributes(el),
    children: Array.from(el.children).map(extractElement).filter(Boolean),
    textContent: el.textContent?.trim(),
  };
}
```

---

## Component 5: Feedback Collection System

### Multi-Format Feedback

#### 5.1 JSON Feedback API

```typescript
// deno/routes/api/feedback/theme.ts
export const handler: Handlers = {
  async POST(req, ctx) {
    const feedback: ThemeFeedback = await req.json();

    // Validate feedback schema
    const validated = await validateFeedback(feedback);

    // Store in database (Deno KV or PostgreSQL)
    await storeFeedback(validated);

    // Enqueue for ML training
    await enqueueForTraining(validated);

    return new Response(JSON.stringify({ success: true }), {
      status: 201,
      headers: { "Content-Type": "application/json" },
    });
  }
};

interface ThemeFeedback {
  themeId: string;
  sourceURL: string;
  extractionQuality: {
    colors: 1 | 2 | 3 | 4 | 5;  // 1=poor, 5=excellent
    typography: 1 | 2 | 3 | 4 | 5;
    layout: 1 | 2 | 3 | 4 | 5;
    overall: 1 | 2 | 3 | 4 | 5;
  };
  correctness: {
    licenseDetection: boolean;
    colorExtraction: boolean;
    structureMapping: boolean;
  };
  improvements: string;  // Free-text suggestions
  examples?: {
    before: string;  // Screenshot URL
    after: string;   // Screenshot URL
  };
  timestamp: string;
  userId?: string;
}
```

#### 5.2 YAML Feedback Format

```yaml
# feedback/theme-extraction-001.yaml
theme_id: "twentytwentyfour-extraction-001"
source_url: "https://wordpress.org/themes/twentytwentyfour/"
extracted_date: "2025-11-23T10:00:00Z"

extraction_quality:
  colors: 5
  typography: 4
  layout: 5
  overall: 4

correctness:
  license_detection: true
  color_extraction: true
  structure_mapping: false  # Header structure was incorrect

improvements: |
  The header navigation structure was not correctly identified.
  Expected: header > nav > ul > li
  Extracted: header > div > nav > ul > li

  Color extraction was excellent, all shades detected.
  Typography extraction missed custom font weights.

corrections:
  - path: "structure.header"
    expected:
      tag: "header"
      children:
        - tag: "nav"
          children:
            - tag: "ul"
    actual:
      tag: "header"
      children:
        - tag: "div"
          children:
            - tag: "nav"

examples:
  before: "https://example.com/screenshots/before.png"
  after: "https://example.com/screenshots/after.png"

user_id: "user-12345"
timestamp: "2025-11-23T10:30:00Z"
```

#### 5.3 Web UI Feedback Form

```typescript
// deno/islands/FeedbackForm.tsx
import { useState } from "preact/hooks";

export default function ThemeFeedbackForm({ themeId }: { themeId: string }) {
  const [ratings, setRatings] = useState({
    colors: 3,
    typography: 3,
    layout: 3,
    overall: 3,
  });

  const [correctness, setCorrectness] = useState({
    licenseDetection: true,
    colorExtraction: true,
    structureMapping: true,
  });

  const [improvements, setImprovements] = useState("");

  const handleSubmit = async (e: Event) => {
    e.preventDefault();

    const feedback = {
      themeId,
      extractionQuality: ratings,
      correctness,
      improvements,
      timestamp: new Date().toISOString(),
    };

    await fetch("/api/feedback/theme", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(feedback),
    });

    alert("Thank you for your feedback!");
  };

  return (
    <form onSubmit={handleSubmit} class="feedback-form">
      <h2>Theme Extraction Feedback</h2>

      <section>
        <h3>Extraction Quality (1-5)</h3>

        <label>
          Colors:
          <input
            type="range"
            min="1"
            max="5"
            value={ratings.colors}
            onChange={(e) => setRatings({...ratings, colors: parseInt(e.currentTarget.value)})}
          />
          <span>{ratings.colors}</span>
        </label>

        {/* Similar for typography, layout, overall */}
      </section>

      <section>
        <h3>Correctness</h3>

        <label>
          <input
            type="checkbox"
            checked={correctness.licenseDetection}
            onChange={(e) => setCorrectness({...correctness, licenseDetection: e.currentTarget.checked})}
          />
          License Detection Correct
        </label>

        {/* Similar for other correctness fields */}
      </section>

      <section>
        <h3>Improvements</h3>
        <textarea
          value={improvements}
          onChange={(e) => setImprovements(e.currentTarget.value)}
          placeholder="Describe any issues or suggestions..."
          rows={6}
        />
      </section>

      <button type="submit">Submit Feedback</button>
    </form>
  );
}
```

---

## Component 6: ML Training Pipeline

### Architecture: LSM + Julia/Logtalk + Supervised Learning

#### 6.1 Liquid State Machine (LSM)

LSMs are a type of spiking neural network ideal for temporal pattern recognition.

**Use Case**: Recognize patterns in theme structure evolution over time.

```julia
# ml/lsm/theme_recognizer.jl
using SpikingNeuralNetworks
using MLDatasets

struct ThemeLSM
    reservoir::LiquidStateReservoir
    readout::LinearReadout
end

function create_theme_lsm(input_size::Int, reservoir_size::Int, output_size::Int)
    # Create liquid state reservoir (randomly connected spiking neurons)
    reservoir = LiquidStateReservoir(
        input_size,
        reservoir_size,
        connection_prob=0.3,
        spectral_radius=0.9
    )

    # Linear readout layer
    readout = LinearReadout(reservoir_size, output_size)

    ThemeLSM(reservoir, readout)
end

function train_lsm!(lsm::ThemeLSM, training_data::Vector{ThemeExample})
    for example in training_data
        # Convert theme structure to spike train
        spikes = encode_theme_to_spikes(example.structure)

        # Feed through reservoir
        reservoir_state = lsm.reservoir(spikes)

        # Train readout layer
        predicted = lsm.readout(reservoir_state)
        loss = mse_loss(predicted, example.target)

        # Update readout weights (reservoir stays fixed)
        update_weights!(lsm.readout, loss)
    end
end

function encode_theme_to_spikes(structure::DOMStructure)::SpikeTrainVector
    # Convert DOM hierarchy to temporal spike patterns
    # Each element type -> specific neuron
    # Nesting depth -> spike timing
    spikes = SpikeTrainVector()

    traverse_structure(structure, 0.0) do element, time
        neuron_id = element_to_neuron_mapping[element.tag]
        push!(spikes, Spike(neuron_id, time))
    end

    return spikes
end
```

#### 6.2 Logtalk Logic Programming

**Use Case**: Declarative rules for theme structure validation and correction.

```logtalk
% ml/logtalk/theme_rules.lgt

:- object(theme_validator).

    % Valid theme structure rules
    :- public(valid_theme/1).
    valid_theme(Theme) :-
        has_header(Theme),
        has_navigation(Theme),
        has_main_content(Theme),
        has_footer(Theme),
        wcag_compliant(Theme).

    % WCAG AAA compliance rules
    :- public(wcag_compliant/1).
    wcag_compliant(Theme) :-
        contrast_ratio_aaa(Theme),
        keyboard_navigable(Theme),
        screen_reader_compatible(Theme),
        no_motion_without_preference(Theme).

    % Color contrast checking
    contrast_ratio_aaa(Theme) :-
        theme_colors(Theme, Colors),
        forall(
            (member(Foreground, Colors), member(Background, Colors)),
            contrast_ratio(Foreground, Background, Ratio),
            Ratio >= 7.0
        ).

    % Structure correction suggestions
    :- public(suggest_corrections/2).
    suggest_corrections(Theme, Corrections) :-
        findall(
            Correction,
            (
                theme_issue(Theme, Issue),
                correction_for_issue(Issue, Correction)
            ),
            Corrections
        ).

    theme_issue(Theme, missing_header) :-
        \+ has_header(Theme).

    theme_issue(Theme, low_contrast(Color1, Color2)) :-
        theme_colors(Theme, Colors),
        member(Color1, Colors),
        member(Color2, Colors),
        contrast_ratio(Color1, Color2, Ratio),
        Ratio < 7.0.

    correction_for_issue(missing_header, add_header_element).
    correction_for_issue(low_contrast(C1, C2), adjust_color(C1, C2)).

:- end_object.
```

#### 6.3 Julia AI Supervised Learning

**Use Case**: Train model to predict optimal ReScript code from schema.

```julia
# ml/julia/theme_generator.jl
using Flux
using BSON
using JSON

struct ThemeGeneratorModel
    encoder::Chain
    decoder::Chain
end

function create_theme_generator()
    # Encoder: Theme schema -> latent representation
    encoder = Chain(
        Dense(512, 256, relu),
        Dense(256, 128, relu),
        Dense(128, 64, tanh)
    )

    # Decoder: Latent representation -> ReScript code (token sequence)
    decoder = Chain(
        LSTM(64, 128),
        LSTM(128, 256),
        Dense(256, vocab_size, softmax)
    )

    ThemeGeneratorModel(encoder, decoder)
end

function train_generator!(model::ThemeGeneratorModel, training_data::Vector{ThemeTrainingExample})
    opt = ADAM(0.001)

    for epoch in 1:100
        total_loss = 0.0

        for example in training_data
            # Encode schema to latent vector
            schema_vector = schema_to_vector(example.schema)
            latent = model.encoder(schema_vector)

            # Decode to ReScript token sequence
            predicted_tokens = model.decoder(latent)

            # Compare with actual ReScript code
            target_tokens = tokenize_rescript(example.rescript_code)
            loss = crossentropy(predicted_tokens, target_tokens)

            # Backpropagation
            Flux.train!(loss, params(model), [(schema_vector, target_tokens)], opt)

            total_loss += loss
        end

        println("Epoch $epoch: Loss = $(total_loss / length(training_data))")
    end
end

function generate_rescript(model::ThemeGeneratorModel, schema::ThemeSchema)::String
    schema_vector = schema_to_vector(schema)
    latent = model.encoder(schema_vector)
    token_sequence = model.decoder(latent)

    # Decode tokens back to ReScript source code
    detokenize_rescript(token_sequence)
end

struct ThemeTrainingExample
    schema::ThemeSchema
    rescript_code::String
    user_rating::Float64  # From feedback system
end
```

#### 6.4 Training Data Pipeline

```typescript
// ml/pipeline/training-data-collector.ts
import { Database } from "https://deno.land/x/denodb/mod.ts";

interface TrainingDataPoint {
  id: string;
  schema: ThemeSchema;
  generatedReScript: string;
  userFeedback: ThemeFeedback;
  rating: number;  // Derived from feedback
  timestamp: string;
}

export async function collectTrainingData(): Promise<TrainingDataPoint[]> {
  const db = await Database.connect();

  // Get all theme extractions with user feedback
  const data = await db.query(`
    SELECT
      e.id,
      e.schema,
      e.generated_rescript,
      f.extraction_quality,
      f.correctness,
      f.improvements
    FROM theme_extractions e
    JOIN feedback f ON e.id = f.theme_id
    WHERE f.extraction_quality.overall >= 3
  `);

  return data.map(row => ({
    id: row.id,
    schema: JSON.parse(row.schema),
    generatedReScript: row.generated_rescript,
    userFeedback: row,
    rating: calculateRating(row),
    timestamp: row.created_at,
  }));
}

function calculateRating(feedback: any): number {
  // Weighted average of quality scores
  const weights = {
    colors: 0.25,
    typography: 0.25,
    layout: 0.30,
    overall: 0.20,
  };

  return (
    feedback.extraction_quality.colors * weights.colors +
    feedback.extraction_quality.typography * weights.typography +
    feedback.extraction_quality.layout * weights.layout +
    feedback.extraction_quality.overall * weights.overall
  );
}

// Export training data for Julia/Logtalk
export async function exportForMLTraining(outputDir: string) {
  const data = await collectTrainingData();

  // Export as JSON for Julia
  await Deno.writeTextFile(
    `${outputDir}/training-data.json`,
    JSON.stringify(data, null, 2)
  );

  // Export as CSV for easy loading
  const csv = convertToCSV(data);
  await Deno.writeTextFile(`${outputDir}/training-data.csv`, csv);

  // Export Logtalk facts
  const logTalkFacts = convertToLogTalkFacts(data);
  await Deno.writeTextFile(`${outputDir}/training-facts.lgt`, logTalkFacts);
}
```

---

## Component 7: WordPress Theme Catalog

### Official WordPress Themes (2003-Present)

```typescript
// data/wordpress-themes-catalog.ts
export const WORDPRESS_OFFICIAL_THEMES = [
  // 2003-2010: The early years
  { year: 2003, name: "Default (Kubrick)", slug: "kubrick", license: "GPL-2.0" },
  { year: 2010, name: "Twenty Ten", slug: "twentyten", license: "GPL-2.0" },
  { year: 2011, name: "Twenty Eleven", slug: "twentyeleven", license: "GPL-2.0" },

  // 2012-2020: Annual releases
  { year: 2012, name: "Twenty Twelve", slug: "twentytwelve", license: "GPL-2.0" },
  { year: 2013, name: "Twenty Thirteen", slug: "twentythirteen", license: "GPL-2.0" },
  { year: 2014, name: "Twenty Fourteen", slug: "twentyfourteen", license: "GPL-2.0" },
  { year: 2015, name: "Twenty Fifteen", slug: "twentyfifteen", license: "GPL-2.0" },
  { year: 2016, name: "Twenty Sixteen", slug: "twentysixteen", license: "GPL-2.0" },
  { year: 2017, name: "Twenty Seventeen", slug: "twentyseventeen", license: "GPL-2.0" },
  { year: 2019, name: "Twenty Nineteen", slug: "twentynineteen", license: "GPL-2.0" },
  { year: 2020, name: "Twenty Twenty", slug: "twentytwenty", license: "GPL-2.0" },

  // 2021-Present: Block themes
  { year: 2021, name: "Twenty Twenty-One", slug: "twentytwentyone", license: "GPL-2.0" },
  { year: 2022, name: "Twenty Twenty-Two", slug: "twentytwentytwo", license: "GPL-2.0" },
  { year: 2023, name: "Twenty Twenty-Three", slug: "twentytwentythree", license: "GPL-2.0" },
  { year: 2024, name: "Twenty Twenty-Four", slug: "twentytwentyfour", license: "GPL-2.0" },
];

export async function downloadOfficialTheme(slug: string): Promise<string> {
  const url = `https://downloads.wordpress.org/theme/${slug}.latest.zip`;
  const response = await fetch(url);

  if (!response.ok) {
    throw new Error(`Failed to download theme ${slug}`);
  }

  return await response.text();
}
```

### IndieWeb Themes

```typescript
// data/indieweb-themes-catalog.ts
export const INDIEWEB_THEMES = [
  {
    name: "Independent Publisher",
    slug: "independent-publisher",
    license: "GPL-2.0",
    url: "https://github.com/raamdev/independent-publisher",
    features: ["webmention", "microformats2", "indieauth"],
    maintained: true,
  },
  {
    name: "Independent Publisher 2",
    slug: "independent-publisher-2",
    license: "GPL-2.0",
    url: "https://wordpress.org/themes/independent-publisher-2/",
    features: ["webmention", "microformats2", "post-kinds"],
    maintained: true,
  },
  {
    name: "SemPress",
    slug: "sempress",
    license: "GPL-2.0",
    url: "https://wordpress.org/themes/sempress/",
    features: ["microformats2", "semantic-html"],
    maintained: true,
  },
  {
    name: "Autonomie",
    slug: "autonomie",
    license: "GPL-2.0",
    url: "https://wordpress.org/themes/autonomie/",
    features: ["microformats2", "indieweb-friendly"],
    maintained: true,
  },
  {
    name: "Doublespace",
    slug: "doublespace",
    license: "MIT",
    url: "https://github.com/cleverdevil/doublespace",
    features: ["microformats2", "micropub", "webmention"],
    maintained: false,  // Last updated 2018
  },
];
```

---

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2) ✅ Started
- [x] Create architecture document (this file)
- [ ] Set up Deno web scraper with license detection
- [ ] Implement basic CSS/DOM extraction
- [ ] Create Cue schema definitions

### Phase 2: Transpiler (Weeks 3-4)
- [ ] Build Haskell transpiler skeleton
- [ ] Implement schema → ReScript transformation
- [ ] Implement schema → WordPress PHP transformation
- [ ] Add CSS generation from design tokens

### Phase 3: Theme Catalog (Weeks 5-6)
- [ ] Download and analyze WordPress official themes
- [ ] Extract IndieWeb themes
- [ ] Create theme database with metadata
- [ ] Generate initial schemas for 5-10 themes

### Phase 4: Feedback System (Weeks 7-8)
- [ ] Build JSON/YAML feedback API
- [ ] Create web UI feedback form
- [ ] Set up database for feedback storage
- [ ] Implement feedback aggregation

### Phase 5: ML Pipeline (Weeks 9-12)
- [ ] Set up Julia environment
- [ ] Implement LSM for pattern recognition
- [ ] Create Logtalk validation rules
- [ ] Train initial supervised learning model
- [ ] Integrate feedback into training loop

### Phase 6: Integration (Weeks 13-14)
- [ ] Connect all components into single pipeline
- [ ] Create CLI tool for theme extraction
- [ ] Build web dashboard for theme library
- [ ] Write comprehensive documentation

### Phase 7: Production (Weeks 15-16)
- [ ] Deploy to production environment
- [ ] Set up continuous training pipeline
- [ ] Create public API for theme generation
- [ ] Launch with initial 20+ themes

---

## Usage Examples

### Example 1: Extract WordPress Theme

```bash
# Using CLI tool
deno run --allow-net --allow-write \
  ./cli/extract-theme.ts \
  --url https://wordpress.org/themes/twentytwentyfour/ \
  --output ./extracted/twentytwentyfour.cue

# Output:
# ✓ License detected: GPL-2.0-or-later (compatible)
# ✓ Downloaded theme files
# ✓ Extracted design tokens (32 colors, 8 typography sizes)
# ✓ Analyzed DOM structure (12 components)
# ✓ Generated Cue schema: ./extracted/twentytwentyfour.cue
```

### Example 2: Transpile Schema to ReScript

```bash
# Using Haskell transpiler
cabal run transpiler -- \
  --schema ./extracted/twentytwentyfour.cue \
  --output ./generated/twentytwentyfour/

# Output:
# ✓ Validated schema
# ✓ Generated ReScript modules (8 files)
# ✓ Generated WordPress templates (12 files)
# ✓ Generated CSS (3,420 lines)
# ✓ Theme package: ./generated/twentytwentyfour/
```

### Example 3: Provide Feedback

```bash
# Using API
curl -X POST https://sinople.org/api/feedback/theme \
  -H "Content-Type: application/json" \
  -d '{
    "themeId": "twentytwentyfour-001",
    "extractionQuality": {
      "colors": 5,
      "typography": 4,
      "layout": 5,
      "overall": 5
    },
    "correctness": {
      "licenseDetection": true,
      "colorExtraction": true,
      "structureMapping": true
    },
    "improvements": "Excellent extraction! Minor issue with font weight detection."
  }'

# Response:
# {"success": true, "id": "feedback-12345"}
```

### Example 4: Train ML Model

```bash
# Collect training data
deno run --allow-net --allow-write \
  ./ml/pipeline/collect-training-data.ts \
  --output ./ml/data/training-2025-11-23.json

# Train Julia model
cd ml/julia
julia --project=. train.jl --data ../data/training-2025-11-23.json

# Output:
# Epoch 1: Loss = 0.456
# Epoch 2: Loss = 0.321
# ...
# Epoch 100: Loss = 0.042
# ✓ Model saved to: ./models/theme-generator-v1.bson
```

---

## Current Status

### Implemented ✅
- Architecture documentation (this file)
- Project vision and roadmap

### In Progress 🚧
- Deno web scraper skeleton
- Cue schema definitions
- Basic license detection

### TODO 📋
- Haskell transpiler
- ML training pipeline
- Theme catalog
- Feedback system
- Integration testing
- Production deployment

---

## Contributing

This is an experimental system under active development. Contributions welcome in:

1. **Scraper Improvements**: Better CSS/DOM extraction algorithms
2. **Schema Refinements**: Enhanced Cue/Nix schema definitions
3. **Transpiler Features**: New ReScript code generation patterns
4. **ML Models**: Alternative approaches (transformers, GANs, etc.)
5. **Theme Catalog**: Adding more themes to the database
6. **Feedback UI**: Improving user feedback collection

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This component of the Sinople WordPress Theme is dual-licensed:

- **MIT License**: For permissive use
- **Palimpsest License v0.8**: For political autonomy

**SPDX-License-Identifier**: `MIT OR Palimpsest-0.8`

---

## References

### Web Scraping
- [Deno DOM](https://deno.land/x/deno_dom)
- [PostCSS](https://postcss.org/)
- [SPDX License List](https://spdx.org/licenses/)

### Schema Languages
- [Cue Language](https://cuelang.org/)
- [Nix Expression Language](https://nixos.org/manual/nix/stable/language/)

### Haskell
- [Aeson JSON Library](https://hackage.haskell.org/package/aeson)
- [Asterius (Haskell to WASM)](https://asterius.netlify.app/)

### Machine Learning
- [Flux.jl (Julia ML)](https://fluxml.ai/)
- [Logtalk Logic Programming](https://logtalk.org/)
- [Liquid State Machines](https://en.wikipedia.org/wiki/Liquid_state_machine)

### IndieWeb
- [IndieWeb Themes](https://indieweb.org/WordPress/Themes)
- [Microformats2](https://microformats.org/wiki/microformats2)

---

**Last Updated**: 2025-11-23
**Version**: 0.1.0-alpha
**Status**: 🚧 Active Development 🚧
