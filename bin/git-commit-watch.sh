#!/usr/bin/env bash
# git-commit-watch.sh — Poll active project repos for new commits.
# Detects commits from other sessions, collaborators, or git operations
# outside the current Claude Code session. Outputs new commit info to stdout
# so the Monitor tool surfaces them to Claude in real time.
#
# Repo list resolution (first match wins):
#   1. $GIT_COMMIT_WATCH_REPOS env var — colon-separated absolute paths
#   2. bin/git-commit-watch.list (sibling to this script) — one path per line,
#      # comments and blank lines ignored. Gitignored; copy from .example to start.
#   3. No repos → script exits silently.

MARKER_DIR="/tmp/git-commit-watch"
INTERVAL=60
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FILE="${SCRIPT_DIR}/git-commit-watch.list"

WATCH_REPOS=()

if [[ -n "$GIT_COMMIT_WATCH_REPOS" ]]; then
  IFS=':' read -ra WATCH_REPOS <<< "$GIT_COMMIT_WATCH_REPOS"
elif [[ -f "$LIST_FILE" ]]; then
  while IFS= read -r line; do
    # Skip blank lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    # Strip leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    WATCH_REPOS+=("${line/#\~/$HOME}")
  done < "$LIST_FILE"
fi

if [ ${#WATCH_REPOS[@]} -eq 0 ]; then
  exit 0
fi

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
