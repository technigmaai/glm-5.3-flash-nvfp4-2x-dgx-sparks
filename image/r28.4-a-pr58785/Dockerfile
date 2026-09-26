ARG BASE_IMAGE=local/vllm:glm53-r28.3-a-pr58454-arm64-sm121-cu134
FROM ${BASE_IMAGE}

ARG BUILD_DATE
ARG VLLM_WHEEL_SHA256=0254c4db71fa1186db64f2dcc9b64d6ba2a156f438589f0ca680ec65150348a9

COPY vllm-0.1.dev1+ga7b41c45a.d20260926.cu134-cp312-cp312-linux_aarch64.whl /tmp/vllm-0.1.dev1+ga7b41c45a.d20260926.cu134-cp312-cp312-linux_aarch64.whl
COPY display-kv-utils.py /tmp/display-kv-utils.py
COPY validate_r284a_static.py /opt/glm53-r28.4-a/validate_r284a_static.py

RUN set -eux; \
    test "$(sha256sum /tmp/vllm-0.1.dev1+ga7b41c45a.d20260926.cu134-cp312-cp312-linux_aarch64.whl | cut -d' ' -f1)" = "${VLLM_WHEEL_SHA256}"; \
    python -m pip install --no-deps --force-reinstall /tmp/vllm-0.1.dev1+ga7b41c45a.d20260926.cu134-cp312-cp312-linux_aarch64.whl; \
    install -m 0644 /tmp/display-kv-utils.py /opt/venv/lib/python3.12/site-packages/vllm/v1/worker/utils.py; \
    rm -f /tmp/vllm-0.1.dev1+ga7b41c45a.d20260926.cu134-cp312-cp312-linux_aarch64.whl /tmp/display-kv-utils.py; \
    python -m py_compile /opt/venv/lib/python3.12/site-packages/vllm/v1/worker/utils.py; \
    python /opt/glm53-r28.3-a/validate_r283a_runtime.py; \
    python /opt/glm53-r28.4-a/validate_r284a_static.py

LABEL org.opencontainers.image.title="GLM-5.3 Flash R28.4-A persistent-top-k correctness for DGX Spark" \
      org.opencontainers.image.description="R28.3-A plus upstream vLLM PR 58785 exact persistent_topk overflow fallback; retains PR 58454 and display-KV" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      local-inference.base.image="local/vllm:glm53-r28.3-a-pr58454-arm64-sm121-cu134" \
      local-inference.vllm.commit="22476af54c637cbb7c7d8193addd160da83a5ce3" \
      local-inference.vllm.candidate-head="a7b41c45ad1c87707eed773dcd0c5b386d36693f" \
      local-inference.vllm.candidate-tree="8ea613beaa5d2cddc121ec4ae298fcc2a3f4baa0" \
      local-inference.vllm.wheel-sha256="0254c4db71fa1186db64f2dcc9b64d6ba2a156f438589f0ca680ec65150348a9" \
      local-inference.vllm.prs="58454,58785" \
      local-inference.vllm.pr58454-head="8408acad51384ff283acafa8ed486cb7417521b7" \
      local-inference.vllm.pr58454-patch-sha256="e05098d0687bd9ea79f2e372643fa11054765e5ac58b5e13cce113978cd09a8b" \
      local-inference.vllm.pr58785-head="8e9d1df44cfba3db11166d403abb1a1786958115" \
      local-inference.vllm.pr58785-patch-sha256="886290126efd4b4f01989c57860f6d4502f54b4946068001f9bad62c358d1863"
