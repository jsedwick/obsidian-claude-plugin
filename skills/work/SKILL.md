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

4. **Summarize:**
   - Confirm mode switch to work
   - Briefly summarize vault contents (topics, sessions, projects, recent work)
   - Note any stale topic alerts from the monitor
