---
description: Execute a workflow or list available workflows
---

Call mcp__obsidian-context-manager__workflow with _invoked_by_slash_command: true.

If the user provided a workflow name as an argument (e.g., `/workflow create-standup-meeting`), pass it as the workflow_name parameter.

If no workflow name was provided (just `/workflow`), omit the workflow_name parameter to list all available workflows.

Output the tool result directly without additional commentary.
