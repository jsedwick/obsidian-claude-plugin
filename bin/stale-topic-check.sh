#!/usr/bin/env bash
# stale-topic-check.sh — One-shot scan for topics not reviewed in 60+ days.
# Runs at session start, reports stale topics in the active mode's vault, exits.
# Does NOT archive or modify anything — use find_stale_topics tool for that.
#
# Mode resolution: $VAULT_MODE env var (matches MCP server's logic), default "work".
# Mode is in-memory in the MCP server, so we can't follow runtime switches —
# but the launch-time mode is the correct one for a session-start one-shot.

THRESHOLD_DAYS=60
MODE="${VAULT_MODE:-work}"

# Discover MCP config (same search order as hooks/session-start.sh)
if [[ -n "$MCP_CONFIG_PATH" && -f "$MCP_CONFIG_PATH" ]]; then
  MCP_CONFIG="$MCP_CONFIG_PATH"
elif [[ -f "$HOME/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.obsidian-mcp.json"
elif [[ -f "$HOME/.config/.obsidian-mcp.json" ]]; then
  MCP_CONFIG="$HOME/.config/.obsidian-mcp.json"
else
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

[ -z "$VAULT_PATH" ] && exit 0
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"
TOPICS_DIR="${VAULT_PATH}/topics"
[ -d "$TOPICS_DIR" ] || exit 0

stale_count=0
stale_list=""

for file in "$TOPICS_DIR"/*.md; do
  [ -f "$file" ] || continue

  # Extract last_reviewed or created date from frontmatter
  review_date=$(sed -n '/^---$/,/^---$/{ s/^last_reviewed: *//p; }' "$file" | head -1)
  if [ -z "$review_date" ]; then
    review_date=$(sed -n '/^---$/,/^---$/{ s/^created: *//p; }' "$file" | head -1)
  fi
  [ -z "$review_date" ] && continue

  # Strip quotes if present
  review_date=$(echo "$review_date" | tr -d '"' | tr -d "'")

  # Calculate age in days
  review_epoch=$(date -j -f "%Y-%m-%d" "$review_date" "+%s" 2>/dev/null)
  [ -z "$review_epoch" ] && continue

  now_epoch=$(date "+%s")
  age_days=$(( (now_epoch - review_epoch) / 86400 ))

  if [ "$age_days" -gt "$THRESHOLD_DAYS" ]; then
    name=$(basename "$file" .md)
    stale_count=$((stale_count + 1))
    stale_list="${stale_list}  - ${name} (${age_days}d)\n"
  fi
done

if [ "$stale_count" -gt 0 ]; then
  echo "Stale topics (>${THRESHOLD_DAYS}d without review): ${stale_count} found"
  printf "$stale_list"
  echo "Run find_stale_topics() or /workflow Vault Management/find-stale-topics to triage."
fi
