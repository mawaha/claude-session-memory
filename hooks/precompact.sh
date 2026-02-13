#!/bin/bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger')

# Determine project info
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    GIT_ROOT=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel)
    PROJECT_NAME=$(basename "$GIT_ROOT")
else
    GIT_ROOT="$PROJECT_DIR"
    PROJECT_NAME=$(basename "$PROJECT_DIR")
fi

# Use project name for memory directory
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_NAME}/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

# Only update if session file exists
if [ -f "$SESSION_FILE" ]; then
    COMPACT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Append compaction note to session file
    cat >> "$SESSION_FILE" << EOF

---

## Compaction Event: $(date +"%H:%M:%S")

Context compaction triggered ($TRIGGER). Session state saved before compaction.

EOF
fi

exit 0
