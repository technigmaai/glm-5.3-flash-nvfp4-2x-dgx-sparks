# GLM-5.3-Flash NVFP4 on 2× DGX Spark

This repository contains a two-node deployment for [`local-inference-lab/GLM-5.3-Flash-NVFP4`](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4) on two NVIDIA DGX Spark systems. It runs one GB10 GPU per node with tensor parallelism 2 over RoCE and exposes an OpenAI-compatible vLLM API on port 8000.

The current qualified baseline uses the R27.0-B PMU128 ARM64 image, a 1,047,552-token maximum context, MTP3, a Marlin MXFP8 draft path, an NVFP4 draft vocabulary head, local argmax reduction and RoCEnante custom collectives. R27.0-B keeps the R27.0-A fused-MTP runtime and adds 128-token prefix matching plus safe retention of the final reusable MTP cache block. Client requests control temperature, `top_p` and reasoning effort.

## Current qualified profile

| Setting | Value |
|---|---|
| Image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-b-pmu128-arm64-sm121` |
| Docker Hub index digest | `sha256:388e0409067656e3f72e2cb23bdad0b2e0ba9d2bfa4daad723c9fa9a7afe920c` |
| ARM64 manifest digest | `sha256:54b740354fda0707a2c542df804af739dc59ac2b523b6aafc69200ff55d001af` |
| Model | `local-inference-lab/GLM-5.3-Flash-NVFP4` |
| Model revision | `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49` |
| Tensor parallelism | 2 nodes × 1 GPU |
| API | OpenAI compatible, port 8000 |
| Maximum context | 1,047,552 tokens |
| Measured KV capacity | 1,074,109 tokens, 1.03× maximum request |
| Maximum sequences | 4 |
| Maximum batched tokens | 4,096 |
| Fixed KV cache | 11,700 MiB per rank, FP8 |
| Physical cache geometry | 1,024-token split target/recurrent pages |
| Speculation | MTP3 |
| MTP expert backend | Marlin, MXFP8 draft experts |
| MTP vocabulary head | Draft-only NVFP4 copy; target verifier remains BF16 |
| Target attention / linear / MoE | B12X |
| KDA prefill | B12X |
| Collectives | RoCEnante up to 2 MiB; PyNCCL fallback above 2 MiB |
| CUDA graphs | Full and piecewise capture |
| Prefix cache | Enabled; 128-token match unit; MTP final-block retention |
| Chunked prefill / async scheduling | Enabled / enabled |
| Model loading | InstantTensor buffered loader |
| Tool / reasoning parsers | `glm47` / `glm45` |
| Chat template | [`files/chat_template.jinja`](files/chat_template.jinja) |

`KV_CACHE_MEMORY_BYTES` controls cache size directly, so `GPU_MEMORY_UTILIZATION` does not resize KV cache in this profile. The service must report a cache capacity above `MAX_MODEL_LEN` during startup.

Temperature, `top_p`, and reasoning effort are intentionally not server defaults. Clients set them per request. A representative quality-oriented request uses `temperature=0.95`, `top_p=1.0`, and `reasoning_effort=high`.

## Runtime and patches

R27.0-B is a Python-only source overlay on the published R27.0-A ARM64 image. It keeps CUDA 13.2, PyTorch 2.13.0, NCCL 2.30.4, FlashInfer 0.6.18, InstantTensor 0.1.9, B12X and the qualified compiled runtime unchanged.

| Project | Change | Purpose |
|---|---|---|
| vLLM | #653, #666 | inherited R26.1 compatibility fixes |
| B12X | #317 | inherited R26.1 compatibility/performance fix |
| vLLM | #665, #701, #706, #715 | inherited R26.2 draft-head, tool JSON, stream-safety and sparse-pool fixes |
| vLLM | #767 | preserve `finish_reason="length"` for truncated automatic tool calls |
| vLLM | #769 | distribute MoE startup-tuning routes across experts |
| B12X | #362 | bound MXFP8 scale reads for padded persistent tiles |
| MiaAI-Lab | #215 | prevent tool-call emission when clients request `tool_choice: "none"` |
| B12X | #280 | enable the existing M8 parallel route packer and split compute path |
| vLLM | #57443 | update sparse-indexer metadata in place across fused MTP draft steps |
| vLLM / PMU128 recipe | #53388-derived MTP block retention and 128-token match-unit scheduling | improve repeated agent-prefix reuse without changing physical KV pages |
| B12X | #353, #354 | excluded after measured TP2 GB10 prefill regression |
| vLLM | #727 | excluded because it depends on B12X #354 |

The R27.0-B overlay and provenance are in [`image/r27.0-b-pmu128/`](image/r27.0-b-pmu128). R27.0-A remains the immediate rollback image at `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121`; its backport is preserved in [`image/r27.0-a-pr57443/`](image/r27.0-a-pr57443).

The deployment files also include the refreshed MiaAI-Lab chat template used by the qualified service. It emits a reasoning-effort system marker only when thinking is enabled and handles empty content and interleaved tool responses more defensively. The compose files make the custom template optional and expose disabled-by-default fairness controls for future compute-share and micro-slicing experiments.

## Build and deploy

Install Docker with the NVIDIA container runtime on both ARM64 DGX Spark nodes. Configure passwordless SSH from the head to the worker, and make the pinned model revision available in the same Hugging Face cache path on both nodes.

```bash
git clone https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks.git
cd glm-5.3-flash-nvfp4-2x-dgx-sparks
docker pull technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-b-pmu128-arm64-sm121
cp .env.example .env
# Edit cache paths, RoCE interfaces, addresses, SSH target, and worker path.
./start.sh
```

To reproduce the image locally from the published R27.0-A base:

```bash
cd image/r27.0-b-pmu128
./build.sh
docker run --rm --entrypoint python3 \
  local/vllm:glm53-r27.0-b-pmu128-arm64-sm121 \
  /opt/glm53-patches/apply_pmu128_patch.py --verify
