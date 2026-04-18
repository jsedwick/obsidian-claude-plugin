---
description: Switch between work and personal vault modes
---

Use the mcp__obsidian-context-manager__switch_mode or mcp__obsidian-context-manager__get_current_mode tool based on the argument provided.

**If no argument is provided or argument is empty:**
Call `get_current_mode` to show the current mode and available modes.

**If argument is "work" or "personal":**
Call `switch_mode` with `mode: "<argument>"` to switch to that mode.

**If argument is anything else:**
Respond with: "Invalid mode. Use `/mode` to see current mode, or `/mode work` or `/mode personal` to switch."

After the tool returns, render the result as your text response so the user sees it — the tool-call panel alone is not sufficient (some chat UIs collapse or hide it). No additional commentary beyond what the tool returned.
