# R28 Karmic Kraken ARM64 port

This recipe rebuilds the 2026-09-20 `karmic-kraken-beta` component set for the
DGX Spark ARM64 / SM121a platform. It uses NVIDIA PyTorch 26.08 (CUDA 13.4.1,
PyTorch 2.14) and compiles every native component locally.

Pinned sources:

- vLLM `22476af54c637cbb7c7d8193addd160da83a5ce3`
- B12X `f6d8b8eb94cdeb4e652652f925a494c6fc86f101`
- FlashInfer `2206a14e46387a56c093860a46bbbdd00596b75b`
- LMCache `688bee14e157b64623d93c07fc0d4db93470e12f`
- InstantTensor `95d4729b6d6a991bb8de61877147a9d9d9100b23`
- NCCL canonical `93fe05d9f9b6963ef841166a69cd0b30e4efe97b`
- blackwell-llm-docker recipe `23d674e8f658dae2db75399c48430693c196b258`

The upstream release compiles for x86_64 / SM120. The local adaptation changes
native targets to `12.1a`, `121a`, `12.1f`, `compute_121`, and `sm_121`, while
retaining the upstream CUDA, PyTorch, source revisions, dependency versions,
and C++11 ABI.

Runtime dependency notes:

- CUTLASS DSL remains pinned to upstream `4.6.2`.
- Quack is pinned to upstream `0.6.4`. Quack `0.6.5` imports the newer
  `cutlass.base_dsl.enums` API and fails during GLM JIT warmup with CUTLASS
  DSL 4.6.2.
- TokenSpeed `0.1.8`, Humming `0.1.12`, TileLang `0.1.12`, and Quack `0.6.4`
  are installed with `--no-deps` because their published dependency metadata
  conflicts with the source-locked Karmic runtime, while the pinned runtime
  combination is the one tested by the upstream recipe.

DGX Spark deployment compatibility notes:

- The current vLLM source removed the old InstantTensor
  `instanttensor_copy`/`instanttensor_distributed` loader options, so the
  deployment sets `INSTANTTENSOR_EXTRA_CONFIG=0`. The InstantTensor buffered
  loader and its buffer/concurrency environment settings remain enabled.
- The two-node 1,047,552-token deployment uses a fixed `11900M` KV cache per
  rank and `GPU_MEMORY_UTILIZATION=0.87`. The fixed allocation exposes
  1,055,149 cache tokens; GPU utilization only supplies the startup guard when
  fixed KV sizing is active.
- First cold startup completed B12X tuning, JIT warmup, and FULL plus PIECEWISE
  CUDA graph capture. `B12X_ROCENANTE` was selected for TP collectives and
  confirmed live for both all-gather and all-reduce.
