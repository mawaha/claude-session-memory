#!/bin/bash
# Transcript parsing utilities for session memory hooks

# Extract basic stats from transcript
# Usage: extract_transcript_stats <transcript_path>
extract_transcript_stats() {
    local transcript="$1"

    if [ ! -f "$transcript" ]; then
        echo "{}"
        return
    fi

    local turn_count=0
    local tool_calls=0
    local errors=0
    local tools_used=""

    while IFS= read -r line; do
        # Count turns (messages)
        if echo "$line" | jq -e '.role' > /dev/null 2>&1; then
            ((turn_count++))
        fi

        # Count tool calls
        if echo "$line" | jq -e '.content[]? | select(.type == "tool_use")' > /dev/null 2>&1; then
            ((tool_calls++))

            # Extract tool names
            local tool_name=$(echo "$line" | jq -r '.content[]? | select(.type == "tool_use") | .name' 2>/dev/null)
            if [ -n "$tool_name" ] && [ "$tool_name" != "null" ]; then
                if [ -z "$tools_used" ]; then
                    tools_used="$tool_name"
                elif ! echo "$tools_used" | grep -q "$tool_name"; then
                    tools_used="$tools_used, $tool_name"
                fi
            fi
        fi

        # Count errors (tool results with errors or assistant messages mentioning errors)
        if echo "$line" | jq -e '.content[]? | select(.type == "tool_result") | .is_error' 2>/dev/null | grep -q true; then
            ((errors++))
        fi
    done < "$transcript"

    # Output as JSON
    jq -n \
        --arg turns "$turn_count" \
        --arg tools "$tool_calls" \
        --arg errors "$errors" \
        --arg tool_list "$tools_used" \
        '{
            turn_count: ($turns | tonumber),
            tool_calls: ($tools | tonumber),
            errors: ($errors | tonumber),
            tools_used: $tool_list
        }'
}

# Extract last N conversation turns
# Usage: extract_recent_context <transcript_path> <num_turns>
extract_recent_context() {
    local transcript="$1"
    local num_turns="${2:-5}"

    if [ ! -f "$transcript" ]; then
        echo ""
        return
    fi

    # Get last N lines (each line is a turn)
    local recent_turns=$(tail -n "$num_turns" "$transcript")

    local context=""
    while IFS= read -r line; do
        local role=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)

        if [ "$role" = "user" ]; then
            local text=$(echo "$line" | jq -r '.content[0].text // .content // empty' 2>/dev/null | head -c 200)
            if [ -n "$text" ]; then
                context="${context}**User:** ${text}...\n\n"
            fi
        elif [ "$role" = "assistant" ]; then
            # Extract text content (skip tool use for brevity)
            local text=$(echo "$line" | jq -r '.content[]? | select(.type == "text") | .text' 2>/dev/null | head -c 200)
            if [ -n "$text" ]; then
                context="${context}**Assistant:** ${text}...\n\n"
            fi

            # Extract tool calls
            local tools=$(echo "$line" | jq -r '.content[]? | select(.type == "tool_use") | .name' 2>/dev/null | head -5)
            if [ -n "$tools" ]; then
                local tool_list=$(echo "$tools" | paste -sd "," - | sed 's/,/, /g')
                context="${context}*Tools used: ${tool_list}*\n\n"
            fi
        fi
    done <<< "$recent_turns"

    echo -e "$context"
}

# Extract files mentioned in recent turns
# Usage: extract_mentioned_files <transcript_path> <num_turns>
extract_mentioned_files() {
    local transcript="$1"
    local num_turns="${2:-10}"

    if [ ! -f "$transcript" ]; then
        echo ""
        return
    fi

    # Get last N turns and extract file paths
    tail -n "$num_turns" "$transcript" | \
        jq -r '
            .content[]? |
            select(.type == "tool_use") |
            select(.name == "Read" or .name == "Edit" or .name == "Write") |
            .input.file_path // empty
        ' 2>/dev/null | \
        sort -u | \
        head -10
}
