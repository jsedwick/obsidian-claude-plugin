---
description: Switch to work mode and load memory base
---

This command combines mode switching and memory base loading for a quick work session start.

**Execute these steps in order:**

1. **Switch to work mode:**
   Call `mcp__obsidian-context-manager__switch_mode` with `mode: "work"`

2. **Load memory base:**
   Call `mcp__obsidian-context-manager__get_memory_base` to load session context (user reference, recent handoffs, corrections).

   **Decision 068 — interpret handoff verifier results.** Each recent handoff in `structuredContent.handoffs[].items` is the parsed carryforward bullets with verifier execution results. The MCP server pre-suppresses items the LLM should never act on — all `kind: historical`, plus `kind: verify-command` absence-grep patterns whose verifier already returned empty (exit ≠ 0, empty stdout, not timed-out, not skipped) — so those will not appear in your context. For items that do survive, apply this interpretation BEFORE reciting any forward-looking carryforward as currently true:
   - `kind: verify-command` + `result.exit_code === 0` — inspect `result.stdout`. If it indicates the claim is now resolved (PR merged, branch in sync, restart already done, etc.), suppress the item or note it as resolved. Otherwise surface as live with confidence.
   - `kind: verify-command` + non-zero exit / `timed_out` / `skipped_budget` — surface with explicit uncertainty. Do NOT state the claim as fact; tell the user the verifier failed and prompt for manual check.
   - `kind: verify-prose` — manual verifier (asking the user, poking the UI). Surface the prose instruction; flag the item as needing manual confirmation before action.
   - `kind: untagged-forward-looking` — writer-contract violation under Decision 068. Treat as suspect; re-verify before reciting.

   **Decision 023 — handoff triage menu.** After applying the Decision 068 interpretation above, identify *triage-eligible* items — bullets that need a user decision before they can stop being recited next session:

   - `kind: verify-prose`
   - `kind: untagged-forward-looking`

   Items pre-suppressed by the MCP server (`historical`, absence-grep resolved) do not appear in `items` at all. `kind: verify-command` items are intentionally excluded (Phase 5+): the chat-bridge server endpoint can't execute verifier commands, so we restrict triage to kinds that don't require execution. Verify-command items remain visible in the `get_memory_base` tool-result panel and can still be tagged via direct CLI commands.

   If zero triage-eligible items exist across all returned handoffs, skip the triage rendering entirely.

   Otherwise, at the END of the **Summarize** step (after all other content), emit ONLY the minimal marker. The chat-bridge frontend fetches `items[]` from `/api/triage/current?mode=<active>&working_directory=<cwd>` the moment the closing `-->` arrives and renders the card instantly — the LLM no longer streams item bodies or hashes:

   ```
   <!--triage-menu:v1 {"ref":"latest","working_directory":"<CWD>"} -->

   Carryforward triage available — see the card below, or type `<N> resolve` / `<N> elaborate` from CLI.
   ```

   **Decision 026 — populate `working_directory`** with the absolute path shown in the session env block as `Primary working directory: ...`. The bridge uses it to mirror MCP's session-selection algorithm (mtime DESC + CWD-priority), so the card's items match the same set the LLM sees in `get_memory_base.triage_items[]` (Decision 027 — flat list, deduped, CWD-bucket-sorted, 1-indexed). Omitting the field is a soft fallback (the bridge degrades to filename-DESC selection across all projects), but emit it whenever the env block contains a `Primary working directory:` line.

   The bridge frontend renders a header with the authoritative count (`Carryforward triage (N items)`); do not state a count in the LLM text. The HTML comment is invisible in rendered markdown; the frontend regex `<!--triage-menu:v1\s*([\s\S]*?)\s*-->` extracts the payload. Emit the JSON as a single line (no internal newlines).

   **Decision 024 — bridge UI bulk-resolve bypasses the LLM.** When the user clicks Submit on the triage card, the chat-bridge frontend POSTs each row to `/api/triage/resolve` directly. You will not see those resolves as chat messages — they never reach the LLM. You are invoked only on Elaborate clicks and CLI input.

   When you DO receive a triage-related message, parse:

   - `<N> elaborate` — look up `get_memory_base.triage_items[N-1]` (Decision 027 — 1-indexed flat list, already deduped + CWD-sorted to match the bridge UI). Load the source session via `get_session_context` using the item's `source_session_slug`; if the body references a topic/decision/commit slug, fetch it via the appropriate tool. Explain in 2–3 sentences. **Do NOT re-render the menu** and **do NOT emit any update marker** — the original card persists in the bridge. **Non-terminal.**
   - `<N> resolve` or `<N> dismiss` — CLI fallback for non-bridge clients. Look up `triage_items[N-1]` the same way, call `tag_handoff_item` with `source_session_slug` + `bullet_id_hash` + matching `action`, then emit `<!--triage-update:v1 {"removed":[N]} -->` followed by "Resolved item N." Do NOT re-render the menu. **Terminal.**
   - Any other input — escape hatch: treat as the user's actual task for the session and proceed normally.

3. **Arm background monitors** (run all in parallel):
   - `Monitor` with `command: "${HOME}/Projects/obsidian-claude-plugin/bin/stale-topic-check.sh"`, `description: "Stale topic check"`, `persistent: false`
   - `Monitor` with `command: "${HOME}/Projects/obsidian-claude-plugin/bin/git-commit-watch.sh"`, `description: "Git commit watcher"`, `persistent: true`
   - `Monitor` with `command: "tail -f /tmp/obsidian-mcp-server.log 2>/dev/null | grep --line-buffered 'ERROR\\|FATAL\\|uncaughtException'"`, `description: "MCP server error monitor"`, `persistent: true`
   - `Monitor` with `command: "${HOME}/Projects/obsidian-claude-plugin/bin/bridge-restart-watch.sh"`, `description: "Claude Chat Bridge restart watcher"`, `persistent: true`

4. **Discover and handle vault-defined monitors:**
   Call `mcp__obsidian-context-manager__list_vault_monitors` to discover custom monitors from the vault's `monitors/` directory. If no monitors are returned, skip this step silently.

   Then split the returned monitors by their `persistent` field and handle each group differently:

   - **Persistent monitors (`persistent: true`):** Arm each one in parallel via `Monitor` with the returned `command`, `description`, `persistent`, and `timeout_ms` values. These stream events for the session lifetime; any `DIRECTIVE:` lines they emit should be actioned as they arrive.
   - **One-shot monitors (`persistent: false`):** Do NOT use the `Monitor` tool — its event delivery is asynchronous and races with this skill's summary step. Instead, run each one-shot monitor's `command` synchronously via `Bash`, capturing stdout. Then, for each line in the captured output:
     - If the line starts with `DIRECTIVE:`, treat the remainder as an actionable instruction and execute it *immediately, in this step*, before moving on. The canonical form is `DIRECTIVE: run workflow <path>` — invoke the `workflow` tool with `<path>`.
     - Otherwise, collect the line as a notification to surface in the final summary.
   - If multiple directives are emitted (across monitors or within one script), run them in the order received.

5. **Summarize:**
   - Confirm mode switch to work
   - Briefly summarize vault contents (topics, sessions, projects, recent work)
   - Note any stale topic alerts from the bundled monitor
   - Report directives executed this session and their outcomes (one-shot vault monitors in step 4)
   - Report non-directive output captured from one-shot vault monitors
   - If triage-eligible carryforward items exist (per Decision 023 in step 2), append the `## Carryforward triage` menu at the very end
