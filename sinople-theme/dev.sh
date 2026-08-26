#!/bin/bash
#
# Development Mode Script for Sinople Theme
#
# Starts watch processes for  and optional Deno Fresh server.
# WASM requires manual rebuild (no watch mode in wasm-pack).
#
# Usage:
#   ./dev.sh              - Start all watchers
#   ./dev.sh      - Watch  only
#   ./dev.sh deno         - Watch Deno only
#   ./dev.sh wasm         - Rebuild WASM once
#

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Project root
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cleanup function to kill background processes
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping development processes...${NC}"
    jobs -p | xargs -r kill 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM


# Function: Watch Deno/Fresh
watch_deno() {
    echo -e "${BLUE}🦕 Starting Deno Fresh development server...${NC}"
    if [ -d "${ROOT_DIR}/deno" ] && [ -f "${ROOT_DIR}/deno/deno.json" ]; then
        cd "${ROOT_DIR}/deno"
        if command -v deno &> /dev/null; then
            deno task dev
        else
            echo -e "${YELLOW}⚠️  Deno not installed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Deno directory not configured${NC}"
    fi
}

# Function: Rebuild WASM
build_wasm() {
    echo -e "${BLUE}🦀 Rebuilding WASM module...${NC}"
    if [ -d "${ROOT_DIR}/wasm/semantic_processor" ]; then
        cd "${ROOT_DIR}/wasm/semantic_processor"
        ./build.sh --dev

        # Copy to WordPress assets
        mkdir -p "${ROOT_DIR}/wordpress/assets/wasm"
        cp pkg/*.{js,wasm} "${ROOT_DIR}/wordpress/assets/wasm/" 2>/dev/null || true

        echo -e "${GREEN}✅ WASM rebuilt and copied to WordPress${NC}"
    else
        echo -e "${YELLOW}⚠️  WASM directory not found${NC}"
    fi
}

# Function: Copy assets on change (simple sync)
sync_assets() {
    echo -e "${BLUE}📋 Syncing assets to WordPress...${NC}"

    # Copy  compiled files
    if [ -d "${ROOT_DIR}//src" ]; then
        mkdir -p "${ROOT_DIR}/wordpress/assets/js"
        find "${ROOT_DIR}//src" -name "*.res.js" -exec cp {} "${ROOT_DIR}/wordpress/assets/js/" \; 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Assets synced${NC}"
}

# Main
echo -e "${GREEN}🎨 Sinople Theme Development Mode${NC}"
echo "======================================"
echo ""

case "${1:-all}" in
    deno)
        watch_deno
        ;;
    wasm)
        build_wasm
        ;;
    sync)
        sync_assets
        ;;
    all)
        echo "Starting all development watchers..."
        echo ""
        echo -e "${YELLOW}📝 Note: WASM requires manual rebuild${NC}"
        echo "   Run: ./dev.sh wasm"
        echo ""


        # Start Deno if available
        if command -v deno &> /dev/null && [ -d "${ROOT_DIR}/deno" ]; then
            watch_deno &
            DENO_PID=$!
        fi

        echo ""
        echo -e "${GREEN}✨ Development mode active${NC}"
        echo ""
        echo "Processes running:"
        [ -n "${DENO_PID}" ] && echo "  - Deno Fresh (PID: ${DENO_PID})"
        echo ""
        echo "Press Ctrl+C to stop all processes"
        echo ""

        # Wait for background processes
        wait
        ;;
    *)
        echo "Usage: ./dev.sh [deno|wasm|sync|all]"
        echo ""
        echo "Commands:"
        echo "    - Watch  files only"
        echo "  deno      - Start Deno Fresh dev server only"
        echo "  wasm      - Rebuild WASM module once"
        echo "  sync      - Sync compiled assets to WordPress"
        echo "  all       - Start all watchers (default)"
        exit 1
        ;;
esac
