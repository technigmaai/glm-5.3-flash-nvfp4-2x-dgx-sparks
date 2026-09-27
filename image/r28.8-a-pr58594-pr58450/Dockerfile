ARG BASE_IMAGE=local/vllm:glm53-r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134
FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG PR58594_RUNTIME_PATCH_SHA256=355d0f7d49571d134a4ab2204616911947222db9de94bd825623528c82e168e2
ARG PR58450_RUNTIME_PATCH_SHA256=526a109184f06f7a89021ffc7594deec337cb86fb3f14cf4acada47a5da7b3fe

COPY pr58594-runtime.patch /tmp/pr58594-runtime.patch
COPY pr58450-runtime.patch /tmp/pr58450-runtime.patch
COPY validate_r288a_static.py /opt/glm53-r28.8-a/validate_r288a_static.py

RUN set -eux; \
    root=/opt/venv/lib/python3.12/site-packages/vllm; \
    attention="$root/models/deepseek_v32/attention.py"; \
    sparse="$root/model_executor/layers/attention/sparse_mla_attention.py"; \
    flashattn="$root/v1/attention/backends/mla/flashattn_mla_sparse.py"; \
    flashinfer="$root/v1/attention/backends/mla/flashinfer_mla_sparse.py"; \
    test "$(sha256sum "$attention" | cut -d' ' -f1)" = "a3a3a784e798a3669e75527f724e9b2d549f0e4c025b2f4524026dc0244f0e39"; \
    test "$(sha256sum "$sparse" | cut -d' ' -f1)" = "7d9437fbb6ac959ebdc83599eb221fcc5c5c50bac2770ffbf15f6327de425084"; \
    test "$(sha256sum "$flashattn" | cut -d' ' -f1)" = "67dd3ead2e8b9d8cda0825ecc93779cb7d670628bc741c759a7d3cd5d474030f"; \
    test "$(sha256sum "$flashinfer" | cut -d' ' -f1)" = "2116d965b2067134d8afa5878d4d16c0149b061258f50c4106d993aa13b073cc"; \
    test "$(sha256sum /tmp/pr58594-runtime.patch | cut -d' ' -f1)" = "${PR58594_RUNTIME_PATCH_SHA256}"; \
    test "$(sha256sum /tmp/pr58450-runtime.patch | cut -d' ' -f1)" = "${PR58450_RUNTIME_PATCH_SHA256}"; \
    patch --batch --forward -p1 -d /opt/venv/lib/python3.12/site-packages < /tmp/pr58594-runtime.patch; \
    patch --batch --forward -p1 -d /opt/venv/lib/python3.12/site-packages < /tmp/pr58450-runtime.patch; \
    rm -f /tmp/pr58594-runtime.patch /tmp/pr58450-runtime.patch; \
    test "$(sha256sum "$attention" | cut -d' ' -f1)" = "35781670cc16f0f02c051a0ef9c2a8b9e1c49ea402b1acfe72a4b12f7a1a03b9"; \
    test "$(sha256sum "$sparse" | cut -d' ' -f1)" = "6a03271a6438083e3fe01dbfd3d2fffaeed6874796c8cbb8d668df1126a6f79c"; \
    test "$(sha256sum "$flashattn" | cut -d' ' -f1)" = "3267e8a298242d7131e54968ca160981d8a528c3d50662dfcb9216e6be44e2ad"; \
    test "$(sha256sum "$flashinfer" | cut -d' ' -f1)" = "c86f67e11f9c8d6e69c67bf64fb422ede51f0c2f7da05784117d8c60b5f6b165"; \
    python -m py_compile "$attention" "$sparse" "$flashattn" "$flashinfer"; \
    python /opt/glm53-r28.5-a/validate_r285a_static.py; \
    python /opt/glm53-r28.8-a/validate_r288a_static.py

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.8-A combined sparse-indexer and metadata optimizations for DGX Spark" \
      org.opencontainers.image.description="R28.5-A plus merged upstream vLLM PRs 58594 and 58450; retains PRs 58454, 58785, and 58779" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      local-inference.base.image="local/vllm:glm53-r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134" \
      local-inference.vllm.base-commit="22476af54c637cbb7c7d8193addd160da83a5ce3" \
      local-inference.vllm.prs="58454,58785,58779,58594,58450" \
      local-inference.vllm.pr58594-head="1c28cffabc751128cf26323ebee7b02ae5e8e651" \
      local-inference.vllm.pr58594-merge="3576691c426ea7565789da98b8440600f8ca488e" \
      local-inference.vllm.pr58450-head="41cc7e9cab96f4156886cf470954dfce195f6518" \
      local-inference.vllm.pr58450-merge="c88f4824fff42794d026348b86f9b78869fa273e" \
      local-inference.vllm.pr58594-runtime-patch-sha256="355d0f7d49571d134a4ab2204616911947222db9de94bd825623528c82e168e2" \
      local-inference.vllm.pr58450-runtime-patch-sha256="526a109184f06f7a89021ffc7594deec337cb86fb3f14cf4acada47a5da7b3fe"
