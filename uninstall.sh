#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🗑️  Claude Session Memory Plugin Uninstaller"
echo ""

PLUGIN_NAME="session-memory"
TARGET_DIR="$HOME/.claude/plugins/$PLUGIN_NAME"

# Remove the plugin symlink
if [ -L "$TARGET_DIR" ]; then
    echo "Removing plugin symlink..."
    rm "$TARGET_DIR"
    echo -e "${GREEN}✅ Plugin symlink removed${NC}"
elif [ -e "$TARGET_DIR" ]; then
    echo -e "${RED}❌ $TARGET_DIR exists but is not a symlink${NC}"
    echo "This may have been installed manually. Remove it yourself with:"
    echo "  rm -rf $TARGET_DIR"
    exit 1
else
    echo -e "${YELLOW}⚠️  Plugin symlink not found at $TARGET_DIR${NC}"
    echo "The plugin may not have been installed."
fi

echo ""

# Offer to remove session memory data
MEMORY_DIRS=()
while IFS= read -r -d '' dir; do
    MEMORY_DIRS+=("$dir")
done < <(find "$HOME/.claude/projects" -maxdepth 2 -type d -name "memory" -print0 2>/dev/null)

GLOBAL_INDEX="$HOME/.claude/sessions/INDEX.md"

if [ ${#MEMORY_DIRS[@]} -gt 0 ] || [ -f "$GLOBAL_INDEX" ]; then
    echo "The following session data was created by this plugin:"
    echo ""

    for dir in "${MEMORY_DIRS[@]}"; do
        local_count=$(find "$dir" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
        echo "  $dir  ($local_count session files)"
    done

    if [ -f "$GLOBAL_INDEX" ]; then
        echo "  $GLOBAL_INDEX"
    fi

    echo ""
    read -p "Remove all session data? This cannot be undone. (y/N) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for dir in "${MEMORY_DIRS[@]}"; do
            rm -rf "$dir"
        done

        if [ -f "$GLOBAL_INDEX" ]; then
            rm "$GLOBAL_INDEX"
            # Remove sessions dir if now empty
            rmdir "$HOME/.claude/sessions" 2>/dev/null || true
        fi

        echo -e "${GREEN}✅ Session data removed${NC}"
    else
        echo "Session data kept."
    fi
else
    echo "No session data found."
fi

echo ""
echo -e "${GREEN}✅ Uninstall complete${NC}"
echo "Restart Claude Code if it is currently running."
