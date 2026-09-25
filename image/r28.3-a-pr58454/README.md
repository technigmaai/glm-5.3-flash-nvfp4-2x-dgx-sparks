# R28.3-A GLM k-pool tail-ring correctness overlay

This is a minimal Python/Triton-source layer over the qualified R28.2 image.
It applies the NVIDIA runtime portion of upstream vLLM PR
[#58454](https://github.com/vllm-project/vllm/pull/58454), pinned at approved
PR head `8408acad51384ff283acafa8ed486cb7417521b7`.

The fix enlarges GLM-5.3-Flash's speculative-decode k-pool tail ring so drafts
behind a rejected pool-completing draft cannot overwrite committed keys. For
the production MTP3 configuration, the ring grows from four to eight slots.

The overlay changes only:

- `vllm/models/glm5next/common/attention.py`
- `vllm/models/glm5next/nvidia/ops/kpool_compress.py`

CUDA, PyTorch, the vLLM native extension, B12X, FlashInfer, InstantTensor,
LMCache, NCCL, display-reserved KV integration, model weights and serving
parameters remain inherited from R28.2.

The build fails unless the two R28.2 input files and the extracted upstream
patch match their recorded SHA-256 hashes. An exact-anchor patcher adapts the
two upstream seed-kernel hunks to R28's earlier contiguous tail-cache layout;
it refuses to continue if any expected source anchor differs. The recipe then
parses and validates the patched runtime files.

Build on gx10:

```bash
./build.sh
```

Default output image:

```text
local/vllm:glm53-r28.3-a-pr58454-arm64-sm121-cu134
```

## Published production image

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.3-a-pr58454-arm64-sm121-cu134
```

Docker Hub digest: `sha256:f39eef91d461b893f3339151102f2b716ffcbf36dbce2c7c329a3ffe949c5473`. The `latest` alias points to the same digest.
The exact published image identity and labels are stored under `manifests/`.
