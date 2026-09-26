ARG BASE_IMAGE=local/vllm:glm53-r28.4-a-pr58454-pr58785-arm64-sm121-cu134
FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG PR58779_RUNTIME_PATCH_SHA256=5f53ac7b2f36abf1160a8aa8247c82f9c261e6ed976047e69fe80201df279588

COPY pr58779-runtime.patch /tmp/pr58779-runtime.patch
COPY validate_r285a_static.py /opt/glm53-r28.5-a/validate_r285a_static.py

RUN set -eux; \
    target=/opt/venv/lib/python3.12/site-packages/vllm/v1/executor/multiproc_executor.py; \
    test "$(sha256sum "$target" | cut -d' ' -f1)" = "17abd1dc68f1993b50b39350df017d22b59d0e1b6e998d4b9d0b2c1ef19e51b3"; \
    test "$(sha256sum /tmp/pr58779-runtime.patch | cut -d' ' -f1)" = "${PR58779_RUNTIME_PATCH_SHA256}"; \
    patch --batch --forward -p1 -d /opt/venv/lib/python3.12/site-packages < /tmp/pr58779-runtime.patch; \
    rm -f /tmp/pr58779-runtime.patch; \
    test "$(sha256sum "$target" | cut -d' ' -f1)" = "86a5415fb39632e53738175392571190512ab45c52b2004d340d0b4de23d5d6c"; \
    python -m py_compile "$target"; \
    python /opt/glm53-r28.4-a/validate_r284a_static.py; \
    python /opt/glm53-r28.5-a/validate_r285a_static.py

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.5-A bounded MTP draft-token RPC waits for DGX Spark" \
      org.opencontainers.image.description="R28.4-A plus merged upstream vLLM PR 58779; retains PRs 58454 and 58785, display-KV, and the native ARM64/SM121 CUDA 13.4 runtime" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      local-inference.base.image="local/vllm:glm53-r28.4-a-pr58454-pr58785-arm64-sm121-cu134" \
      local-inference.vllm.base-commit="22476af54c637cbb7c7d8193addd160da83a5ce3" \
      local-inference.vllm.candidate-head="41d28da376fe0b98546c5cc3533ccba5d44b3e71" \
      local-inference.vllm.candidate-tree="93473ceffede701f75866eca1f21da824cd12f5f" \
      local-inference.vllm.prs="58454,58785,58779" \
      local-inference.vllm.pr58779-head="fbb946710010ebb1e31c1bbf66cc338ecbc5e121" \
      local-inference.vllm.pr58779-merge="8a2364605c0b0581ea5d0d3720cb1125b47abc6f" \
      local-inference.vllm.pr58779-runtime-patch-sha256="5f53ac7b2f36abf1160a8aa8247c82f9c261e6ed976047e69fe80201df279588"
