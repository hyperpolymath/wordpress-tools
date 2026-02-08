#!/usr/bin/env bash
# Quick parsing script for WP Praxis Manifest Parser
# Usage: ./scripts/parse.sh <manifest-file>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 <command> <manifest-file> [options]"
    echo ""
    echo "Commands:"
    echo "  parse      - Parse and display manifest"
    echo "  validate   - Validate manifest structure"
    echo "  optimize   - Optimize manifest"
    echo "  inspect    - Inspect manifest details"
    echo "  export     - Export to JSON"
    echo ""
    echo "Options:"
    echo "  --json     - Output as JSON"
    echo "  --pretty   - Pretty-print output"
    echo "  -o FILE    - Output to file"
    echo ""
    echo "Examples:"
    echo "  $0 parse examples/simple.yaml"
    echo "  $0 validate examples/complex.toml"
    echo "  $0 export examples/simple.yaml -o output.json"
}

# Check arguments
if [ $# -lt 2 ]; then
    print_usage
    exit 1
fi

COMMAND="$1"
MANIFEST_FILE="$2"
shift 2

# Check if manifest file exists
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}Error: Manifest file not found: $MANIFEST_FILE${NC}"
    exit 1
fi

# Change to project root
cd "$PROJECT_ROOT"

# Ensure compiled
if [ ! -d "_build/default/lib/manifest_parser" ]; then
    echo -e "${YELLOW}Compiling project...${NC}"
    rebar3 compile
fi

# Execute command
case "$COMMAND" in
    parse)
        echo -e "${GREEN}Parsing manifest: $MANIFEST_FILE${NC}"
        rebar3 lfe run -c cli-interface -- parse "$MANIFEST_FILE" "$@"
        ;;
    validate)
        echo -e "${GREEN}Validating manifest: $MANIFEST_FILE${NC}"
        rebar3 lfe run -c cli-interface -- validate "$MANIFEST_FILE" "$@"
        ;;
    optimize)
        echo -e "${GREEN}Optimizing manifest: $MANIFEST_FILE${NC}"
        rebar3 lfe run -c cli-interface -- optimize "$MANIFEST_FILE" "$@"
        ;;
    inspect)
        echo -e "${GREEN}Inspecting manifest: $MANIFEST_FILE${NC}"
        rebar3 lfe run -c cli-interface -- inspect "$MANIFEST_FILE" "$@"
        ;;
    export)
        echo -e "${GREEN}Exporting manifest: $MANIFEST_FILE${NC}"
        rebar3 lfe run -c cli-interface -- export "$MANIFEST_FILE" "$@"
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        print_usage
        exit 1
        ;;
esac
