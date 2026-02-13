#!/usr/bin/env bats

load test_helper

@test "precompact hook appends to existing session file" {
    # Create a session file first
    SESSION_ID="test-session-precompact"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

    mkdir -p "$SESSIONS_DIR"
    cat > "$SESSION_FILE" << 'EOF'
---
timestamp_start: 2026-02-13T10:00:00Z
session_id: test-session-precompact
project: test-project
status: in_progress
---

# Session Content

Some work was done here.
EOF

    # Run precompact hook
    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "trigger": "auto"
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    # Verify compaction note was appended
    assert_file_exists "$SESSION_FILE"
    assert_file_contains "$SESSION_FILE" "## Compaction Event:"
    assert_file_contains "$SESSION_FILE" "Context compaction triggered (auto)"
}

@test "precompact hook handles manual trigger" {
    SESSION_ID="test-session-manual"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

    mkdir -p "$SESSIONS_DIR"
    cat > "$SESSION_FILE" << 'EOF'
---
timestamp_start: 2026-02-13T10:00:00Z
session_id: test-session-manual
---

# Session Content
EOF

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "trigger": "manual"
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    assert_file_contains "$SESSION_FILE" "Context compaction triggered (manual)"
}

@test "precompact hook does nothing if session file doesn't exist" {
    SESSION_ID="nonexistent-session"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

    mkdir -p "$SESSIONS_DIR"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "trigger": "auto"
}
EOF
)

    # Should not error even if file doesn't exist
    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    # File should still not exist
    [ ! -f "$SESSION_FILE" ]
}

@test "precompact hook preserves original content" {
    SESSION_ID="test-preserve"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

    mkdir -p "$SESSIONS_DIR"
    ORIGINAL_CONTENT="# Important Session Notes

This content should be preserved.

## Work Done
- Item 1
- Item 2"

    echo "$ORIGINAL_CONTENT" > "$SESSION_FILE"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "trigger": "auto"
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    # Original content should still be there
    assert_file_contains "$SESSION_FILE" "# Important Session Notes"
    assert_file_contains "$SESSION_FILE" "This content should be preserved"
    assert_file_contains "$SESSION_FILE" "- Item 1"

    # New compaction note should be added
    assert_file_contains "$SESSION_FILE" "## Compaction Event:"
}

@test "precompact hook can be called multiple times" {
    SESSION_ID="test-multiple"
    MEMORY_DIR="$HOME/.claude/projects/test-project/memory"
    SESSIONS_DIR="$MEMORY_DIR/sessions"
    SESSION_FILE="$SESSIONS_DIR/${SESSION_ID}.md"

    mkdir -p "$SESSIONS_DIR"
    echo "# Session" > "$SESSION_FILE"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "trigger": "auto"
}
EOF
)

    # Call twice
    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"
    echo "$INPUT" | "$PLUGIN_ROOT/hooks/precompact.sh"

    # Should have two compaction events
    COUNT=$(grep -c "## Compaction Event:" "$SESSION_FILE")
    [ "$COUNT" -eq 2 ]
}
