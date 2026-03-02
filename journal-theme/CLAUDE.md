# CLAUDE.md - AI Assistant Guide for Sinople Theme

## 🌿 Project Overview

**Sinople** is a WordPress journal theme designed for layered, narrative-rich content. Named after a heraldic pigment that transformed from red to green, it embodies contradiction and agency. This is a **CSS-first, accessibility-focused, semantically-rich** theme for poetic storytelling and decentralized publishing.

### Core Philosophy
- **CSS-first architecture**: Minimal JavaScript, maximum declarative styling
- **WCAG 2.3 AAA compliance**: Full accessibility is fundamental, not optional
- **IndieWeb integration**: Microformats, Webmentions, POSSE
- **Semantic web**: JSON-LD, RDFa, Open Graph, structured metadata
- **Narrative focus**: Support for field notes, glosses, constructs, and threaded archives

## 🗂 Project Structure

```
sinople-theme/
├── style.css              # Theme header + base styles (not yet created)
├── functions.php          # WordPress theme functions (not yet created)
├── index.php              # Main post template (not yet created)
├── header.php             # Site header with ARIA landmarks (not yet created)
├── footer.php             # Site footer (not yet created)
├── templates/             # Custom page templates (not yet created)
├── assets/                # Static assets (not yet created)
├── semantic/              # Structured data and ontologies
│   ├── constructs/        # Semantic construct definitions
│   └── glosses/           # Glossary and annotation data
├── content/               # Content examples and field notes
├── entries/               # Entry examples
├── docs/                  # Documentation
│   ├── ethos.md          # Project philosophy
│   ├── styles-guide.md   # Style guide
│   ├── spans.md          # Documentation on span types
│   ├── taxonomy.md       # Content taxonomy
│   └── PORTALS.md        # External inspirations
├── tests/                 # Testing resources
├── README.md              # Project readme
├── CONTRIBUTING.md        # Contribution guidelines
└── metadata.jsonld        # Theme-level structured data
```

### Current State
This is an **early-stage theme** currently focused on documentation, semantic structure, and philosophical foundations. PHP theme files (functions.php, index.php, etc.) and CSS assets are not yet created. The semantic layer and documentation are well-established.

## 🎯 Key Concepts

### Spans
"Spans" are content types or narrative modes:
- **Field Notes**: Observational micro-essays
- **Characters & Constructs**: Symbolic entities (e.g., "Eteri Mistveil")
- **Glosses**: Footnotes with `aria-describedby` annotations
- **Portals**: Annotated external inspirations
- **Threaded Archives**: Entries organized by color, emotion, or motif

### Semantic Layer
The theme uses multiple semantic formats:
- **JSON-LD**: Schema.org vocabulary for structured data
- **RDFa**: Inline semantic markup
- **Microformats v2**: h-entry, h-card, p-name for IndieWeb
- **Open Graph**: Social media preview metadata
- **Turtle (.ttl)**: Optional RDF ontology definitions

### Accessibility Standards
All code must meet **WCAG 2.3 AAA** requirements:
- Semantic HTML5 landmarks (`<main>`, `<nav>`, `<header>`, `<footer>`)
- ARIA roles and attributes where appropriate
- Keyboard navigation support
- Skip links for navigation
- Visible focus indicators
- Motion sensitivity respect (prefers-reduced-motion)
- Dark/light mode support
- Minimum contrast ratios

## 🛠 Development Guidelines

### When Adding Features

1. **Check accessibility first**: Does this meet WCAG 2.3 AAA?
2. **Use semantic HTML**: Avoid div soup, use appropriate elements
3. **CSS-first**: Can this be done with CSS? Only use JS when necessary
4. **Add structured data**: Include relevant JSON-LD or microformats
5. **Document narrative intent**: This theme is poetic—explain symbolic choices

### Code Style

#### PHP
- Follow **WordPress Coding Standards**
- Use semantic function names that reflect narrative intent
- Include inline documentation for complex logic
- Prefix all functions with `sinople_`

#### CSS
- Mobile-first responsive design
- Use CSS custom properties (variables) for theming
- Organize by component or span type
- Include accessibility states (`:focus-visible`, `:hover`, etc.)
- Respect `prefers-reduced-motion`, `prefers-color-scheme`

#### HTML
- Always use semantic elements (`<article>`, `<aside>`, `<section>`)
- Include ARIA attributes for complex interactions
- Add microformat classes (`h-entry`, `p-name`, `u-url`)
- Ensure keyboard navigation works

### Semantic Data

When adding structured data:
```php
// Example: Adding JSON-LD for an article
$json_ld = array(
    '@context' => 'https://schema.org',
    '@type' => 'Article',
    'headline' => get_the_title(),
    'author' => array(
        '@type' => 'Person',
        'name' => get_the_author()
    )
);
```

Always validate JSON-LD at https://validator.schema.org/

## 📋 Common Tasks

### Creating a New Span Type

1. Document the span in `docs/spans.md`
2. Create PHP template in `templates/{span-name}.php`
3. Add CSS in `assets/css/spans/{span-name}.css`
4. Include JSON-LD schema definition
5. Add microformat classes
6. Test with screen reader
7. Validate structured data

### Adding Accessibility Features

