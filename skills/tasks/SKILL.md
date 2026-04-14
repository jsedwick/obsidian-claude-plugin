---
description: Display outstanding tasks for the current vault mode
---

Query outstanding tasks for the current mode and display a prioritized report.

## Step 1: Query Tasks (in parallel)

Call all four queries simultaneously:
mcp__obsidian-context-manager__get_tasks_by_date({ date: "overdue", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "today", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "this-week", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "todo", status: "incomplete" })

## Step 2: Generate Report

Present tasks in priority order:

- **Overdue** — show first with warning emphasis
- **Due Today** — show next
- **Due This Week** — show next
- **Todo (No Date)** — show last

If a section has no tasks, omit it entirely. Preserve task metadata (priority, project, context, due dates).
