# R28.2 B12X TG3 overlay

This recipe rebuilds only B12X and installs it over the published R28.1
display-KV image. CUDA, PyTorch, vLLM, FlashInfer, InstantTensor, LMCache, NCCL
and the display-reserved KV integration remain byte-for-byte inherited from
R28.1.

The B12X source starts at
`f6d8b8eb94cdeb4e652652f925a494c6fc86f101` and applies these upstream commits
in order:

1. `b294e69d8eba2ea56d2aed7cc359c0df4bcaa57d` — NVFP4 decode register/grid tuning.
2. `1dc77276e9d0ba297ad753eb3af04327759c1a3b` — Spark decode routing, indexer scheduling and preparation.
3. `4f3028b19c1d8290dc72b6f483aba40de23eae5a` — KDA sliced-state reuse.

Build on an ARM64 DGX Spark with Docker BuildKit and enough free unified memory:

```bash
./build.sh
```

The generated B12X wheel is kept under `wheelhouse/` locally and excluded from
Git. Override `WORK_DIR`, `BUILDER_IMAGE`, `BASE_IMAGE` or `IMAGE_TAG` as needed.
The qualified image is published as
`technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.2-b12x-tg3-arm64-sm121-cu134`.
