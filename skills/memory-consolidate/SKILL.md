---
name: memory-consolidate
description: Consolidate learnings from recent sessions into topic files
argument-hint: [timeframe, e.g., "last week"]
---

Consolidate learnings from recent session files into organized topic files.

## Your Task

1. **Read recent session files** from `~/.claude/projects/*/memory/sessions/`
   - Focus on sessions from the last week or user-specified timeframe
   - Use YAML frontmatter to filter efficiently

2. **Extract reusable knowledge**:
   - Development patterns and conventions
   - Architectural decisions and rationale
   - Solutions to debugging problems
   - Useful commands and workflows
   - Key insights and learnings

3. **Update topic files**:
   - `patterns.md` - Development patterns and code conventions
   - `learnings.md` - Key insights and solutions discovered
   - `debugging.md` - Solutions to specific problems
   - `architecture.md` - Architectural decisions and design

4. **Keep MEMORY.md concise**:
   - Update the "Key Patterns" section with high-level summaries
   - Ensure MEMORY.md stays under 200 lines
   - Link to detailed topic files

## What to Extract

✅ **DO extract:**
- Patterns that could apply to future work
- Solutions to tricky problems
- Important architectural decisions
- Reusable commands or workflows
- Key insights about the codebase

❌ **DON'T extract:**
- Session-specific details
- Temporary decisions
- One-off fixes
- Information already in project documentation

## Output

After consolidating, provide a summary:
- How many sessions were reviewed
- What was added to each topic file
- Any important patterns discovered
