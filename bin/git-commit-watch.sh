#!/usr/bin/env bash
# git-commit-watch.sh — Poll active project repos for new commits.
# Detects commits from other sessions, collaborators, or git operations
# outside the current Claude Code session. Outputs new commit info to stdout
# so the Monitor tool surfaces them to Claude in real time.

MARKER_DIR="/tmp/git-commit-watch"
INTERVAL=60

# Repos to watch — add/remove as needed
WATCH_REPOS=(
  "${HOME}/Projects/obsidian-mcp-server"
  "${HOME}/Projects/claude-chat-bridge"
  "${HOME}/Projects/obsidian-claude-plugin"
)

# Create marker directory if it doesn't exist
mkdir -p "$MARKER_DIR"

# Initialize markers with current HEAD for each repo
for repo in "${WATCH_REPOS[@]}"; do
  [ -d "$repo/.git" ] || continue
  name=$(basename "$repo")
  marker="$MARKER_DIR/$name"
  if [ ! -f "$marker" ]; then
    git -C "$repo" rev-parse HEAD 2>/dev/null > "$marker"
  fi
done

while true; do
  for repo in "${WATCH_REPOS[@]}"; do
    [ -d "$repo/.git" ] || continue
    name=$(basename "$repo")
    marker="$MARKER_DIR/$name"

    current_head=$(git -C "$repo" rev-parse HEAD 2>/dev/null)
    [ -z "$current_head" ] && continue

    last_seen=$(cat "$marker" 2>/dev/null)

    if [ -n "$last_seen" ] && [ "$current_head" != "$last_seen" ]; then
      # Report each new commit since last check
      git -C "$repo" log --oneline "$last_seen..$current_head" 2>/dev/null | \
        while IFS= read -r line; do
          echo "New commit in $name: $line"
        done
    fi

    echo "$current_head" > "$marker"
  done
  sleep "$INTERVAL"
done
