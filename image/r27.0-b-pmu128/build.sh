#!/usr/bin/env bash
set -euo pipefail

base_image="${BASE_IMAGE:-technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121}"
output_image="${OUTPUT_IMAGE:-local/vllm:glm53-r27.0-b-pmu128-arm64-sm121}"

docker build \
  --build-arg "BASE_IMAGE=${base_image}" \
  --tag "${output_image}" \
  .
