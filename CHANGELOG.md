# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet - see [1.0.0] for the initial release

## [1.0.0] - 2026-02-13

### Added
- ✅ Stop hook for automatic session capture
- ✅ SessionEnd hook for session finalization
- ✅ YAML frontmatter with structured metadata
- ✅ Session search skill (`/session-memory:session-search`)
- ✅ Memory consolidation skill (`/session-memory:memory-consolidate`)
- ✅ Automatic MEMORY.md index maintenance (200 line limit)
- ✅ Global session index at `~/.claude/sessions/INDEX.md`
- ✅ Auto-detection of session tags (testing, documentation, work-in-progress)
- ✅ Installation script with symlink support
- ✅ Comprehensive test suite (27 tests, 100% passing)
- ✅ GitHub Actions CI/CD
- ✅ Shellcheck linting
- ✅ Makefile for common tasks
- ✅ Complete documentation (README, CONTRIBUTING, CHANGELOG)

### Technical Details
- Session files stored per-project at `~/.claude/projects/{project-name}/memory/sessions/`
- Simplified path normalization using project basename
- Fixed-string grep for reliable text matching in tests
- Proper handling of empty git status in tag detection

## [1.0.0] - YYYY-MM-DD

_Release notes will be added when version 1.0.0 is released_

---

## Version History Guidelines

### Types of Changes
- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security vulnerability fixes

### Version Numbers
- **MAJOR** version when you make incompatible API changes
- **MINOR** version when you add functionality in a backward compatible manner
- **PATCH** version when you make backward compatible bug fixes

[Unreleased]: https://github.com/yourusername/claude-session-memory/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/claude-session-memory/releases/tag/v1.0.0
