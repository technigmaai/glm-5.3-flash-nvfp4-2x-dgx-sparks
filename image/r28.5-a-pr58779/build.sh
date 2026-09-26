#!/usr/bin/env bash
set -euo pipefail

BASE_IMAGE="${BASE_IMAGE:-technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.4-a-pr58454-pr58785-arm64-sm121-cu134}"
IMAGE_TAG="${IMAGE_TAG:-local/vllm:glm53-r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134}"
BUILD_DATE="${BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

docker build \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "BUILD_DATE=${BUILD_DATE}" \
  --tag "${IMAGE_TAG}" \
  .

docker run --rm --entrypoint python "${IMAGE_TAG}" \
  /opt/glm53-r28.5-a/validate_r285a_static.py

docker image inspect "${IMAGE_TAG}" \
  --format 'built={{.Id}} size={{.Size}} created={{.Created}}'
