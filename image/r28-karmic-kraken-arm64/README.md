# R28 Karmic Kraken ARM64 image

This directory reproduces the R28 runtime used by the two-node DGX Spark
deployment. It ports the pinned `karmic-kraken-beta` component assembly from
SM120/x86-64 to ARM64 and SM121a, using NVIDIA PyTorch 26.08, CUDA 13.4.1 and
PyTorch 2.14.

The published image is:

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28-karmic-kraken-arm64-sm121-cu134
```

## Source locks

| Component | Commit |
|---|---|
| vLLM | `22476af54c637cbb7c7d8193addd160da83a5ce3` |
| B12X | `f6d8b8eb94cdeb4e652652f925a494c6fc86f101` |
| FlashInfer | `2206a14e46387a56c093860a46bbbdd00596b75b` |
| LMCache | `688bee14e157b64623d93c07fc0d4db93470e12f` |
| InstantTensor | `95d4729b6d6a991bb8de61877147a9d9d9100b23` |
| NCCL canonical | `93fe05d9f9b6963ef841166a69cd0b30e4efe97b` |
| Upstream assembly recipe | `23d674e8f658dae2db75399c48430693c196b258` |

[`PATCH-MANIFEST.md`](PATCH-MANIFEST.md) explains the ARM64 changes and runtime
compatibility decisions. The two JSON manifests preserve the upstream assembly
and package provenance.

## Build

Run this on an ARM64 DGX Spark with Docker BuildKit and the NVIDIA container
runtime. The first build clones the pinned sources, initializes their
submodules, compiles all native wheels and creates the final image. Expect a
long build and substantial temporary disk use.

```bash
cd image/r28-karmic-kraken-arm64
./build.sh
```

Useful overrides:

```bash
BUILD_JOBS=8 NVCC_THREADS=1 ./build.sh
RESUME=1 ./build.sh
WORK_DIR=/path/to/large/scratch ./build.sh
FINAL_IMAGE=local/vllm:my-r28-build ./build.sh
```

`RESUME=1` reuses completed wheels after an interrupted build. Generated wheels
remain in the ignored `wheelhouse/` directory; binary wheels and source trees
are deliberately excluded from Git. The script validates CUDA, GPU capability
and all core packages after constructing the image.

The generated Dockerfiles are retained for review. They are derived from the
pinned upstream release recipes with the SM120 targets adapted to SM121a.
