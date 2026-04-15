#!/usr/bin/env bash
# stale-topic-check.sh — One-shot scan for topics not reviewed in 30+ days.
# Runs at session start, reports stale topics, then exits.
# Does NOT archive or modify anything — use find_stale_topics tool for that.

OBSIDIAN_ROOT="${HOME}/Documents/Obsidian"
TOPICS_DIR="${OBSIDIAN_ROOT}/AI-Work/topics"
THRESHOLD_DAYS=30

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
