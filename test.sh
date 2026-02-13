#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Claude Session Memory Plugin - Test Suite"
echo ""

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}❌ bats is not installed${NC}"
    echo ""
    echo "Install bats to run tests:"
    echo "  macOS:   brew install bats-core"
    echo "  Linux:   npm install -g bats (or use package manager)"
    echo ""
    echo "Or install bats-core from source:"
    echo "  git clone https://github.com/bats-core/bats-core.git"
    echo "  cd bats-core"
    echo "  sudo ./install.sh /usr/local"
    echo ""
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: jq is not installed${NC}"
    echo "Some tests may fail without jq."
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    echo ""
fi

# Run tests
echo "Running tests..."
echo ""

if bats tests/*.bats; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
