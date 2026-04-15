#!/bin/bash

# SessionEnd Hook - Git Sync All Vaults (Push)
# This hook runs when Claude Code session ends to:
# 1. Discover all vaults from MCP config (primary + secondary, work + personal modes)
# 2. Auto-commit any uncommitted vault changes
# 3. Push changes to remote git repository for each vault

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GIT SYNC - Push vault changes to remote for ALL vaults
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

COMMIT_COUNT=0
PUSH_ERRORS=()

# Detect bridge mode: skip git push when running as a -p subprocess
# (each bridge message is a separate process; pushing on every exit is wasteful and delays UI)
SKIP_PUSH=false
if [[ -n "$CHAT_BRIDGE_SESSION" ]]; then
  SKIP_PUSH=true
fi

# Sync each vault
while IFS= read -r VAULT_PATH; do
  [[ -z "$VAULT_PATH" ]] && continue

  # Skip if not a git repository
  if [[ ! -d "$VAULT_PATH/.git" ]]; then
    continue
  fi

  cd "$VAULT_PATH" || continue

  # Stage all changes (vault_custodian may have modified files)
  git add . 2>/dev/null

  # Commit if there are changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
    git commit -m "Session end auto-commit: $TIMESTAMP" --quiet 2>/dev/null
    COMMIT_COUNT=$((COMMIT_COUNT + 1))
  fi

  # Push to remote (skip in bridge mode — /vault:close handles push for bridge sessions)
  if [[ "$SKIP_PUSH" == false ]]; then
    if ! git push --quiet 2>&1; then
      PUSH_ERRORS+=("$VAULT_PATH")
    fi
  fi
done <<< "$VAULT_PATHS"

# Report results
if [ $COMMIT_COUNT -gt 0 ]; then
  echo "Auto-committed changes in $COMMIT_COUNT vault(s)" >&2
fi

if [[ "$SKIP_PUSH" == true ]]; then
  # Silent in bridge mode — commits saved locally, push deferred to /vault:close
  :
elif [ ${#PUSH_ERRORS[@]} -eq 0 ]; then
  echo "All vaults synced to remote" >&2
else
  cat >&2 <<EOF
Git push failed for some vaults - changes saved locally

Failed vaults:
$(printf '  • %s\n' "${PUSH_ERRORS[@]}")

Run this manually when connection restored:
  cd [vault-path]
  git push
EOF
fi

# Always exit 0 - session end should never fail due to git push failure
exit 0
