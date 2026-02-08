# Sinople Theme Usage Guide

## Working with Constructs

### Creating a Construct

1. Navigate to **Constructs → Add New** in WordPress admin
2. Enter construct title (e.g., "Time")
3. Add description in content editor
4. Fill metadata:
   - **Gloss**: Brief explanation
   - **Complexity**: 0-10 scale
   - **Type**: philosophical/scientific/mathematical/etc
   - **RDF IRI**: Unique identifier

### Example Construct

```
Title: Consciousness
Gloss: Awareness of one's own existence and surroundings
Complexity: 10
Type: philosophical
RDF IRI: https://sinople.org/constructs/consciousness
```

## Creating Entanglements

Entanglements connect constructs:

1. Go to **Entanglements → Add New**
2. Select **Source** construct
3. Select **Target** construct
4. Set **Relationship Type** (e.g., "depends on")
5. Set **Strength** (0.0-1.0)
6. Check **Bidirectional** if applicable

## Semantic Graph Visualization

The WASM processor generates interactive graphs:

```javascript
// Load semantic data
const response = await fetch('/wp-json/sinople/v1/semantic-graph');
const {nodes, edges} = await response.json();

// Visualize with D3, Cytoscape, or vis.js
```

## IndieWeb Integration

### Receiving Webmentions

Webmentions are automatically received at:
```
https://yoursite.com/wp-json/sinople/v1/webmention
```

### Micropub Publishing

Authenticate with IndieAuth and POST to:
```
https://yoursite.com/wp-json/sinople/v1/micropub
```

## Accessibility Features

- Use **Alt+1** to skip to main content
- Use **Alt+2** to skip to navigation
- All interactive elements have visible focus indicators
- Screen readers announce all semantic relationships

## Development Workflow

1. Edit ReScript files in `rescript/src/`
2. Run `npm run watch` to compile
3. Edit Rust in `wasm/semantic_processor/src/`
4. Run `./build.sh` to recompile WASM
5. Refresh WordPress to see changes

## REST API Endpoints

- `GET /wp-json/sinople/v1/semantic-graph` - Full graph
- `GET /wp-json/sinople/v1/constructs/{id}/rdf` - RDF for construct
- `GET /wp-json/sinople/v1/ontology` - Complete ontology export
- `POST /wp-json/sinople/v1/webmention` - Webmention endpoint
- `POST /wp-json/sinople/v1/micropub` - Micropub endpoint
