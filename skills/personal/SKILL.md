---
description: Switch to personal mode and load memory base
---

This command combines mode switching and memory base loading for a quick personal session start.

**Execute these steps in order:**

1. **Switch to personal mode:**
   Call `mcp__obsidian-context-manager__switch_mode` with `mode: "personal"`

2. **Load memory base:**
   Call `mcp__obsidian-context-manager__get_memory_base` to load session context (user reference, recent handoffs, corrections)

3. **Summarize:**
   - Confirm mode switch to personal
   - Briefly summarize vault contents (topics, sessions, projects, recent work)
