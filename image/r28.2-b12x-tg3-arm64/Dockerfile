ARG BASE_IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.1-display-kv-arm64-sm121-cu134
FROM ${BASE_IMAGE}

COPY wheelhouse/b12x-*.whl /tmp/b12x.whl
RUN python -m pip install --no-deps --force-reinstall /tmp/b12x.whl \
 && rm -f /tmp/b12x.whl \
 && python -c "import b12x; print(b12x.__file__)"

COPY build-manifest.json /opt/glm53-r28.2-tg/build-manifest.json

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.2 B12X TG3 for DGX Spark" \
      org.opencontainers.image.description="R28.1 display-KV runtime plus three surgical B12X decode/KDA performance backports" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      local-inference.base.image="technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.1-display-kv-arm64-sm121-cu134" \
      local-inference.b12x.base="f6d8b8eb94cdeb4e652652f925a494c6fc86f101" \
      local-inference.b12x.integration="7748a84" \
      local-inference.b12x.patches="b294e69d8eba2ea56d2aed7cc359c0df4bcaa57d,1dc77276e9d0ba297ad753eb3af04327759c1a3b,4f3028b19c1d8290dc72b6f483aba40de23eae5a"
