#!/bin/bash
set -euo pipefail

# Get script directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/transcript-parser.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
TRIGGER=$(echo "$INPUT" | jq -r '.trigger')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

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

    # Extract recent context from transcript
    RECENT_CONTEXT=""
    MENTIONED_FILES=""
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        RECENT_CONTEXT=$(extract_recent_context "$TRANSCRIPT_PATH" 5)
        MENTIONED_FILES=$(extract_mentioned_files "$TRANSCRIPT_PATH" 10)
    fi

    # Append compaction note to session file
    cat >> "$SESSION_FILE" << EOF

---

## Compaction Event: $(date +"%H:%M:%S")

Context compaction triggered ($TRIGGER). Session state saved before compaction.

### Recent Context
EOF

    if [ -n "$RECENT_CONTEXT" ]; then
        echo "$RECENT_CONTEXT" >> "$SESSION_FILE"
    else
        echo "*(No recent context available)*" >> "$SESSION_FILE"
    fi

    if [ -n "$MENTIONED_FILES" ]; then
        cat >> "$SESSION_FILE" << EOF

### Files in Focus
\`\`\`
$MENTIONED_FILES
\`\`\`

EOF
    fi
fi

exit 0
