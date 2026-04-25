#!/usr/bin/env bash
# vault-watch.sh — Poll the active mode's vault for externally modified files.
# Runs as a persistent plugin monitor. Outputs changed file paths to stdout so
# the Monitor tool surfaces them to Claude in real time.
#
# Mode resolution: $VAULT_MODE env var (matches MCP server's logic), default "work".
# Mode is in-memory in the MCP server, so this monitor reflects the launch-time
# mode. Restart the monitor (or session) after switching modes to retarget.

MARKER="/tmp/vault-watch-marker"
INTERVAL=30
MODE="${VAULT_MODE:-work}"

# Discover MCP config (same search order as hooks/session-start.sh)
if [[ -n "$MCP_CONFIG_PATH" && -f "$MCP_CONFIG_PATH" ]]; then
  MCP_CONFIG="$MCP_CONFIG_PATH"
elif [[ -f "$HOME/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.obsidian-mcp.json"
elif [[ -f "$HOME/.config/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.config/.obsidian-mcp.json"
else
  echo "vault-watch: no MCP config found — exiting" >&2
  exit 0
fi

# Resolve the primary vault path matching the active mode
VAULT_PATH=$(node -e "
  const c = require('$MCP_CONFIG');
  const v = (c.primaryVaults || []).find(x => x.mode === '$MODE');
  if (!v) process.exit(0);
  let p = v.path;
  if (p.endsWith('/')) p = p.slice(0, -1);
  console.log(p);
" 2>/dev/null)

if [ -z "$VAULT_PATH" ]; then
  echo "vault-watch: no primaryVaults entry for mode '$MODE' — exiting" >&2
  exit 0
fi

VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
OBSIDIAN_ROOT=$(dirname "$VAULT_PATH")

WATCH_DIRS=(
  "${VAULT_PATH}/topics"
  "${VAULT_PATH}/decisions"
  "${VAULT_PATH}/projects"
)

if [ ! -f "$MARKER" ]; then
  touch "$MARKER"
fi

while true; do
  for dir in "${WATCH_DIRS[@]}"; do
    [ -d "$dir" ] || continue
    changed=$(find "$dir" -name "*.md" -newer "$MARKER" -type f 2>/dev/null)
    if [ -n "$changed" ]; then
      while IFS= read -r path; do
        relpath="${path#"${OBSIDIAN_ROOT}/"}"
        echo "Vault file changed: ${relpath}"
      done <<< "$changed"
    fi
  done
  touch "$MARKER"
  sleep "$INTERVAL"
done
