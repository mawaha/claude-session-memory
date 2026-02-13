# Claude Code Hooks - Comprehensive Reference

Based on implementation experience with the session-memory plugin.

## Hook Execution Model

### What Hooks Are
- **External bash scripts** that run at specific lifecycle events
- Receive JSON input via stdin
- Output to stdout/stderr (for logging)
- Write to files for persistence
- **Cannot invoke Claude skills** - they run as separate processes
- **Cannot affect Claude's behavior mid-execution** - no return values to Claude

### What Hooks Cannot Do
❌ Invoke Claude skills directly (e.g., `/session-memory:summarize`)
❌ Make Claude execute actions during the hook
❌ Return data that Claude automatically processes
❌ Access Claude's conversation context (only transcript file path)
❌ Interrupt or modify Claude's response in progress

### What Hooks CAN Do
✅ Read and write files (including globally)
✅ Parse JSON/JSONL (transcript, tool inputs/outputs)
✅ Execute shell commands (jq, awk, grep, git, etc.)
✅ Create/update structured data files
✅ Set flags/markers that Claude can check later
✅ Log activity for future analysis

## Available Hooks

### 1. PostToolUse Hook

**Timing:** Runs **after each individual tool use** completes

**Access:**
- ✅ Tool name (e.g., "WebSearch", "Read", "Edit")
- ✅ Tool input (parameters passed to tool)
- ✅ Tool result (output from tool)
- ✅ Error status (`is_error: true/false`)
- ✅ Session ID
- ✅ Current working directory
- ❌ Full conversation context (only individual tool)

**Use Cases:**
- Real-time activity logging
- Immediate data capture (search queries, file operations)
- Building timeline of tool usage
- Detecting patterns as they happen
- Enriching data before Stop hook runs

**Limitations:**
- Runs many times per response (once per tool)
- Must be fast (timeout typically 5s)
- Cannot trigger skills (no Claude session active yet)
- Data must be written to files for later use

**Example Input:**
```json
{
  "session_id": "abc123",
  "cwd": "/Users/user/project",
  "tool_name": "WebSearch",
  "tool_input": {
    "query": "bash YAML parsing"
  },
  "tool_result": {
    "results": [...]
  },
  "is_error": false
}
```

**Our Implementation:**
- Logs tool activity to `.tool-activity-{session-id}.jsonl`
- Captures search queries, file operations, commands
- Categorizes activity types (research, testing, file_read, etc.)
- Provides richer data for Stop hook and consolidation

---

### 2. Stop Hook

**Timing:** Runs **after Claude finishes a complete response**

**Access:**
- ✅ Session ID
- ✅ Current working directory
- ✅ Transcript file path (JSONL)
- ✅ Permission mode
- ✅ Hook event name
- ✅ Stop hook active flag (prevents infinite loops)
- ✅ Can read files created by PostToolUse hook
- ❌ Direct conversation context (must parse transcript)

**Use Cases:**
- Create/update session files
- Extract conversation statistics
- Detect activities from tool usage
- Update memory indexes
- Set flags for skills to check later

