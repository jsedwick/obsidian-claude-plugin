---
description: Switch to work mode and load memory base
---

This command combines mode switching and memory base loading for a quick work session start.

**Execute these steps in order:**

1. **Switch to work mode:**
   Call `mcp__obsidian-context-manager__switch_mode` with `mode: "work"`

2. **Load memory base:**
   Call `mcp__obsidian-context-manager__get_memory_base` to load session context (user reference, recent handoffs, corrections)

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
