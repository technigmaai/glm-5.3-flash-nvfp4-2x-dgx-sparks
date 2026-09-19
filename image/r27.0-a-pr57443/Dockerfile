ARG BASE_IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.4-combined-experimental-arm64-sm121
FROM ${BASE_IMAGE}

COPY apply_pr57443_backport.py /opt/glm53-r270a/apply_pr57443_backport.py
COPY validate_r270a_runtime.py /opt/glm53-r270a/validate_r270a_runtime.py

RUN set -eux; \
    VLLM_PACKAGE_ROOT=/opt/vllm/vllm \
      python3 /opt/glm53-r270a/apply_pr57443_backport.py; \
    VLLM_PACKAGE_ROOT=/opt/venv/lib/python3.12/site-packages/vllm \
      python3 /opt/glm53-r270a/apply_pr57443_backport.py; \
    python3 -m py_compile \
      /opt/vllm/vllm/v1/attention/backends/mla/indexer.py \
      /opt/vllm/vllm/v1/attention/backends/mla/flashattn_mla_sparse.py \
      /opt/vllm/vllm/v1/worker/gpu/spec_decode/speculator.py \
      /opt/venv/lib/python3.12/site-packages/vllm/v1/attention/backends/mla/indexer.py \
      /opt/venv/lib/python3.12/site-packages/vllm/v1/attention/backends/mla/flashattn_mla_sparse.py \
      /opt/venv/lib/python3.12/site-packages/vllm/v1/worker/gpu/spec_decode/speculator.py; \
    python3 /opt/glm53-r270a/validate_r270a_runtime.py

ENV LOCAL_INFERENCE_CACHE_FINGERPRINT=glm53-r270a-pr57443-20260919 \
    XDG_CACHE_HOME=/cache/jit/glm53-r270a-pr57443-20260919 \
    VLLM_CACHE_ROOT=/cache/jit/glm53-r270a-pr57443-20260919/vllm \
    VLLM_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/vllm \
    TRITON_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/triton \
    TORCHINDUCTOR_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/torchinductor \
    TORCH_EXTENSIONS_DIR=/cache/jit/glm53-r270a-pr57443-20260919/torch_extensions \
    FLASHINFER_WORKSPACE_BASE=/cache/jit/glm53-r270a-pr57443-20260919/flashinfer \
    VLLM_FLASHINFER_AUTOTUNE_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/flashinfer-autotune \
    TVM_FFI_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/tvm-ffi \
    TVM_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/tvm \
    TILELANG_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/tilelang \
    CUTE_DSL_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/cute-dsl \
    B12X_CUTE_COMPILE_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/b12x-cute \
    B12X_COMPILE_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/b12x/compile \
    SPARKINFER_COMPILE_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/b12x/compile \
    DG_JIT_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/deep-gemm \
    CUDA_CACHE_PATH=/cache/jit/glm53-r270a-pr57443-20260919/cuda \
    CUPY_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/cupy \
    NUMBA_CACHE_DIR=/cache/jit/glm53-r270a-pr57443-20260919/numba

LABEL org.opencontainers.image.title="GLM-5.3 R27.0-A fused MTP ARM64 experiment" \
      org.opencontainers.image.description="R26.4 production plus the applicable runtime backport of upstream vLLM PR 57443" \
      org.opencontainers.image.base.name="technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.4-combined-experimental-arm64-sm121" \
      local-inference.r270a.vllm.pr="57443" \
      local-inference.r270a.vllm.pr-commit="bddb53640ee662f995e0f38611194c22adc9e85f" \
      local-inference.r270a.vllm.pr-patch-sha256="d69545f6d8d3f75313bd5f6b03f1ee8fb96eb2e9fc612b01ff2a0a1ba26898fa" \
      local-inference.r270a.cache-fingerprint="glm53-r270a-pr57443-20260919"

