---
description: Switch to work mode and load memory base
---

This command combines mode switching and memory base loading for a quick work session start.

**Execute these steps in order:**

1. **Switch to work mode:**
   Call `mcp__obsidian-context-manager__switch_mode` with `mode: "work"`

2. **Load memory base:**
   Call `mcp__obsidian-context-manager__get_memory_base` to load session context (user reference, recent handoffs, corrections)

3. **Summarize:**
   - Confirm mode switch to work
   - Briefly summarize vault contents (topics, sessions, projects, recent work)
