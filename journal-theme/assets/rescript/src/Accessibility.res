/**
 * Accessibility Module
 *
 * Font sizing, theme toggle, high contrast mode,
 * and keyboard navigation enhancements.
 * WCAG 2.3 AAA compliant.
 *
 * @package Sinople
 * @since 0.1.0
 */

@val external document: Dom.document = "document"
@val external window: Dom.window = "window"
@val external console: {..} = "console"

module LocalStorage = {
  @val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
  @val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
  @val @scope("localStorage") external removeItem: string => unit = "removeItem"
}

module Dom = {
  @val @scope("document") external getElementById: string => Nullable.t<Dom.element> = "getElementById"
  @val @scope("document") external querySelector: string => Nullable.t<Dom.element> = "querySelector"
  @val @scope("document") external querySelectorAll: string => array<Dom.element> = "querySelectorAll"
  @val @scope("document") external documentElement: Dom.element = "documentElement"

  @send external addEventListener: (Dom.document, string, 'event => unit) => unit = "addEventListener"
  @send external addElementEventListener: (Dom.element, string, 'event => unit) => unit = "addEventListener"
  @send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
  @send external getAttribute: (Dom.element, string) => Nullable.t<string> = "getAttribute"
  @send external focus: Dom.element => unit = "focus"
  @send external scrollIntoView: (Dom.element, {..}) => unit = "scrollIntoView"

  @get external style: Dom.element => {..} = "style"
  @get external dataset: Dom.element => {..} = "dataset"
  @get external classList: Dom.element => {..} = "classList"
  @get external id: Dom.element => string = "id"
}

// Apply font scale to document
let applyFontScale = (scale: float) => {
  let html = Dom.documentElement
  let _ = %raw(`html.style.setProperty('--text-scale', scale.toString())`)
}

// Font size controls (WCAG AAA)
let initFontSizeControls = () => {
  let decreaseBtn = Dom.getElementById("font-size-decrease")
  let increaseBtn = Dom.getElementById("font-size-increase")

  switch (Nullable.toOption(decreaseBtn), Nullable.toOption(increaseBtn)) {
  | (Some(decBtn), Some(incBtn)) => {
      // Get current scale from localStorage
      let savedScale = LocalStorage.getItem("font-scale")
      let currentScale = ref(
        switch Nullable.toOption(savedScale) {
        | Some(s) => Float.fromString(s)->Option.getOr(1.0)
        | None => 1.0
        }
      )

      applyFontScale(currentScale.contents)

      // Decrease handler
      Dom.addElementEventListener(decBtn, "click", _ => {
        currentScale := Math.max(0.8, currentScale.contents -. 0.1)
        applyFontScale(currentScale.contents)
        LocalStorage.setItem("font-scale", Float.toString(currentScale.contents))
      })

      // Increase handler
      Dom.addElementEventListener(incBtn, "click", _ => {
        currentScale := Math.min(1.5, currentScale.contents +. 0.1)
        applyFontScale(currentScale.contents)
        LocalStorage.setItem("font-scale", Float.toString(currentScale.contents))
      })
    }
  | _ => ()
  }
}

// Apply theme to document
let applyTheme = (theme: string) => {
  let html = Dom.documentElement
  let _ = %raw(`html.dataset.theme = theme`)
}

// Update theme toggle button state
let updateThemeButton = (button: Dom.element, theme: string) => {
  Dom.setAttribute(button, "aria-pressed", theme == "dark" ? "true" : "false")
  Dom.setAttribute(
    button,
    "aria-label",
    theme == "dark" ? "Switch to light mode" : "Switch to dark mode",
  )
}

// Theme toggle (dark/light mode)
let initThemeToggle = () => {
  let toggleBtn = Dom.getElementById("theme-toggle")

  switch Nullable.toOption(toggleBtn) {
  | Some(btn) => {
      // Get initial theme
      let savedTheme = LocalStorage.getItem("theme")
      let systemDark: bool = %raw(`window.matchMedia('(prefers-color-scheme: dark)').matches`)

      let currentTheme = switch Nullable.toOption(savedTheme) {
      | Some(t) => t
      | None => systemDark ? "dark" : "light"
      }

      applyTheme(currentTheme)
      updateThemeButton(btn, currentTheme)

      // Toggle on click
      Dom.addElementEventListener(btn, "click", _ => {
        let html = Dom.documentElement
        let currentDataTheme: string = %raw(`html.dataset.theme || 'light'`)
        let newTheme = currentDataTheme == "dark" ? "light" : "dark"
        applyTheme(newTheme)
        updateThemeButton(btn, newTheme)
        LocalStorage.setItem("theme", newTheme)
      })

      // Listen for system preference changes
      let _ = %raw(`
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
          if (!localStorage.getItem('theme')) {
            const theme = e.matches ? 'dark' : 'light';
            document.documentElement.dataset.theme = theme;
          }
        })
      `)
    }
  | None => ()
  }
}

// High contrast toggle
let initContrastToggle = () => {
  let toggleBtn = Dom.getElementById("contrast-toggle")

  switch Nullable.toOption(toggleBtn) {
  | Some(btn) => {
      let savedContrast = LocalStorage.getItem("contrast")

      switch Nullable.toOption(savedContrast) {
      | Some("high") => {
          let _ = %raw(`document.documentElement.dataset.contrast = 'high'`)
          Dom.setAttribute(btn, "aria-pressed", "true")
        }
      | _ => ()
      }

      Dom.addElementEventListener(btn, "click", _ => {
        let isHigh: bool = %raw(`document.documentElement.dataset.contrast === 'high'`)

        if isHigh {
          let _ = %raw(`delete document.documentElement.dataset.contrast`)
          Dom.setAttribute(btn, "aria-pressed", "false")
          LocalStorage.removeItem("contrast")
        } else {
          let _ = %raw(`document.documentElement.dataset.contrast = 'high'`)
          Dom.setAttribute(btn, "aria-pressed", "true")
          LocalStorage.setItem("contrast", "high")
        }
      })
    }
  | None => ()
  }
}

// Close modal helper
let closeModal = (modal: Dom.element) => {
  Dom.setAttribute(modal, "aria-hidden", "true")
  let _ = %raw(`modal.classList.remove('is-open')`)

  let modalId = Dom.id(modal)
  let trigger = Dom.querySelector(`[aria-controls="${modalId}"]`)

  switch Nullable.toOption(trigger) {
  | Some(t) => Dom.focus(t)
  | None => ()
  }
}

// Enhanced keyboard navigation
let initKeyboardNavigation = () => {
  // Trap focus in modals with Escape key
  Dom.addEventListener(document, "keydown", event => {
    let key: string = %raw(`event.key`)

    if key == "Escape" {
      let openModal = Dom.querySelector(`[role="dialog"][aria-hidden="false"]`)

      switch Nullable.toOption(openModal) {
      | Some(modal) => closeModal(modal)
      | None => ()
      }
    }
  })

  // Focus management for menu toggle
  let menuToggle = Dom.querySelector(".menu-toggle")
  let menu = Dom.getElementById("primary-menu")

  switch (Nullable.toOption(menuToggle), Nullable.toOption(menu)) {
  | (Some(toggle), Some(menuEl)) => {
      Dom.addElementEventListener(toggle, "click", _ => {
        let isExpanded: bool = %raw(`toggle.getAttribute('aria-expanded') === 'true'`)
        Dom.setAttribute(toggle, "aria-expanded", !isExpanded ? "true" : "false")
        let _ = %raw(`menuEl.classList.toggle('is-open')`)

        if !isExpanded {
          let firstLink = %raw(`menuEl.querySelector('a')`)
          switch Nullable.toOption(firstLink) {
          | Some(link) => Dom.focus(link)
          | None => ()
          }
        }
      })
    }
  | _ => ()
  }
}

// Skip links visibility
let initSkipLinks = () => {
  let skipLinks = Dom.querySelectorAll(".skip-link")

  skipLinks->Array.forEach(link => {
    Dom.addElementEventListener(link, "click", event => {
      let _ = %raw(`event.preventDefault()`)
      let href: Nullable.t<string> = %raw(`link.getAttribute('href')`)

      switch Nullable.toOption(href) {
      | Some(h) => {
          let target = Dom.querySelector(h)
          switch Nullable.toOption(target) {
          | Some(t) => {
              Dom.focus(t)
              Dom.scrollIntoView(t, {"behavior": "smooth"})
            }
          | None => ()
          }
        }
      | None => ()
      }
    })
  })
}

// Initialize all accessibility features
let init = () => {
  initFontSizeControls()
  initThemeToggle()
  initContrastToggle()
  initKeyboardNavigation()
  initSkipLinks()
}
