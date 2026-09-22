# R28.1 display-reserved KV derivative

This is a small, auditable layer on top of the qualified R28 ARM64 image. It
replaces only vLLM's shared KV-buffer allocation and adds the GB10 DRM/CUDA
allocator. The model runtime, CUDA 13.4.1, PyTorch 2.14, vLLM, B12X and all
inference kernels remain byte-for-byte inherited from R28.

Build it on an ARM64 DGX Spark that already has the R28 base image:

```bash
./build.sh
```

The image requires the host setup and Compose overlay documented in
[`../../docs/display-kv-r28.1.md`](../../docs/display-kv-r28.1.md). It fails
closed if the display reservation cannot be mapped; it does not silently fall
back to ordinary unified memory when enabled.

The allocator source is derived from coolbho3k's DeepSeek V4.1 Flash recipe at
the pinned commit recorded in `files/display-kv-r28/ORIGIN.md` and remains
AGPL-3.0-only. Corresponding source and license files are copied into the image
under `/opt/glm53-display-kv/source/`.
