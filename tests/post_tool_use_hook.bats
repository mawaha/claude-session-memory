#!/usr/bin/env bats

load test_helper

@test "post-tool-use hook creates tool activity log" {
    SESSION_ID="test-post-tool-use"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Read",
  "tool_input": {"file_path": "/tmp/test.txt"},
  "tool_result": "file contents",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_exists "$TOOL_LOG"
}

@test "post-tool-use hook captures WebSearch activity" {
    SESSION_ID="test-websearch"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "WebSearch",
  "tool_input": {"query": "bash YAML parsing"},
  "tool_result": {"results": []},
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_exists "$TOOL_LOG"
    assert_file_contains "$TOOL_LOG" 'activity_type'
    assert_file_contains "$TOOL_LOG" 'research'
    assert_file_contains "$TOOL_LOG" 'bash YAML parsing'
}

@test "post-tool-use hook captures WebFetch activity" {
    SESSION_ID="test-webfetch"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "WebFetch",
  "tool_input": {"url": "https://example.com/docs"},
  "tool_result": "documentation content",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'research'
    assert_file_contains "$TOOL_LOG" 'https://example.com/docs'
}

@test "post-tool-use hook captures file Read activity" {
    SESSION_ID="test-file-read"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Read",
  "tool_input": {"file_path": "/path/to/file.js"},
  "tool_result": "file contents",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'file_read'
    assert_file_contains "$TOOL_LOG" '/path/to/file.js'
}

@test "post-tool-use hook captures file Write activity" {
    SESSION_ID="test-file-write"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Write",
  "tool_input": {"file_path": "/path/to/new.js", "content": "code"},
  "tool_result": "success",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'file_write'
    assert_file_contains "$TOOL_LOG" '/path/to/new.js'
}

@test "post-tool-use hook captures file Edit activity" {
    SESSION_ID="test-file-edit"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Edit",
  "tool_input": {"file_path": "/path/to/existing.js"},
  "tool_result": "success",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'file_edit'
    assert_file_contains "$TOOL_LOG" '/path/to/existing.js'
}

@test "post-tool-use hook captures test command activity" {
    SESSION_ID="test-bash-test"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Bash",
  "tool_input": {"command": "make test"},
  "tool_result": "tests passed",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'testing'
    assert_file_contains "$TOOL_LOG" 'make test'
}

@test "post-tool-use hook captures regular bash command" {
    SESSION_ID="test-bash-regular"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Bash",
  "tool_input": {"command": "ls -la"},
  "tool_result": "file list",
  "is_error": false
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'command'
    assert_file_contains "$TOOL_LOG" 'ls -la'
}

@test "post-tool-use hook appends multiple activities" {
    SESSION_ID="test-multiple-tools"

    # First tool use
    INPUT1=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "WebSearch",
  "tool_input": {"query": "test query"},
  "tool_result": {},
  "is_error": false
}
EOF
)

    # Second tool use
    INPUT2=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Read",
  "tool_input": {"file_path": "/test.js"},
  "tool_result": "content",
  "is_error": false
}
EOF
)

    echo "$INPUT1" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"
    echo "$INPUT2" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"

    # Should have both activities (count tool entries)
    WEBSEARCH_COUNT=$(grep -c 'WebSearch' "$TOOL_LOG")
    READ_COUNT=$(grep -c 'Read' "$TOOL_LOG")
    [ "$WEBSEARCH_COUNT" -ge 1 ]
    [ "$READ_COUNT" -ge 1 ]

    # Should have both activities
    assert_file_contains "$TOOL_LOG" 'WebSearch'
    assert_file_contains "$TOOL_LOG" 'Read'
}

@test "post-tool-use hook records error status" {
    SESSION_ID="test-error-status"

    INPUT=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "cwd": "$TEST_PROJECT_DIR",
  "tool_name": "Read",
  "tool_input": {"file_path": "/nonexistent.txt"},
  "tool_result": "error message",
  "is_error": true
}
EOF
)

    echo "$INPUT" | "$PLUGIN_ROOT/hooks/post-tool-use.sh"

    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"
    assert_file_contains "$TOOL_LOG" 'is_error'
}

@test "stop hook reads tool activity log for activity detection" {
    SESSION_ID="test-stop-reads-log"
    TOOL_LOG="$HOME/.claude/projects/test-project/memory/.tool-activity-${SESSION_ID}.jsonl"

    mkdir -p "$(dirname "$TOOL_LOG")"

    # Create tool log with testing activity
    cat > "$TOOL_LOG" << 'EOF'
{"timestamp":"2026-02-13T10:00:00Z","tool":"Bash","input":{"command":"make test"},"is_error":false,"command":"make test","activity_type":"testing"}
{"timestamp":"2026-02-13T10:01:00Z","tool":"WebSearch","input":{"query":"test"},"is_error":false,"query":"test","activity_type":"research"}
EOF

    # Create transcript (empty for this test)
    TRANSCRIPT_FILE="$HOME/transcript.jsonl"
    touch "$TRANSCRIPT_FILE"

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

    # Check that activities were detected from tool log
    assert_file_contains "$SESSION_FILE" "activities_detected:"

    # Should detect both testing and learning (check file directly since it's an array)
    assert_file_contains "$SESSION_FILE" "testing"
    assert_file_contains "$SESSION_FILE" "learning"
}

@test "stop hook falls back to transcript if tool log missing" {
    SESSION_ID="test-fallback"
    TRANSCRIPT_FILE="$HOME/transcript-fallback.jsonl"

    # Create transcript with test command (no tool log)
    cat > "$TRANSCRIPT_FILE" << 'EOF'
{"role":"assistant","content":[{"type":"tool_use","name":"Bash","input":{"command":"make test"}}]}
EOF

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

    # Should still detect testing activity from transcript
    assert_file_contains "$SESSION_FILE" "activities_detected:"
}
