#!/bin/bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
END_REASON=$(echo "$INPUT" | jq -r '.reason')

# Determine project info
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    GIT_ROOT=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel)
    PROJECT_NAME=$(basename "$GIT_ROOT")
else
    GIT_ROOT="$PROJECT_DIR"
    PROJECT_NAME=$(basename "$PROJECT_DIR")
fi

# Use project name for memory directory (simpler and more predictable)
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_NAME}/memory"
SESSIONS_DIR="$MEMORY_DIR/sessions"
SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

# Only update if session file exists
if [ -f "$SESSION_FILE" ]; then
    END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create temporary file for awk processing
    TEMP_FILE=$(mktemp)

    # Update frontmatter fields
    awk -v end_time="$END_TIME" -v end_reason="$END_REASON" '
        BEGIN { in_frontmatter=0; frontmatter_ended=0 }
        /^---$/ && !in_frontmatter {
            in_frontmatter=1
            print
            next
        }
        /^---$/ && in_frontmatter && !frontmatter_ended {
            print "end_reason: " end_reason
            print
            frontmatter_ended=1
            next
        }
        /^timestamp_end:/ && in_frontmatter {
            print "timestamp_end: " end_time
            next
        }
        /^status:/ && in_frontmatter {
            print "status: completed"
            next
        }
        { print }
    ' "$SESSION_FILE" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$SESSION_FILE"
fi

exit 0
