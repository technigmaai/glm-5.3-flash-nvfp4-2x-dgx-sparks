# R27.0-A fused MTP baseline

Base image: `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.4-combined-experimental-arm64-sm121`.

This baseline backports the applicable runtime portion of upstream vLLM PR
[#57443](https://github.com/vllm-project/vllm/pull/57443), commit
`bddb53640ee662f995e0f38611194c22adc9e85f`. The upstream patch SHA-256 is
`d69545f6d8d3f75313bd5f6b03f1ee8fb96eb2e9fc612b01ff2a0a1ba26898fa`.

The backport enables in-place sparse-indexer metadata updates between MTP draft
steps and propagates draft positions into attention metadata. This lets the
existing R26 fused multi-step driver build metadata once and update it between
steps when every active backend supports that operation.

R26 does not contain upstream main's `KpoolTailMetadataBuilder`, so that
upstream-only section and its tests are not copied. CUDA, PyTorch, NCCL,
compiled vLLM extensions, B12X, model weights and the serving recipe are
inherited unchanged from R26.4. The patch is Python-only and is applied to both
the source and installed vLLM package trees.

## Published image

- Tag: `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121`
- OCI index digest: `sha256:f1b6af40c1421204d8901a108a1ff712b58b085b8e1c8111ebc1be389fc9dbf3`
- Linux ARM64 manifest: `sha256:a62b9904bf47c34831aa746e170ee397e9f225699167a7b4116f3baf3ac9d9ae`

The corrected build completed target and speculator graph capture, returned an
HTTP 200 coherence response, and completed three matched llama-benchy sweeps
without CUDA, OOM, traceback or service errors. The initial backport used the
newer upstream `num_tokens` variable; R26 uses `num_tokens_padded`. The recipe
contains the corrected R26-compatible implementation.
