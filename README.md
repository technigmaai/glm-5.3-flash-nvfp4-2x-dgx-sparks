# GLM-5.3-Flash NVFP4 on 2× DGX Spark

This repository contains the qualified two-node deployment for [`local-inference-lab/GLM-5.3-Flash-NVFP4`](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4) on two NVIDIA DGX Spark systems. It runs one GB10 GPU per node with tensor parallelism 2 over RoCE and exposes an OpenAI-compatible vLLM API on port 8000.

The published image is Linux ARM64 and targets Blackwell `sm_121`. It keeps the R26.1 B12X package because B12X pull requests #353 and #354 reduced prefill throughput on this cluster, while adding compatible vLLM correctness fixes from the R26.2 experiment.

## Qualified production profile

| Setting | Value |
|---|---|
| Image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121` |
| Local image ID used for qualification | `sha256:c13006e527115a28cf8d680ce48c2fa5bfb9fa4165474fccb8c6a13898413325` |
| Model revision | `46aaae8a82032f77100f2f03e9cc11b391df3b4d` |
| Tensor parallelism | 2 nodes × 1 GPU |
| Maximum context | 524,288 tokens |
| Maximum sequences | 4 |
| Maximum batched tokens | 4,096 |
| GPU memory utilization | 0.89 |
| Fixed KV cache | 11,700 MB per rank, FP8 |
| Cache geometry | 512-token split target pages |
| Speculation | MTP, 3 speculative tokens |
| MTP draft head | BF16 |
| Target attention / linear / MoE | B12X |
| KDA prefill | B12X |
| MTP MoE | Humming |
| Prefix cache | Enabled |
| Chunked prefill / async scheduling | Enabled / enabled |
| Model loading | InstantTensor buffered loader |
| Tool / reasoning parsers | `glm47` / `glm45` |
| Chat template | [`files/chat_template.jinja`](files/chat_template.jinja) |

Temperature, `top_p`, and reasoning effort are intentionally not server defaults. Clients set them per request. For example, llama-benchy accepts `--extra-body temperature=0.95,top_p=1.0,reasoning_effort=high`.

## Runtime packages

| Component | Version or pin |
|---|---|
| CUDA toolkit | 13.2 (`cuda_13.2.r13.2/compiler.37668154_0`) |
| Python | 3.12.3 |
| vLLM | `0.26.1rc0+jj.glm53.r26.universal.arm64.sm121.cu132.20260905` |
| PyTorch | `2.13.0+cu132` |
| FlashInfer | `0.6.18+cu132` |
| B12X | source commit `60dbc57098a3abff60cbf6048bcf8784c117feaf`, with R26.1 PR #317 |
| InstantTensor | 0.1.9, commit `49b4010afc1cae0441e71fe0b0bffc24fa05e932` |
| LMCache | `0.5.2+glm53.r26` |
| CUTLASS DSL | 4.6.2 |
| Triton | 3.7.1 |
| transformers | 5.16.1 |
| safetensors | 0.8.0 |
| xgrammar | 0.2.5 |
| NCCL | 2.30.4 |

The full Python environment and OCI labels are recorded in [`manifests/`](manifests). The image recipe and the six exact vLLM overlay files are in [`image/r26.2-quality/`](image/r26.2-quality).

## Included and excluded changes

| Project | Change | Status | Purpose |
|---|---|---|---|
| vLLM | #653, #666 | inherited from R26.1 | R26.1 conservative compatibility fixes |
| B12X | #317 | inherited from R26.1 | R26.1 B12X compatibility/performance fix |
| vLLM | #665 | included | runtime-owned MTP draft-head guard; BF16 is selected here |
| vLLM | #701 | included | tool-call JSON recovery and stale KV completion hardening |
| vLLM | #706 | included | shared-expert output stream safety |
| vLLM | #715 | included | preserve incomplete sparse-attention pool tails |
| vLLM | #727 | excluded | depends on B12X #354 |
| B12X | #353, #354 | excluded | caused the measured prefill regression on TP2 GB10 |

See [`image/r26.2-quality/PATCH-MANIFEST.md`](image/r26.2-quality/PATCH-MANIFEST.md) and [`docs/benchmark.md`](docs/benchmark.md) for provenance and measured results.

## Deploy

Install Docker with the NVIDIA container runtime on both ARM64 DGX Spark nodes. Configure passwordless SSH from the head to the worker and make the model revision available in the same Hugging Face cache path on both nodes.

```bash
git clone https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks.git
cd glm-5.3-flash-nvfp4-2x-dgx-sparks
cp .env.example .env
# Edit the cache path, RoCE interfaces, IP addresses, SSH target, and worker path.
docker pull technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.2-quality-bf16-arm64-sm121
./start.sh
```

`start.sh` syncs the repository to the worker, starts rank 1 first, waits 15 seconds, and starts rank 0. It does not copy `.git`, `logs/`, or `tmp/`.

```bash
./status.sh
./tail-log.sh
./stop.sh
```

The expected health endpoint is `http://HEAD_IP:8000/health`; the OpenAI-compatible base URL is `http://HEAD_IP:8000/v1`.

## Benchmark

Run from a separate client so the benchmark does not compete for CPU or memory on either inference node:

```bash
uvx --refresh llama-benchy \
  --base-url http://HEAD_IP:8000/v1 \
  --depth 4096 8192 \
  --latency-mode generation \
  --concurrency 1 2 4 \
  --tg 128 \
  --model local-inference-lab/GLM-5.3-Flash-NVFP4
```

The qualified R26.2 quality arm measured 1,693–1,856 total prefill tokens/s and 21.11–28.57 total generation tokens/s across these depth/concurrency cells. All coherence checks passed. Results vary with concurrent clients, cache warmth, prompt content, and sampling.

## Image recipe

The final image is a small Python-source overlay on the locally qualified R26.1 ARM64 base. No CUDA, PyTorch, NCCL, FlashInfer, B12X, or compiled vLLM extension is rebuilt by this layer.

```bash
cd image/r26.2-quality
./build.sh
python validate_r262_runtime.py
```

The default build expects the recorded local base tag `local/vllm:glm53-r26.1-conservative-arm64-sm121`. The published final image is the portable artifact; the overlay recipe is retained for audit and local reproduction from that base.

## Security and repository contents

Model weights, Hugging Face caches, `.env`, credentials, logs, benchmark raw output, container archives, and the cluster `tmp/` research archive are excluded. Keep `.env` local because it contains site-specific paths and addresses.

The copied vLLM files retain their upstream Apache-2.0 licensing. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).
