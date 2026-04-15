#!/usr/bin/env bash
# vault-watch.sh — Poll Obsidian vault directories for externally modified files.
# Designed to run as a persistent plugin monitor. Outputs changed file paths
# to stdout so the Monitor tool surfaces them to Claude in real time.

OBSIDIAN_ROOT="${HOME}/Documents/Obsidian"
MARKER="/tmp/vault-watch-marker"
INTERVAL=30

# Directories to watch (topics and decisions across work vaults)
WATCH_DIRS=(
  "${OBSIDIAN_ROOT}/AI-Work/topics"
  "${OBSIDIAN_ROOT}/AI-Work/decisions"
  "${OBSIDIAN_ROOT}/AI-Work/projects"
)

# Initialize marker if it doesn't exist
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
