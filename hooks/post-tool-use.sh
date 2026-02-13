#!/bin/bash
set -euo pipefail

# Get script directory for sourcing libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}')
TOOL_RESULT=$(echo "$INPUT" | jq -r '.tool_result // {}')
IS_ERROR=$(echo "$INPUT" | jq -r '.is_error // false')

# Determine project info
if git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    GIT_ROOT=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel)
    PROJECT_NAME=$(basename "$GIT_ROOT")
else
    GIT_ROOT="$PROJECT_DIR"
    PROJECT_NAME=$(basename "$PROJECT_DIR")
fi

# Tool activity log location
MEMORY_DIR="$HOME/.claude/projects/${PROJECT_NAME}/memory"
mkdir -p "$MEMORY_DIR"
TOOL_LOG="$MEMORY_DIR/.tool-activity-${SESSION_ID}.jsonl"

# Generate timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create tool activity entry
ACTIVITY=$(jq -n \
    --arg timestamp "$TIMESTAMP" \
    --arg tool "$TOOL_NAME" \
    --argjson input "$TOOL_INPUT" \
    --argjson is_error "$IS_ERROR" \
    '{
        timestamp: $timestamp,
        tool: $tool,
        input: $input,
        is_error: $is_error
    }')

# Enhance with tool-specific data
case "$TOOL_NAME" in
    "WebSearch")
        QUERY=$(echo "$TOOL_INPUT" | jq -r '.query // empty')
        if [ -n "$QUERY" ]; then
            ACTIVITY=$(echo "$ACTIVITY" | jq --arg query "$QUERY" '. + {query: $query, activity_type: "research"}')
        fi
        ;;

    "WebFetch")
        URL=$(echo "$TOOL_INPUT" | jq -r '.url // empty')
        if [ -n "$URL" ]; then
            ACTIVITY=$(echo "$ACTIVITY" | jq --arg url "$URL" '. + {url: $url, activity_type: "research"}')
        fi
        ;;

    "Read")
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        if [ -n "$FILE_PATH" ]; then
            ACTIVITY=$(echo "$ACTIVITY" | jq --arg file "$FILE_PATH" '. + {file: $file, activity_type: "file_read"}')
        fi
        ;;

    "Write")
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        if [ -n "$FILE_PATH" ]; then
            ACTIVITY=$(echo "$ACTIVITY" | jq --arg file "$FILE_PATH" '. + {file: $file, activity_type: "file_write"}')
        fi
        ;;

    "Edit")
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
        if [ -n "$FILE_PATH" ]; then
            ACTIVITY=$(echo "$ACTIVITY" | jq --arg file "$FILE_PATH" '. + {file: $file, activity_type: "file_edit"}')
        fi
        ;;

    "Bash")
        COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' | head -c 100)
        if [ -n "$COMMAND" ]; then
            # Detect test commands
            if echo "$COMMAND" | grep -qi "pytest\|bats\|npm test\|make test\|cargo test\|go test\|jest"; then
                ACTIVITY=$(echo "$ACTIVITY" | jq --arg cmd "$COMMAND" '. + {command: $cmd, activity_type: "testing"}')
            else
                ACTIVITY=$(echo "$ACTIVITY" | jq --arg cmd "$COMMAND" '. + {command: $cmd, activity_type: "command"}')
            fi
        fi
        ;;
esac

# Append to tool log
echo "$ACTIVITY" >> "$TOOL_LOG"

exit 0
