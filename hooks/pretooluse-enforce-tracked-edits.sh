#!/bin/bash
# Intercepts Edit/Write to enforce tracked file operations
# - Vault files → update_document (or create_decision for new decisions)
# - Code files → code_file

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

if [[ -z "$FILE_PATH" ]]; then
  exit 0  # Can't determine path, allow through
fi

# Allow .claude/ config files through (not tracked)
if [[ "$FILE_PATH" == *"/.claude/"* ]]; then
  exit 0
fi

# Check if vault file
if [[ "$FILE_PATH" == *"/Documents/Obsidian/"* ]]; then
  # Check if it's a NEW decision file (doesn't exist yet)
  if [[ "$FILE_PATH" == *"/decisions/"* ]] && [[ ! -f "$FILE_PATH" ]]; then
    cat >&2 <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 USE create_decision FOR NEW DECISIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Creating decisions directly bypasses:
  • Auto-numbering (001, 002, etc.)
  • Decision vs topic validation
  • Proactive related content linking
  • Session metadata tracking

Use instead:
  mcp__obsidian-context-manager__create_decision

For UPDATING existing decisions, use:
  mcp__obsidian-context-manager__update_document
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2  # Block with feedback
  fi

  # Existing vault file (or non-decision new file) → update_document
  cat >&2 <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 USE update_document FOR VAULT FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Native Edit/Write bypasses file tracking.

Use instead:
  mcp__obsidian-context-manager__update_document

This ensures:
  • File access is tracked for vault_custodian
  • Frontmatter is updated automatically
  • Phase 2 enforcement works correctly
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  exit 2  # Block with feedback
fi

# For all other files (code files)
cat >&2 <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 USE code_file FOR CODE FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Native Edit/Write bypasses file tracking.

Use instead:
  mcp__obsidian-context-manager__code_file

This ensures:
  • File access is tracked in filesAccessed
  • Repository detection works correctly
  • Two-phase close can detect commits
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
exit 2  # Block with feedback
