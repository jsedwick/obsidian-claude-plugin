#!/bin/bash

# SessionStart Hook - Git Sync All Vaults + Load Memory Context
# This hook runs at the start of every Claude Code session to:
# 1. Discover all vaults from MCP config (primary + secondary, work + personal modes)
# 2. Pull latest changes from remote for each git-tracked vault
# 3. Show user tip about /vault:mb and /vault:close commands

# MCP config discovery - search standard locations (same as MCP server)
# 1. Environment variable override
# 2. Home directory
# 3. .config directory
if [[ -n "$MCP_CONFIG_PATH" && -f "$MCP_CONFIG_PATH" ]]; then
  MCP_CONFIG="$MCP_CONFIG_PATH"
elif [[ -f "$HOME/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.obsidian-mcp.json"
elif [[ -f "$HOME/.config/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.config/.obsidian-mcp.json"
else
  MCP_CONFIG=""
fi

# Read all available input from stdin (non-blocking)
if [ -t 0 ]; then
  INPUT=""
else
  INPUT=$(cat)
fi

# Check if a session has already been started in this conversation
TRANSCRIPT_PATH=$(echo "$INPUT" | grep -o '"transcript_path":"[^"]*"' | cut -d'"' -f4)

SESSION_ALREADY_STARTED=false
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  if grep -q 'mcp__obsidian-context-manager__start_session' "$TRANSCRIPT_PATH" 2>/dev/null; then
    SESSION_ALREADY_STARTED=true
  fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GIT SYNC - Pull latest vault changes for ALL vaults
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Extract all vault paths from MCP config (both primary and secondary vaults)
if [[ -f "$MCP_CONFIG" ]]; then
  VAULT_PATHS=$(node -e "
    const config = require('$MCP_CONFIG');
    const vaults = new Set();

    // Add primary vaults
    if (config.primaryVaults) {
      config.primaryVaults.forEach(v => vaults.add(v.path.replace(/\/$/, '')));
    }

    // Add secondary vaults
    if (config.secondaryVaults) {
      config.secondaryVaults.forEach(v => vaults.add(v.path.replace(/\/$/, '')));
    }

    console.log(Array.from(vaults).join('\n'));
  " 2>/dev/null)
else
  # Fallback to work vault if config not found
  VAULT_PATHS="/Users/jsedwick/Documents/Obsidian/AI-Work"
fi

SYNC_ERRORS=()

# Sync each vault
while IFS= read -r VAULT_PATH; do
  [[ -z "$VAULT_PATH" ]] && continue

  # Skip if not a git repository
  if [[ ! -d "$VAULT_PATH/.git" ]]; then
    continue
  fi

  cd "$VAULT_PATH" || continue

  # Auto-commit any orphaned changes from outside sessions
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    git add . 2>/dev/null
    git commit -m "Auto-commit: $(date +%Y-%m-%d_%H-%M-%S)" --quiet 2>/dev/null
  fi

  # Pull latest changes (fast-forward only to prevent auto-merges)
  if ! git pull --ff-only --quiet 2>&1; then
    SYNC_ERRORS+=("$VAULT_PATH")
  fi
done <<< "$VAULT_PATHS"

# Report any sync failures
if [ ${#SYNC_ERRORS[@]} -gt 0 ]; then
  cat >&2 <<EOF
⚠️  VAULT SYNC FAILED

Git pull encountered conflicts or errors for:
$(printf '  • %s\n' "${SYNC_ERRORS[@]}")

This usually means:
  • Changes made on another device conflict with local changes
  • Network connection failed
  • Remote repository unavailable

TO RESOLVE:
  cd [vault-path]
  git status
  git pull --rebase  # Or resolve conflicts manually

Session starting with LOCAL vault state for failed syncs.
EOF
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# USER TIP (if not already shown)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$SESSION_ALREADY_STARTED" == false ]]; then
  # Output only JSON - Claude Code can't parse mixed plain text + JSON
  cat <<EOF
{
  "systemMessage": "💡 Tip: Run /vault:work or /vault:personal to switch vaults and load context. Run /vault:close when finished to save this session."
}
EOF
fi

exit 0
