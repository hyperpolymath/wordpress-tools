# 🎨 Style Guide for Semantic Naming

## 🧵 Constructs
- Use lowercase, hyphenated filenames (`eteri-mistveil.jsonld`)
- ID URI: `https://sinople.example.com/constructs/{name}`
- Include `alternateName`, `embodies`, `entanglesWith`

## 🔖 Glosses
- Use schema.org `DefinedTerm`
- Filename matches `termCode` (`fog-threading.ttl`)
- Include `description`, `inDefinedTermSet`, and `appliesTo`

## ✒️ Ontologies
- Prefix custom vocabulary with `sin:`  
- Use `Class`, `ObjectProperty`, `DatatypeProperty`  
- Organize properties by domain (e.g. `Construct`, `Gloss`, `Thread`)
