---
description: Close session without Git integration, only vault maintenance
---

Please orchestrate a session close workflow WITHOUT Git operations:

## Step 0: Load Corrections

**FIRST ACTION:** Search for and read `accumulator-corrections.md` from the primary vault to refresh your memory on common mistakes before proceeding with the close process.

Use this search-then-read pattern:
1. Call `mcp__obsidian-context-manager__search_vault` with query: "accumulator-corrections"
2. Read the file path from search results using the Read tool

**IMPORTANT:** Do NOT call `get_memory_base` here - it resets session start time and breaks commit detection.

Before calling the close_session tool:
1. Analyze the conversation to determine a concise, descriptive topic/title (2-5 words, hyphenated) that captures the main focus of the session
2. Provide a brief summary of what we worked on in this conversation

## Phase 1: Initial Close

1. Use `mcp__obsidian-context-manager__close_session` with:
   - `topic` parameter (for the filename)
   - `summary` parameter (for the content)
   - `_invoked_by_slash_command: true`
   - `working_directories` parameter - Extract from your environment context (the `<env>` section shows "Working directory:" and "Additional working directories:"). Pass ALL of these paths as an array. This is CRITICAL for correct repository detection.
   - `session_start_override` parameter - Look for `SESSION_START_TIME: <timestamp>` in your context (emitted by /mb). If found, pass the ISO 8601 timestamp as fallback.
   
   This will:
   - Auto-detect Git repositories from files accessed during the session
   - Automatically create/update project pages for detected repositories
   - Automatically link topics to projects
   - Create bidirectional links between sessions, topics, and projects
   - Run vault integrity checks on all files created/updated during this session

2. **SKIP all Git operations:**
   - Do NOT check `git status`
   - Do NOT create commits
   - Do NOT record commits
   - Do NOT auto-detect unrecorded commits

## Phase 2: Finalization (Always required - Decision 044)

The Phase 1 close_session call will return commit analysis with `session_data`. You must:

1. Review the commit analysis and suggested topic updates
2. Update relevant topics using `update_document` (NEVER use Edit/Write directly — they don't track file access for vault_custodian)
3. **DO NOT re-run Phase 1 steps** - skip straight to Phase 2 finalization
4. Call `close_session` DIRECTLY with the exact parameters shown in Phase 1's output:
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
- Do NOT check for uncommitted changes
- Do NOT create new commits
- Do NOT analyze the conversation again
- ONLY call close_session with finalize: true and the session_data

## Handoff Format (Decision 068)

The `handoff` parameter MUST use the verifier-tagged carryforward format. Every forward-looking item is a checkbox bullet paired with a `**verify:**` clause; immutable past events are tagged `[historical]` and need no verifier. Narrative-prose handoffs produce zero parseable items — the chat-bridge's Open Items panel and `/vault:mb` programmatic suppression both depend on this format.

```
- [ ] PR #42 awaiting merge — **verify:** `gh pr view 42 --json state`
- [ ] bridge restart owed for `860df06` — **verify:** bridge PID start time vs `git log -1 --format=%cI 860df06`
- [ ] smoke test owed for `dc7ff03` — **verify:** ask user, or poke the feature in the bridge UI
- [historical] Decision 067 shipped in `70d3298` — no verifier (immutable past event)
```

Rules:
- Every `- [ ]` bullet must have a `**verify:**` clause (command in backticks for `verify-command`, plain text for `verify-prose`).
- Items without a verifier must be tagged `[historical]` or dropped at write-time.
- Narrative summary paragraphs are fine alongside the bullets — but the carryforward state itself goes in bullet form.

## Summary

Provide a summary of:
- Session creation status (what was captured)
- Topics/decisions/projects linked to this session
- Repository auto-linking (if applicable)
- Vault maintenance results (automatically included in close_session output)
- Note that Git operations were skipped (remind user to commit manually if needed)
