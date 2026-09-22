# GLM-5.3-Flash NVFP4 on 2× DGX Spark

This repository provides a reproducible two-node deployment for
[`local-inference-lab/GLM-5.3-Flash-NVFP4`](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4)
on two NVIDIA DGX Spark systems. It runs one GB10 GPU per node with tensor
parallelism 2 over RoCE and exposes an OpenAI-compatible vLLM API on port 8000.

The current production profile is the R28 Karmic Kraken ARM64/SM121a build. It
uses CUDA 13.4.1, PyTorch 2.14, a pinned vLLM/B12X stack, one-million-token
context, MTP3 speculative decoding, fixed FP8 KV cache and image input. Client
requests control temperature, `top_p` and reasoning effort.

## Production profile

| Setting | Value |
|---|---|
| Image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28-karmic-kraken-arm64-sm121-cu134` |
| Platform | Linux ARM64, GB10 / SM121a |
| CUDA / PyTorch | 13.4.1 / 2.14.0 NVIDIA 26.08 build |
| Model | `local-inference-lab/GLM-5.3-Flash-NVFP4` |
| Model revision | `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49` |
| Parallelism | 2 nodes × 1 GPU, TP2, DCP1 |
| Maximum context | 1,047,552 tokens |
| Measured KV capacity | 1,055,149 tokens |
| Fixed KV cache | 11,900 MiB per rank, FP8 |
| Maximum sequences / batched tokens | 4 / 4,096 |
| Physical split target page | 1,024 tokens |
| Prefix cache | Enabled, 128-token match unit |
| Speculation | MTP3, greedy draft and standard rejection sampling |
| MTP experts / attention | Marlin MXFP8 / B12X |
| MTP vocabulary head | NVFP4 draft head; target verifier remains BF16 |
| Target attention, linear, MoE / KDA | B12X / B12X |
| Scheduling | Async scheduling and chunked prefill enabled |
| Collectives | RoCEnante up to 2 MiB, PyNCCL fallback |
| CUDA graphs | Full and piecewise capture |
| Loader | InstantTensor buffered loader |
| Multimodal limits | Up to 32 images, video disabled, 2 GiB processor cache |
| Tool / reasoning parsers | `glm47` / `glm45` |
| Chat template | [`files/chat_template.jinja`](files/chat_template.jinja) |

`KV_CACHE_MEMORY_BYTES` fixes the cache allocation, so
`GPU_MEMORY_UTILIZATION` acts as a startup guard rather than determining KV
capacity. Startup must report capacity above `MAX_MODEL_LEN`.

The image profile was also verified with a real image request. Video is disabled
to avoid reserving memory for an unused modality; the 32-image limit is an
admission limit per request, not a preallocation of 32 decoded images.

## R28 source stack

R28 rebuilds the pinned local-inference-lab Karmic Kraken assembly natively for
ARM64/SM121a rather than installing x86-64 release wheels.

| Component | Pinned revision |
|---|---|
| vLLM | `22476af54c637cbb7c7d8193addd160da83a5ce3` |
| B12X | `f6d8b8eb94cdeb4e652652f925a494c6fc86f101` |
| FlashInfer | `2206a14e46387a56c093860a46bbbdd00596b75b` |
| LMCache | `688bee14e157b64623d93c07fc0d4db93470e12f` |
| InstantTensor | `95d4729b6d6a991bb8de61877147a9d9d9100b23` |
| NCCL canonical | `93fe05d9f9b6963ef841166a69cd0b30e4efe97b` |
| blackwell-llm-docker recipe | `23d674e8f658dae2db75399c48430693c196b258` |

The complete build recipe, source manifests and ARM64 adaptation notes are in
[`image/r28-karmic-kraken-arm64/`](image/r28-karmic-kraken-arm64). Generated
wheels, build trees and caches are intentionally ignored.

## Deploy

Install Docker with the NVIDIA container runtime on both DGX Spark nodes.
Configure passwordless SSH from the head to the worker, and make the pinned
model revision available in the same Hugging Face cache path on both systems.

```bash
git clone https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks.git
cd glm-5.3-flash-nvfp4-2x-dgx-sparks
docker pull technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28-karmic-kraken-arm64-sm121-cu134
cp .env.example .env
# Edit the cache path, RoCE interfaces, IP addresses, SSH target and worker path.
./start.sh
```

`start.sh` syncs the deployment files to the worker, starts rank 1, then starts
rank 0. It excludes `.git`, logs, `tmp/`, local credentials and model data.

```bash
./status.sh
./tail-log.sh
./stop.sh
```

The health endpoint is `http://HEAD_IP:8000/health`; the API base URL is
`http://HEAD_IP:8000/v1`. Set `CHAT_TEMPLATE=` in `.env` to use the model's
bundled template. Temperature, `top_p` and reasoning effort are intentionally
not set by the server recipe.

Optional scheduler fairness controls are documented in `.env.example` and are
disabled in the qualified profile. This preserves the benchmarked behavior.

## Rebuild the image

The first build compiles all pinned native components and can take several
hours. Use a filesystem with ample temporary storage.

```bash
cd image/r28-karmic-kraken-arm64
./build.sh
```

See the [R28 recipe README](image/r28-karmic-kraken-arm64/README.md) for resume,
scratch-directory and output-tag options.

## Qualified performance

The strongest warm R28 run used `llama-benchy 0.4.0` from a separate RTX host,
with 2,048 prompt tokens, 128 generated tokens and no request errors. The first
sample after startup can include JIT and cache warm-up, so production
comparisons should use a warm repeat.

| Depth | Concurrency | PP t/s | TG t/s | TTFT ms |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,810 | 30.0 | 3,484 |
| 4,096 | 2 | 1,814 | 40.1 | 6,122 |
| 4,096 | 4 | 1,884 | 37.5 | 10,667 |
| 8,192 | 1 | 1,871 | 33.1 | 5,563 |
| 8,192 | 2 | 1,901 | 41.7 | 10,111 |
| 8,192 | 4 | 1,922 | 28.6 | 16,530 |
| 16,384 | 1 | 1,883 | 34.6 | 9,881 |
| 16,384 | 2 | 1,897 | 25.8 | 17,082 |
| 16,384 | 4 | 1,915 | 16.2 | 27,399 |

A clean reboot repeat matched the strong run closely after excluding its first
cold d4096/c1 sample. Detailed R28 validation and earlier R26/R27 comparisons
are preserved in [`docs/benchmark.md`](docs/benchmark.md).

## Repository scope

Model weights, Hugging Face caches, `.env`, credentials, logs, raw test output,
container archives and the cluster `tmp/` research archive are excluded. The
repository contains the reviewed deployment, public example configuration,
source-locked image recipes and summarized evidence.

The copied and derived upstream files retain their original licenses. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Credits

- Kudos to [`0rand`](https://github.com/0rand) for the original
  [two-node DGX Spark repository](https://github.com/0rand/glm-5.3-flash-nvfp4-2x-dgx-sparks)
  and its deployment foundation.
- Kudos to [`MiaAI-Lab`](https://github.com/MiaAI-Lab) for the
  [GLM-5.3 chat template](https://github.com/MiaAI-Lab/GLM-5.3-Flash-EXL3-2x-DGX-Sparks/blob/main/files/chat_template.jinja)
  included in this repository.
- Thanks to local-inference-lab and the vLLM, B12X, FlashInfer,
  InstantTensor, LMCache and NCCL maintainers.
