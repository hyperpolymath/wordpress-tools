/**
 * Service Worker for Sinople Theme
 *
 * Provides offline support, caching strategies,
 * and progressive web app capabilities.
 *
 * @package Sinople
 * @since 0.1.0
 */

const CACHE_VERSION = 'sinople-v1';
const CACHE_ASSETS = [
  '/',
  '/wp-content/themes/sinople/style.css',
  '/wp-content/themes/sinople/assets/css/main.css',
  '/wp-content/themes/sinople/assets/js/dist/main.js',
];

// Install event - cache assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_VERSION).then((cache) => {
      return cache.addAll(CACHE_ASSETS);
    })
  );
  self.skipWaiting();
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name !== CACHE_VERSION)
          .map((name) => caches.delete(name))
      );
    })
  );
  self.clients.claim();
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      if (response) {
        return response;
      }

      return fetch(event.request).then((response) => {
        // Cache successful responses
        if (response && response.status === 200 && response.type === 'basic') {
          const responseToCache = response.clone();

          caches.open(CACHE_VERSION).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }

        return response;
      });
    })
  );
});
