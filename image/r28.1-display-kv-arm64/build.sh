#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BASE_IMAGE="${BASE_IMAGE:-local/vllm:glm53-karmic-r28-arm64-sm121-cu134}"
IMAGE_TAG="${IMAGE_TAG:-local/vllm:glm53-r28.1-display-kv-arm64-sm121-cu134}"
BUILD_CONTEXT="$(mktemp -d "${TMPDIR:-/tmp}/glm53-r281-display-kv.XXXXXX")"
trap 'rm -rf "$BUILD_CONTEXT"' EXIT

cp "$SCRIPT_DIR/Dockerfile" "$BUILD_CONTEXT/Dockerfile"
mkdir -p "$BUILD_CONTEXT/payload"
cp \
  "$REPO_ROOT/files/display-kv-r28/glm53_display_kv.py" \
  "$REPO_ROOT/files/display-kv-r28/utils.py" \
  "$REPO_ROOT/files/display-kv-r28/libglm53_display_kv.so" \
  "$REPO_ROOT/files/display-kv-r28/display_kv_r28.c" \
  "$REPO_ROOT/files/display-kv-r28/ORIGIN.md" \
  "$REPO_ROOT/files/display-kv-r28/LICENSE.AGPL-3.0" \
  "$BUILD_CONTEXT/payload/"

docker build \
  --build-arg "BASE_IMAGE=$BASE_IMAGE" \
  --file "$BUILD_CONTEXT/Dockerfile" \
  --tag "$IMAGE_TAG" \
  "$BUILD_CONTEXT"

echo "Built $IMAGE_TAG from $BASE_IMAGE"
