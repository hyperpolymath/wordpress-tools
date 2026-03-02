# 🧵 Glosses: Semantic Footnotes and Conceptual Annotations

This directory houses symbolic footnotes—*glosses*—expressed in structured formats. Glosses are conceptual threads that annotate, clarify, or emotionally inflect entries and constructs across Sinople.

Each gloss provides:
- **Semantic richness** (for search engines and agents)
- **Symbolic depth** (via named terms and emotional motifs)
- **Interoperability** (through shared vocabularies like schema.org, SKOS, or OWL)

---

## 📁 Included Formats

| Format       | Purpose                            | Best For                          |
|--------------|------------------------------------|-----------------------------------|
| `.jsonld`    | Lightweight, SEO-friendly glossary | HTML embedding, structured search |
| `.ttl`       | RDF Turtle for Linked Data         | SPARQL, dataset description       |
| `.owl`       | Ontology of gloss types            | Semantic reasoning, vocab reuse  |

Glosses often appear via `aria-describedby` or inline semantic markup, connecting pages to their deeper meanings.

---

## 🔖 Naming Convention

- `gloss-term.jsonld` — individual gloss  
- `gloss-term.ttl` — RDF definition  
- `glosses.owl` — shared ontology defining gloss types (e.g. ResistanceGloss, FogGloss)

Keep file names slugified and meaningful: `fog-threading.jsonld`, `stitched-memory.ttl`

---

## 🧬 Guidance for Contributors

1. Keep glosses short, symbolic, and evocative.
2. Include links to where gloss is used in the journal.
3. Align vocabularies where possible (e.g. `schema:DefinedTerm`, `skos:Concept`, custom `sin:GlossType`)
4. Don't duplicate across formats unless justified by context.

Every gloss is a stitched voice—name it with care.
