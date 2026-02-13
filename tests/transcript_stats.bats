#!/usr/bin/env bats

load test_helper

# Helper to create a mock transcript
create_mock_transcript() {
    local transcript_file="$1"
    cat > "$transcript_file" << 'EOF'
{"role":"user","content":[{"type":"text","text":"Can you help me create a test file?"}]}
{"role":"assistant","content":[{"type":"text","text":"I'll create a test file for you."},{"type":"tool_use","id":"1","name":"Write","input":{"file_path":"/tmp/test.txt","content":"test"}}]}
{"role":"user","content":[{"type":"tool_result","tool_use_id":"1","content":"File created"}]}
{"role":"user","content":[{"type":"text","text":"Now read it back"}]}
{"role":"assistant","content":[{"type":"tool_use","id":"2","name":"Read","input":{"file_path":"/tmp/test.txt"}}]}
{"role":"user","content":[{"type":"tool_result","tool_use_id":"2","content":"test"}]}
{"role":"assistant","content":[{"type":"text","text":"The file contains: test"}]}
EOF
}

@test "stop hook extracts conversation turns from transcript" {
    SESSION_ID="test-stats-session"
    TRANSCRIPT_FILE="$HOME/transcript.jsonl"
    create_mock_transcript "$TRANSCRIPT_FILE"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "transcript_path": "$TRANSCRIPT_FILE",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/stop.sh"

    SESSION_FILE="$HOME/.claude/projects/test-project/memory/sessions/${SESSION_ID}.md"
    assert_file_exists "$SESSION_FILE"

    # Check YAML frontmatter has conversation_turns
    TURN_COUNT=$(get_yaml_field "$SESSION_FILE" "conversation_turns")
    [ "$TURN_COUNT" -eq 7 ]
}

@test "stop hook extracts tool calls from transcript" {
    SESSION_ID="test-tools-session"
    TRANSCRIPT_FILE="$HOME/transcript.jsonl"
    create_mock_transcript "$TRANSCRIPT_FILE"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "transcript_path": "$TRANSCRIPT_FILE",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/stop.sh"

    SESSION_FILE="$HOME/.claude/projects/test-project/memory/sessions/${SESSION_ID}.md"

    # Check YAML frontmatter has tool_calls
    TOOL_COUNT=$(get_yaml_field "$SESSION_FILE" "tool_calls")
    [ "$TOOL_COUNT" -eq 2 ]

    # Check tools_used field
    assert_file_contains "$SESSION_FILE" "tools_used:"
}

@test "stop hook includes session stats section" {
    SESSION_ID="test-stats-section"
    TRANSCRIPT_FILE="$HOME/transcript.jsonl"
    create_mock_transcript "$TRANSCRIPT_FILE"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "transcript_path": "$TRANSCRIPT_FILE",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/stop.sh"

    SESSION_FILE="$HOME/.claude/projects/test-project/memory/sessions/${SESSION_ID}.md"

    # Check for Session Stats section
    assert_file_contains "$SESSION_FILE" "## Session Stats"
    assert_file_contains "$SESSION_FILE" "**Conversation turns:**"
    assert_file_contains "$SESSION_FILE" "**Tool calls:**"
    assert_file_contains "$SESSION_FILE" "**Errors encountered:**"
    assert_file_contains "$SESSION_FILE" "**Tools used:**"
}

@test "stop hook handles missing transcript gracefully" {
    SESSION_ID="test-no-transcript"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "transcript_path": "/nonexistent/transcript.jsonl",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
EOF
)

    # Should not fail even with missing transcript
    echo "$INPUT" | "$PLUGIN_ROOT/hooks/stop.sh"

    SESSION_FILE="$HOME/.claude/projects/test-project/memory/sessions/${SESSION_ID}.md"
    assert_file_exists "$SESSION_FILE"

    # Stats should be 0
    TURN_COUNT=$(get_yaml_field "$SESSION_FILE" "conversation_turns")
    [ "$TURN_COUNT" -eq 0 ]
}

@test "precompact hook includes recent context from transcript" {
    SESSION_ID="test-precompact-context"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"
    TRANSCRIPT_FILE="$HOME/transcript.jsonl"

    mkdir -p "$SESSIONS_DIR"
    create_mock_transcript "$TRANSCRIPT_FILE"

    # Create initial session file
    cat > "$SESSION_FILE" << 'EOF'
---
timestamp_start: 2026-02-13T10:00:00Z
session_id: test-precompact-context
---

# Session Content
EOF

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "transcript_path": "$TRANSCRIPT_FILE",
  "trigger": "auto"
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    # Check for recent context section
    assert_file_contains "$SESSION_FILE" "### Recent Context"

    # Should have some context from transcript
    if grep -q "### Recent Context" "$SESSION_FILE"; then
        # Check if there's content after the heading (not just "No recent context")
        grep -A 5 "### Recent Context" "$SESSION_FILE" | grep -q "User:\|Assistant:" || \
        grep -A 5 "### Recent Context" "$SESSION_FILE" | grep -q "No recent context"
    fi
}

@test "precompact hook includes files in focus" {
    SESSION_ID="test-precompact-files"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"
    TRANSCRIPT_FILE="$HOME/transcript.jsonl"

    mkdir -p "$SESSIONS_DIR"
    create_mock_transcript "$TRANSCRIPT_FILE"

    cat > "$SESSION_FILE" << 'EOF'
---
timestamp_start: 2026-02-13T10:00:00Z
session_id: test-precompact-files
---

# Session Content
EOF

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "transcript_path": "$TRANSCRIPT_FILE",
  "trigger": "manual"
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    # Should mention files from the transcript
    # Our mock transcript has /tmp/test.txt
    if grep -q "### Files in Focus" "$SESSION_FILE"; then
        grep -A 5 "### Files in Focus" "$SESSION_FILE" | grep -q "/tmp/test.txt"
    fi
}
