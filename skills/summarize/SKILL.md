---
name: summarize
description: Auto-generate session summary using AI analysis of the conversation
argument-hint: "[session-id]"
---

# Session Summarization Skill

This skill analyzes a session's transcript and auto-generates comprehensive summaries for:
- **Summary**: One-line overview of what was accomplished
- **Work Done**: Key accomplishments and changes made
- **Decisions Made**: Important architectural or implementation decisions
- **Next Steps**: What to work on in the next session
- **Notes**: Any other context worth preserving

## Usage

```bash
/session-memory:summarize [session-id]
```

If no session-id is provided, summarizes the current session.

## How It Works

1. Locates the session file (current session or specified session-id)
2. Reads the session's transcript to understand the conversation
3. Uses Claude to analyze the conversation and generate summaries
4. Updates the session file with the generated content
5. Preserves all existing metadata and stats

## What Gets Updated

The skill fills in the placeholder sections in the session file:
- `## Summary` - Single line of what was accomplished
- `## Work Done` - Bullet list of key accomplishments
- `## Decisions Made` - Bullet list of important decisions
- `## Next Steps` - Bullet list of recommended next actions
- `## Notes` - Any additional context or observations

## Requirements

- Active Claude Code session (uses Claude in context)
- Valid session file in `~/.claude/projects/{project}/memory/sessions/`
- Readable transcript file

## Example

Before running the skill, session sections have placeholders:
```markdown
## Summary
<!-- Add a one-line summary of what was accomplished -->
<!-- Or run /session-memory:summarize to auto-generate -->

## Work Done
<!-- Key accomplishments and changes made -->
```

After running `/session-memory:summarize`:
```markdown
## Summary
Implemented PreCompact hook to capture context before compaction events

## Work Done
- Created transcript-parser.sh library for extracting conversation context
- Updated stop.sh hook to include conversation stats in YAML frontmatter
- Enhanced precompact.sh to capture recent context and files in focus
- Added auto-generated session statistics (turns, tools, errors)
```

## Instructions

When this skill is invoked:

1. **Determine the session to summarize:**
   - If argument provided: use that session-id
   - If no argument: use current `$SESSION_ID` from environment

2. **Locate session file:**
   - Determine project name from `$PROJECT_DIR` or current directory
   - Path: `~/.claude/projects/{project}/memory/sessions/{session-id}.md`
   - If file doesn't exist, report error and exit

3. **Read the transcript:**
   - Extract `transcript:` path from YAML frontmatter of session file
   - Read the transcript JSONL file
   - Parse conversation turns (user/assistant messages, tool calls)

4. **Analyze the conversation:**
   You have the full transcript. Generate summaries by analyzing:
   - What tasks were requested
   - What files were created/modified/read
   - What tools were used and why
   - What problems were solved
   - What decisions were made about approach/architecture
   - What errors occurred and how they were resolved
   - What remains to be done

5. **Generate summaries:**
   Create concise, actionable content for each section:

   - **Summary** (1 line): Clear statement of primary accomplishment
   - **Work Done** (3-7 bullets): Concrete accomplishments, not process
   - **Decisions Made** (2-5 bullets): Important choices and rationale
   - **Next Steps** (2-5 bullets): Clear, actionable next tasks
   - **Notes** (optional, 1-3 bullets): Context that doesn't fit elsewhere

6. **Update the session file:**
   - Read current session file content
   - Replace placeholder comments with generated summaries
   - Preserve all YAML frontmatter and session stats
   - Write updated content back to session file

7. **Report completion:**
   - Confirm which session was summarized
   - Show the generated summary section
   - Provide path to updated session file

## Important Guidelines

- **Be concise**: Users will read many sessions; keep summaries scannable
- **Be specific**: "Added PreCompact hook" not "Made improvements"
- **Focus on outcomes**: What was built/fixed, not just what was discussed
- **Preserve decisions**: Why choices were made, not just what was chosen
- **Make next steps actionable**: Clear tasks that can be picked up later
- **Don't hallucinate**: Only summarize what actually happened in the transcript

## Error Handling

If session file doesn't exist:
- Report: "Session file not found for session-id: {id}"
- List available sessions in project

If transcript is missing/unreadable:
- Report: "Transcript not accessible: {path}"
- Offer to generate summary from session metadata only

If session already has summaries (no placeholder comments):
- Ask user: "Session already has summaries. Regenerate? (yes/no)"
- If yes: regenerate; if no: exit without changes
