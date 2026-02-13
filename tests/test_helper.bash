#!/bin/bash

# Test helper functions for Claude Session Memory plugin tests

# Setup function - runs before each test
setup() {
    # Create temporary directory for test isolation
    export TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="$TEST_TEMP_DIR/home"
    mkdir -p "$HOME"

    # Set up test environment
    export PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"

    # Create test project directory
    export TEST_PROJECT_DIR="$TEST_TEMP_DIR/test-project"
    mkdir -p "$TEST_PROJECT_DIR"

    # Initialize git repo for testing
    cd "$TEST_PROJECT_DIR"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create initial commit
    echo "# Test Project" > README.md
    git add README.md
    git commit -q -m "Initial commit"
}

# Teardown function - runs after each test
teardown() {
    # Clean up temporary directory
    if [ -n "$TEST_TEMP_DIR" ] && [ -d "$TEST_TEMP_DIR" ]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Create a mock hook input JSON
create_hook_input() {
    local session_id="${1:-test-session-123}"
    local cwd="${2:-$TEST_PROJECT_DIR}"
    local hook_event="${3:-Stop}"
    local stop_hook_active="${4:-false}"

    cat <<EOF
{
  "session_id": "$session_id",
  "transcript_path": "$HOME/.claude/projects/test/transcript.jsonl",
  "cwd": "$cwd",
  "permission_mode": "default",
  "hook_event_name": "$hook_event",
  "stop_hook_active": $stop_hook_active
}
EOF
}

# Create a mock hook input for SessionEnd
create_session_end_input() {
    local session_id="${1:-test-session-123}"
    local cwd="${2:-$TEST_PROJECT_DIR}"
    local reason="${3:-logout}"

    cat <<EOF
{
  "session_id": "$session_id",
  "transcript_path": "$HOME/.claude/projects/test/transcript.jsonl",
  "cwd": "$cwd",
  "permission_mode": "default",
  "hook_event_name": "SessionEnd",
  "reason": "$reason"
}
EOF
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "File does not exist: $file" >&2
        return 1
    fi
}

# Assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    if ! grep -qF -- "$text" "$file"; then
        echo "File does not contain expected text: $text" >&2
        echo "File contents:" >&2
        cat "$file" >&2
        return 1
    fi
}

# Assert YAML frontmatter field
assert_yaml_field() {
    local file="$1"
    local field="$2"
    local expected="$3"

    local actual=$(awk -v field="$field:" '/^---$/,/^---$/ {if ($1 == field) print $2}' "$file" | head -1)

    if [ "$actual" != "$expected" ]; then
        echo "YAML field '$field' mismatch:" >&2
        echo "  Expected: $expected" >&2
        echo "  Actual: $actual" >&2
        return 1
    fi
}

# Count lines in file
count_lines() {
    local file="$1"
    wc -l < "$file" | tr -d ' '
}

# Extract YAML frontmatter field
get_yaml_field() {
    local file="$1"
    local field="$2"

    awk -v field="$field:" '
        /^---$/ { in_yaml++; next }
        in_yaml == 1 && $1 == field { $1=""; sub(/^ +/, ""); print; exit }
    ' "$file"
}

# Create test files for modification tracking
create_test_files() {
    echo "test content" > "$TEST_PROJECT_DIR/file1.txt"
    echo "test content" > "$TEST_PROJECT_DIR/file2.js"
    git add file1.txt file2.js
    git commit -q -m "Add test files"
}

# Modify test files
modify_test_files() {
    echo "modified" >> "$TEST_PROJECT_DIR/file1.txt"
    echo "modified" >> "$TEST_PROJECT_DIR/file2.js"
}
