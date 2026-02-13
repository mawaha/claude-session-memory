#!/bin/bash
set -euo pipefail

# Get script directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/transcript-parser.sh"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
PERMISSION_MODE=$(echo "$INPUT" | jq -r '.permission_mode')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')

# Prevent infinite loops
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Determine project info
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    GIT_ROOT=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel)
    PROJECT_NAME=$(basename "$GIT_ROOT")
    GIT_BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    GIT_COMMIT=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
else
    GIT_ROOT="$PROJECT_DIR"
    PROJECT_NAME=$(basename "$PROJECT_DIR")
    GIT_BRANCH="n/a"
    GIT_COMMIT="n/a"
fi

# Use project name for memory directory (simpler and more predictable)
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_NAME}/memory"
mkdir -p "$MEMORY_DIR"

SESSIONS_DIR="$MEMORY_DIR/sessions"
mkdir -p "$SESSIONS_DIR"

# Session file path (using session_id for uniqueness)
SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

# Generate timestamps
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get files modified
FILES_MODIFIED=$(cd "$PROJECT_DIR" && git diff --name-only HEAD 2>/dev/null | head -20 || echo "")
if [ -z "$FILES_MODIFIED" ]; then
    FILES_MODIFIED_COUNT=0
else
    FILES_MODIFIED_COUNT=$(echo "$FILES_MODIFIED" | wc -l | tr -d ' ')
fi

# Auto-detect tags
TAGS="[]"
if [ -n "$(git -C "$PROJECT_DIR" status --short 2>/dev/null)" ]; then
    TAGS=$(echo "$TAGS" | jq '. + ["work-in-progress"]')
fi
if echo "$FILES_MODIFIED" | grep -qi "test" 2>/dev/null; then
    TAGS=$(echo "$TAGS" | jq '. + ["testing"]')
fi
if echo "$FILES_MODIFIED" | grep -qi "\.md$" 2>/dev/null; then
    TAGS=$(echo "$TAGS" | jq '. + ["documentation"]')
fi

# Extract transcript stats
TRANSCRIPT_STATS=$(extract_transcript_stats "$TRANSCRIPT_PATH")
TURN_COUNT=$(echo "$TRANSCRIPT_STATS" | jq -r '.turn_count // 0')
TOOL_CALLS=$(echo "$TRANSCRIPT_STATS" | jq -r '.tool_calls // 0')
ERRORS=$(echo "$TRANSCRIPT_STATS" | jq -r '.errors // 0')
TOOLS_USED=$(echo "$TRANSCRIPT_STATS" | jq -r '.tools_used // ""')

# Detect activities for topic file consolidation
ACTIVITIES="[]"

# Testing activity: test commands found in transcript
if [ -f "$TRANSCRIPT_PATH" ]; then
    if grep -qi "pytest\|bats\|npm test\|npm run test\|make test\|cargo test\|go test\|jest" "$TRANSCRIPT_PATH" 2>/dev/null; then
        ACTIVITIES=$(echo "$ACTIVITIES" | jq '. + ["testing"]')
    fi

    # Debugging activity: errors were encountered
    if [ "$ERRORS" -gt 0 ]; then
        ACTIVITIES=$(echo "$ACTIVITIES" | jq '. + ["debugging"]')
    fi

    # Learning activity: research tools used
    if grep -qi "WebSearch\|WebFetch" "$TRANSCRIPT_PATH" 2>/dev/null; then
        ACTIVITIES=$(echo "$ACTIVITIES" | jq '. + ["learning"]')
    fi

    # Architecture activity: new directories or major structural changes
    if grep -qi "mkdir\|Write.*\.md\|create.*directory" "$TRANSCRIPT_PATH" 2>/dev/null; then
        ACTIVITIES=$(echo "$ACTIVITIES" | jq '. + ["architecture"]')
    fi

    # Refactoring activity: Edit tool used heavily
    EDIT_COUNT=$(grep -c '"name":"Edit"' "$TRANSCRIPT_PATH" 2>/dev/null || echo "0")
    if [ "$EDIT_COUNT" -gt 5 ]; then
        ACTIVITIES=$(echo "$ACTIVITIES" | jq '. + ["refactoring"]')
    fi
fi

# Check if session file exists
if [ ! -f "$SESSION_FILE" ]; then
    # Create new session file
    cat > "$SESSION_FILE" << EOF
