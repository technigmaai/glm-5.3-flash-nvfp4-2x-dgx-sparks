#!/bin/bash
# One-way deployment synchronization: HEAD (GX10) -> WORKER (GX10-2).
# The worker is intentionally not a second source of truth.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

[ -f .env ] || { echo "[glm53] Missing .env"; exit 1; }
set -a; source .env; set +a

: "${WORKER_SSH_TARGET:?Set WORKER_SSH_TARGET in .env}"
: "${WORKER_DIR:?Set WORKER_DIR in .env}"

echo "[glm53] Syncing repository HEAD -> WORKER..."
ssh "$WORKER_SSH_TARGET" "mkdir -p '$WORKER_DIR'"

# No --delete: preserve unexpected worker-local files. Runtime logs and Git
# metadata are node-local and must never be copied.
rsync -az --checksum --itemize-changes \
  --exclude='.git/' \
  --exclude='logs/' \
  --exclude='tmp/' \
  --exclude='*.log' \
  --exclude='.DS_Store' \
  "$SCRIPT_DIR/" \
  "$WORKER_SSH_TARGET:$WORKER_DIR/"

ssh "$WORKER_SSH_TARGET" \
  "find '$WORKER_DIR' -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +"

echo "[glm53] Repository sync complete."
