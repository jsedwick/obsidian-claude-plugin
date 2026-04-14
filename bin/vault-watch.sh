#!/bin/bash
# Vault file change monitor — polls for recently modified files
# Uses find + a marker file to detect changes since last check
# No external dependencies (fswatch not required)
# Vault paths discovered from MCP config (same pattern as session hooks)

MARKER="/tmp/.vault-watch-marker"
POLL_INTERVAL=30

# MCP config discovery - search standard locations (same as MCP server)
if [[ -n "$MCP_CONFIG_PATH" && -f "$MCP_CONFIG_PATH" ]]; then
  MCP_CONFIG="$MCP_CONFIG_PATH"
elif [[ -f "$HOME/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.obsidian-mcp.json"
elif [[ -f "$HOME/.config/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.config/.obsidian-mcp.json"
else
  MCP_CONFIG=""
fi

# Build watch directories from MCP config vault paths
WATCH_DIRS=()
if [[ -f "$MCP_CONFIG" ]]; then
  while IFS= read -r vault_path; do
    [[ -z "$vault_path" ]] && continue
    # Watch topics/ and decisions/ subdirectories of each vault
    [[ -d "$vault_path/topics" ]] && WATCH_DIRS+=("$vault_path/topics")
    [[ -d "$vault_path/decisions" ]] && WATCH_DIRS+=("$vault_path/decisions")
  done < <(node -e "
    const config = require('$MCP_CONFIG');
    const vaults = new Set();
    if (config.primaryVaults) {
      config.primaryVaults.forEach(v => vaults.add(v.path.replace(/\/$/, '').replace(/^~/, process.env.HOME)));
    }
    if (config.secondaryVaults) {
      config.secondaryVaults.forEach(v => vaults.add(v.path.replace(/\/$/, '').replace(/^~/, process.env.HOME)));
    }
    console.log(Array.from(vaults).join('\n'));
  " 2>/dev/null)
fi

# Fallback if config not found or no directories discovered
if [[ ${#WATCH_DIRS[@]} -eq 0 ]]; then
  echo "No vault directories discovered from MCP config — exiting" >&2
  exit 1
fi

# Initialize marker if it doesn't exist
if [[ ! -f "$MARKER" ]]; then
  touch "$MARKER"
fi

while true; do
  for dir in "${WATCH_DIRS[@]}"; do
    [[ ! -d "$dir" ]] && continue

    # Find files modified since the marker timestamp
    changed=$(find "$dir" -name "*.md" -newer "$MARKER" -type f 2>/dev/null)
    if [[ -n "$changed" ]]; then
      while IFS= read -r file; do
        # Get relative path from home for readability
        rel_path="${file#$HOME/Documents/Obsidian/}"
        echo "Vault changed: $rel_path"
      done <<< "$changed"
    fi
  done

  # Update marker timestamp
  touch "$MARKER"
  sleep "$POLL_INTERVAL"
done
