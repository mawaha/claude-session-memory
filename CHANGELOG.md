# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- ✅ PostToolUse hook for real-time tool activity logging
- ✅ Tool activity log (`.tool-activity-{session-id}.jsonl`) with detailed tool usage timeline
- ✅ Auto-generated session statistics (conversation turns, tool calls, errors)
- ✅ Transcript parsing library for extracting conversation context
- ✅ Session stats section in session files
- ✅ Enhanced PreCompact hook with recent conversation context
- ✅ Files in focus tracking during compaction events
- ✅ Session summarization skill (`/session-memory:summarize`) with auto-mode
- ✅ Activity detection system using PostToolUse data (testing, debugging, learning, architecture, refactoring)
- ✅ Session consolidation skill (`/session-memory:consolidate`) for topic file updates
- ✅ Topic file auto-population with rich data from tool activity logs
  - testing.md - Exact test commands with timestamps
  - debugging.md - Error tracking and solutions
  - learnings.md - Research timeline with search queries and URLs
  - architecture.md - File creation timeline
  - patterns.md - Edit history and refactoring patterns
- ✅ Complete auto-workflow: PostToolUse → Stop → Summarize → Consolidate (fully automatic)
- ✅ Auto-check behavior in MEMORY.md for triggering summarization and consolidation

### Changed
- Enhanced YAML frontmatter with conversation_turns, tool_calls, errors_encountered, tools_used, activities_detected, needs_summary, needs_consolidation
- PreCompact hook now captures last 5 conversation turns and files being discussed
- Stop hook detects activities and sets consolidation flags
- Stop hook extracts stats from transcript for automatic session documentation
- Auto-workflow now includes three phases: detection, summarization, consolidation

### Fixed
- get_yaml_field function now correctly parses YAML frontmatter fields

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
