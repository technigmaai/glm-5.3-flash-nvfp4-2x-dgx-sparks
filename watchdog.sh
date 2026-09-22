#!/bin/bash
# Coordinate recovery of the two-node GLM deployment after repeated failures.
# Intended to run once per minute from the head node's user crontab.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/watchdog.log"
STATE_FILE="$SCRIPT_DIR/.watchdog-state"
DISABLED_FILE="$SCRIPT_DIR/.watchdog-disabled"
LOCK_FILE="$SCRIPT_DIR/.watchdog.lock"
FAILURES_BEFORE_RESTART=3
STARTUP_GRACE_SECONDS=900
RESTART_COOLDOWN_SECONDS=900

mkdir -p "$LOG_DIR"

# Load the configured API port for status and health checks when available.
if [ -f .env ]; then
  set -a; source .env; set +a
fi

exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

log() {
  if [ -f "$LOG_FILE" ] && [ "$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)" -gt 10485760 ]; then
    mv "$LOG_FILE" "$LOG_FILE.1"
  fi
  printf '%s %s\n' "$(date --iso-8601=seconds)" "$*" >> "$LOG_FILE"
}

case "${1:-check}" in
  enable)
    rm -f "$DISABLED_FILE"
    printf '0 0\n' > "$STATE_FILE"
    echo "GLM watchdog enabled"
    exit 0
    ;;
  disable)
    touch "$DISABLED_FILE"
    echo "GLM watchdog disabled"
    exit 0
    ;;
  status)
    if [ -f "$DISABLED_FILE" ]; then state=disabled; else state=enabled; fi
    health=$(curl -fsS --max-time 5 -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT:-8000}/health" 2>/dev/null || true)
    echo "watchdog=$state health=${health:-unreachable} state=$(cat "$STATE_FILE" 2>/dev/null || echo '0 0')"
    exit 0
    ;;
  check) ;;
  *)
    echo "Usage: $0 [check|enable|disable|status]" >&2
    exit 2
    ;;
esac

[ -f "$DISABLED_FILE" ] && exit 0
[ -f .env ] || { log "missing .env; cannot monitor"; exit 1; }

read -r failures last_restart < "$STATE_FILE" 2>/dev/null || {
  failures=0
  last_restart=0
}

health=$(curl -fsS --max-time 5 -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT:-8000}/health" 2>/dev/null || true)
if [ "$health" = "200" ]; then
  [ "$failures" -eq 0 ] || log "health restored after $failures failed checks"
  printf '0 %s\n' "$last_restart" > "$STATE_FILE"
  exit 0
fi

# A running head receives a 15-minute startup grace period because a cold R28
# boot spends several minutes loading weights and preparing B12X kernels.
running=$(docker inspect -f '{{.State.Running}}' glm53-nvfp4 2>/dev/null || true)
started=$(docker inspect -f '{{.State.StartedAt}}' glm53-nvfp4 2>/dev/null || true)
if [ "$running" = "true" ] && [ -n "$started" ]; then
  started_epoch=$(date -d "$started" +%s 2>/dev/null || echo 0)
  now=$(date +%s)
  if [ "$started_epoch" -gt 0 ] && [ $((now - started_epoch)) -lt "$STARTUP_GRACE_SECONDS" ]; then
    exit 0
  fi
fi

failures=$((failures + 1))
now=$(date +%s)
printf '%s %s\n' "$failures" "$last_restart" > "$STATE_FILE"
log "health check failed ($failures/$FAILURES_BEFORE_RESTART), http=${health:-unreachable}"
[ "$failures" -lt "$FAILURES_BEFORE_RESTART" ] && exit 0

if [ $((now - last_restart)) -lt "$RESTART_COOLDOWN_SECONDS" ]; then
  log "restart suppressed by cooldown"
  exit 0
fi

log "coordinated restart beginning"
printf '0 %s\n' "$now" > "$STATE_FILE"

ssh -o BatchMode=yes -o ConnectTimeout=10 "$WORKER_SSH_TARGET" \
  "cd '$WORKER_DIR' && docker compose --env-file .env -f compose.worker.yaml down --remove-orphans" \
  >> "$LOG_FILE" 2>&1 || log "worker shutdown returned an error"
docker compose --env-file .env -f compose.head.yaml down --remove-orphans \
  >> "$LOG_FILE" 2>&1 || log "head shutdown returned an error"

sleep 5
if "$SCRIPT_DIR/start.sh" >> "$LOG_FILE" 2>&1; then
  log "coordinated restart completed"
else
  log "coordinated restart failed; inspect the preceding startup log"
  exit 1
fi
