---
description: Close session with Git integration and vault maintenance
---

Please orchestrate a comprehensive session close workflow:

## Step 0: Load Corrections

**FIRST ACTION:** Search for and read `accumulator-corrections.md` from the primary vault to refresh your memory on common mistakes before proceeding with the complex multi-step close process.

Use this search-then-read pattern:
1. Call `mcp__obsidian-context-manager__search_vault` with query: "accumulator-corrections"
2. Read the file path from search results using the Read tool

**IMPORTANT:** Do NOT call `get_memory_base` here - it resets session start time and breaks commit detection.

## Phase 1: Initial Close (Before any close_session call)

1. **Analyze the conversation** to determine:
   - A concise, descriptive topic/title (2-5 words, hyphenated) that captures the main focus
   - A brief summary of what we worked on

2. **Check for uncommitted changes in any detected repositories:**
   - Use `mcp__obsidian-context-manager__detect_session_repositories` to find repositories accessed during this session
   - For each repository found, run `git status` to check for uncommitted changes
   - If uncommitted changes exist, create a commit BEFORE calling close_session:
     - Stage the changes with `git add`
     - Create a descriptive commit message summarizing the work done
     - Follow the standard Git commit protocol (see system instructions for commit message format)
     - Include the Claude Code attribution footer

3. **Call `mcp__obsidian-context-manager__close_session`** with:
   - `topic` parameter (for the filename, 2-5 words hyphenated)
   - `summary` parameter (detailed description of work done)
   - `_invoked_by_slash_command: true`
   - `working_directories` parameter - Extract from your environment context (the `<env>` section shows "Working directory:" and "Additional working directories:"). Pass ALL of these paths as an array. This is CRITICAL for correct repository detection.
   - `session_start_override` parameter - Look for `SESSION_START_TIME: <timestamp>` in your context (emitted by /mb). If found, pass the ISO 8601 timestamp. This is a fallback if MCP server state was lost.

## Phase 2: Finalization (Always required - Decision 044)

The Phase 1 close_session call will return commit analysis with `session_data`. You must:

1. Review the commit analysis and suggested topic updates
2. Update relevant topics using `update_document` (NEVER use Edit/Write directly — they don't track file access for vault_custodian)
3. **DO NOT commit topic updates** - they will be included in vault custodian's finalization
4. **DO NOT re-run Phase 1 steps** - skip straight to Phase 2 finalization
5. Call `close_session` DIRECTLY with the exact parameters shown in Phase 1's output:
   ```typescript
   close_session({
     summary: "...",
     topic: "...",
     finalize: true,
     handoff: "[paste generated handoff notes here]",  // REQUIRED (Decision 052)
     session_data: { ...the session_data from Phase 1... }
   })
   ```

**IMPORTANT: Phase 2 is a DIRECT tool call, not a restart of this workflow.**
- Do NOT check for uncommitted changes again
- Do NOT create new commits
- Do NOT analyze the conversation again
- ONLY call close_session with finalize: true and the session_data

## Final Summary Format

Present the closing summary using this exact key-value format (no tables):

```
Session Close Complete

Session ID        {session-id}
Session File      {relative-path-from-vault}
Repository        {repo-name} ({branch}) [if linked]
Commit Recorded   {short-hash} - {message} [if any]
Vault Custodian   {fixes} fixes, {issues} issues
```

If topics/decisions/projects were created, updated, or linked during the session, add them as simple lists:
```
Topics Created    topic-name-1, topic-name-2 [if any]
Topics Updated    topic-name-3, topic-name-4 [if any]
Decisions Made    decision-name-1 [if any]
Projects Linked   project-name [if any]
```

**Note:** Only include lines for categories that have items. Skip empty categories.
