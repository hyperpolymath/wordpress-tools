/**
 * View Transitions Module
 *
 * Handles View Transitions API for smooth page transitions.
 * Falls back gracefully on unsupported browsers.
 *
 * @package Sinople
 * @since 0.1.0
 */

@val external document: Dom.document = "document"
@val external console: {..} = "console"

module Dom = {
  @val @scope("document") external querySelectorAll: string => array<Dom.element> = "querySelectorAll"
  @send external addEventListener: (Dom.element, string, 'event => unit) => unit = "addEventListener"
  @get external href: Dom.element => string = "href"
}

// Check if View Transitions API is available
let isSupported = (): bool => {
  %raw(`'startViewTransition' in document`)
}

// Navigate with view transition
let navigateWithTransition = (url: string): unit => {
  if isSupported() {
    let _ = %raw(`
      document.startViewTransition(async () => {
        const response = await fetch(url);
        const html = await response.text();
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');

        // Update the main content
        const newMain = doc.querySelector('main');
        const currentMain = document.querySelector('main');
        if (newMain && currentMain) {
          currentMain.innerHTML = newMain.innerHTML;
        }

        // Update the title
        document.title = doc.title;

        // Update the URL
        history.pushState({}, '', url);
      });
    `)
  } else {
    // Fallback: standard navigation
    let _ = %raw(`window.location.href = url`)
  }
}

// Setup navigation handlers
let setupNavigationHandlers = () => {
  let links = Dom.querySelectorAll("a[data-view-transition]")

  links->Array.forEach(link => {
    Dom.addEventListener(link, "click", event => {
      let _ = %raw(`event.preventDefault()`)
      let url = Dom.href(link)
      navigateWithTransition(url)
    })
  })
}

// Handle back/forward navigation
let setupPopStateHandler = () => {
  let _ = %raw(`
    window.addEventListener('popstate', () => {
      if ('startViewTransition' in document) {
        document.startViewTransition(async () => {
          const response = await fetch(window.location.href);
          const html = await response.text();
          const parser = new DOMParser();
          const doc = parser.parseFromString(html, 'text/html');

          const newMain = doc.querySelector('main');
          const currentMain = document.querySelector('main');
          if (newMain && currentMain) {
            currentMain.innerHTML = newMain.innerHTML;
          }

          document.title = doc.title;
        });
      }
    });
  `)
}

// Initialize View Transitions
let init = () => {
  if isSupported() {
    console["log"]("View Transitions API available")
    setupNavigationHandlers()
    setupPopStateHandler()
  } else {
    console["log"]("View Transitions API not supported, using standard navigation")
  }
}
