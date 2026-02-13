#!/usr/bin/env bats

load test_helper

@test "MEMORY.md stays under 200 lines with many sessions" {
    # Create 20 sessions
    for i in {1..20}; do
        create_hook_input "session-$i" | bash "$PLUGIN_ROOT/hooks/stop.sh"
    done

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local memory_file="$memory_dir/MEMORY.md"

    local line_count=$(count_lines "$memory_file")
    [ "$line_count" -le 200 ]
}

@test "MEMORY.md keeps only last 10 sessions in index" {
    # Create 15 sessions
    for i in {1..15}; do
        create_hook_input "session-$i" | bash "$PLUGIN_ROOT/hooks/stop.sh"
    done

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local memory_file="$memory_dir/MEMORY.md"

    # Extract session count from Recent Sessions section
    local session_count=$(awk '/^## Recent Sessions/,/^## / {if (/^- \[/) print}' "$memory_file" | wc -l | tr -d ' ')

    [ "$session_count" -le 10 ]
}

@test "MEMORY.md is created with proper structure" {
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local memory_file="$memory_dir/MEMORY.md"

    # Check for all required sections
    assert_file_contains "$memory_file" "## Recent Sessions"
    assert_file_contains "$memory_file" "## Active Work"
    assert_file_contains "$memory_file" "## Key Patterns"
    assert_file_contains "$memory_file" "## Quick Commands"
    assert_file_contains "$memory_file" "## Topic Files"
}

@test "MEMORY.md includes topic file links" {
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local memory_file="$memory_dir/MEMORY.md"

    # Check for topic file references
    assert_file_contains "$memory_file" "[Architecture](architecture.md)"
    assert_file_contains "$memory_file" "[Learnings](learnings.md)"
    assert_file_contains "$memory_file" "[Patterns](patterns.md)"
    assert_file_contains "$memory_file" "[Debugging](debugging.md)"
}

@test "session files are organized in sessions directory" {
    create_hook_input "session-1" | bash "$PLUGIN_ROOT/hooks/stop.sh"
    create_hook_input "session-2" | bash "$PLUGIN_ROOT/hooks/stop.sh"

    local memory_dir="$HOME/.claude/projects/test-project/memory"
    local sessions_dir="$memory_dir/sessions"

    # Check sessions directory exists
    [ -d "$sessions_dir" ]

    # Check both session files exist
    [ -f "$sessions_dir/session-1.md" ]
    [ -f "$sessions_dir/session-2.md" ]
}
