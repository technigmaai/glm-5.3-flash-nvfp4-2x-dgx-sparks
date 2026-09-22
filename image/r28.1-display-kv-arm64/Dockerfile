ARG BASE_IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28-karmic-kraken-arm64-sm121-cu134
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.1 display-KV for DGX Spark" \
      org.opencontainers.image.description="ARM64 R28 derivative using the headless GB10 display reservation as part of the vLLM KV allocation" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      org.opencontainers.image.licenses="Apache-2.0 AND AGPL-3.0-only"

COPY payload/glm53_display_kv.py /opt/venv/lib/python3.12/site-packages/glm53_display_kv.py
COPY payload/utils.py /opt/venv/lib/python3.12/site-packages/vllm/v1/worker/utils.py
COPY payload/libglm53_display_kv.so /opt/glm53-display-kv/libglm53_display_kv.so
COPY payload/display_kv_r28.c /opt/glm53-display-kv/source/display_kv_r28.c
COPY payload/ORIGIN.md /opt/glm53-display-kv/source/ORIGIN.md
COPY payload/LICENSE.AGPL-3.0 /opt/glm53-display-kv/source/LICENSE.AGPL-3.0

ENV GLM53_DISPLAY_KV_ENABLE=1 \
    GLM53_DISPLAY_KV_MIN_BYTES=4294967296

RUN test "$(sha256sum /opt/glm53-display-kv/libglm53_display_kv.so | cut -d' ' -f1)" = \
        "ad142abfcf25a9ea91ca03acc2729decefd2a5cddf8c7d0316a48d3d2d37cde5" && \
    test "$(sha256sum /opt/venv/lib/python3.12/site-packages/vllm/v1/worker/utils.py | cut -d' ' -f1)" = \
        "f8030342c9d02e95b737dd6f04dd5e4a3e2b409000460038e32ec4885b19bbf1"
