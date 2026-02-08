#!/bin/bash
# Generate a simple screenshot for Sinople theme
# WordPress standard: 1200x900 pixels

convert -size 1200x900 \
  -background "#006400" \
  -fill white \
  -font "DejaVu-Sans-Bold" \
  -pointsize 120 \
  -gravity center \
  label:"Sinople\nTheme" \
  screenshot.png

echo "Screenshot generated: screenshot.png"
