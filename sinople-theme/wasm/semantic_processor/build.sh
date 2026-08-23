#!/bin/bash
#
# Build script for semantic_processor WASM module
#
# This script builds the Rust code to WASM using wasm-pack.
# Note: Due to network restrictions, wasm-pack must be installed via cargo:
#   cargo install wasm-pack
#
# Usage:
#   ./build.sh [--dev]
#
# Options:
#   --dev    Build in development mode (faster, larger)
#   (default is release mode)

set -e  # Exit on error

echo "🦀 Building Semantic Processor WASM module..."

# Check if wasm-pack is installed
if ! command -v wasm-pack &> /dev/null; then
    echo "❌ wasm-pack not found"
    echo "📦 Installing wasm-pack via cargo..."
    cargo install wasm-pack
fi

# Determine build mode
if [ "$1" == "--dev" ]; then
    echo "🔧 Building in development mode..."
    wasm-pack build --target web --out-dir pkg --dev
else
    echo "🚀 Building in release mode..."
    wasm-pack build --target web --out-dir pkg
fi

# Skip cargo tests (require browser environment)
echo "⏭️  Skipping WASM tests (require browser environment)"
echo "   Run integration tests with: deno test tests/integration/"

# Display output
echo ""
echo "✅ Build complete!"
echo "📁 Output: pkg/"
echo "📦 Files:"
ls -lh pkg/ | grep -E '\.(wasm|js)$' || true

# Show WASM size
if [ -f pkg/semantic_processor_bg.wasm ]; then
    SIZE=$(du -h pkg/semantic_processor_bg.wasm | cut -f1)
    echo "📏 WASM size: $SIZE"
fi

echo ""
echo "🎯 Next steps:"
echo "   1. Test WASM: open examples/test.html in browser"
echo "   2. Integrate with : use bindings in /src/bindings/SemanticProcessor.res"
echo "   3. Deploy to WordPress: copy pkg/* to wordpress/assets/wasm/"
