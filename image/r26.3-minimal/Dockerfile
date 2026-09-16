ARG BASE_IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121
FROM ${BASE_IMAGE}

COPY overlay/vllm/ /opt/venv/lib/python3.12/site-packages/vllm/
COPY overlay/vllm/ /opt/vllm/vllm/
COPY overlay/b12x/ /opt/venv/lib/python3.12/site-packages/b12x/

ENV VLLM_GLM53_MTP_DRAFT_HEAD=bf16 \
    LOCAL_INFERENCE_CACHE_FINGERPRINT=glm53-r263-minimal-20260916 \
    XDG_CACHE_HOME=/cache/jit/glm53-r263-minimal-20260916 \
    VLLM_CACHE_ROOT=/cache/jit/glm53-r263-minimal-20260916/vllm \
    VLLM_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/vllm \
    TRITON_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/triton \
    TORCHINDUCTOR_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/torchinductor \
    TORCH_EXTENSIONS_DIR=/cache/jit/glm53-r263-minimal-20260916/torch_extensions \
    FLASHINFER_WORKSPACE_BASE=/cache/jit/glm53-r263-minimal-20260916/flashinfer \
    VLLM_FLASHINFER_AUTOTUNE_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/flashinfer-autotune \
    TVM_FFI_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/tvm-ffi \
    TVM_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/tvm \
    TILELANG_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/tilelang \
    TILELANG_TMP_DIR=/cache/jit/glm53-r263-minimal-20260916/tilelang/tmp \
    CUTE_DSL_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/cute-dsl \
    B12X_CUTE_COMPILE_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/b12x-cute \
    B12X_COMPILE_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/b12x/compile \
    SPARKINFER_COMPILE_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/b12x/compile \
    DG_JIT_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/deep-gemm \
    MM_SPARSE_ATTN_AOT_CACHE=/cache/jit/glm53-r263-minimal-20260916/minfer/mm_sparse_attn \
    MINFER_FMHA_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/minfer/fmha_sm100 \
    CUDA_CACHE_PATH=/cache/jit/glm53-r263-minimal-20260916/cuda \
    CUPY_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/cupy \
    NUMBA_CACHE_DIR=/cache/jit/glm53-r263-minimal-20260916/numba

LABEL org.opencontainers.image.title="GLM-5.3 R26.3 minimal ARM64 experiment" \
      org.opencontainers.image.description="Qualified R26.2 plus vLLM 767/769 and B12X 362; fresh MoE tuning cache" \
      org.opencontainers.image.base.name="technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121" \
      local-inference.r263.vllm.base="7f53b30481b4110f293521d09f7af18f9e8f9d9e" \
      local-inference.r263.b12x.base="60dbc57098a3abff60cbf6048bcf8784c117feaf" \
      local-inference.r263.vllm.patches="767,769" \
      local-inference.r263.b12x.patches="362" \
      local-inference.r263.inherited.vllm.patches="665,701,706,715" \
      local-inference.r263.inherited.b12x.patches="317" \
      local-inference.r263.excluded.vllm.patches="727" \
      local-inference.r263.excluded.b12x.patches="353,354" \
      local-inference.r263.cache-fingerprint="glm53-r263-minimal-20260916"