**Limitations:**
- Cannot invoke skills directly
- Runs after response is complete (can't modify it)
- Must set flags for Claude to check on **next** response
- Should be fast (blocks user interaction briefly)

**Example Input:**
```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/Users/user/project",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
```

**Our Implementation:**
- Creates session file with YAML frontmatter
- Reads tool activity log from PostToolUse
- Detects activities (testing, learning, debugging, etc.)
- Extracts conversation stats (turns, tool calls, errors)
- Sets flags: `needs_summary: true`, `needs_consolidation: true`
- Updates MEMORY.md index
- Updates global session index

**Important:** Check `stop_hook_active` to prevent infinite loops!

---

### 3. PreCompact Hook

**Timing:** Runs **before context compaction** (memory optimization)

**Access:**
- ✅ Session ID
- ✅ Current working directory
- ✅ Trigger type (auto/manual)
- ✅ Transcript file path
- ❌ Which parts of context will be compacted

**Use Cases:**
- Prevent context loss by capturing state
- Save recent conversation turns
- Identify files being discussed
- Log what was in progress

**Limitations:**
- Cannot prevent compaction
- Cannot invoke skills
- Limited time (compaction is about to happen)

**Example Input:**
```json
{
  "session_id": "abc123",
  "cwd": "/Users/user/project",
  "trigger": "auto",
  "transcript_path": "/path/to/transcript.jsonl"
}
```

**Our Implementation:**
- Appends compaction event note to session file
- Captures last 5 conversation turns
- Extracts files in focus (from recent tool calls)
- Preserves "what we were doing" context

---

### 4. SessionEnd Hook

**Timing:** Runs **when session terminates** (logout, timeout, close)

**Access:**
- ✅ Session ID
- ✅ Current working directory
- ✅ End reason (logout, timeout, etc.)
- ✅ Transcript file path
- ✅ **Can write globally** (unlike Stop hook in some contexts)
- ❌ **No conversation context** - Claude has terminated
- ❌ **Cannot invoke skills** - no active Claude session

**Use Cases:**
- Finalize session metadata
- Update timestamps
- Set completion status
- Global index updates

**Limitations:**
- **Claude is gone** - cannot invoke skills or trigger actions
- Only bash operations available
- Cannot summarize or analyze (no AI available)
- Cannot ask user questions or get confirmation

**Example Input:**
```json
{
  "session_id": "abc123",
  "cwd": "/Users/user/project",
  "transcript_path": "/path/to/transcript.jsonl",
  "reason": "logout"
}
```

**Our Implementation:**
- Updates `timestamp_end` in session file YAML
- Sets `status: completed`
- Adds `end_reason` to metadata
- Finalizes session without AI processing

**Critical:** This hook cannot do AI analysis - Claude is terminated!

---

## Skill Invocation Pattern

Since hooks **cannot invoke skills**, we use a flag-based pattern:

### The Pattern

```
1. PostToolUse Hook:
   - Captures data → writes to .tool-activity-{session-id}.jsonl

2. Stop Hook:
   - Reads tool activity log
   - Analyzes data
   - Sets flags: needs_summary: true, needs_consolidation: true

3. User sends next message

4. Claude responds:
   - FIRST: Checks for needs_summary flag
   - If true: Auto-invokes /session-memory:summarize
   - THEN: Checks for needs_consolidation flag
   - If true: Auto-invokes /session-memory:consolidate
   - FINALLY: Responds normally to user
```

### Why This Works

- Hooks set markers/flags in files
- Claude checks for flags at start of each response
- Skills run during active Claude session
- All automatic, no user intervention

### Timing Trade-off

- ✅ Everything is automatic
- ⚠️ Skills run on response **after** the activity occurred
- ⚠️ If user ends session immediately, skills run next session
- ⚠️ One-message delay between activity and processing

## Hook Configuration

### hooks.json Structure

```json
{
  "description": "Plugin description",
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/post-tool-use.sh",
        "timeout": 5,
        "statusMessage": "Logging tool activity..."
      }]
    }],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/stop.sh",
        "timeout": 30,
        "statusMessage": "Saving session memory..."
      }]
    }],
    "PreCompact": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/precompact.sh",
        "timeout": 10,
        "statusMessage": "Saving pre-compaction state..."
      }]
    }],
    "SessionEnd": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-end.sh",
        "timeout": 10,
        "statusMessage": "Finalizing session..."
      }]
    }]
  }
}
```

### Important Notes

- `${CLAUDE_PLUGIN_ROOT}` resolves to plugin directory
- `timeout` in seconds (max varies by hook)
- `statusMessage` shown to user while hook runs
- Hooks can be chained (array of hook objects)

## Best Practices

### 1. Keep Hooks Fast
- PostToolUse: < 5s (runs frequently)
- Stop: < 30s (blocks briefly)
- PreCompact: < 10s (compaction waiting)
- SessionEnd: < 10s (session ending)

### 2. Handle Missing Data
```bash
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty')
if [ -n "$FILE_PATH" ]; then
    # Safe to use
fi
```

### 3. Prevent Infinite Loops
```bash
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0  # Don't recurse
fi
```

### 4. Use Structured Data
- JSONL for logs (one JSON object per line)
- YAML frontmatter for metadata
- Markdown for human-readable content

### 5. Clean Up Temporary Files
- Delete `.tool-activity-*.jsonl` after consolidation
- Remove markers after processing
- Archive old sessions

### 6. Fail Gracefully
```bash
set -euo pipefail  # Fail on errors
# But handle expected failures:
RESULT=$(command 2>/dev/null || echo "default")
```

## Data Flow Architecture

```
User ←→ Claude ←→ Tools
         ↓
    PostToolUse Hook (per tool)
         ↓
    .tool-activity-{session}.jsonl
         ↓
    Stop Hook (per response)
         ↓
    Session file + flags
         ↓
    User message
         ↓
    Claude checks flags
         ↓
    Auto-invoke skills
         ↓
    Skills read logs + session
         ↓
    Update topic files
         ↓
    Clean up logs
```

## Summary

### Hook Capabilities Matrix

| Hook | Timing | Can Write Files | Can Read Transcript | Can Invoke Skills | Has Claude Context |
|------|--------|----------------|---------------------|-------------------|-------------------|
| PostToolUse | After each tool | ✅ | ✅ | ❌ | ❌ (only tool) |
| Stop | After response | ✅ | ✅ | ❌ | ❌ (only transcript) |
| PreCompact | Before compaction | ✅ | ✅ | ❌ | ❌ (only transcript) |
| SessionEnd | Session ends | ✅ | ✅ | ❌ | ❌ (Claude terminated) |

### Key Insights

1. **Hooks cannot invoke skills** - They set flags that Claude checks
2. **PostToolUse gives best data** - Captures activity in real-time
3. **Stop is the orchestrator** - Analyzes data, sets workflow flags
4. **SessionEnd is limited** - Only metadata updates, no AI
5. **One-response delay** - Skills run on next user message

### Recommended Pattern

```
PostToolUse → capture data
Stop → analyze + set flags
Claude (next response) → invoke skills
Skills → process + consolidate
```

This pattern balances:
- Rich data capture (PostToolUse)
- Automatic workflow (Stop flags)
- AI-powered processing (Claude skills)
- User transparency (happens naturally)
