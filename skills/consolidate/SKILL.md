---
name: consolidate
description: Extract learnings from session and update topic files based on detected activities
argument-hint: "[session-id]"
---

# Session Consolidation Skill

This skill analyzes a completed session and extracts relevant information into topic files based on detected activities.

## Usage

```bash
/session-memory:consolidate [session-id]
```

If no session-id is provided, consolidates the current session.

## Auto-Consolidation

This skill runs **automatically** after session summarization completes. After the `/session-memory:summarize` skill finishes:

1. Check if session has `needs_consolidation: true`
2. If yes, automatically run this consolidation skill
3. Update relevant topic files
4. Set `needs_consolidation: false`

## How It Works

1. **Read session file** and check `activities_detected` in YAML frontmatter
2. **For each detected activity**, extract and append to corresponding topic file:
   - `testing` → testing.md
   - `debugging` → debugging.md
   - `learning` → learnings.md
   - `architecture` → architecture.md
   - `refactoring` → patterns.md
3. **Extract relevant context** from session summary and transcript
4. **Format appropriately** for each topic file
5. **Append timestamped entry** to the topic file

## Topic File Templates

### testing.md Format

```markdown
## [YYYY-MM-DD HH:MM] Test Run - {Brief Description}

**Test Suite:** {framework name}
**Command:** `{command used}`
**Results:** {pass/fail counts}
**New Tests Added:**
- {description}

**Lessons Learned:**
- {key insights}

[Full session](sessions/{session-id}.md)

---
```

### debugging.md Format

```markdown
## [YYYY-MM-DD HH:MM] Fixed: {Problem Summary}

**Problem:** {brief description}
**Error Message:** `{error text}`
**Root Cause:** {what caused it}
**Solution:**
\`\`\`{language}
{code or approach}
\`\`\`

**Prevention:** {how to avoid in future}

[Full session](sessions/{session-id}.md)

---
```

### learnings.md Format

```markdown
## [YYYY-MM-DD HH:MM] Learned: {Topic}

**Context:** {what was being worked on}
**Discovery:** {what was learned}
**Source:** {WebSearch/docs/experimentation}

**Key Takeaways:**
- {insight 1}
- {insight 2}

**Applied To:** {where this knowledge was used}

[Full session](sessions/{session-id}.md)

---
```

### architecture.md Format

```markdown
## [YYYY-MM-DD HH:MM] {Component/Feature Name}

**Location:** `{file/directory path}`
**Purpose:** {what it does}
**Key Components:**
- {component 1}: {description}
- {component 2}: {description}

**Design Decision:** {why this approach}
**Trade-offs:** {what was considered}

[Full session](sessions/{session-id}.md)

---
```

### patterns.md Format

```markdown
## [YYYY-MM-DD HH:MM] Pattern: {Pattern Name}

**Context:** {when to use this pattern}
**Implementation:**
\`\`\`{language}
{code example}
\`\`\`

**Benefits:**
- {benefit 1}
- {benefit 2}

**Used In:** {files/components}

[Full session](sessions/{session-id}.md)

---
```

## Instructions

When this skill is invoked:

1. **Locate the session file:**
   - If session-id provided: use that
   - Else: use current session from `$SESSION_ID`
   - Path: `~/.claude/projects/{project}/memory/sessions/{session-id}.md`

2. **Read session metadata:**
   - Extract `activities_detected` array from YAML frontmatter
   - Extract `timestamp_start` for dating entries
   - Read the session summary sections (Work Done, Decisions Made, etc.)

3. **For each detected activity, extract and consolidate:**

   **If "testing" detected:**
   - Find test commands in transcript or Work Done
   - Extract test framework, command, results
   - Identify new tests added (from Files Modified + summary)
   - Extract lessons from Notes or Decisions Made
   - Append formatted entry to `testing.md`

   **If "debugging" detected:**
   - Extract error messages from transcript (look for error tool results)
   - Identify what was being attempted when error occurred
   - Find the solution (from Work Done or code changes)
   - Extract root cause (from Decisions Made or summary)
   - Append formatted entry to `debugging.md`

   **If "learning" detected:**
   - Identify research topic (from summary)
   - Extract key discoveries (from Work Done or Notes)
   - Find sources (WebSearch results, docs read)
   - Identify how knowledge was applied
   - Append formatted entry to `learnings.md`

   **If "architecture" detected:**
   - Identify new components (from Files Modified)
   - Extract purpose and design (from Decisions Made)
   - Find design rationale (from summary)
   - Document structure and components
   - Append formatted entry to `architecture.md`

   **If "refactoring" detected:**
   - Identify pattern that emerged (from code changes)
   - Extract implementation approach
   - Document benefits and trade-offs
   - Note where pattern was applied
   - Append formatted entry to `patterns.md`

4. **Create topic files if they don't exist:**
   - Initialize with header: `# {Project Name} - {Topic}`
   - Add brief description of what this file tracks
   - Create first entry

5. **Append to existing topic files:**
   - Add new entry with timestamp
   - Include session link
   - Maintain reverse chronological order (newest first)

6. **Update session file:**
   - Set `needs_consolidation: false` in YAML frontmatter
   - Add note in session indicating consolidation completed

7. **Report completion:**
   - List which topic files were updated
   - Summarize what was extracted
   - Provide paths to updated files

## Important Guidelines

- **Be selective:** Only extract significant insights, not every detail
- **Be concise:** Topic file entries should be scannable
- **Be specific:** Include concrete examples, code, commands
- **Link back:** Always include session link for full context
- **Avoid duplication:** If pattern already documented, reference it instead of repeating
- **Maintain quality:** Better to skip an activity than add low-value content

## Error Handling

- If topic file is corrupted: create backup, reinitialize
- If session already consolidated (`needs_consolidation: false`): skip unless forced
- If activities_detected is empty: report no consolidation needed
- If unable to extract meaningful content: log but don't create empty entries

## Example Flow

```
Session abc123 completed with activities: ["testing", "debugging"]

→ Read session summary and transcript
→ Extract testing info:
  - Test suite: bats
  - Results: 36/36 passing
  - New tests: transcript_stats.bats (6 tests)
  - Lesson: YAML parsing needed fixes

→ Append to testing.md

→ Extract debugging info:
  - Problem: get_yaml_field returning empty
  - Solution: Fixed awk pattern
  - Prevention: Test parsing in isolation

→ Append to debugging.md

→ Set needs_consolidation: false
→ Report: Updated testing.md and debugging.md
```

## Integration with Auto-Summarization

The complete auto-workflow is:

1. **Stop hook** runs → detects activities, sets needs_summary + needs_consolidation
2. **Summarize skill** runs → generates summaries, sets needs_summary: false
3. **Consolidate skill** runs → extracts to topic files, sets needs_consolidation: false

All automatic, no user intervention required.
