#!/bin/bash
# Generate favicons for Sinople theme in multiple sizes

SINOPLE_GREEN="#006400"
OUTPUT_DIR="assets/images"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate 512x512 base icon (for high-res displays and PWA)
magick -size 512x512 xc:"$SINOPLE_GREEN" \
  -fill white \
  -draw "circle 256,256 256,100" \
  -fill "$SINOPLE_GREEN" \
  -draw "circle 256,256 256,180" \
  -pointsize 280 \
  -gravity center \
  -annotate +0+0 "S" \
  "$OUTPUT_DIR/favicon-512.png"

# Generate standard sizes
for size in 32 64 128 192 256; do
  magick "$OUTPUT_DIR/favicon-512.png" -resize ${size}x${size} "$OUTPUT_DIR/favicon-${size}.png"
done

# Generate ICO file (16x16, 32x32, 48x48)
magick "$OUTPUT_DIR/favicon-512.png" -resize 16x16 "$OUTPUT_DIR/favicon-16.png"
magick "$OUTPUT_DIR/favicon-512.png" -resize 48x48 "$OUTPUT_DIR/favicon-48.png"
magick "$OUTPUT_DIR/favicon-16.png" "$OUTPUT_DIR/favicon-32.png" "$OUTPUT_DIR/favicon-48.png" "$OUTPUT_DIR/favicon.ico"

# Generate Apple Touch Icon
magick "$OUTPUT_DIR/favicon-512.png" -resize 180x180 "$OUTPUT_DIR/apple-touch-icon.png"

echo "✓ Generated favicons in $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR/"
