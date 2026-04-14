#!/bin/bash
# Vault file change monitor — polls for recently modified files
# Uses find + a marker file to detect changes since last check
# No external dependencies (fswatch not required)

MARKER="/tmp/.vault-watch-marker"
POLL_INTERVAL=30

# Directories to watch (active mode's primary vault topics + decisions)
WATCH_DIRS=(
  "$HOME/Documents/Obsidian/AI-Work/topics"
  "$HOME/Documents/Obsidian/AI-Work/decisions"
  "$HOME/Documents/Obsidian/AI-Home/topics"
  "$HOME/Documents/Obsidian/AI-Home/decisions"
)

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
        # Get relative path from Obsidian root for readability
        rel_path="${file#$HOME/Documents/Obsidian/}"
        echo "Vault changed: $rel_path"
      done <<< "$changed"
    fi
  done

  # Update marker timestamp
  touch "$MARKER"
  sleep "$POLL_INTERVAL"
done