```

`start.sh` syncs the repository to the worker, starts rank 1 first, waits 15 seconds, and starts rank 0. It does not copy `.git`, `logs/`, or `tmp/`.

```bash
./status.sh
./tail-log.sh
./stop.sh
```

The expected health endpoint is `http://HEAD_IP:8000/health`; the API base URL is `http://HEAD_IP:8000/v1`. The compose files also expose optional compute-share and micro-slicing fairness controls, which are disabled in the qualified baseline. Setting `CHAT_TEMPLATE` to an empty value starts vLLM without a custom template.

## Latest matched benchmark

The benchmark ran from a separate RTX client using llama-benchy 0.4.0. Coherence passed and no CUDA, OOM, traceback or service errors occurred.

```bash
uvx --refresh llama-benchy \
  --base-url http://HEAD_IP:8000/v1 \
  --depth 0 4096 8192 \
  --latency-mode generation \
  --concurrency 1 2 4 \
  --tg 128 \
  --model local-inference-lab/GLM-5.3-Flash-NVFP4
```

| Depth | Concurrency | Prefill t/s | Generation t/s | TTFR ms |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1,638 | 33.5 | 1,415 |
| 0 | 2 | 1,746 | 49.9 | 2,359 |
| 0 | 4 | 1,656 | 54.3 | 4,136 |
| 4,096 | 1 | 1,765 | 33.8 | 3,647 |
| 4,096 | 2 | 1,710 | 42.8 | 6,789 |
| 4,096 | 4 | 1,724 | 32.3 | 10,708 |
| 8,192 | 1 | 1,799 | 35.4 | 5,857 |
| 8,192 | 2 | 1,767 | 30.7 | 9,929 |
| 8,192 | 4 | 1,738 | 23.1 | 16,049 |

In the latest matched A/B run, R27.0-B raised total TG in all nine cells. At c2 it moved from 43.2 to 49.9 t/s at d0, 29.6 to 42.8 at d4096, and 24.4 to 30.7 at d8192. Prefill was generally lower, while an identical 13,505-token prompt reused 13,440 tokens on its second request and fell from 7.523 seconds to 0.289 seconds. Because 13,440 is divisible by 128 but not 1,024, this directly verifies fine-grained PMU128 matching. Detailed results and the R27.0-A comparison are in [`docs/benchmark.md`](docs/benchmark.md).

## Repository contents

Model weights, Hugging Face caches, `.env`, credentials, logs, raw benchmark output, container archives and the cluster `tmp/` research archive are excluded. Keep `.env` local because it contains site-specific paths and addresses.

The copied vLLM files retain their upstream Apache-2.0 licensing. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Credits

- Kudos to [`0rand`](https://github.com/0rand) for the original [two-node DGX Spark repository](https://github.com/0rand/glm-5.3-flash-nvfp4-2x-dgx-sparks) and its deployment foundation.
- Kudos to [`MiaAI-Lab`](https://github.com/MiaAI-Lab) for the [GLM-5.3 chat template](https://github.com/MiaAI-Lab/GLM-5.3-Flash-EXL3-2x-DGX-Sparks/blob/main/files/chat_template.jinja) included in this repository.
- Thanks to `local-inference-lab` and the vLLM, B12X, FlashInfer, InstantTensor and related upstream maintainers.
