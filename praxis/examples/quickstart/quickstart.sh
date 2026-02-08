#!/bin/bash
# WP Praxis Quick Start Script
# One-command setup for development environment

set -e

echo "================================"
echo "WP Praxis Quick Start"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WP_PRAXIS_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo -e "${YELLOW}WP Praxis root: $WP_PRAXIS_ROOT${NC}"
echo ""

# Check for required tools
echo "Step 1: Checking prerequisites..."

check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1 found"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 not found"
        return 1
    fi
}

MISSING_DEPS=0

check_command "git" || MISSING_DEPS=1
check_command "cargo" || MISSING_DEPS=1
check_command "pwsh" || MISSING_DEPS=1
check_command "php" || MISSING_DEPS=1
check_command "mix" || MISSING_DEPS=1
check_command "bun" || MISSING_DEPS=1
check_command "docker" || echo -e "  ${YELLOW}⚠${NC}  docker not found (optional)"
check_command "psql" || echo -e "  ${YELLOW}⚠${NC}  postgresql not found (optional)"

if [ $MISSING_DEPS -eq 1 ]; then
    echo -e "${RED}Error: Missing required dependencies${NC}"
    echo "Please install missing tools and try again"
    echo "See: Docs/installation.md"
    exit 1
fi

echo ""

# Build Rust injector
echo "Step 2: Building Rust injector..."
cd "$WP_PRAXIS_ROOT/wp_injector"
cargo build --release
echo -e "${GREEN}✓ Rust injector built${NC}"
echo ""

# Setup Elixir CLI
echo "Step 3: Setting up Elixir CLI..."
cd "$WP_PRAXIS_ROOT/Core/cli-wrapper"
mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
echo -e "${GREEN}✓ Elixir CLI ready${NC}"
echo ""

# Install TypeScript dependencies
echo "Step 4: Installing TypeScript dependencies..."
cd "$WP_PRAXIS_ROOT/SymbolicEngine/swarm"
bun install
echo -e "${GREEN}✓ Swarm dependencies installed${NC}"

cd "$WP_PRAXIS_ROOT/SymbolicEngine/dashboard"
bun install
echo -e "${GREEN}✓ Dashboard dependencies installed${NC}"
echo ""

# Create output directories
echo "Step 5: Creating output directories..."
mkdir -p "$WP_PRAXIS_ROOT/outputs"
mkdir -p "$WP_PRAXIS_ROOT/reports"
mkdir -p "$WP_PRAXIS_ROOT/baselines"
mkdir -p "$WP_PRAXIS_ROOT/archives"
echo -e "${GREEN}✓ Directories created${NC}"
echo ""

# Create config file if it doesn't exist
echo "Step 6: Configuring WP Praxis..."
CONFIG_DIR="$HOME/.wp-praxis"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << 'EOF'
wordpress:
  path: "/var/www/html"
  url: "http://localhost"

database:
  connection: "postgresql://localhost/wp_praxis_dev"
  pool_size: 10

outputs:
  directory: "./outputs"

logging:
  level: "info"
  file: "./wp-praxis.log"

swarm:
  dispatcher:
    host: "localhost"
    port: 8080
EOF
    echo -e "${GREEN}✓ Config file created: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}  Please edit this file to match your environment${NC}"
else
    echo -e "${GREEN}✓ Config file exists: $CONFIG_FILE${NC}"
fi
echo ""

# Optional: Setup database
read -p "Setup PostgreSQL database? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Setting up PostgreSQL..."

    # Check if database exists
    if psql -lqt | cut -d \| -f 1 | grep -qw wp_praxis_dev; then
        echo -e "${YELLOW}Database wp_praxis_dev already exists${NC}"
    else
        createdb wp_praxis_dev
        echo -e "${GREEN}✓ Database created${NC}"
    fi

    # Run migrations
    cd "$WP_PRAXIS_ROOT/Core/cli-wrapper"
    mix ecto.migrate
    echo -e "${GREEN}✓ Migrations complete${NC}"
fi
echo ""

# Run example workflow
read -p "Run example workflow? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Running example workflow..."
    cd "$WP_PRAXIS_ROOT"

    pwsh SymbolicEngine/core/symbolic.ps1 \
        -WorkflowPath examples/tutorials/01-getting-started/simple-workflow.yaml \
        -Verbose

    echo -e "${GREEN}✓ Example workflow executed${NC}"
fi
echo ""

# Optional: Start dashboard
read -p "Start dashboard? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting dashboard..."
    cd "$WP_PRAXIS_ROOT/SymbolicEngine/dashboard"
    echo -e "${GREEN}Dashboard starting at http://localhost:3000${NC}"
    bun run dev &

    # Wait for dashboard to start
    sleep 3

    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:3000
    elif command -v open &> /dev/null; then
        open http://localhost:3000
    else
        echo -e "${YELLOW}Open http://localhost:3000 in your browser${NC}"
    fi
fi
echo ""

# Success message
echo "================================"
echo -e "${GREEN}✓ WP Praxis Quick Start Complete!${NC}"
echo "================================"
echo ""
echo "Next steps:"
echo "  1. Edit config: $CONFIG_FILE"
echo "  2. Review tutorials: $WP_PRAXIS_ROOT/examples/tutorials/"
echo "  3. Run workflows: pwsh SymbolicEngine/core/symbolic.ps1 --help"
echo "  4. View dashboard: http://localhost:3000"
echo ""
echo "Documentation: $WP_PRAXIS_ROOT/Docs/"
echo "Examples: $WP_PRAXIS_ROOT/examples/"
echo ""
echo "Happy coding!"
