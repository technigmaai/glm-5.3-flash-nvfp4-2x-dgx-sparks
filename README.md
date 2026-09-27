# GLM-5.3-Flash NVFP4 on 2× DGX Spark

This repository provides a reproducible two-node deployment for
[`local-inference-lab/GLM-5.3-Flash-NVFP4`](https://huggingface.co/local-inference-lab/GLM-5.3-Flash-NVFP4)
on two NVIDIA DGX Spark systems. It runs one GB10 GPU per node with tensor
parallelism 2 over RoCE and exposes an OpenAI-compatible vLLM API on port 8000.

**Use R28.8-A for new deployments.** It is the qualified production image and
the current `latest` alias. R28.6-A and R28.7-A are retained as isolated
comparison images for PRs #58594 and #58450; they are not newer alternatives
to R28.8-A.

R28.8-A combines the complete qualified patch chain—vLLM PRs
[#58454](https://github.com/vllm-project/vllm/pull/58454),
[#58785](https://github.com/vllm-project/vllm/pull/58785),
[#58779](https://github.com/vllm-project/vllm/pull/58779),
[#58594](https://github.com/vllm-project/vllm/pull/58594) and
[#58450](https://github.com/vllm-project/vllm/pull/58450)—with the R28.2 B12X
performance stack. It provides a one-million-token context, MTP3 speculative
decoding, fixed FP8 KV cache and image input on CUDA 13.4.1 / PyTorch 2.14.

## Current release

| Setting | Value |
|---|---|
| Recommended release | **R28.8-A** |
| Docker repository | [`technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks`](https://hub.docker.com/r/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks) |
| Versioned tag | `r28.8-a-pr58454-pr58785-pr58779-pr58594-pr58450-arm64-sm121-cu134` |
| Immutable digest | `sha256:1169f797539454e3c286557d49fddd488488957d9a3f10638b01052998370622` |
| Immutable pull | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks@sha256:1169f797539454e3c286557d49fddd488488957d9a3f10638b01052998370622` |
| Moving alias | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:latest` resolves to the same digest |
| Parent image | R28.5-A |
| Added over parent | PRs [#58594](https://github.com/vllm-project/vllm/pull/58594) and [#58450](https://github.com/vllm-project/vllm/pull/58450) |
| GitHub release | [R28.8-A release notes](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.8-a-pr58454-pr58785-pr58779-pr58594-pr58450-arm64-sm121-cu134) |
| Reproducible recipe | [`image/r28.8-a-pr58594-pr58450/`](image/r28.8-a-pr58594-pr58450) |

Use the versioned tag or immutable digest in production. The `latest` tag is a
convenience alias and may move in a future release.

## Qualified runtime profile

| Setting | Value |
|---|---|
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
| Sparse split target block size | 1,024 tokens (`GLM53_SPLIT_TARGET_BLOCK_SIZE=1024`) |
| Prefix cache | Enabled, 128-token match unit |
| Speculation | MTP3, greedy draft and standard rejection sampling |
| MTP experts / attention | Marlin MXFP8 / B12X |
| MTP vocabulary head | NVFP4 draft head; target verifier remains BF16 |
| Target MoE / KDA prefill | B12X / B12X |
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

`GLM53_SPLIT_TARGET_BLOCK_SIZE=1024` controls the sparse-attention split target;
it is separate from `MAX_NUM_BATCHED_TOKENS=4096`, which limits tokens admitted
to one scheduler iteration.

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

The complete native build recipe and ARM64 adaptation notes are in
[`image/r28-karmic-kraken-arm64/`](image/r28-karmic-kraken-arm64). Generated
wheels, build trees and caches are intentionally excluded from Git.

### Release lineage

| Release | Parent | Change introduced | Recipe | Role |
|---|---|---|---|---|
| R28.1 | R28 | Display-reserved KV allocation | [`r28.1-display-kv-arm64`](image/r28.1-display-kv-arm64) | Historical foundation |
| R28.2 | R28.1 | B12X wheel with three pinned upstream backports | [`r28.2-b12x-tg3-arm64`](image/r28.2-b12x-tg3-arm64) | Performance foundation |
| R28.3-A | R28.2 | PR #58454: GLM k-pool tail-ring correctness | [`r28.3-a-pr58454`](image/r28.3-a-pr58454) | Superseded |
| R28.4-A | R28.3-A | PR #58785: persistent top-k overflow fallback | [`r28.4-a-pr58785`](image/r28.4-a-pr58785) | Superseded |
| R28.5-A | R28.4-A | PR #58779: bounded MTP draft-token RPC wait | [`r28.5-a-pr58779`](image/r28.5-a-pr58779) | Qualified reference |
| R28.6-A | R28.5-A | PR #58594: sparse-indexer top-k backend selection | [`r28.6-a-pr58594`](image/r28.6-a-pr58594) | Isolated comparison |
| R28.7-A | R28.5-A | PR #58450: GLM metadata construction | [`r28.7-a-pr58450`](image/r28.7-a-pr58450) | Isolated comparison |
| **R28.8-A** | R28.5-A | **PRs #58594 + #58450 combined** | [`r28.8-a-pr58594-pr58450`](image/r28.8-a-pr58594-pr58450) | **Production / latest** |

R28.6-A and R28.7-A branch independently from R28.5-A. R28.8-A combines their
two changes; it is not built by layering R28.7-A over R28.6-A.

### Published patch images

Docker repository for every tag below:
[`technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks`](https://hub.docker.com/r/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks).

| Image | Tag | Digest | GitHub release |
|---|---|---|---|
| R28.1 | `r28.1-display-kv-arm64-sm121-cu134` | `92f11062…` | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.1-display-kv-arm64-sm121-cu134) |
| R28.2 | `r28.2-b12x-tg3-arm64-sm121-cu134` | [`b895b0c0…`](manifests/r28.2-image-identity.txt) | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.2-b12x-tg3-arm64-sm121-cu134) |
| R28.3-A | `r28.3-a-pr58454-arm64-sm121-cu134` | [`f39eef91…`](manifests/r28.3-a-image-identity.txt) | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.3-a-pr58454-arm64-sm121-cu134) |
| R28.4-A | `r28.4-a-pr58454-pr58785-arm64-sm121-cu134` | [`1e88fd52…`](manifests/r28.4-a-image-identity.txt) | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.4-a-pr58454-pr58785-arm64-sm121-cu134) |
| R28.5-A | `r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134` | [`ca40c504…`](manifests/r28.5-a-image-identity.txt) | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134) |
| R28.6-A | `r28.6-a-pr58454-pr58785-pr58779-pr58594-arm64-sm121-cu134` | [`b288dfa4…`](manifests/r28.6-a-image-identity.txt) | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.6-a-pr58454-pr58785-pr58779-pr58594-arm64-sm121-cu134) |
| R28.7-A | `r28.7-a-pr58454-pr58785-pr58779-pr58450-arm64-sm121-cu134` | [`92858727…`](manifests/r28.7-a-image-identity.txt) | [Release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.7-a-pr58454-pr58785-pr58779-pr58450-arm64-sm121-cu134) |
| **R28.8-A** | `r28.8-a-pr58454-pr58785-pr58779-pr58594-pr58450-arm64-sm121-cu134` | [`1169f797…`](manifests/r28.8-a-image-identity.txt) | [Latest release](https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks/releases/tag/r28.8-a-pr58454-pr58785-pr58779-pr58594-pr58450-arm64-sm121-cu134) |

Digest links open the stored image identity with the complete SHA-256 value;
the R28.1 value is recorded in its release notes.

## Deploy

Install Docker with the NVIDIA container runtime on both DGX Spark nodes.
Configure passwordless SSH from the head to the worker, and make the pinned
model revision available in the same Hugging Face cache path on both systems.

```bash
git clone https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks.git
cd glm-5.3-flash-nvfp4-2x-dgx-sparks
docker pull technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.8-a-pr58454-pr58785-pr58779-pr58594-pr58450-arm64-sm121-cu134
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

To reproduce the current production image from its published R28.5-A parent:

```bash
cd image/r28.8-a-pr58594-pr58450
./build.sh
```

The R28.8-A recipe is a small fail-closed Python overlay. It verifies the
parent files, patch inputs and resulting files by SHA-256 and does not rebuild
CUDA, PyTorch, vLLM native extensions or B12X.

To reproduce the isolated comparison images:

```bash
cd image/r28.6-a-pr58594
./build.sh
cd ../r28.7-a-pr58450
./build.sh
```

Rebuilding the native R28 foundation or R28.4-A wheel can take several hours
and needs substantial temporary storage. Use the linked recipe in the release
lineage table; the [R28 foundation README](image/r28-karmic-kraken-arm64/README.md)
documents resume and scratch-directory options.

## Qualified performance

R28.6-A, R28.7-A and R28.8-A were qualified on 2026-09-27 from the same RTX
client. Tests ran strictly one at a time. Each image received one cold sweep,
two warm sweeps and a chat smoke test.

```bash
uvx tool-eval-bench --base-url http://HEAD_IP:8000 \
  --perf-only --depth "4096,8192,16384"
```

Each sweep contains 27 measurements: a 2,048-token prompt, 128 generated
tokens, depths 4K/8K/16K, concurrency 1/2/4 and three runs per cell.

### Qualification runs

| Image | Change over R28.5-A | Cold | Warm 1 | Warm 2 | Warm mean | Smoke | Outcome |
|---|---|---:|---:|---:|---:|---|---|
| R28.6-A | PR #58594 | 9:26 | 9:09 | 8:47 | 8:58 | Pass | Qualified comparison |
| R28.7-A | PR #58450 | 9:22 | 8:47 | 8:45 | 8:46 | Pass | Qualified comparison |
| **R28.8-A** | **PRs #58594 + #58450** | **9:26** | **8:47** | **8:50** | **8:49** | **Pass** | **Selected production image** |

Every smoke returned HTTP 200 with exact `SMOKE_OK` content. Both nodes used
matching image IDs, stayed at zero restarts and reported a 1,049,451-token KV
cache. Logs contained no matched CUDA, OOM, NCCL, traceback or runtime errors.

### Warm performance aggregates

The patch-image rows average all 18 cells from their two warm sweeps. The
R28.5-A reference contains nine cells from a separate valid 8:46 warm sweep
collected with the same command; a transient 14:58 run was excluded.

| Image | Warm cells | Mean prompt | Mean generation | Mean TTFT | Mean total latency | Total vs R28.5-A |
|---|---:|---:|---:|---:|---:|---:|
| R28.5-A reference | 9 | 1,898.44 t/s | 31.19 t/s | 11,673.11 ms | 18,397.89 ms | — |
| R28.6-A | 18 | 1,862.89 t/s | 31.30 t/s | 12,044.50 ms | 18,779.39 ms | +2.1% |
| R28.7-A | 18 | 1,890.28 t/s | 31.24 t/s | 11,735.89 ms | 18,410.83 ms | +0.1% |
| **R28.8-A** | **18** | **1,888.33 t/s** | **31.31 t/s** | **11,799.28 ms** | **18,475.06 ms** | **+0.4%** |

Positive values in the last column mean higher latency. R28.7-A and R28.8-A
are effectively flat against R28.5-A within the observed run-to-run variation.
No speedup is attributed solely to either patch; R28.8-A was selected because
it combines both merged changes without a measurable regression.

An earlier 2026-09-26 R28.5-A warm sweep completed in 8:43 and is preserved
with the R28.4-A comparison in the detailed report. It is not the nine-cell
R28.5-A reference used in the aggregate table above.

Historical R28.3-A sustained-decode results, the R28.4-A persistent-top-k GPU
regression, every per-cell measurement and the earlier cold/warm comparisons
are in [`docs/benchmark.md`](docs/benchmark.md).

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
