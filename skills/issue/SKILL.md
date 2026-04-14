---
description: Manage persistent issues across sessions
---

Parse the arguments and call mcp__obsidian-context-manager__issue with the appropriate mode:

**No arguments (list):**
```
/issue
```
-> Call `issue({ mode: "list" })`
-> Display active issues with priority and session count

**Load issue (load):**
```
/issue <slug>
```
-> Call `issue({ mode: "load", slug: "<slug>" })`
-> Display issue context and link current session to the issue

**Create issue (create):**
```
/issue create <name>
```
-> Call `issue({ mode: "create", name: "<name>" })` (priority defaults to "medium")
-> Confirm issue created

**Resolve issue (resolve - human only):**
```
/issue resolve <slug>
```
-> Call `issue({ mode: "resolve", slug: "<slug>", _invoked_by_slash_command: true })`
-> Archive the issue and confirm resolution

**Output format:**
- For list: Show active issues with status
- For load: Display issue details and confirm session linked
- For create: Confirm creation
- For resolve: Confirm archived

Keep output concise and actionable.
