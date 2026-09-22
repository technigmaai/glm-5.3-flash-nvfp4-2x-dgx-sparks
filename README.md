# GLM-5.3-Flash NVFP4 on 2× DGX Spark

This repository provides a reproducible two-node deployment for
[`local-inference-lab/GLM-5.3-Flash-NVFP4`](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4)
on two NVIDIA DGX Spark systems. It runs one GB10 GPU per node with tensor
parallelism 2 over RoCE and exposes an OpenAI-compatible vLLM API on port 8000.

The current production profile is the R28.1 display-KV derivative of the R28
Karmic Kraken ARM64/SM121a build. It uses CUDA 13.4.1, PyTorch 2.14, a pinned
vLLM/B12X stack, one-million-token context, MTP3 speculative decoding, fixed
FP8 KV cache and image input. On headless Sparks, 1.75 GiB of each rank's KV
buffer is backed by the firmware display reservation. Client requests control
temperature, `top_p` and reasoning effort.

## Production profile

| Setting | Value |
|---|---|
| Image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.1-display-kv-arm64-sm121-cu134` |
| Base image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28-karmic-kraken-arm64-sm121-cu134` |
| Docker Hub digest | `sha256:92f1106261a70c846f9110f68dad87aaae83c03c8d66d88a3e603deb7d39d539` |
| Moving alias | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:latest` points to the same digest |
| Platform | Linux ARM64, GB10 / SM121a |
| CUDA / PyTorch | 13.4.1 / 2.14.0 NVIDIA 26.08 build |
| Model | `local-inference-lab/GLM-5.3-Flash-NVFP4` |
| Model revision | `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49` |
| Parallelism | 2 nodes × 1 GPU, TP2, DCP1 |
| Maximum context | 1,047,552 tokens |
| Measured KV capacity | 1,049,451 tokens |
| Fixed KV cache | 11,840 MiB per rank, FP8 |
| Display-backed KV | 1,792 MiB per rank; 10,040 MiB remains in ordinary unified memory |
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
| Multimodal limits | Up to 32 images, video disabled, 1 GiB processor cache |
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
wheels, build trees and caches are intentionally ignored. R28.1 preserves that
runtime and adds only the display-KV allocation layer documented in
[`image/r28.1-display-kv-arm64/`](image/r28.1-display-kv-arm64).

## Deploy

Install Docker with the NVIDIA container runtime on both DGX Spark nodes.
Configure passwordless SSH from the head to the worker, and make the pinned
model revision available in the same Hugging Face cache path on both systems.

```bash
git clone https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks.git
cd glm-5.3-flash-nvfp4-2x-dgx-sparks
docker pull technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.1-display-kv-arm64-sm121-cu134
cp .env.example .env
# Apply the headless host setup in docs/display-kv-r28.1.md on both nodes.
# Edit the cache path, RoCE interfaces, IP addresses, SSH target and worker path.
./start.sh
```

`start.sh` syncs the deployment files to the worker, starts rank 1, then starts
rank 0. When `DISPLAY_KV_ENABLE=1`, it also supplies `/dev/dri/card0` through
the display-KV Compose overlay. It excludes `.git`, logs, `tmp/`, local
credentials and model data. Complete host preparation, validation markers and
rollback instructions are in
[`docs/display-kv-r28.1.md`](docs/display-kv-r28.1.md).

```bash
./status.sh
./tail-log.sh
./stop.sh
```

`watchdog.sh` coordinates recovery if the API fails three consecutive
one-minute health checks. It stops the remote worker and local head before
starting the worker-first launch sequence, observes a 15-minute startup grace
period, and limits automatic restarts to one every 15 minutes. An intentional
`./stop.sh` disables recovery; the next `./start.sh` enables it again.

Install the head-node user cron entry once:

```bash
(crontab -l 2>/dev/null | grep -v '/watchdog.sh check' || true; echo '* * * * * /absolute/path/to/watchdog.sh check >/dev/null 2>&1') | crontab -
./watchdog.sh status
```

Apply the lower swap preference locally on both nodes. The first command is
persistent and the second applies it immediately; no reboot is required.

```bash
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-glm53-memory.conf >/dev/null
sudo sysctl -w vm.swappiness=10
```

The qualified one-million-token profile uses an 11,840 MiB fixed KV cache,
which provides approximately 1.00x maximum-context capacity. The 1 GiB
multimodal processor cache retains image support while leaving more system
memory available than the earlier 2 GiB setting. Keep image builds, pushes,
downloads and compression jobs off the serving nodes while the model is live.
This profile still operates close to the unified-memory limit; the measured
post-warmup swap and the September 22 recovery are documented in
[`docs/incident-2026-09-22-rpc-timeout.md`](docs/incident-2026-09-22-rpc-timeout.md).

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

The R28.1 derivative is a small layer and does not rebuild CUDA, PyTorch, vLLM
or B12X:

```bash
cd image/r28.1-display-kv-arm64
./build.sh
```

## Qualified performance

The qualified warm R28.1 display-KV run used `llama-benchy 0.4.0` from a separate RTX host,
with 2,048 prompt tokens, 128 generated tokens and no request errors. The first
sample after startup can include JIT and cache warm-up, so production
comparisons should use a warm repeat.

| Depth | Concurrency | PP t/s | TG t/s | TTFT ms |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,886 | 35.4 | 3,360 |
| 4,096 | 2 | 1,798 | 37.0 | 6,073 |
| 4,096 | 4 | 1,856 | 31.6 | 10,486 |
| 8,192 | 1 | 1,918 | 32.1 | 5,443 |
| 8,192 | 2 | 1,880 | 32.8 | 9,565 |
| 8,192 | 4 | 1,913 | 24.8 | 16,038 |
| 16,384 | 1 | 1,946 | 33.9 | 9,577 |
| 16,384 | 2 | 1,915 | 21.0 | 15,825 |
| 16,384 | 4 | 1,926 | 15.2 | 26,756 |

The separate 27-request `tool-eval-bench --perf-only` qualification completed
in 6:11 with no request errors. The latest full agent/tool evaluation scored
**94/100**: 82 passed, two partial and four failed scenarios. Autonomous
Planning was the weakest category at 67%; the retained TC-51 warning concerns
tool sequencing between calendar creation and email delivery. Detailed R28.1
validation and earlier R26/R27 comparisons are preserved in
[`docs/benchmark.md`](docs/benchmark.md).

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
- Thanks to [`coolbho3k`](https://github.com/coolbho3k) for discovering and
  publishing the GB10 display-reserved CUDA allocation technique used by R28.1.
- Kudos to [`MiaAI-Lab`](https://github.com/MiaAI-Lab) for the
  [GLM-5.3 chat template](https://github.com/MiaAI-Lab/GLM-5.3-Flash-EXL3-2x-DGX-Sparks/blob/main/files/chat_template.jinja)
  included in this repository.
- Thanks to local-inference-lab and the vLLM, B12X, FlashInfer,
  InstantTensor, LMCache and NCCL maintainers.
