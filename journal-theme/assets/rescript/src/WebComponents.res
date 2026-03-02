/**
 * Web Components Module
 *
 * Custom elements for Sinople theme features.
 * Progressive enhancement - works without JS.
 *
 * @package Sinople
 * @since 0.1.0
 */

@val external console: {..} = "console"

// Define sinople-gloss custom element for inline annotations
let defineGlossComponent = () => {
  let _ = %raw(`
    if (!customElements.get('sinople-gloss')) {
      class SinopolGloss extends HTMLElement {
        constructor() {
          super();
          this.attachShadow({ mode: 'open' });
        }

        connectedCallback() {
          const term = this.getAttribute('term') || '';
          const definition = this.getAttribute('definition') || this.textContent;

          this.shadowRoot.innerHTML = \`
            <style>
              :host {
                position: relative;
                display: inline;
              }
              .gloss-term {
                text-decoration: underline dotted;
                cursor: help;
              }
              .gloss-definition {
                position: absolute;
                bottom: 100%;
                left: 50%;
                transform: translateX(-50%);
                padding: 0.5em 1em;
                background: var(--color-surface-elevated, #333);
                color: var(--color-text-inverse, #fff);
                border-radius: 4px;
                font-size: 0.875em;
                white-space: nowrap;
                opacity: 0;
                visibility: hidden;
                transition: opacity 0.2s, visibility 0.2s;
                z-index: 1000;
              }
              :host(:hover) .gloss-definition,
              :host(:focus-within) .gloss-definition {
                opacity: 1;
                visibility: visible;
              }
              @media (prefers-reduced-motion: reduce) {
                .gloss-definition {
                  transition: none;
                }
              }
            </style>
            <span class="gloss-term" tabindex="0" role="term" aria-describedby="def">
              \${term}
            </span>
            <span class="gloss-definition" id="def" role="definition">
              \${definition}
            </span>
          \`;
        }
      }

      customElements.define('sinople-gloss', SinopolGloss);
    }
  `)
}

// Define sinople-fieldnote custom element for observational micro-essays
let defineFieldNoteComponent = () => {
  let _ = %raw(`
    if (!customElements.get('sinople-fieldnote')) {
      class SinopolFieldNote extends HTMLElement {
        constructor() {
          super();
          this.attachShadow({ mode: 'open' });
        }

        connectedCallback() {
          const location = this.getAttribute('location') || '';
          const timestamp = this.getAttribute('timestamp') || '';
          const content = this.innerHTML;

          this.shadowRoot.innerHTML = \`
            <style>
              :host {
                display: block;
                margin: 1.5em 0;
                padding: 1em;
                border-left: 3px solid var(--color-accent, #4a7c59);
                background: var(--color-surface-muted, #f5f5f5);
              }
              .fieldnote-meta {
                font-size: 0.75em;
                color: var(--color-text-muted, #666);
                margin-bottom: 0.5em;
              }
              .fieldnote-location::before {
                content: '📍 ';
              }
              .fieldnote-timestamp::before {
                content: '⏱ ';
                margin-left: 1em;
              }
              .fieldnote-content {
                font-style: italic;
              }
            </style>
            <div class="fieldnote-meta">
              \${location ? \`<span class="fieldnote-location">\${location}</span>\` : ''}
              \${timestamp ? \`<time class="fieldnote-timestamp" datetime="\${timestamp}">\${timestamp}</time>\` : ''}
            </div>
            <div class="fieldnote-content">
              <slot></slot>
            </div>
          \`;
        }
      }

      customElements.define('sinople-fieldnote', SinopolFieldNote);
    }
  `)
}

// Define sinople-portal custom element for annotated external links
let definePortalComponent = () => {
  let _ = %raw(`
    if (!customElements.get('sinople-portal')) {
      class SinopolPortal extends HTMLElement {
        constructor() {
          super();
          this.attachShadow({ mode: 'open' });
        }

        connectedCallback() {
          const href = this.getAttribute('href') || '#';
          const title = this.getAttribute('title') || '';
          const description = this.getAttribute('description') || '';

          this.shadowRoot.innerHTML = \`
            <style>
              :host {
                display: block;
                margin: 1em 0;
              }
              .portal {
                display: block;
                padding: 1em;
                border: 1px solid var(--color-border, #ccc);
                border-radius: 4px;
                text-decoration: none;
                color: inherit;
                transition: box-shadow 0.2s, border-color 0.2s;
              }
              .portal:hover,
              .portal:focus {
                border-color: var(--color-accent, #4a7c59);
                box-shadow: 0 2px 8px rgba(0,0,0,0.1);
              }
              .portal-title {
                font-weight: bold;
                color: var(--color-link, #1a5f7a);
              }
              .portal-description {
                margin-top: 0.5em;
                font-size: 0.875em;
                color: var(--color-text-muted, #666);
              }
              .portal-url {
                margin-top: 0.5em;
                font-size: 0.75em;
                color: var(--color-text-muted, #888);
              }
              @media (prefers-reduced-motion: reduce) {
                .portal {
                  transition: none;
                }
              }
            </style>
            <a class="portal" href="\${href}" target="_blank" rel="noopener noreferrer">
              <span class="portal-title">\${title}</span>
              \${description ? \`<p class="portal-description">\${description}</p>\` : ''}
              <span class="portal-url">\${new URL(href, window.location.origin).hostname}</span>
            </a>
          \`;
        }
      }

      customElements.define('sinople-portal', SinopolPortal);
    }
  `)
}

// Initialize all web components
let init = () => {
  // Check for Custom Elements support
  let hasCustomElements: bool = %raw(`'customElements' in window`)

  if hasCustomElements {
    defineGlossComponent()
    defineFieldNoteComponent()
    definePortalComponent()
    console["log"]("Web Components initialized")
  } else {
    console["log"]("Custom Elements not supported")
  }
}
