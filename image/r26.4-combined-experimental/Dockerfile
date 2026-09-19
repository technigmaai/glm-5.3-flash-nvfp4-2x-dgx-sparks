ARG BASE_IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.3-minimal-arm64-sm121
FROM ${BASE_IMAGE}

COPY patch_tool_choice_none.py /opt/glm53-r264/patch_tool_choice_none.py

RUN GLM53_TOOL_CHOICE_NONE_PY=/opt/venv/lib/python3.12/site-packages/vllm/parser/glm47_moe.py \
      python3 /opt/glm53-r264/patch_tool_choice_none.py \
    && GLM53_TOOL_CHOICE_NONE_PY=/opt/vllm/vllm/parser/glm47_moe.py \
      python3 /opt/glm53-r264/patch_tool_choice_none.py \
    && python3 -m py_compile \
      /opt/venv/lib/python3.12/site-packages/vllm/parser/glm47_moe.py \
      /opt/vllm/vllm/parser/glm47_moe.py \
    && grep -Fq 'grid=(self.num_tokens, self.num_topk, 1)' \
      /opt/venv/lib/python3.12/site-packages/b12x/moe/_shared/kernels/m8_route_pack.py

ENV B12X_DYNAMIC_SPLIT_ROUTE_COMPUTE=1 \
    B12X_DYNAMIC_SPLIT_FAST_PREPARE=1 \
    B12X_DYNAMIC_SPLIT_LOW_SMEM=1 \
    B12X_DYNAMIC_SKIP_SPLIT_BARRIER_RESET=1 \
    LOCAL_INFERENCE_CACHE_FINGERPRINT=glm53-r264-combined-20260919 \
    XDG_CACHE_HOME=/cache/jit/glm53-r264-combined-20260919 \
    VLLM_CACHE_ROOT=/cache/jit/glm53-r264-combined-20260919/vllm \
    VLLM_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/vllm \
    TRITON_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/triton \
    TORCHINDUCTOR_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/torchinductor \
    TORCH_EXTENSIONS_DIR=/cache/jit/glm53-r264-combined-20260919/torch_extensions \
    FLASHINFER_WORKSPACE_BASE=/cache/jit/glm53-r264-combined-20260919/flashinfer \
    VLLM_FLASHINFER_AUTOTUNE_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/flashinfer-autotune \
    TVM_FFI_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/tvm-ffi \
    TVM_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/tvm \
    TILELANG_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/tilelang \
    CUTE_DSL_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/cute-dsl \
    B12X_CUTE_COMPILE_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/b12x-cute \
    B12X_COMPILE_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/b12x/compile \
    SPARKINFER_COMPILE_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/b12x/compile \
    DG_JIT_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/deep-gemm \
    CUDA_CACHE_PATH=/cache/jit/glm53-r264-combined-20260919/cuda \
    CUPY_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/cupy \
    NUMBA_CACHE_DIR=/cache/jit/glm53-r264-combined-20260919/numba

LABEL org.opencontainers.image.title="GLM-5.3 R26.4 combined ARM64 experiment" \
      org.opencontainers.image.description="R26.3 plus MiaAI 215 and enabled pre-existing B12X 280 M8 split route/compute path" \
      org.opencontainers.image.base.name="technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.3-minimal-arm64-sm121" \
      local-inference.r264.miaai.patch="215" \
      local-inference.r264.b12x.patch="280-existing-kernel-enabled" \
      local-inference.r264.b12x.excluded="353,354" \
      local-inference.r264.cache-fingerprint="glm53-r264-combined-20260919"
