#!/bin/bash
# Start GLM-5.3-Flash NVFP4 cluster.
#
# ORDER MATTERS: start worker FIRST, wait ~15s, then head.
#
# Usage:
#   ./start.sh               # sync configs to worker, start both
#   ./start.sh head          # HEAD node only (rank 0)
#   ./start.sh worker        # WORKER node only (rank 1)
#   ./start.sh --no-sync     # local only, skip remote sync

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Require .env
[ -f .env ] || { echo "[glm53] Missing .env — copy .env.example to .env and edit"; exit 1; }
set -a; source .env; set +a

# Parse mode
MODE="${1:-both}"
DO_SYNC=true
case "$MODE" in
  head)
    NODE="head"
    ;;
  worker)
    NODE="worker"
    ;;
  --no-sync)
    MODE="both"
    DO_SYNC=false
    ;;
  both)
    ;;
  *)
    echo "Usage: $0 [head|worker|--no-sync]"
    echo ""
    echo "  head       — HEAD node only (rank 0) — start AFTER worker"
    echo "  worker     — WORKER node only (rank 1) — start FIRST"
    echo "  --no-sync  — start both nodes locally, skip remote sync"
    echo "  (default)  — sync configs to worker, then start both"
    exit 1
    ;;
esac

# An explicit start arms the watchdog again. The marker is created by
# stop.sh so planned maintenance is not mistaken for a service failure.
if [ "$MODE" = "both" ] || [ "$MODE" = "head" ]; then
  rm -f "$SCRIPT_DIR/.watchdog-disabled"
fi

# --- Sync configs to worker ---
sync_worker() {
  "$SCRIPT_DIR/sync-repo.sh"
}

# --- Start worker ---
start_worker() {
  echo "[glm53] Starting WORKER (rank 1)..."
  ssh "$WORKER_SSH_TARGET" "cd $WORKER_DIR && docker compose --env-file .env -f compose.worker.yaml up -d"
  echo "[glm53] Worker started."
}

# --- Start head ---
start_head() {
  echo "[glm53] Starting HEAD (rank 0)..."
  docker compose --env-file .env -f compose.head.yaml up -d
  echo "[glm53] Head started."
  echo ""
  echo "  Follow logs: docker logs -f glm53-nvfp4"
  echo "  Health: curl -s -o /dev/null -w '%{http_code}' http://localhost:${PORT:-8000}/health"
}


# --- Log capture: pipe head container output to a log file, tail on ready ---
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE=""

start_log_tail() {
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/glm53-$(date +%Y%m%d-%H%M%S).head.log"
  nohup docker logs -f glm53-nvfp4 2>&1 | tee "$LOG_FILE" >/dev/null 2>&1 &
  echo $! > "$LOG_DIR/tee.pid"
  echo "[glm53] Logging head output to: $LOG_FILE"
  echo "        (follow anytime: tail -f $LOG_FILE)"
}

wait_ready() {
  # returns 0=ready, 1=timeout, 2=container died
  local max_wait=1800 waited=0
  while [ "$waited" -lt "$max_wait" ]; do
    if grep -q "Application startup complete" "$LOG_FILE" 2>/dev/null; then return 0; fi
    if ! docker ps --format '{{.Names}}' | grep -q '^glm53-nvfp4$'; then return 2; fi
    sleep 10; waited=$((waited+10))
    echo "[glm53] ... booting ($((waited/60))m $((waited%60))s)"
  done
  return 1
}

report_boot() {
  local rc=$1
  echo ""
  if [ "$rc" -eq 0 ]; then
    echo "[glm53] === STARTUP COMPLETE ==="
    grep -E 'Model loading took|InstantTensor|B12X|GPU KV cache size|Application startup complete' "$LOG_FILE" | tail -10
    echo ""
    echo "[glm53] === last 30 lines of $LOG_FILE ==="
    tail -n 30 "$LOG_FILE"
  elif [ "$rc" -eq 2 ]; then
    echo "[glm53] !!! head container died during boot — last 40 lines:"
    tail -n 40 "$LOG_FILE"
  else
    echo "[glm53] !!! boot timed out (30 min) — last 40 lines:"
    tail -n 40 "$LOG_FILE"
  fi
}


# --- Execute ---
case "$MODE" in
  both)
    $DO_SYNC && sync_worker
    echo ""
    echo "[glm53] === Launch Sequence ==="
    echo "[glm53] Step 1/2: Starting WORKER..."
    start_worker
    echo "[glm53] Waiting 15s for worker to initialize..."
    sleep 15
    echo "[glm53] Step 2/2: Starting HEAD..."
    start_head
    echo ""
    start_log_tail
    wait_ready; rc=$?
    report_boot "$rc"
    echo "  Expected boot: about 6-7 min with InstantTensor on a warm model cache"
    echo ""
    echo "  Boot markers (check in order):"
    echo "    1. B12X attention / linear / MoE kernels selected"
    echo "    2. InstantTensor finishes loading the checkpoint (~90 s observed)"
    echo "    3. GPU KV cache size: N tokens"
    echo "    4. Application startup complete"
    echo ""
    echo "  To stop both:"
    echo "    ssh $WORKER_SSH_TARGET 'cd $WORKER_DIR && ./stop.sh'"
    echo "    ./stop.sh"
    ;;
  head)
    start_head
    start_log_tail
    wait_ready; rc=$?
    report_boot "$rc"
    ;;
  worker)
    $DO_SYNC && sync_worker
    start_worker
    ;;
esac
