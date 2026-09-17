# GLM-5.3-Flash NVFP4 on 2× DGX Spark

This repository contains a two-node deployment for [`local-inference-lab/GLM-5.3-Flash-NVFP4`](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4) on two NVIDIA DGX Spark systems. It runs one GB10 GPU per node with tensor parallelism 2 over RoCE and exposes an OpenAI-compatible vLLM API on port 8000.

The current qualified profile uses the R26.3 minimal ARM64 image, a 1,047,552-token maximum context, MTP3, a Marlin MXFP8 draft path, an NVFP4 draft vocabulary head, local argmax reduction and RoCEnante custom collectives. Client requests control temperature, `top_p` and reasoning effort.

## Current qualified profile

| Setting | Value |
|---|---|
| Image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.3-minimal-arm64-sm121` |
| Docker Hub index digest | `sha256:b691df035abd9255b4ee9ebbb07ceeb8914ab2a550597c548dff3a8bd5f8b464` |
| ARM64 manifest digest | `sha256:63579eb51013ad63af46919993d668516cab2c3cc1205e47f0610f6fea2ff5c7` |
| Model | `local-inference-lab/GLM-5.3-Flash-NVFP4` |
| Model revision | `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49` |
| Tensor parallelism | 2 nodes × 1 GPU |
| API | OpenAI compatible, port 8000 |
| Maximum context | 1,047,552 tokens |
| Measured KV capacity | 1,074,109 tokens, 1.03× maximum request |
| Maximum sequences | 4 |
| Maximum batched tokens | 4,096 |
| Fixed KV cache | 11,700 MiB per rank, FP8 |
| Cache geometry | 1,024-token split target pages |
| Speculation | MTP3 |
| MTP expert backend | Marlin, MXFP8 draft experts |
| MTP vocabulary head | Draft-only NVFP4 copy; target verifier remains BF16 |
| Target attention / linear / MoE | B12X |
| KDA prefill | B12X |
| Collectives | RoCEnante up to 2 MiB; PyNCCL fallback above 2 MiB |
| CUDA graphs | Full and piecewise capture |
| Prefix cache | Enabled |
| Chunked prefill / async scheduling | Enabled / enabled |
| Model loading | InstantTensor buffered loader |
| Tool / reasoning parsers | `glm47` / `glm45` |
| Chat template | [`files/chat_template.jinja`](files/chat_template.jinja) |

`KV_CACHE_MEMORY_BYTES` controls cache size directly, so `GPU_MEMORY_UTILIZATION` does not resize KV cache in this profile. The service must report a cache capacity above `MAX_MODEL_LEN` during startup.

Temperature, `top_p`, and reasoning effort are intentionally not server defaults. Clients set them per request. A representative quality-oriented request uses `temperature=0.95`, `top_p=1.0`, and `reasoning_effort=high`.

## Runtime and patches

R26.3 is a small source overlay on the published R26.2 ARM64 image. It keeps CUDA 13.2, PyTorch 2.13.0, NCCL 2.30.4, FlashInfer 0.6.18, InstantTensor 0.1.9 and the qualified R26.2 compiled runtime.

| Project | Change | Purpose |
|---|---|---|
| vLLM | #653, #666 | inherited R26.1 compatibility fixes |
| B12X | #317 | inherited R26.1 compatibility/performance fix |
| vLLM | #665, #701, #706, #715 | inherited R26.2 draft-head, tool JSON, stream-safety and sparse-pool fixes |
| vLLM | #767 | preserve `finish_reason="length"` for truncated automatic tool calls |
| vLLM | #769 | distribute MoE startup-tuning routes across experts |
| B12X | #362 | bound MXFP8 scale reads for padded persistent tiles |
| B12X | #353, #354 | excluded after measured TP2 GB10 prefill regression |
| vLLM | #727 | excluded because it depends on B12X #354 |

The exact R26.3 overlay and patch provenance are in [`image/r26.3-minimal/`](image/r26.3-minimal). The published R26.2 base image remains available as `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121`.

## Build and deploy

Install Docker with the NVIDIA container runtime on both ARM64 DGX Spark nodes. Configure passwordless SSH from the head to the worker, and make the pinned model revision available in the same Hugging Face cache path on both nodes.

```bash
git clone https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks.git
cd glm-5.3-flash-nvfp4-2x-dgx-sparks
docker pull technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.3-minimal-arm64-sm121
cp .env.example .env
# Edit cache paths, RoCE interfaces, addresses, SSH target, and worker path.
./start.sh
```

To reproduce the image locally from the published R26.2 base:

```bash
cd image/r26.3-minimal
./build.sh
python validate_r263_runtime.py
```

`start.sh` syncs the repository to the worker, starts rank 1 first, waits 15 seconds, and starts rank 0. It does not copy `.git`, `logs/`, or `tmp/`.

```bash
./status.sh
./tail-log.sh
./stop.sh
```

The expected health endpoint is `http://HEAD_IP:8000/health`; the API base URL is `http://HEAD_IP:8000/v1`.

## Latest matched benchmark

The benchmark ran from a separate RTX client using llama-benchy 0.4.0. Coherence passed and no CUDA, OOM, traceback or service errors occurred.

```bash
uvx --refresh llama-benchy \
  --base-url http://HEAD_IP:8000/v1 \
  --depth 4096 8192 \
  --latency-mode generation \
  --concurrency 1 2 4 \
  --tg 128 \
  --model local-inference-lab/GLM-5.3-Flash-NVFP4
```

| Depth | Concurrency | Prefill t/s | Generation t/s | TTFR ms |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,678.19 | 31.09 | 3,855.86 |
| 4,096 | 2 | 1,760.55 | 29.09 | 5,240.97 |
| 4,096 | 4 | 1,727.87 | 27.98 | 8,964.70 |
| 8,192 | 1 | 1,873.13 | 31.62 | 5,659.05 |
| 8,192 | 2 | 1,809.84 | 24.26 | 8,872.79 |
| 8,192 | 4 | 1,740.44 | 21.34 | 14,890.66 |

With identical MTP3/4096 settings, the non-Spark checkpoint generated faster than the Spark checkpoint in all six cells. Spark prefills faster, while the non-Spark checkpoint's higher MTP acceptance makes it the preferred agent/decode profile. Detailed historical and matched results are in [`docs/benchmark.md`](docs/benchmark.md).

## Repository contents

Model weights, Hugging Face caches, `.env`, credentials, logs, raw benchmark output, container archives and the cluster `tmp/` research archive are excluded. Keep `.env` local because it contains site-specific paths and addresses.

The copied vLLM files retain their upstream Apache-2.0 licensing. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Credits

- Kudos to [`0rand`](https://github.com/0rand) for the original [two-node DGX Spark repository](https://github.com/0rand/glm-5.3-flash-nvfp4-2x-dgx-sparks) and its deployment foundation.
- Kudos to [`MiaAI-Lab`](https://github.com/MiaAI-Lab) for the [GLM-5.3 chat template](https://github.com/MiaAI-Lab/GLM-5.3-Flash-EXL3-2x-DGX-Sparks/blob/main/files/chat_template.jinja) included in this repository.
- Thanks to `local-inference-lab` and the vLLM, B12X, FlashInfer, InstantTensor and related upstream maintainers.
