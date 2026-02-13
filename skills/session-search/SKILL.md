---
name: session-search
description: Search session history by metadata (branch, tags, date, project)
argument-hint: [search criteria]
---

Search through session history to find sessions matching the user's criteria.

Session files are located at: `~/.claude/projects/*/memory/sessions/*.md`

Each session file has YAML frontmatter with metadata:
- timestamp_start, timestamp_end
- session_id
- project
- git_branch, git_commit
- files_modified_count
- permission_mode
- status (in_progress, completed)
- tags (array)
- transcript (path)
- end_reason (if completed)

## Your Task

1. **Understand the search criteria** from the user's request
2. **Use Grep to search frontmatter** for matching sessions
3. **Read matching session files** to get summaries
4. **Present results** in a clear, organized format

## Example Searches

"Find sessions on the feature/auth branch"
→ Use Grep: `git_branch: feature/auth`

"Show me debugging sessions from last week"
→ Use Grep with date range and tags

"What sessions modified the API?"
→ Use Grep in Files Modified sections

"Find interrupted sessions"
→ Use Grep: `status: in_progress` or `end_reason: prompt_input_exit`

## Output Format

Present results as:
```
Found X sessions matching criteria:

1. **Project** (branch) - Date
   Summary: ...
   Files: X modified
   [View session](file://path)

2. ...
```

Be helpful and suggest related searches if appropriate.
