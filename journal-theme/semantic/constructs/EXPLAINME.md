<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# 🧶 Semantic Constructs: Help & Guidance

This folder contains semantic representations of narrative constructs in various formats:

- `.jsonld` — Lightweight JSON for structured data (used by search engines, APIs)
- `.ttl` — RDF in Turtle format (ideal for Linked Data and SPARQL)
- `.owl` — Ontology fragments describing symbolic logic and relationships

### ✅ Suggested Use Per Format

| Format        | Purpose                             | Best For                          |
|---------------|--------------------------------------|-----------------------------------|
| `.jsonld`     | Easy embedding & SEO                | HTML templates, rich results      |
| `.ttl`        | RDF graph publication               | Linked Data, ontology browsing    |
| `.owl`        | Formal ontology & reasoning         | Semantic inference, vocab modeling|

Each construct may be referenced across posts, glosses, or portals. Semantic files help express agency, relationships, and narrative weight in machine-readable form.

---

### 📌 About “Heavily Relational”

This means the construct:
- Has **explicit semantic links** to other entities (e.g. `entanglesWith`, `knows`, `hasThread`)
- May be used in **reasoning engines** to infer relationships or class memberships
- Operates within a **symbolic network**, rather than being a standalone descriptor

You can scale this up with properties like:
- `hasVeil`, `appearsIn`, `resonatesWith`, `originatesFrom`
- Use cardinality constraints or OWL restrictions if needed

