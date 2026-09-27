ARG BASE_IMAGE=local/vllm:glm53-r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134
FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG PR58594_RUNTIME_PATCH_SHA256=355d0f7d49571d134a4ab2204616911947222db9de94bd825623528c82e168e2

COPY pr58594-runtime.patch /tmp/pr58594-runtime.patch
COPY validate_r286a_static.py /opt/glm53-r28.6-a/validate_r286a_static.py

RUN set -eux; \
    target=/opt/venv/lib/python3.12/site-packages/vllm/models/deepseek_v32/attention.py; \
    test "$(sha256sum "$target" | cut -d' ' -f1)" = "a3a3a784e798a3669e75527f724e9b2d549f0e4c025b2f4524026dc0244f0e39"; \
    test "$(sha256sum /tmp/pr58594-runtime.patch | cut -d' ' -f1)" = "${PR58594_RUNTIME_PATCH_SHA256}"; \
    patch --batch --forward -p1 -d /opt/venv/lib/python3.12/site-packages < /tmp/pr58594-runtime.patch; \
    rm -f /tmp/pr58594-runtime.patch; \
    test "$(sha256sum "$target" | cut -d' ' -f1)" = "35781670cc16f0f02c051a0ef9c2a8b9e1c49ea402b1acfe72a4b12f7a1a03b9"; \
    python -m py_compile "$target"; \
    python /opt/glm53-r28.5-a/validate_r285a_static.py; \
    python /opt/glm53-r28.6-a/validate_r286a_static.py

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.6-A sparse-indexer top-k backend fix for DGX Spark" \
      org.opencontainers.image.description="R28.5-A plus merged upstream vLLM PR 58594 semantic backport; retains PRs 58454, 58785, and 58779" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      local-inference.base.image="local/vllm:glm53-r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134" \
      local-inference.vllm.base-commit="22476af54c637cbb7c7d8193addd160da83a5ce3" \
      local-inference.vllm.prs="58454,58785,58779,58594" \
      local-inference.vllm.pr58594-head="1c28cffabc751128cf26323ebee7b02ae5e8e651" \
      local-inference.vllm.pr58594-merge="3576691c426ea7565789da98b8440600f8ca488e" \
      local-inference.vllm.pr58594-runtime-patch-sha256="355d0f7d49571d134a4ab2204616911947222db9de94bd825623528c82e168e2" \
      local-inference.vllm.pr58594-backport="DeepseekV32Indexer.run_indexer compatibility call site"
