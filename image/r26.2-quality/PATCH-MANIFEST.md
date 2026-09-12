# R26.2 compatible quality BF16 image with R26.1 B12X

Base image: `local/vllm:glm53-r26.1-conservative-arm64-sm121`

Included vLLM runtime changes copied from the validated R26.2 overlay:

- vLLM #665: runtime-owned MTP-head guard. The image defaults to the BF16 path.
- vLLM #701: tool-call JSON recovery and stale KV-completion hardening.
- vLLM #706: preserve shared-expert output until consumer-stream reads finish.
- vLLM #715: keep incomplete sparse-attention pool tails in the active prefix.
Excluded B12X runtime changes:

- B12X #353: split-materialized NVFP4 prefill kernels.
- B12X #354: shared NVFP4 input quantization for uniform expert scales.

Also excluded:

- vLLM #727: it passes `immutable_input_scales` into B12X and therefore has a
  hard runtime dependency on B12X #354. The first isolation image proved this
  dependency by failing at model initialization with `TypeError:
  prepare_weights() got an unexpected keyword argument
  'immutable_input_scales'`.

The complete B12X package comes unchanged from the exact R26.1 base image. No
`overlay/b12x` directory is copied during the build. CUDA, PyTorch, NCCL,
FlashInfer, Humming, InstantTensor, compiled vLLM extensions, and the remainder
of the R26.1 filesystem are unchanged.

The normalized installed B12X package digest is
`ffb9c733e09db19c927f21e1b661d19b32a414ef359278fad86d42e75d45bae7`,
identical to R26.1. R26.1's B12X PR #317 remains present.

Benchmark recipe requirement: `GLM53_MTP_DRAFT_HEAD=bf16`; retain 4,096 maximum
batched tokens and all other settings from the three-arm comparison.
