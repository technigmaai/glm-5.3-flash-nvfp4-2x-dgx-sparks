ARG BASE_IMAGE=local/vllm:glm53-r26.1-conservative-arm64-sm121
FROM ${BASE_IMAGE}

COPY overlay/vllm/ /opt/venv/lib/python3.12/site-packages/vllm/
COPY overlay/vllm/ /opt/vllm/vllm/

ENV VLLM_GLM53_MTP_DRAFT_HEAD=bf16 \
    LOCAL_INFERENCE_CACHE_FINGERPRINT=vllm-r262-quality-bf16-r261-b12x-compatible-20260911 \
    XDG_CACHE_HOME=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911 \
    VLLM_CACHE_ROOT=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/vllm \
    VLLM_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/vllm \
    TRITON_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/triton \
    TORCHINDUCTOR_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/torchinductor \
    TORCH_EXTENSIONS_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/torch_extensions \
    FLASHINFER_WORKSPACE_BASE=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/flashinfer \
    VLLM_FLASHINFER_AUTOTUNE_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/flashinfer-autotune \
    TVM_FFI_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/tvm-ffi \
    TVM_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/tvm \
    TILELANG_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/tilelang \
    TILELANG_TMP_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/tilelang/tmp \
    CUTE_DSL_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/cute-dsl \
    B12X_CUTE_COMPILE_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/b12x-cute \
    B12X_COMPILE_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/b12x/compile \
    SPARKINFER_COMPILE_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/b12x/compile \
    DG_JIT_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/deep-gemm \
    MM_SPARSE_ATTN_AOT_CACHE=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/minfer/mm_sparse_attn \
    MINFER_FMHA_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/minfer/fmha_sm100 \
    CUDA_CACHE_PATH=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/cuda \
    CUPY_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/cupy \
    NUMBA_CACHE_DIR=/cache/jit/vllm-r262-quality-bf16-r261-b12x-compatible-20260911/numba

LABEL org.opencontainers.image.title="GLM-5.3 R26.2 compatible quality BF16 ARM64 experiment" \
      org.opencontainers.image.description="R26.1 plus compatible R26.2 vLLM correctness patches; vLLM 727 and B12X 353/354 excluded" \
      org.opencontainers.image.base.name="local/vllm:glm53-r26.1-conservative-arm64-sm121" \
      local-inference.r262.vllm.base="a671305245fc4a8ddcf6cb41d85e70626e61b8b6" \
      local-inference.r262.b12x.base="60dbc57098a3abff60cbf6048bcf8784c117feaf" \
      local-inference.r262.b12x.r261-pr317="e8ad299b174f16e2e8fb5879bea272f4efbb53f2" \
      local-inference.r262.b12x.package-sha256="ffb9c733e09db19c927f21e1b661d19b32a414ef359278fad86d42e75d45bae7" \
      local-inference.r262.vllm.patches="665,701,706,715" \
      local-inference.r262.vllm.excluded="727" \
      local-inference.r262.b12x.patches="none" \
      local-inference.r262.b12x.excluded="353,354"
