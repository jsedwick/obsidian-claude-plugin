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
echo "Call: mcp__obsidian-context-manager__search_vault"
echo ""
echo "Extract keywords from user question and search vault BEFORE using Read/Grep/Glob/WebFetch/WebSearch/Task."
echo ""
echo "Vault contains:"
echo "  • topics/ - Technical notes and concepts"
echo "  • sessions/ - Previous conversation logs"
echo "  • projects/ - Project documentation"
echo "  • decisions/ - Architecture and design decisions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 0
