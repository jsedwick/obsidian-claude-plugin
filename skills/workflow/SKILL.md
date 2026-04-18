---
description: Execute a workflow or list available workflows
---

Call mcp__obsidian-context-manager__workflow with _invoked_by_slash_command: true.

If the user provided a workflow name as an argument (e.g., `/workflow create-standup-meeting`), pass it as the workflow_name parameter.

If no workflow name was provided (just `/workflow`), omit the workflow_name parameter to list all available workflows.

After the tool returns, render the result as your text response so the user sees it — the tool-call panel alone is not sufficient (some chat UIs collapse or hide it). Reproduce the tool's content verbatim as assistant text, without extra commentary, explanations, or usage tips.

If the workflow content describes actions to perform (most workflows do — e.g. `verify-work`, `refresh-calendar-cache`), then after rendering the content, proceed to execute those steps and report the outcome. If the workflow is purely informational or the user invoked `/workflow` with no arguments (list mode), stop after rendering.
