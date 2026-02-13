#!/usr/bin/env bats

load test_helper

@test "session end hook updates timestamp_end" {
    # Create session file first with stop hook
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Run session end hook
    create_session_end_input | bash "$PLUGIN_ROOT/hooks/session-end.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # timestamp_end should no longer be null
    run grep "timestamp_end: null" "$session_file"
    [ "$status" -eq 1 ]

    # Should have actual timestamp
    assert_file_contains "$session_file" "timestamp_end: 2"
}

@test "session end hook updates status to completed" {
    # Create session file first
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Verify initial status
    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"
    assert_file_contains "$session_file" "status: in_progress"

    # Run session end hook
    create_session_end_input | bash "$PLUGIN_ROOT/hooks/session-end.sh"

    # Status should be updated
    assert_file_contains "$session_file" "status: completed"
}

@test "session end hook adds end_reason" {
    # Create session file first
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Run session end hook with custom reason
    create_session_end_input "test-session-123" "$TEST_PROJECT_DIR" "clear" | \
        bash "$PLUGIN_ROOT/hooks/session-end.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    assert_file_contains "$session_file" "end_reason: clear"
}

@test "session end hook handles missing session file gracefully" {
    # Run session end without creating session first
    create_session_end_input | bash "$PLUGIN_ROOT/hooks/session-end.sh"

    # Should exit successfully without error
    [ "$?" -eq 0 ]
}

@test "session end hook preserves session content" {
    # Create session file
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # Count lines before
    local lines_before=$(count_lines "$session_file")

    # Run session end
    create_session_end_input | bash "$PLUGIN_ROOT/hooks/session-end.sh"

    # Content should still be present
    assert_file_contains "$session_file" "## Summary"
    assert_file_contains "$session_file" "## Work Done"
    assert_file_contains "$session_file" "## Files Modified"
}
