#!/bin/bash

# UserPromptSubmit Hook - Remind Claude Code to search vault
# This hook reminds Claude to check the vault for relevant context before responding.

# Read input (required even if we don't use it)
INPUT=$(cat)

# Extract prompt to check if it's a simple command
PROMPT=$(echo "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")

# Skip reminder for very simple edits/commands
if [[ "$PROMPT" =~ ^(fix|change|update|delete|remove).{0,30}(line|file|typo|bug) ]]; then
  exit 0
fi

# Output explicit directive
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔴 REQUIRED FIRST ACTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Delegate vault lookup to the vault:researcher subagent."
echo ""
echo "Use the Agent tool with subagent_type=\"vault:researcher\". The agent will search the vault and return a concise summary (Found / Key facts / Gaps / Related) — no raw result dumps back into this context."
echo ""
echo "Do this BEFORE using Read/Grep/Glob/WebFetch/WebSearch/Task for research queries."
echo ""
echo "Direct search_vault is acceptable only for trivial single-keyword lookups where you already know the file you need."
echo ""
echo "Vault contains:"
echo "  • topics/ - Technical notes and concepts"
echo "  • sessions/ - Previous conversation logs"
echo "  • projects/ - Project documentation"
echo "  • decisions/ - Architecture and design decisions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
