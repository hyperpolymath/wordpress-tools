# SPDX-License-Identifier: AGPL-3.0-or-later
# Strict security headers for production sites

{
  headers = [
    { name = "X-Frame-Options", value = "DENY" },
    { name = "X-Content-Type-Options", value = "nosniff" },
    { name = "X-XSS-Protection", value = "0" },  # Disabled, CSP is better
    { name = "Referrer-Policy", value = "strict-origin-when-cross-origin" },
    { name = "Permissions-Policy", value = "accelerometer=(), ambient-light-sensor=(), autoplay=(), battery=(), camera=(), cross-origin-isolated=(), display-capture=(), document-domain=(), encrypted-media=(), execution-while-not-rendered=(), execution-while-out-of-viewport=(), fullscreen=(self), geolocation=(), gyroscope=(), keyboard-map=(), magnetometer=(), microphone=(), midi=(), navigation-override=(), payment=(), picture-in-picture=(), publickey-credentials-get=(), screen-wake-lock=(), sync-xhr=(), usb=(), web-share=(), xr-spatial-tracking=()" },
    { name = "Cross-Origin-Opener-Policy", value = "same-origin" },
    { name = "Cross-Origin-Resource-Policy", value = "same-origin" },
  ],

  csp = [
    { directive = "default-src", sources = ["'self'"] },
    { directive = "script-src", sources = ["'self'"] },
    { directive = "style-src", sources = ["'self'"] },
    { directive = "img-src", sources = ["'self'", "data:"] },
    { directive = "font-src", sources = ["'self'"] },
    { directive = "connect-src", sources = ["'self'"] },
    { directive = "media-src", sources = ["'self'"] },
    { directive = "object-src", sources = ["'none'"] },
    { directive = "child-src", sources = ["'self'"] },
    { directive = "frame-src", sources = ["'none'"] },
    { directive = "worker-src", sources = ["'self'"] },
    { directive = "frame-ancestors", sources = ["'none'"] },
    { directive = "form-action", sources = ["'self'"] },
    { directive = "base-uri", sources = ["'self'"] },
    { directive = "manifest-src", sources = ["'self'"] },
    { directive = "upgrade-insecure-requests", sources = [] },
    { directive = "block-all-mixed-content", sources = [] },
  ],
}
