#!/usr/bin/env bats

load test_helper

@test "stop hook creates session file on first run" {
    # Run the stop hook with mock input
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Assert session file was created
    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    assert_file_exists "$session_file"
}

@test "stop hook creates YAML frontmatter with correct fields" {
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # Check required YAML fields exist
    assert_file_contains "$session_file" "session_id: test-session-123"
    assert_file_contains "$session_file" "status: in_progress"
    assert_file_contains "$session_file" "timestamp_start:"
    assert_file_contains "$session_file" "timestamp_end: null"
}

@test "stop hook creates MEMORY.md index" {
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local memory_file="$memory_dir/MEMORY.md"

    assert_file_exists "$memory_file"
    assert_file_contains "$memory_file" "## Recent Sessions"
}

@test "stop hook updates MEMORY.md on subsequent runs" {
    # First run
    create_hook_input "session-1" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Second run
    create_hook_input "session-2" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local memory_file="$memory_dir/MEMORY.md"

    # Should contain both sessions
    assert_file_contains "$memory_file" "session-1"
    assert_file_contains "$memory_file" "session-2"
}

@test "stop hook limits MEMORY.md to 200 lines" {
    # Create a large MEMORY.md
    local memory_dir="$HOME/.claude/projects/test-project/memory"
    mkdir -p "$memory_dir"

    # Create 250 lines
    for i in {1..250}; do
        echo "Line $i" >> "$memory_dir/MEMORY.md"
    done

    # Run hook
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Check file is trimmed
    local line_count=$(count_lines "$memory_dir/MEMORY.md")
    [ "$line_count" -le 200 ]
}

@test "stop hook does not run when stop_hook_active is true" {
    # Run with stop_hook_active=true
    create_hook_input "test-session" "$TEST_PROJECT_DIR" "Stop" "true" | \
        bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session.md"

    # Session file should not be created
    [ ! -f "$session_file" ]
}

@test "stop hook appends update to existing session file" {
    # First run - creates file
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # Second run - should append
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Check for update marker
    assert_file_contains "$session_file" "## Update:"
}

@test "stop hook detects git branch and commit" {
    # Create a feature branch
    cd "$TEST_PROJECT_DIR"
    git checkout -q -b feature/test-branch

    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    assert_file_contains "$session_file" "git_branch: feature/test-branch"
}

@test "stop hook tracks modified files count" {
    create_test_files
    modify_test_files

    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # Should show 2 files modified
    assert_file_contains "$session_file" "files_modified_count: 2"
}

@test "stop hook auto-detects tags for test files" {
    create_test_files
    echo "test" > "$TEST_PROJECT_DIR/test.spec.js"
    git add test.spec.js

    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local session_file="$memory_dir/sessions/test-session-123.md"

    # Should detect testing tag
    assert_file_contains "$session_file" "testing"
}

@test "stop hook creates global index entry" {
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local global_index="$HOME/.claude/sessions/INDEX.md"

    assert_file_exists "$global_index"
    assert_file_contains "$global_index" "test-session-123"
}
