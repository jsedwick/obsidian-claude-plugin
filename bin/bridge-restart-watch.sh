#!/usr/bin/env bash
# bridge-restart-watch.sh — Persistent monitor for Claude Chat Bridge launchd lifecycle.
# Polls launchctl every POLL_INTERVAL seconds; on PID change, actively polls the
# /api/health endpoint until it responds, then emits an explicit "restart complete,
# do not retry" event. Designed to short-circuit Claude's restart-retry loop when
# the bridge is already coming back up.

SERVICE_LABEL="com.jsedwick.claude-chat-bridge"
HEALTH_URL="https://localhost:${CHAT_BRIDGE_PORT:-3456}/api/health"
POLL_INTERVAL=3
HEALTH_TIMEOUT=30
HEALTH_POLL_INTERVAL=1

read_pid() {
  local pid
  pid=$(launchctl list 2>/dev/null | awk -v label="$SERVICE_LABEL" '$3 == label { print $1 }')
  [ -z "$pid" ] && pid="not-registered"
  echo "$pid"
}

wait_for_health() {
  local deadline=$(( $(date +%s) + HEALTH_TIMEOUT ))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    if curl -sfk -m 2 "$HEALTH_URL" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$HEALTH_POLL_INTERVAL"
  done
  return 1
}

last_pid=$(read_pid)

while true; do
  sleep "$POLL_INTERVAL"
  current_pid=$(read_pid)

  if [ "$current_pid" = "$last_pid" ]; then
    continue
  fi

  ts=$(date "+%Y-%m-%d %H:%M:%S")

  # Case 1: bridge went down — launchd (KeepAlive=true) will auto-restart it.
  if [ "$current_pid" = "-" ] || [ "$current_pid" = "not-registered" ]; then
    echo "[$ts] Claude Chat Bridge STOPPED (was PID $last_pid). launchd KeepAlive will auto-restart it — DO NOT issue a manual restart. Waiting for it to come back."
    last_pid="$current_pid"
    continue
  fi

  # Case 2: PID transitioned to a valid number — restart or fresh start.
  if [ "$last_pid" = "-" ] || [ "$last_pid" = "not-registered" ]; then
    echo "[$ts] Claude Chat Bridge STARTED: PID $current_pid. Verifying health endpoint before confirming..."
  else
    echo "[$ts] Claude Chat Bridge RESTART DETECTED: PID $last_pid -> $current_pid. Verifying health endpoint before confirming — DO NOT attempt another restart."
  fi

  if wait_for_health; then
    ts2=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$ts2] Claude Chat Bridge RESTART COMPLETE: PID $current_pid, $HEALTH_URL responding 200 OK. The server is ready. Resume what you were doing — DO NOT issue any further launchctl kickstart commands. In-memory session map was reset, so browser sessions will need to reconnect, but the bridge itself is healthy."
  else
    ts2=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$ts2] Claude Chat Bridge restart detected (PID $current_pid) but $HEALTH_URL did not respond within ${HEALTH_TIMEOUT}s. Investigate chat-bridge-error.log in the project root before issuing another restart."
  fi

  last_pid="$current_pid"
done
