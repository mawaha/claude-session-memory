# Session Memory Plugin for Claude Code

Automatic session memory tracking with YAML frontmatter and searchable history.

## Features

- 📝 **Automatic session tracking** - Stop and SessionEnd hooks capture session details
- 🏷️ **YAML frontmatter** - Structured metadata for easy searching
- 🔍 **Session search** - `/session-memory:session-search` skill to find past sessions
- 🧠 **Memory consolidation** - `/session-memory:memory-consolidate` skill to extract learnings
- 📊 **Auto memory integration** - Works with Claude Code's auto memory system

## Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-session-memory.git

# Run the installation script
cd claude-session-memory
./install.sh
```

The install script will:
1. Create a symlink in `~/.claude/plugins/session-memory`
2. Make hook scripts executable

### Manual Install

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-session-memory.git

# Create symlink
ln -s "$(pwd)/claude-session-memory" ~/.claude/plugins/session-memory

# Make scripts executable
chmod +x claude-session-memory/hooks/*.sh
```

### Verify Installation

After installation, restart Claude Code and verify the plugin is loaded:

```bash
claude
```

Then check for the skills:
```
/session-memory:session-search
/session-memory:memory-consolidate
```

## How It Works

### Stop Hook
- Runs when Claude finishes responding
- Creates session file with YAML frontmatter containing metadata
- Updates MEMORY.md index (auto-loaded in next session)
- Handles multiple Stop invocations gracefully

### SessionEnd Hook
- Runs when session terminates
- Finalizes session metadata (end time, duration, reason)
- Updates session status to "completed"

### Session Files
Located at: `~/.claude/projects/<project>/memory/sessions/<session-id>.md`

Each file contains:
- **YAML frontmatter** with structured metadata
- Summary of work done
- Files modified
- Decisions made
- Next steps

### MEMORY.md
Auto-loaded (first 200 lines) in every session, contains:
- Last 10 session links (1 line each)
- Key patterns extracted from sessions
- Links to topic files for detailed information

## Session Metadata

Each session file includes YAML frontmatter with:

| Field                  | Description                                    |
|------------------------|------------------------------------------------|
| `timestamp_start`      | When session started (ISO 8601)                |
| `timestamp_end`        | When session ended (ISO 8601)                  |
| `session_id`           | Unique session identifier                      |
| `project`              | Project name                                   |
| `git_branch`           | Active git branch                              |
| `git_commit`           | Current commit hash                            |
| `files_modified_count` | Number of files changed                        |
| `permission_mode`      | Permission mode during session                 |
| `status`               | Session status (in_progress, completed)        |
| `tags`                 | Auto-detected tags (testing, documentation...) |
| `transcript`           | Path to full session transcript                |
| `end_reason`           | Why session ended (clear, logout, etc.)        |

## Skills

### `/session-memory:session-search`

Search sessions by:
- Date range
- Git branch
- Project name
- Tags
- Status

**Examples:**
```
/session-memory:session-search find debugging sessions from last week
/session-memory:session-search show sessions on feature/auth branch
/session-memory:session-search what sessions modified the API?
```

### `/session-memory:memory-consolidate`

Extract patterns and learnings from recent sessions into topic files.

**Examples:**
```
/session-memory:memory-consolidate review last 2 weeks
/session-memory:memory-consolidate consolidate this month's sessions
```

## Searching Sessions Manually

With YAML frontmatter, you can use standard command-line tools:

```bash
# Find sessions on a specific branch
grep "git_branch: feature/auth" ~/.claude/projects/*/memory/sessions/*.md

# Find interrupted sessions
grep "status: in_progress" ~/.claude/projects/*/memory/sessions/*.md

# Find sessions from February 2024
find ~/.claude/projects/*/memory/sessions/ -name "*2024-02-*"

# Find sessions with many file changes
grep "files_modified_count: [2-9][0-9]" ~/.claude/projects/*/memory/sessions/*.md
```

## File Structure

After installation, your memory directory will look like this:

```
~/.claude/projects/<project>/memory/
├── MEMORY.md                    # Auto-loaded index (≤200 lines)
├── sessions/                    # Full session details
│   ├── <session-id-1>.md
│   ├── <session-id-2>.md
│   └── ...
├── architecture.md              # Architectural decisions
├── learnings.md                 # Accumulated insights
├── patterns.md                  # Development patterns
└── debugging.md                 # Debugging solutions
```

## Development

### Running Tests

The plugin includes a comprehensive test suite using [bats](https://github.com/bats-core/bats-core):

```bash
# Install bats (one-time setup)
brew install bats-core  # macOS
# or
npm install -g bats     # Linux/Windows

# Run all tests
./test.sh

# Or use make
make test
```

### Test Coverage

- **Stop Hook Tests** (`tests/stop_hook.bats`) - Session creation, YAML frontmatter, file tracking
- **SessionEnd Hook Tests** (`tests/session_end_hook.bats`) - Session finalization, metadata updates
- **Memory Management Tests** (`tests/memory_management.bats`) - MEMORY.md limits, indexing
- **Integration Tests** (`tests/integration.bats`) - Full session lifecycle, multi-project scenarios

### Linting

```bash
# Install shellcheck
brew install shellcheck  # macOS

# Lint all shell scripts
make lint
```

### CI/CD

GitHub Actions automatically runs tests on:
- Ubuntu Latest
- macOS Latest

Tests run on every push and pull request.

## Requirements

- Claude Code >=0.1.0
- `jq` for JSON parsing (install with: `brew install jq` on macOS)
- `git` (optional, for git metadata)
- `bats` (for running tests, development only)

## Troubleshooting

**Hooks not running:**
- Verify scripts are executable: `chmod +x hooks/*.sh`
- Check plugin is enabled via symlink: `ls -la ~/.claude/plugins/session-memory`
- Enable verbose mode: `Ctrl+O`
- Run with debug: `claude --debug`

**Session files not created:**
- Check `~/.claude/projects/` directory exists
- Verify hook scripts have correct permissions
- Check that `jq` is installed: `which jq`

**MEMORY.md exceeds 200 lines:**
- This is normal - the plugin automatically trims it
- Detailed information is preserved in session files
- Use `/session-memory:memory-consolidate` to extract patterns to topic files

## Uninstall

```bash
# Remove the symlink
rm ~/.claude/plugins/session-memory

# Optionally, remove the cloned repository
rm -rf /path/to/claude-session-memory
```

Session files in `~/.claude/projects/` will be preserved.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

- Issues: https://github.com/yourusername/claude-session-memory/issues
- Discussions: https://github.com/yourusername/claude-session-memory/discussions
