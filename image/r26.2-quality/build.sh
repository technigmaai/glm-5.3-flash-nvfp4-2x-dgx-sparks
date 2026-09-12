#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

base_image="${BASE_IMAGE:-local/vllm:glm53-r26.1-conservative-arm64-sm121}"
output_image="${OUTPUT_IMAGE:-technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121}"

sha256sum -c OVERLAY-VLLM.sha256
docker build \
  --build-arg "BASE_IMAGE=${base_image}" \
  --tag "${output_image}" \
  .

echo "Built ${output_image}"