1. Reference `tests/aria-checklist.md`
2. Test keyboard navigation
3. Verify focus indicators are visible
4. Check color contrast ratios
5. Test with screen reader (NVDA, JAWS, or VoiceOver)
6. Verify semantic HTML structure

### Modifying Semantic Data

1. Edit files in `semantic/` directory
2. Update `metadata.jsonld` if theme-level changes
3. Validate with appropriate tools:
   - JSON-LD: https://validator.schema.org/
   - RDF/Turtle: https://www.w3.org/RDF/Validator/
4. Document changes in commit message

## 🧪 Testing

### Accessibility Testing
- **Keyboard navigation**: Tab through all interactive elements
- **Screen readers**: Test with NVDA, JAWS, or VoiceOver
- **Contrast**: Use WebAIM Contrast Checker
- **Validators**: Use WAVE or axe DevTools
- Reference: `tests/aria-checklist.md`

### Semantic Validation
- **JSON-LD**: https://validator.schema.org/
- **Microformats**: https://microformats.io/
- **HTML**: https://validator.w3.org/
- Reference: `tests/validator-links.md`

### WordPress Testing
- Test in WordPress Customizer
- Verify theme appears correctly in admin
- Test with common plugins (Webmention, Post Kinds)
- Check responsive behavior

## 🎨 Design Principles

### Visual Identity
- **Fog-bound aesthetic**: Muted, atmospheric
- **High contrast**: For accessibility (AAA)
- **Typographic hierarchy**: Clear, readable
- **Minimal ornamentation**: CSS-driven, not image-heavy

### Content Principles
- **Poetic ambiguity**: Allow for layered meaning
- **Emotional depth**: Support introspective writing
- **Resistance**: Against algorithmic flattening
- **Agency**: User control over presentation and data

## 🔗 IndieWeb Integration

### Required Microformats
- `h-entry`: For posts/articles
- `h-card`: For author information
- `p-name`: Post title
- `e-content`: Post content
- `dt-published`: Publication date
- `u-url`: Canonical URL
- `u-syndication`: Syndication links (POSSE)

### Recommended Plugins
- **Webmention**: For receiving/sending webmentions
- **Post Kinds**: For different post types (note, reply, bookmark)
- **IndieAuth**: For authentication
- **Syndication Links**: For POSSE workflow

## 📚 Important Files

- **`README.md`**: User-facing documentation
- **`CONTRIBUTING.md`**: Contribution guidelines
- **`docs/ethos.md`**: Philosophical foundation
- **`docs/taxonomy.md`**: Content organization system
- **`docs/styles-guide.md`**: Visual and typographic standards
- **`metadata.jsonld`**: Theme-level structured data
- **`sinople.ttl`**: RDF ontology (optional)

## 🚨 Important Conventions

### Never Compromise On
1. **Accessibility**: WCAG 2.3 AAA is non-negotiable
2. **Semantic markup**: Always use appropriate HTML elements
3. **Performance**: CSS-first, minimal JS
4. **Privacy**: No tracking, no external dependencies without consent
5. **Licensing**: GPL v3 for code, CC BY 4.0 for content

### Prefer
- Semantic HTML over divs
- CSS over JavaScript
- Progressive enhancement over graceful degradation
- Structured data over unstructured
- Poetry over precision (where appropriate)

## 🧵 Git Workflow

### Branch Naming
- Feature branches: `feature/feature-name`
- Bug fixes: `fix/bug-description`
- Documentation: `docs/doc-update`
- Spans: `span/span-name`

### Commit Messages
Be descriptive and narrative when appropriate:
```
Good: "Add ARIA labels to navigation skip links"
Good: "Introduce Eteri Mistveil construct with h-card markup"
Avoid: "Update file"
Avoid: "Fix bug"
```

## 💡 Working with This Theme

### As an AI Assistant
When asked to modify this theme:

1. **Understand the narrative context**: This isn't just code, it's poetic infrastructure
2. **Prioritize accessibility**: Always check WCAG compliance
3. **Maintain CSS-first approach**: Avoid adding JavaScript unless necessary
4. **Add semantic metadata**: Include JSON-LD and microformats
5. **Document your choices**: Especially if they're symbolic or poetic
6. **Reference existing patterns**: Look at `docs/` for guidance
7. **Test thoroughly**: Use the checklist in `tests/`

### Questions to Ask
- Does this meet WCAG 2.3 AAA?
- Is this semantic HTML?
- Have I added appropriate structured data?
- Does this work with keyboard only?
- Have I respected the CSS-first philosophy?
- Does this align with Sinople's ethos?

## 🌐 External Resources

### WordPress
- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/)
- [Theme Handbook](https://developer.wordpress.org/themes/)

### Accessibility
- [WCAG 2.3 Guidelines](https://www.w3.org/WAI/WCAG23/quickref/)
- [WebAIM](https://webaim.org/)
- [A11y Project](https://www.a11yproject.com/)

### IndieWeb
- [IndieWeb Wiki](https://indieweb.org/)
- [Microformats](http://microformats.org/)

### Semantic Web
- [Schema.org](https://schema.org/)
- [JSON-LD Playground](https://json-ld.org/playground/)
- [RDF Primer](https://www.w3.org/TR/rdf11-primer/)

---

**Remember**: Sinople is stitched with care, contradiction, and quiet resistance. Every commit should honor that intent.
