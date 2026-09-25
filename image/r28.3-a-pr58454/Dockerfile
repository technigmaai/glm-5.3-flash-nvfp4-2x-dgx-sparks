ARG BASE_IMAGE=local/vllm:glm53-r28.2-b12x-tg3-arm64-sm121-cu134
FROM ${BASE_IMAGE}

ARG BUILD_DATE

COPY upstream-pr58454-nvidia.patch /opt/glm53-r28.3-a/upstream-pr58454-nvidia.patch
COPY apply_pr58454_r28.py /opt/glm53-r28.3-a/apply_pr58454_r28.py
COPY validate_r283a_runtime.py /opt/glm53-r28.3-a/validate_r283a_runtime.py

RUN set -eux; \
    test "$(sha256sum /opt/venv/lib/python3.12/site-packages/vllm/models/glm5next/common/attention.py | cut -d' ' -f1)" = "362bbf0e6c50cdfa446c6551b9b1ddff425e08f88e3d4140fd8db88f8a619e0c"; \
    test "$(sha256sum /opt/venv/lib/python3.12/site-packages/vllm/models/glm5next/nvidia/ops/kpool_compress.py | cut -d' ' -f1)" = "bd6f1d7b5e88a10d9756799a744d3e201421b6caabd32f7b3319d31904a91a0a"; \
    test "$(sha256sum /opt/glm53-r28.3-a/upstream-pr58454-nvidia.patch | cut -d' ' -f1)" = "e05098d0687bd9ea79f2e372643fa11054765e5ac58b5e13cce113978cd09a8b"; \
    python /opt/glm53-r28.3-a/apply_pr58454_r28.py; \
    cd /opt/venv/lib/python3.12/site-packages; \
    python -m py_compile \
      vllm/models/glm5next/common/attention.py \
      vllm/models/glm5next/nvidia/ops/kpool_compress.py; \
    python /opt/glm53-r28.3-a/validate_r283a_runtime.py

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.3-A k-pool ring fix for DGX Spark" \
      org.opencontainers.image.description="R28.2 plus upstream vLLM PR 58454 GLM speculative-decode k-pool tail-ring correctness fix" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      local-inference.base.image="local/vllm:glm53-r28.2-b12x-tg3-arm64-sm121-cu134" \
      local-inference.vllm.pr="58454" \
      local-inference.vllm.pr-url="https://github.com/vllm-project/vllm/pull/58454" \
      local-inference.vllm.pr-head="8408acad51384ff283acafa8ed486cb7417521b7" \
      local-inference.vllm.pr-patch-sha256="e05098d0687bd9ea79f2e372643fa11054765e5ac58b5e13cce113978cd09a8b"
