# Sinople Deno + Fresh Integration

This directory contains the Deno + Fresh framework integration for Sinople theme.

## Setup

1. Install Deno:
   ```bash
   curl -fsSL https://deno.land/install.sh | sh
   ```

2. Run development server:
   ```bash
   deno task dev
   ```

3. Build for production:
   ```bash
   deno task build
   ```

## Structure

- `main.ts` - Production entry point
- `dev.ts` - Development server
- `routes/` - Fresh file-based routing
- `islands/` - Interactive islands (client-side)
- `components/` - Server-side components
- `lib/` - Utility functions

## API Routes

- `/api/webmention` - Webmention endpoint
- `/api/micropub` - Micropub endpoint
- `/api/semantic` - Semantic graph queries
- `/api/void` - VoID dataset description

## Fresh Islands

Islands are interactive components that hydrate on the client:

- `SemanticGraph.tsx` - RDF graph visualization
- `GlossAnnotation.tsx` - Inline gloss annotations
- `CharacterNetwork.tsx` - Character relationship viewer
- `SearchFilter.tsx` - Accessible search/filter

## Integration with WordPress

The Fresh application proxies requests to WordPress REST API
and enhances with client-side interactivity where needed.
