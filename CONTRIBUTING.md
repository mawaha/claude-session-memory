# Contributing to Claude Session Memory Plugin

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/claude-session-memory.git
   cd claude-session-memory
   ```
3. **Install dependencies**:
   ```bash
   brew install bats-core jq shellcheck  # macOS
   # or appropriate package manager for your OS
   ```
4. **Run tests** to ensure everything works:
   ```bash
   make test
   ```

## Development Workflow

### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Write code following the existing style
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests and linting**:
   ```bash
   make test
   make lint
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

### Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat: add new feature` - New feature
- `fix: resolve bug in stop hook` - Bug fix
- `docs: update README` - Documentation
- `test: add tests for session-end hook` - Tests
- `refactor: simplify YAML parsing` - Code refactoring
- `chore: update dependencies` - Maintenance

### Pull Request Process

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub

3. **Ensure CI passes**:
   - All tests must pass
   - Linting must pass
   - No merge conflicts

4. **Wait for review**:
   - Address any feedback
   - Make requested changes
   - Re-run tests

## Testing

### Writing Tests

Tests are written using [bats](https://github.com/bats-core/bats-core). Place test files in `tests/`:

```bash
# tests/my_feature.bats
#!/usr/bin/env bats

load test_helper

@test "my feature works correctly" {
    # Arrange
    create_hook_input | bash "$PLUGIN_ROOT/hooks/stop.sh"

    # Assert
    assert_file_exists "$expected_file"
}
```

### Test Helper Functions

Available helper functions in `tests/test_helper.bash`:

- `setup()` / `teardown()` - Test setup and cleanup
- `create_hook_input()` - Generate mock hook input
- `create_session_end_input()` - Generate SessionEnd input
- `assert_file_exists()` - Assert file exists
- `assert_file_contains()` - Assert file contains text
- `assert_yaml_field()` - Assert YAML field value
- `create_test_files()` - Create test files for modification tracking

### Running Tests

```bash
# Run all tests
./test.sh

# Run specific test file
bats tests/stop_hook.bats

# Run with verbose output
bats -t tests/stop_hook.bats
```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -euo pipefail` for error handling
- Quote all variables: `"$VAR"` not `$VAR`
- Use meaningful variable names
- Add comments for complex logic
- Run `shellcheck` on all scripts

### Documentation

- Update README.md for user-facing changes
- Update CHANGELOG.md for all changes
- Add inline comments for complex code
- Update skill descriptions if behavior changes

## Project Structure

```
claude-session-memory/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── hooks/
│   ├── hooks.json           # Hook configuration
│   ├── stop.sh              # Stop hook implementation
│   └── session-end.sh       # SessionEnd hook implementation
├── skills/
│   ├── session-search/
│   │   └── SKILL.md         # Session search skill
│   └── memory-consolidate/
│       └── SKILL.md         # Memory consolidation skill
├── tests/
│   ├── test_helper.bash     # Test utilities
│   ├── stop_hook.bats       # Stop hook tests
│   ├── session_end_hook.bats# SessionEnd hook tests
│   ├── memory_management.bats# Memory management tests
│   └── integration.bats     # Integration tests
├── .github/
│   └── workflows/
│       └── test.yml         # CI/CD configuration
├── install.sh               # Installation script
├── test.sh                  # Test runner
├── Makefile                 # Build automation
├── CHANGELOG.md             # Version history
├── CONTRIBUTING.md          # This file
├── LICENSE                  # MIT License
└── README.md                # User documentation
```

## Adding New Features

### Adding a New Hook

1. Create the hook script in `hooks/`
2. Add hook configuration to `hooks/hooks.json`
3. Write tests in `tests/`
4. Update README.md with hook documentation
5. Update CHANGELOG.md

### Adding a New Skill

1. Create skill directory in `skills/`
2. Create `SKILL.md` with frontmatter and instructions
3. Test the skill manually
4. Update README.md with skill documentation
5. Update CHANGELOG.md

### Modifying Existing Functionality

1. Update the relevant files
2. Update or add tests
3. Run full test suite
4. Update documentation
5. Update CHANGELOG.md

## Release Process

Releases are managed by maintainers:

1. Update version in `.claude-plugin/plugin.json`
2. Update CHANGELOG.md with release notes
3. Tag release: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tags: `git push origin v1.0.0`
5. Create GitHub release

## Getting Help

- **Issues**: Report bugs or request features via [GitHub Issues](https://github.com/yourusername/claude-session-memory/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/yourusername/claude-session-memory/discussions)
- **Security**: Report security issues privately via email

## Code of Conduct

Be respectful and constructive:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what's best for the community
- Show empathy towards others

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
