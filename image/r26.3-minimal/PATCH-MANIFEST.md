# R26.3 minimal candidate

Base image: `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121`

Base digest: `sha256:c13006e527115a28cf8d680ce48c2fa5bfb9fa4165474fccb8c6a13898413325`

This candidate keeps the complete qualified R26.2 runtime and configuration, then adds three narrowly scoped source changes.

## Added changes

- **vLLM #769, adapted to the R26.2 source:** distribute the MoE startup-tuning routes across `tokens × top_k` experts instead of repeating only experts `0..top_k-1`. Live router output, model weights, arithmetic and serving routes are unchanged. The upstream PR targets a newer preparation API, so this recipe backports only the tuning-corpus correction. The new `glm53-r263-minimal-20260916` cache namespace guarantees a fresh tuning selection.
- **B12X #362:** bound manual MXFP8 weight-scale reads when persistent swizzle scheduling visits padded N tiles. This is the exact runtime hunk from the merged PR and directly covers the GLM TP2 KDA `N=12448` projection geometry.
- **vLLM #767:** preserve an engine-provided `finish_reason="length"` when a streamed or non-streamed automatic tool call is truncated. Complete tool calls still report `tool_calls`.

The `patches/` directory records the exact transformations. The `overlay/` directory contains the complete post-patch runtime files copied into the image.

## Retained R26.2 behavior

- vLLM #665, #701, #706 and #715 remain inherited.
- B12X #317 remains inherited.
- B12X #353/#354 and vLLM #727 remain excluded.
- CUDA 13.2, PyTorch, NCCL, FlashInfer, InstantTensor, Humming and compiled vLLM extensions are unchanged.
- The production compose configuration remains unchanged until this candidate passes startup, coherence, tool-response and matched performance tests.

## Qualification boundary

The upstream #769 performance evidence was collected on TP4 RTX PRO 6000 systems and is not treated as a GB10 TP2 speed claim. This image must be compared against R26.2 with the same model revision, cache geometry, MTP3, 4,096-token batch budget and benchmark client.
