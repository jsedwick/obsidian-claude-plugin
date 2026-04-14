---
description: Display tasks across both work and personal vaults
---

Query tasks across both work and personal vault modes and combine them into a single unified report.

## Step 1: Capture Starting Mode

Note the current mode so you can restore it at the end:
mcp__obsidian-context-manager__get_current_mode

## Step 2: Query Work Mode Tasks

If not already in work mode, switch first:
mcp__obsidian-context-manager__switch_mode({ mode: "work" })

Query all four task types in parallel:
mcp__obsidian-context-manager__get_tasks_by_date({ date: "overdue", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "today", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "this-week", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "todo", status: "incomplete" })

## Step 3: Query Personal Mode Tasks
mcp__obsidian-context-manager__switch_mode({ mode: "personal" })

Query all four task types in parallel:
mcp__obsidian-context-manager__get_tasks_by_date({ date: "overdue", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "today", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "this-week", status: "incomplete" })
mcp__obsidian-context-manager__get_tasks_by_date({ date: "todo", status: "incomplete" })


## Step 4: Restore Original Mode

Switch back to whichever mode was active at the start.

## Step 5: Generate Combined Report

Present a unified report grouped by urgency, with Work and Personal subsections:

- **Overdue** — Work / Personal
- **Due Today** — Work / Personal
- **Due This Week** — Work / Personal
- **Todo (No Date)** — Work / Personal

If a vault has no tasks in a section, show "No tasks" for that subsection. Preserve task metadata (priority, project, context, due dates).
