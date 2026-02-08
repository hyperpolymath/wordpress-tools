/**
 * Navigation and Accessibility JavaScript for Sinople Theme
 *
 * Handles:
 * - Keyboard navigation
 * - Mobile menu toggle
 * - Skip links
 * - Focus management
 *
 * @package Sinople
 * @since 1.0.0
 */

(function() {
  'use strict';

  /**
   * Initialize navigation when DOM is ready
   */
  document.addEventListener('DOMContentLoaded', function() {
    initMobileMenu();
    initKeyboardNavigation();
    initSkipLinks();
    initFocusTrap();
  });

  /**
   * Mobile Menu Toggle
   */
  function initMobileMenu() {
    const nav = document.querySelector('.main-navigation');
    if (!nav) return;

    // Create mobile toggle button
    const toggleButton = document.createElement('button');
    toggleButton.className = 'menu-toggle';
    toggleButton.setAttribute('aria-expanded', 'false');
    toggleButton.setAttribute('aria-controls', 'primary-menu');
    toggleButton.innerHTML = '<span class="screen-reader-text">Menu</span><span aria-hidden="true">☰</span>';

    nav.insertBefore(toggleButton, nav.firstChild);

    const menu = nav.querySelector('ul');
    if (menu) {
      menu.id = 'primary-menu';
      menu.setAttribute('aria-label', 'Primary Menu');
    }

    // Toggle menu on button click
    toggleButton.addEventListener('click', function() {
      const expanded = this.getAttribute('aria-expanded') === 'true';
      this.setAttribute('aria-expanded', !expanded);
      nav.classList.toggle('toggled');
    });
  }

  /**
   * Keyboard Navigation Enhancements
   */
  function initKeyboardNavigation() {
    // Alt+1: Skip to main content
    // Alt+2: Skip to navigation
    document.addEventListener('keydown', function(e) {
      if (e.altKey) {
        switch(e.key) {
          case '1':
            e.preventDefault();
            focusElement('#main');
            break;
          case '2':
            e.preventDefault();
            focusElement('#nav');
            break;
        }
      }

      // Escape to close mobile menu
      if (e.key === 'Escape') {
        const nav = document.querySelector('.main-navigation.toggled');
        if (nav) {
          const toggleButton = nav.querySelector('.menu-toggle');
          if (toggleButton) {
            toggleButton.setAttribute('aria-expanded', 'false');
            nav.classList.remove('toggled');
            toggleButton.focus();
          }
        }
      }
    });

    // Arrow key navigation in menus
    const menuItems = document.querySelectorAll('.main-navigation a');
    menuItems.forEach((item, index) => {
      item.addEventListener('keydown', function(e) {
        let targetIndex;

        switch(e.key) {
          case 'ArrowDown':
          case 'ArrowRight':
            e.preventDefault();
            targetIndex = index + 1;
            if (targetIndex < menuItems.length) {
              menuItems[targetIndex].focus();
            }
            break;
          case 'ArrowUp':
          case 'ArrowLeft':
            e.preventDefault();
            targetIndex = index - 1;
            if (targetIndex >= 0) {
              menuItems[targetIndex].focus();
            }
            break;
          case 'Home':
            e.preventDefault();
            menuItems[0].focus();
            break;
          case 'End':
            e.preventDefault();
            menuItems[menuItems.length - 1].focus();
            break;
        }
      });
    });
  }

  /**
   * Skip Links Focus Management
   */
  function initSkipLinks() {
    const skipLinks = document.querySelectorAll('.skip-link');

    skipLinks.forEach(link => {
      link.addEventListener('click', function(e) {
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
          e.preventDefault();
          target.setAttribute('tabindex', '-1');
          target.focus();

          // Remove tabindex after blur
          target.addEventListener('blur', function() {
            this.removeAttribute('tabindex');
          }, { once: true });
        }
      });
    });
  }

  /**
   * Focus Trap for Modals
   */
  function initFocusTrap() {
    const modals = document.querySelectorAll('[role="dialog"]');

    modals.forEach(modal => {
      modal.addEventListener('keydown', function(e) {
        if (e.key !== 'Tab') return;

        const focusableElements = modal.querySelectorAll(
          'a[href], button, textarea, input, select, [tabindex]:not([tabindex="-1"])'
        );

        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        // Shift + Tab on first element -> focus last
        if (e.shiftKey && document.activeElement === firstElement) {
          e.preventDefault();
          lastElement.focus();
        }
        // Tab on last element -> focus first
        else if (!e.shiftKey && document.activeElement === lastElement) {
          e.preventDefault();
          firstElement.focus();
        }
      });
    });
  }

  /**
   * Helper: Focus Element by Selector
   */
  function focusElement(selector) {
    const element = document.querySelector(selector);
    if (element) {
      element.setAttribute('tabindex', '-1');
      element.focus();
      element.addEventListener('blur', function() {
        this.removeAttribute('tabindex');
      }, { once: true });
    }
  }

  /**
   * Announce to Screen Readers
   */
  function announceToScreenReader(message) {
    const liveRegion = document.getElementById('aria-live-region') ||
      (() => {
        const region = document.createElement('div');
        region.id = 'aria-live-region';
        region.setAttribute('aria-live', 'polite');
        region.setAttribute('aria-atomic', 'true');
        region.className = 'screen-reader-text';
        document.body.appendChild(region);
        return region;
      })();

    liveRegion.textContent = message;

    // Clear after 1 second
    setTimeout(() => {
      liveRegion.textContent = '';
    }, 1000);
  }

  // Expose to global scope if needed
  window.sinople = window.sinople || {};
  window.sinople.announceToScreenReader = announceToScreenReader;

})();
