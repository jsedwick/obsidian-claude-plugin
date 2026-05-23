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
3. **Add forward-looking carryforward items to the canonical file (Decision 028 Phase 4).** For each forward-looking bullet that next-session needs to act on, call `mcp__obsidian-context-manager__add_carryforward_item`:
   ```typescript
   add_carryforward_item({
     body: "Bridge restart owed for `860df06`",
     verifier: "bridge PID start time vs `git log -1 --format=%cI 860df06`",
     cwd: "/path/from/env-block-Primary-working-directory"  // REQUIRED
   })
   ```
   - One call per bullet. The tool is hash-idempotent — duplicate bullets become no-ops.
   - `cwd` is REQUIRED and must be the env block's `Primary working directory:` value verbatim.
   - `kind` is inferred from `verifier`: backtick-wrapped command → `verify-command`; plain text → `verify-prose`; absent → `untagged-forward-looking` (discouraged — prefer to either add a verifier or drop the item).
   - Skip immutable past events (`[historical]`) — those go in the narrative prose of the `handoff` parameter, not into canonical.
4. **DO NOT re-run Phase 1 steps** - skip straight to Phase 2 finalization
5. Call `close_session` DIRECTLY with the exact parameters shown in Phase 1's output:
   ```typescript
   close_session({
     summary: "...",
     topic: "...",
     finalize: true,
     handoff: "[narrative prose summarizing what happened, what we tried, and what to watch for — NO checkbox bullets]",  // REQUIRED (Decision 052)
     session_data: { ...the session_data from Phase 1... }
   })
   ```

**IMPORTANT: Phase 2 is a DIRECT tool call, not a restart of this workflow.**
- Do NOT check for uncommitted changes
- Do NOT create new commits
- Do NOT analyze the conversation again
- ONLY call close_session with finalize: true and the session_data

## Closing Notes Format (Decision 028 Phase 4 + Decision 068)

Forward-looking carryforward items live in the canonical `open-carryforward.md` file (via `add_carryforward_item` in step 3 above). The `handoff` parameter passed to `close_session` is **narrative-only prose** — no `- [ ]` checkbox bullets. The MCP server writes this prose into the session file's `## Closing notes` section.

```
This session shipped Decision 067 in `70d3298` after exploring two alternatives (X
and Y). We initially tried X but reverted after the integrity check failed on
malformed input — Y handles the edge case cleanly. Next session should watch for
PR #42 reaching its review window and confirm the bridge restart picked up the
new behavior.
```

Rules for the `handoff` narrative:
- Prose paragraphs that capture what happened, what was tried, and watch-fors that aren't actionable bullets.
- `[historical]` past events that next session might want context on go here as prose (not bullets).
- Forward-looking actionable items (restarts owed, smoke tests owed, follow-up fixes) belong in `add_carryforward_item` calls, NOT in the narrative.
- An empty handoff parameter triggers a post-write integrity check failure — always emit at least a one-sentence summary.

## Summary

Provide a summary of:
- Session creation status (what was captured)
- Topics/decisions/projects linked to this session
- Repository auto-linking (if applicable)
- Vault maintenance results (automatically included in close_session output)
- Note that Git operations were skipped (remind user to commit manually if needed)
