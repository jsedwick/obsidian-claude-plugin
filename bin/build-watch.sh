#!/usr/bin/env bash
# build-watch.sh — Tail build log files for TypeScript/build errors.
# Works with any project that writes build output to a known log path.
# To use: start a watch build redirected to the log file, e.g.:
#   cd ~/Projects/obsidian-mcp-server && npx tsc --watch 2>&1 | tee /tmp/obsidian-mcp-server-build.log &
#   cd ~/Projects/claude-chat-bridge && npx tsc --watch 2>&1 | tee /tmp/claude-chat-bridge-build.log &
#
# The monitor will pick up any matching log files automatically.

LOG_PATTERN="/tmp/*-build.log"
CHECK_INTERVAL=5

# Wait for at least one build log to appear
while true; do
  logs=( $LOG_PATTERN )
  [ -f "${logs[0]}" ] 2>/dev/null && break
  sleep "$CHECK_INTERVAL"
done

# Tail all matching build logs, filtering for errors
# tail -f follows new files matching the pattern as they appear
tail -f $LOG_PATTERN 2>/dev/null | grep --line-buffered -E \
  'error TS[0-9]+|Build failed|ERROR|Cannot find module|SyntaxError|TypeError|Found [0-9]+ error'