---
timestamp_start: $ISO_TIMESTAMP
timestamp_end: null
session_id: $SESSION_ID
project: $PROJECT_NAME
git_branch: $GIT_BRANCH
git_commit: $GIT_COMMIT
files_modified_count: $FILES_MODIFIED_COUNT
permission_mode: $PERMISSION_MODE
status: in_progress
tags: $TAGS
transcript: $TRANSCRIPT_PATH
conversation_turns: $TURN_COUNT
tool_calls: $TOOL_CALLS
errors_encountered: $ERRORS
tools_used: "$TOOLS_USED"
activities_detected: $ACTIVITIES
needs_summary: true
needs_consolidation: true
---

# Session: $TIMESTAMP

## Summary
<!-- Add a one-line summary of what was accomplished -->
<!-- Or run /session-memory:summarize to auto-generate -->

## Session Stats
- **Conversation turns:** $TURN_COUNT
- **Tool calls:** $TOOL_CALLS
- **Errors encountered:** $ERRORS
- **Tools used:** $TOOLS_USED

## Work Done
<!-- Key accomplishments and changes made -->

## Files Modified
\`\`\`
$FILES_MODIFIED
\`\`\`

## Decisions Made
<!-- Important architectural or implementation decisions -->

## Next Steps
<!-- What to work on next session -->

## Notes
<!-- Any other context worth preserving -->

---

**Full transcript:** [$TRANSCRIPT_PATH](file://$TRANSCRIPT_PATH)
EOF

    # Update MEMORY.md
    MEMORY_FILE="$MEMORY_DIR/MEMORY.md"

    if [ ! -f "$MEMORY_FILE" ]; then
        # Create initial MEMORY.md
        cat > "$MEMORY_FILE" << EOF
# $PROJECT_NAME - Project Memory

Last updated: $ISO_TIMESTAMP

## Recent Sessions
- [$TIMESTAMP](sessions/${SESSION_ID}.md) - $GIT_BRANCH @ $GIT_COMMIT - $FILES_MODIFIED_COUNT files

## Active Work
Current branch: $GIT_BRANCH

## Key Patterns
<!-- Claude extracts patterns from sessions into this section -->

## Quick Commands
<!-- Frequently used commands discovered during sessions -->

## Topic Files
- [Architecture](architecture.md) - System design and decisions
- [Learnings](learnings.md) - Insights and solutions discovered
- [Patterns](patterns.md) - Development patterns and conventions
- [Debugging](debugging.md) - Solutions to problems encountered

EOF
    else
        # Update existing MEMORY.md
        TEMP_FILE=$(mktemp)

        awk -v new_line="- [$TIMESTAMP](sessions/${SESSION_ID}.md) - $GIT_BRANCH @ $GIT_COMMIT - $FILES_MODIFIED_COUNT files" \
            -v timestamp="$ISO_TIMESTAMP" \
            -v branch="$GIT_BRANCH" '
            BEGIN { in_recent=0; sessions=0 }
            /^Last updated:/ {
                print "Last updated: " timestamp
                next
            }
            /^## Recent Sessions/ {
                print
                print new_line
                in_recent=1
                next
            }
            /^## / && in_recent==1 {
                in_recent=0
            }
            in_recent==1 {
                sessions++
                if (sessions <= 9) print
                next
            }
            /^Current branch:/ {
                print "Current branch: " branch
                next
            }
            { print }
        ' "$MEMORY_FILE" > "$TEMP_FILE"

        mv "$TEMP_FILE" "$MEMORY_FILE"
    fi

    # Ensure MEMORY.md stays under 200 lines
    LINE_COUNT=$(wc -l < "$MEMORY_FILE")
    if [ "$LINE_COUNT" -gt 200 ]; then
        head -195 "$MEMORY_FILE" > "$MEMORY_FILE.tmp"
        echo "" >> "$MEMORY_FILE.tmp"
        echo "<!-- Trimmed to 200 lines. See topic files and sessions/ for details. -->" >> "$MEMORY_FILE.tmp"
        mv "$MEMORY_FILE.tmp" "$MEMORY_FILE"
    fi

else
    # Session file exists - append update
    cat >> "$SESSION_FILE" << EOF

---

## Update: $(date +"%H:%M:%S")

Stop hook triggered again. Claude continued working.

### Files Modified (update)
\`\`\`
$FILES_MODIFIED
\`\`\`

EOF
fi

# Update global index
GLOBAL_INDEX="$HOME/.claude/sessions/INDEX.md"
mkdir -p "$(dirname "$GLOBAL_INDEX")"

if ! grep -q "$SESSION_ID" "$GLOBAL_INDEX" 2>/dev/null; then
    echo "- [$ISO_TIMESTAMP] **$PROJECT_NAME** ($GIT_BRANCH) → [session](file://$SESSION_FILE)" >> "$GLOBAL_INDEX"
fi

exit 0
