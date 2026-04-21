---
description: Execute a workflow or list available workflows
---

Call mcp__obsidian-context-manager__workflow with _invoked_by_slash_command: true.

If the user provided a workflow name as an argument (e.g., `/workflow create-standup-meeting`), pass it as the workflow_name parameter.

If no workflow name was provided (just `/workflow`), omit the workflow_name parameter to list all available workflows.

After the tool returns, handle the output based on what the workflow is:

- **List mode** (user invoked `/workflow` with no arguments — the tool returned a list of available workflows): render the tool's content verbatim as assistant text — the tool-call panel alone is not sufficient (some chat UIs collapse or hide it). Stop after rendering.
- **Informational workflow** (the content is a reference doc with no action steps for you to carry out): render the tool's content verbatim as assistant text. Stop after rendering.
- **Actionable workflow** (the content describes steps for you to perform — e.g. `verify-work`, `refresh-calendar-cache`): do NOT echo the workflow's instructions into chat. The content is a script for you to follow, not a briefing for the user. Execute the steps directly. Only produce assistant text when the workflow explicitly requires input or confirmation from the user, and at the end when reporting the outcome (what ran, what you found, any issues).
