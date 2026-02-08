# Sinople Technology Stack

## Frontend

### ReScript 11+
- **Why**: Type safety without TypeScript overhead
- **Use**: UI components, WASM bindings, domain logic
- **Compiles to**: ES6 JavaScript

### Deno 1.40+ with Fresh
- **Why**: Modern runtime, no build step, native TypeScript
- **Use**: Server-side rendering, API routes, islands architecture
- **Security**: Permissions-based, secure by default

## Backend (WASM)

### Rust Stable
- **Why**: Memory safety, performance, WebAssembly support
- **Use**: RDF graph processing, SPARQL queries
- **Crates**:
  - `sophia_api 0.8` - RDF API
  - `sophia_inmem 0.8` - In-memory graphs
  - `sophia_turtle 0.8` - Turtle parser
  - `wasm-bindgen 0.2` - JS/WASM bridge

## WordPress

### PHP 7.4+
- **Why**: WordPress requirement
- **Use**: Theme hooks, custom post types, admin interface
- **Security**: Escaping, sanitization, nonces, capabilities

## Semantic Web

### RDF 1.1 / Turtle
- **Why**: W3C standard for knowledge graphs
- **Use**: Ontology definition, data exchange
- **Namespaces**: sn, rdf, rdfs, owl, dc, foaf

### OWL 2
- **Why**: Ontology modeling
- **Use**: Class hierarchies, property definitions

## IndieWeb

### Webmention
- **Spec**: [W3C Recommendation](https://www.w3.org/TR/webmention/)
- **Use**: Decentralized comments and interactions

### Micropub
- **Spec**: [W3C Recommendation](https://micropub.spec.indieweb.org/)
- **Use**: Publishing interface

### Microformats2
- **Use**: Semantic HTML markup (h-entry, h-card)

## Accessibility

### WCAG 2.3 AAA
- **Contrast**: 7:1 for normal text, 4.5:1 for large
- **Keyboard**: Full navigation, visible focus
- **Screen readers**: ARIA labels, landmarks, live regions

## Build Tools

### wasm-pack
- **Why**: Rust → WASM compilation
- **Output**: ES modules + TypeScript definitions

### ReScript Compiler
- **Why**: ReScript → JavaScript
- **Output**: Clean, readable ES6

## Testing

### Deno Test
- **Use**: Integration tests, API tests
- **Features**: Built-in assertions, async support

### Cargo Test
- **Use**: Rust unit tests
- **Note**: WASM tests skipped (need browser)

## Development

### Git
- **Branches**: feature/, fix/, docs/
- **Commits**: Conventional commits format

### Hot Reload
- ReScript watch mode
- Deno --watch flag
- WordPress auto-refresh

## Deployment

### WordPress Hosting
- Shared/VPS/Managed WordPress
- PHP 7.4+, MySQL 5.7+

### WASM Assets
- Served as static files
- ~1.3MB gzipped
- Cached at CDN edge

## Performance

- WASM: Near-native speed for graph operations
- Fresh: Islands architecture (selective hydration)
- WordPress: Object caching (Redis/Memcached)
- CDN: Static asset distribution

## Security

- Rust: Memory safety guarantees
- WordPress: Security best practices
- Deno: Permissions-based sandbox
- HTTPS: Required for WASM/Service Workers
