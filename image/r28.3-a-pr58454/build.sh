#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-local/vllm:glm53-r28.2-b12x-tg3-arm64-sm121-cu134}"
IMAGE_TAG="${IMAGE_TAG:-local/vllm:glm53-r28.3-a-pr58454-arm64-sm121-cu134}"
BUILD_DATE="${BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

docker build \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "BUILD_DATE=${BUILD_DATE}" \
  --tag "${IMAGE_TAG}" \
  .

docker run --rm --entrypoint python "${IMAGE_TAG}" \
  /opt/glm53-r28.3-a/validate_r283a_runtime.py

docker image inspect "${IMAGE_TAG}" \
  --format 'built={{.Id}} size={{.Size}} created={{.Created}}'
