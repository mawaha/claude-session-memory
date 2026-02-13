#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "📦 Claude Session Memory Plugin Installer"
echo ""

# Get the directory where this script is located
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_NAME="session-memory"
TARGET_DIR="$HOME/.claude/plugins/$PLUGIN_NAME"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: jq is not installed${NC}"
    echo "The plugin requires jq for JSON parsing."
    echo ""
    echo "Install it with:"
    echo "  macOS:   brew install jq"
    echo "  Linux:   apt-get install jq  (or your package manager)"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create plugins directory if it doesn't exist
mkdir -p "$HOME/.claude/plugins"

# Check if symlink already exists
if [ -L "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠️  Symlink already exists at $TARGET_DIR${NC}"
    read -p "Remove and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$TARGET_DIR"
    else
        echo "Installation cancelled."
        exit 0
    fi
elif [ -e "$TARGET_DIR" ]; then
    echo -e "${RED}❌ A file or directory already exists at $TARGET_DIR${NC}"
    echo "Please remove it manually and try again."
    exit 1
fi

# Create symlink
echo "Creating symlink..."
ln -s "$PLUGIN_DIR" "$TARGET_DIR"

# Make hook scripts executable
echo "Making hook scripts executable..."
chmod +x "$PLUGIN_DIR/hooks"/*.sh

# Verify installation
if [ -L "$TARGET_DIR" ] && [ -e "$TARGET_DIR" ]; then
    echo ""
    echo -e "${GREEN}✅ Installation successful!${NC}"
    echo ""
    echo "Plugin location: $TARGET_DIR"
    echo "Points to: $PLUGIN_DIR"
    echo ""
    echo "Next steps:"
    echo "1. Restart Claude Code (if running)"
    echo "2. Verify the plugin is loaded:"
    echo "   - Run: claude"
    echo "   - Try: /session-memory:session-search"
    echo ""
    echo "3. Start working and the plugin will automatically track sessions!"
    echo ""
else
    echo -e "${RED}❌ Installation failed${NC}"
    echo "Symlink verification failed. Please check manually."
    exit 1
fi
