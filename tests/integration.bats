#!/usr/bin/env bats

load test_helper

@test "full session lifecycle: start to end" {
    # Simulate a complete session lifecycle

    # 1. Stop hook creates session
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # Verify session created with in_progress status
    assert_file_exists "$session_file"
    assert_file_contains "$session_file" "status: in_progress"
    assert_file_contains "$session_file" "timestamp_end: null"

    # 2. SessionEnd hook finalizes
    create_session_end_input | bash "$PLUGIN_ROOT/hooks/session-end.sh"

    # Verify session completed
    assert_file_contains "$session_file" "status: completed"
    run grep "timestamp_end: null" "$session_file"
    [ "$status" -eq 1 ]
    assert_file_contains "$session_file" "end_reason: logout"
}

@test "multiple sessions in same project" {
    # Create multiple sessions
    create_hook_input "session-1" | bash "$PLUGIN_ROOT/hooks/stop.sh"
    create_hook_input "session-2" | bash "$PLUGIN_ROOT/hooks/stop.sh"
    create_hook_input "session-3" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"

    # All session files should exist
    [ -f "$memory_dir/sessions/session-1.md" ]
    [ -f "$memory_dir/sessions/session-2.md" ]
    [ -f "$memory_dir/sessions/session-3.md" ]

    # MEMORY.md should list all three
    assert_file_contains "$memory_dir/MEMORY.md" "session-1"
    assert_file_contains "$memory_dir/MEMORY.md" "session-2"
    assert_file_contains "$memory_dir/MEMORY.md" "session-3"
}

@test "sessions across different branches" {
    cd "$TEST_PROJECT_DIR"

    # Session on main
    create_hook_input "session-main" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Create and switch to feature branch
    git checkout -q -b feature/test

    # Session on feature branch
    create_hook_input "session-feature" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"

    # Verify branch info in sessions
    assert_file_contains "$memory_dir/sessions/session-main.md" "git_branch: main"
    assert_file_contains "$memory_dir/sessions/session-feature.md" "git_branch: feature/test"
}

@test "global index tracks sessions across projects" {
    # Create first project session
    create_hook_input "session-1" "$TEST_PROJECT_DIR" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Create second project
    local project2="$TEST_TEMP_DIR/project2"
    mkdir -p "$project2"
    cd "$project2"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "test" > README.md
    git add README.md
    git commit -q -m "init"

    # Create second project session
    create_hook_input "session-2" "$project2" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Global index should have both
    local global_index="$HOME/.claude/sessions/INDEX.md"
    assert_file_contains "$global_index" "session-1"
    assert_file_contains "$global_index" "session-2"
}
