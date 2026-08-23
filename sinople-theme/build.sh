#!/bin/bash
#
# Master Build Script for Sinople Theme
#
# Builds all components: WASM, , Deno, and assembles WordPress theme
#

set -e  # Exit on error

echo "🎨 Building Sinople WordPress Theme..."
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Build WASM semantic processor
echo -e "${BLUE}📦 Step 1: Building Rust WASM module...${NC}"
if [ -d "wasm/semantic_processor" ]; then
    cd wasm/semantic_processor

    # Check if wasm-pack is installed
    if ! command -v wasm-pack &> /dev/null; then
        echo "Installing wasm-pack..."
        cargo install wasm-pack
    fi

    # Build WASM
    wasm-pack build --target web --out-dir pkg

    echo -e "${GREEN}✅ WASM build complete${NC}"
    cd ../..
else
    echo -e "${RED}⚠️  WASM directory not found, skipping${NC}"
fi

# Step 2: Compile 
echo -e "${BLUE}🔧 Step 2: Compiling ...${NC}"
if [ -d "" ]; then
    cd 

    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "Installing  dependencies..."
        npm install
    fi

    # Compile 
    npx  clean
    npx  build

    echo -e "${GREEN}✅  compilation complete${NC}"
    cd ..
else
    echo -e "${RED}⚠️   directory not found, skipping${NC}"
fi

# Step 3: Bundle Deno application (if applicable)
echo -e "${BLUE}🦕 Step 3: Bundling Deno application...${NC}"
if [ -d "deno" ] && [ -f "deno/deno.json" ]; then
    cd deno

    # Check if deno is installed
    if command -v deno &> /dev/null; then
        echo "Deno found, checking tasks..."
        if deno task build 2>/dev/null; then
            echo -e "${GREEN}✅ Deno build complete${NC}"
        else
            echo "No build task defined, skipping..."
        fi
    else
        echo "Deno not installed, skipping..."
    fi

    cd ..
else
    echo "Deno directory not configured, skipping..."
fi

# Step 4: Assemble WordPress theme
echo -e "${BLUE}📋 Step 4: Assembling WordPress theme...${NC}"

# Create assets directories
mkdir -p wordpress/assets/{wasm,js,css}

# Copy WASM files
if [ -d "wasm/semantic_processor/pkg" ]; then
    echo "Copying WASM assets..."
    cp wasm/semantic_processor/pkg/*.{js,wasm} wordpress/assets/wasm/ 2>/dev/null || true
fi

# Copy  compiled files
if [ -d "/src" ]; then
    echo "Copying  compiled files..."
    find /src -name "*.res.js" -exec cp {} wordpress/assets/js/ \; 2>/dev/null || true
fi

# Copy build outputs
if [ -d "build/" ]; then
    cp -r build//* wordpress/assets/js/ 2>/dev/null || true
fi

if [ -d "build/deno" ]; then
    cp -r build/deno/* wordpress/assets/js/ 2>/dev/null || true
fi

echo -e "${GREEN}✅ Assets copied to WordPress theme${NC}"

# Step 5: Generate asset report
echo ""
echo -e "${BLUE}📊 Build Summary:${NC}"
echo "======================================"

if [ -f "wordpress/assets/wasm/semantic_processor_bg.wasm" ]; then
    WASM_SIZE=$(du -h wordpress/assets/wasm/semantic_processor_bg.wasm | cut -f1)
    echo "WASM module: $WASM_SIZE"
fi

if [ -d "wordpress/assets/js" ]; then
    JS_COUNT=$(find wordpress/assets/js -name "*.js" | wc -l)
    echo "JavaScript files: $JS_COUNT"
fi

echo ""
echo -e "${GREEN}✨ Build complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Copy wordpress/ to your WordPress themes directory"
echo "  2. Activate 'Sinople' theme in WordPress admin"
echo "  3. Visit Constructs → Add New to create semantic content"
echo ""
echo "Development:"
echo "  ./dev.sh         - Start development mode"
echo "  cd tests && deno test - Run integration tests"
