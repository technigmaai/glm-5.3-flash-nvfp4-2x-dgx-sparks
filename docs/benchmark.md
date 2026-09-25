# Benchmark results

This document keeps the qualified production measurements and the historical comparisons that explain the selected image and model. Unless stated otherwise, performance tests used `llama-benchy 0.4.0` from a separate RTX client. PP is total prompt-processing throughput, TG is generation throughput, and TTFR is time to first response.

## R28.3-A PR #58454 production profile

Qualified on 2026-09-25 with image `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.3-a-pr58454-arm64-sm121-cu134` and Docker Hub digest
`sha256:f39eef91d461b893f3339151102f2b716ffcbf36dbce2c7c329a3ffe949c5473`. The moving `latest` alias resolves to the same digest.

R28.3-A preserves the complete R28.2 serving profile and adds the NVIDIA
runtime part of [vLLM PR #58454](https://github.com/vllm-project/vllm/pull/58454),
pinned at PR head `8408acad51384ff283acafa8ed486cb7417521b7`. The patch grows
the GLM k-pool speculative tail ring from four to eight positions for MTP3 so
rejected pool-completing drafts cannot overwrite committed keys. It changes
only `common/attention.py` and `nvidia/ops/kpool_compress.py`; CUDA, PyTorch,
native vLLM extensions, B12X and the serving parameters remain unchanged.

### Sustained decode qualification

The comparison used `llm-decode-bench 0.6.2` at repository commit
`ccd9ad8ced7e387794391bfb0ac6d99b1f66ba6f`, 30 seconds per decode cell and
2,048 maximum output tokens. R28.1 is the previous production reference. The
cold R28.3-A pass was captured immediately after service startup; the warm
pass followed it on the same healthy deployment.

| Context | C | R28.1 TG t/s | R28.3-A cold TG t/s | R28.3-A warm TG t/s | Warm TG/request |
|---:|---:|---:|---:|---:|---:|
| 16,384 | 1 | 32.2 | 29.7 | 30.8 | 30.8 |
| 16,384 | 2 | 45.0 | 45.7 | 44.9 | 22.5 |
| 16,384 | 4 | 68.5 | 64.6 | 66.2 | 16.5 |
| 32,768 | 1 | 28.8 | 32.9 | 30.6 | 30.6 |
| 32,768 | 2 | 48.6 | 46.4 | 44.9 | 22.4 |
| 32,768 | 4 | 72.2 | 66.1 | 71.5 | 17.9 |
| 65,536 | 1 | 27.5 | 32.9 | 29.5 | 29.5 |
| 65,536 | 2 | 46.4 | 46.0 | 45.6 | 22.8 |
| 65,536 | 4 | 69.0 | 63.4 | 70.4 | 17.6 |

Average total TG across all cells was 48.7 tokens/s for R28.1, 47.5 for the
cold R28.3-A pass and 48.3 for the warm R28.3-A pass. Warm R28.3-A averages
by concurrency were 30.3, 45.1 and 69.4 tokens/s for c1, c2 and c4.

| Prefill depth | R28.1 PP t/s | R28.3-A cold PP t/s | R28.3-A warm PP t/s |
|---:|---:|---:|---:|
| 8,192 | 1,969 | 1,589 | 1,944 |
| 16,384 | 2,034 | 1,940 | 1,941 |
| 32,768 | 2,060 | 1,936 | 1,943 |
| 65,536 | 2,079 | 1,993 | 2,085 |
| 131,072 | 2,055 | 1,939 | 2,029 |

MTP normalized throughput and average accepted-token counts for the warm pass
were: 11.4/2.70, 17.1/2.63 and 24.1/2.74 at 16K; 11.4/2.69, 17.2/2.61 and
25.7/2.78 at 32K; and 11.4/2.60, 17.1/2.66 and 25.4/2.77 at 64K for c1/c2/c4.
The overlay therefore retained the established production performance while
fixing a correctness hazard in speculative k-pool maintenance.

## R28.2 B12X TG3 production profile

Qualified on 2026-09-24 with image
`technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.2-b12x-tg3-arm64-sm121-cu134`
and model revision `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49`.

R28.2 preserves the R28.1 display-reserved KV runtime and serving recipe. It
replaces only B12X with a wheel built from base
`f6d8b8eb94cdeb4e652652f925a494c6fc86f101` plus three surgical upstream
backports:

| Commit | Purpose |
|---|---|
| `b294e69d8eba2ea56d2aed7cc359c0df4bcaa57d` | NVFP4 decode register/grid tuning |
| `1dc77276e9d0ba297ad753eb3af04327759c1a3b` | Spark decode routing, indexer scheduling and preparation |
| `4f3028b19c1d8290dc72b6f483aba40de23eae5a` | Reuse KDA sliced state |

The qualified deployment used TP2/DCP1, MTP3, one-million-token context,
11,840 MiB FP8 KV per rank, 1,024-token split pages, 128-token prefix matching,
four maximum sequences and 4,096 maximum batched tokens. B12X exhaustive
autotuning, scheduler fairness and EAGLE block dropping were disabled.

The command was `tool-eval-bench --perf-only --depth "4096,8192,16384"`.
Its embedded llama-benchy run used 2,048 prompt tokens, 128 generated tokens,
three samples per cell and generation-latency mode. All 27 requests passed and
the sweep completed in 8 minutes 50 seconds.

| Depth | C | PP t/s | TG t/s | TTFT ms | Total ms |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,802 | 30.5 | 3,531 | 7,613 |
| 4,096 | 2 | 1,792 | 38.2 | 6,164 | 11,794 |
| 4,096 | 4 | 1,875 | 35.4 | 10,685 | 19,450 |
| 8,192 | 1 | 1,883 | 30.5 | 5,559 | 9,645 |
| 8,192 | 2 | 1,898 | 37.2 | 10,104 | 15,845 |
| 8,192 | 4 | 1,929 | 27.7 | 16,413 | 26,458 |
| 16,384 | 1 | 1,932 | 31.5 | 9,662 | 13,618 |
| 16,384 | 2 | 1,932 | 26.1 | 16,724 | 23,061 |
| 16,384 | 4 | 1,941 | 16.6 | 27,063 | 39,447 |

R28.2 improved c4 generation throughput over the qualified R28.1 run at all
three depths: 31.6 to 35.4, 24.8 to 27.7, and 15.2 to 16.6 tokens/s. Prefill
remained around 1.88–1.94K tokens/s in the warm c4 cells.

## R28 Karmic Kraken production profile

Qualified on 2026-09-22 with image
`technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28-karmic-kraken-arm64-sm121-cu134`
and model revision `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49`.

R28 rebuilds the source-locked Karmic Kraken component set for ARM64/SM121a on
NVIDIA PyTorch 26.08, CUDA 13.4.1 and PyTorch 2.14. The production deployment
used TP2/DCP1, MTP3, fixed 11,900 MiB FP8 KV per rank, a 1,047,552-token limit,
1,024-token split pages, 128-token prefix matching, four maximum sequences and
4,096 maximum batched tokens. It reported 1,055,149 cache tokens.

### Strong warm reference

This throughput run used 2,048 prompt tokens, 128 generated tokens, three runs
per cell and generation-latency mode. It completed in 8 minutes 45 seconds.

| Depth | C | PP t/s | TG t/s | TTFT ms | Total ms |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,810 | 30.0 | 3,484 | 7,667 |
| 4,096 | 2 | 1,814 | 40.1 | 6,122 | 11,406 |
| 4,096 | 4 | 1,884 | 37.5 | 10,667 | 18,532 |
| 8,192 | 1 | 1,871 | 33.1 | 5,563 | 9,346 |
| 8,192 | 2 | 1,901 | 41.7 | 10,111 | 15,358 |
| 8,192 | 4 | 1,922 | 28.6 | 16,530 | 26,115 |
| 16,384 | 1 | 1,883 | 34.6 | 9,881 | 13,502 |
| 16,384 | 2 | 1,897 | 25.8 | 17,082 | 23,618 |
| 16,384 | 4 | 1,915 | 16.2 | 27,399 | 39,893 |

### Reboot verification

After performance had degraded during repeated backend and scheduler
experiments, both nodes were rebooted and the same saved R28 profile was
started. The repeat completed in 8 minutes 55 seconds. Its first d4096/c1
prefill was a cold outlier; the remaining cells recovered the earlier profile.

| Depth | C | PP t/s | TG t/s | TTFT ms | Total ms |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,235 | 33.9 | 6,530 | 10,171 |
| 4,096 | 2 | 1,677 | 37.7 | 6,664 | 12,347 |
| 4,096 | 4 | 1,821 | 36.3 | 11,014 | 18,960 |
| 8,192 | 1 | 1,871 | 37.0 | 5,617 | 8,936 |
| 8,192 | 2 | 1,865 | 39.5 | 10,291 | 15,696 |
| 8,192 | 4 | 1,885 | 28.0 | 16,807 | 26,587 |
| 16,384 | 1 | 1,911 | 36.9 | 9,791 | 13,120 |
| 16,384 | 2 | 1,926 | 26.1 | 16,765 | 23,033 |
| 16,384 | 4 | 1,934 | 16.5 | 27,144 | 39,372 |

The deployed multimodal admission profile was subsequently set to 32 images,
zero videos and a 1 GiB processor cache. A vision sanity request passed. These
limits do not change the text execution backends or fixed KV allocation.

## R27.0-B PMU128 production profile

Qualified on 2026-09-20 with image `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-b-pmu128-arm64-sm121` and model revision `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49`.

R27.0-B is a small Python overlay on R27.0-A. It retains the proven 1,024-token physical split-page geometry and adds a 128-token prefix match unit plus safe MTP final-cache-block retention. The OCI index digest is `sha256:388e0409067656e3f72e2cb23bdad0b2e0ba9d2bfa4daad723c9fa9a7afe920c`; the Linux ARM64 manifest is `sha256:54b740354fda0707a2c542df804af739dc59ac2b523b6aafc69200ff55d001af`.

An identical raw-completions prompt proved fine-grained cache reuse:

| Request | Prompt tokens | Cached tokens | Elapsed |
|---|---:|---:|---:|
| First/cold | 13,505 | 0 | 7.523 s |
| Identical second/warm | 13,505 | 13,440 | 0.289 s |

The second of two complete production sweeps is shown below. Both passed coherence and completed without CUDA, OOM, traceback, distributed, or cache-coordinator errors.

| Depth | Concurrency | PP total | TG total | TG/request | TTFR ms |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,809.53 | 30.98 | 30.98 | 3,571.36 |
| 4,096 | 2 | 1,738.99 | 29.94 | 19.75 | 5,557.75 |
| 4,096 | 4 | 1,746.73 | 29.38 | 11.97 | 9,393.23 |
| 8,192 | 1 | 1,863.31 | 31.55 | 31.55 | 5,671.48 |
| 8,192 | 2 | 1,794.76 | 25.38 | 19.29 | 8,941.67 |
| 8,192 | 4 | 1,749.72 | 21.21 | 10.26 | 14,716.68 |

### Latest matched R27.0-A versus R27.0-B run

This separate compact llama-benchy A/B used the same 2,048-token prefill sample, 128 generated tokens, depths, and concurrency levels for both images. TG values are total throughput across the active requests.

| Depth | C | A PP | B PP | A TG | B TG | A TTFT ms | B TTFT ms |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 1 | 1,833 | 1,638 | 32.5 | 33.5 | 1,287 | 1,415 |
| 0 | 2 | 1,568 | 1,746 | 43.2 | 49.9 | 2,098 | 2,359 |
| 0 | 4 | 1,731 | 1,656 | 50.4 | 54.3 | 3,400 | 4,136 |
| 4,096 | 1 | 1,856 | 1,765 | 31.8 | 33.8 | 3,479 | 3,647 |
| 4,096 | 2 | 1,764 | 1,710 | 29.6 | 42.8 | 5,353 | 6,789 |
| 4,096 | 4 | 1,760 | 1,724 | 30.5 | 32.3 | 9,118 | 10,708 |
| 8,192 | 1 | 1,866 | 1,799 | 32.9 | 35.4 | 5,658 | 5,857 |
| 8,192 | 2 | 1,807 | 1,767 | 24.4 | 30.7 | 8,676 | 9,929 |
| 8,192 | 4 | 1,759 | 1,738 | 21.3 | 23.1 | 14,923 | 16,049 |

R27.0-B improved total TG in every matched cell. The strongest concurrency changes were c2: 43.2 to 49.9 at d0, 29.6 to 42.8 at d4096, and 24.4 to 30.7 at d8192. PP and TTFT generally favored R27.0-A, apart from d0/c2 PP. R27.0-B is the selected production image because it combines the stronger decode result with finer repeated-agent prefix reuse.

## R27.0-A fused MTP baseline

Qualified on 2026-09-19 with image `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121` and non-Spark model revision `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49`.

R27.0-A backports the applicable runtime portion of upstream vLLM PR #57443 onto R26.4. Sparse-indexer metadata is built once and updated in place across fused MTP draft steps. The serving configuration remained unchanged: TP2/DCP1, MTP3, 1,047,552-token context, fixed 11,700 MiB FP8 KV cache per rank, split target page 1,024, four maximum sequences and 4,096 maximum batched tokens.

The published OCI index digest is `sha256:f1b6af40c1421204d8901a108a1ff712b58b085b8e1c8111ebc1be389fc9dbf3`; its Linux ARM64 manifest is `sha256:a62b9904bf47c34831aa746e170ee397e9f225699167a7b4116f3baf3ac9d9ae`.

All three sweeps passed coherence and completed without CUDA, OOM, traceback or service errors. Run 1 contained a noisy d4096/c1 prefill sample; runs 2 and 3 were clean warm repeats.

### Three-run results

| Depth | Concurrency | Run 1 PP | Run 2 PP | Run 3 PP | Run 1 TG | Run 2 TG | Run 3 TG |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,636.06 | 1,871.70 | 1,877.20 | 30.19 | 27.59 | 31.45 |
| 4,096 | 2 | 1,758.62 | 1,770.96 | 1,762.97 | 27.53 | 28.28 | 30.52 |
| 4,096 | 4 | 1,717.07 | 1,762.21 | 1,759.94 | 28.16 | 29.57 | 28.54 |
| 8,192 | 1 | 1,868.67 | 1,872.98 | 1,863.59 | 33.86 | 30.25 | 30.52 |
| 8,192 | 2 | 1,802.39 | 1,799.60 | 1,794.69 | 23.53 | 26.16 | 22.76 |
| 8,192 | 4 | 1,758.45 | 1,762.08 | 1,763.20 | 21.11 | 21.31 | 21.27 |

### Warm-run comparison with R26.4

The R27.0-A values below are the arithmetic mean of runs 2 and 3. The standing R26.4 reference used the same checkpoint, MTP3 depth, batch budget, context limit and cache geometry.

| Depth | Concurrency | R26.4 PP | R27.0-A PP | R26.4 TG | R27.0-A TG |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,857.03 | 1,874.45 | 27.91 | 29.52 |
| 4,096 | 2 | 1,749.94 | 1,766.97 | 26.15 | 29.40 |
| 4,096 | 4 | 1,759.26 | 1,761.08 | 26.68 | 29.06 |
| 8,192 | 1 | 1,867.49 | 1,868.29 | 27.36 | 30.39 |
| 8,192 | 2 | 1,791.68 | 1,797.15 | 24.15 | 24.46 |
| 8,192 | 4 | 1,796.45 | 1,762.64 | 19.65 | 21.29 |

R27.0-A improved warm-run TG in every cell. Prefill remained effectively level through d8192/c2 and was lower at d8192/c4. This profile is the new qualified baseline; R26.4 remains the rollback image.

## R26.3 production profile

Qualified on 2026-09-17 with image `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.3-minimal-arm64-sm121` and non-Spark model revision `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49`.

| Setting | Value |
|---|---|
| Model | `local-inference-lab/GLM-5.3-Flash-NVFP4` |
| Maximum context | 1,047,552 tokens |
| Fixed FP8 KV cache | 11,700 MiB per rank |
| Measured KV capacity | 1,074,109 tokens (1.03× maximum request) |
| Split target page | 1,024 tokens |
| Maximum sequences | 4 |
| Maximum batched tokens | 4,096 |
| Speculative decoding | MTP3 |
| Draft experts | Marlin MXFP8 |
| Vocabulary heads | NVFP4 draft; BF16 target verifier |
| Target backends | B12X attention, linear, MoE, and KDA prefill |
| Collectives | Local argmax reduction; RoCEnante up to 2 MiB |
| CUDA graphs | Full and piecewise capture |

All reported R26.3 runs passed the coherence check and completed without CUDA, OOM, or traceback errors.

### Long-context performance

Single-request run with a 2,048-token prompt-processing sample and 512 generated tokens.

| Depth | PP (tokens/s) | TG512 (tokens/s) | Peak TG (tokens/s) | TTFR (ms) |
|---:|---:|---:|---:|---:|
| 4,096 | 1,657.92 ± 78.56 | 29.77 ± 2.26 | 42.67 ± 1.25 | 3,525.13 ± 141.52 |
| 8,192 | 1,766.63 ± 21.32 | 30.85 ± 0.97 | 42.67 ± 2.49 | 5,310.22 ± 66.78 |
| 16,384 | 1,792.35 ± 178.22 | 26.80 ± 3.82 | 41.00 ± 2.45 | 9,368.27 ± 1,099.26 |
| 32,768 | 1,874.71 ± 1.40 | 28.09 ± 3.60 | 39.67 ± 2.62 | 16,795.57 ± 104.70 |
| 65,536 | 1,862.19 ± 0.28 | 27.23 ± 3.06 | 38.67 ± 4.11 | 32,366.90 ± 65.06 |
| 131,072 | 1,835.00 ± 1.42 | 27.93 ± 1.09 | 41.33 ± 1.70 | 64,663.42 ± 15.21 |
| 262,144 | 1,775.35 ± 1.30 | 38.04 ± 4.69 | 46.33 ± 1.70 | 132,001.31 ± 114.48 |
| 524,288 | 388.42 ± 0.60 | 28.95 ± 1.14 | 47.00 ± 5.66 | 1,201,452.71 ± 2,324.39 |

Prefill remained between 1,657.92 and 1,874.71 tokens/s through 262K depth. At 524K it fell to 388.42 tokens/s, so that result is treated as distinct long-context behavior rather than part of the shorter-depth average.

### Concurrency performance

Both runs used a 2,048-token prompt-processing sample at concurrency 1, 2, and 4. The only benchmark change was the requested generation length.

#### 512 generated tokens

| Depth | Concurrency | PP total (tokens/s) | TG total (tokens/s) | TG/request (tokens/s) | TTFR (ms) |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,869.30 ± 18.55 | 26.36 ± 3.98 | 26.36 ± 3.98 | 3,470.02 ± 32.46 |
| 4,096 | 2 | 1,772.59 ± 11.99 | 38.21 ± 0.60 | 20.89 ± 1.25 | 5,458.41 ± 1,503.98 |
| 4,096 | 4 | 1,766.78 ± 1.66 | 44.98 ± 3.45 | 13.52 ± 1.57 | 8,869.44 ± 3,823.61 |
| 8,192 | 1 | 1,845.96 ± 18.87 | 30.78 ± 1.39 | 30.78 ± 1.39 | 5,730.73 ± 57.13 |
| 8,192 | 2 | 1,808.67 ± 2.70 | 35.43 ± 2.84 | 20.45 ± 2.32 | 8,879.60 ± 2,443.67 |
| 8,192 | 4 | 1,765.40 ± 3.02 | 40.15 ± 1.97 | 12.81 ± 1.85 | 14,553.52 ± 6,202.62 |
| 16,384 | 1 | 1,874.34 ± 1.21 | 29.45 ± 1.04 | 29.45 ± 1.04 | 10,016.78 ± 6.34 |
| 16,384 | 2 | 1,790.21 ± 1.97 | 31.39 ± 1.62 | 19.87 ± 4.35 | 15,709.46 ± 4,882.54 |
| 16,384 | 4 | 1,766.36 ± 0.14 | 32.65 ± 0.26 | 11.95 ± 2.80 | 26,453.85 ± 11,567.27 |

#### 128 generated tokens

Date: 2026-09-18. The measured generation latency before the sweep was 217.50 ms.

```bash
uvx --refresh llama-benchy \
  --base-url http://HEAD_IP:8000/v1 \
  --depth 4096 8192 16384 \
  --latency-mode generation \
  --concurrency 1 2 4 \
  --tg 128 \
  --model local-inference-lab/GLM-5.3-Flash-NVFP4
```

| Depth | Concurrency | PP total (tokens/s) | TG total (tokens/s) | TG/request (tokens/s) | TTFR (ms) |
|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,898.20 ± 14.25 | 30.21 ± 1.95 | 30.21 ± 1.95 | 3,454.43 ± 24.42 |
| 4,096 | 2 | 1,766.26 ± 7.91 | 28.38 ± 0.47 | 19.38 ± 5.42 | 5,482.85 ± 1,501.62 |
| 4,096 | 4 | 1,768.19 ± 3.90 | 28.99 ± 0.62 | 11.92 ± 4.23 | 8,635.03 ± 3,905.91 |
| 8,192 | 1 | 1,879.95 ± 11.71 | 28.92 ± 2.21 | 28.92 ± 2.21 | 5,664.68 ± 33.79 |
| 8,192 | 2 | 1,806.21 ± 0.99 | 24.41 ± 0.78 | 18.13 ± 5.06 | 8,896.83 ± 2,441.78 |
| 8,192 | 4 | 1,762.06 ± 2.57 | 20.63 ± 0.65 | 9.89 ± 4.43 | 14,633.69 ± 6,220.29 |
| 16,384 | 1 | 1,877.83 ± 7.37 | 30.98 ± 2.15 | 30.98 ± 2.15 | 10,033.21 ± 38.61 |
| 16,384 | 2 | 1,792.28 ± 1.96 | 17.30 ± 0.14 | 17.42 ± 8.48 | 15,683.62 ± 4,884.46 |
| 16,384 | 4 | 1,763.86 ± 1.84 | 13.48 ± 0.15 | 8.54 ± 5.77 | 26,498.28 ± 11,579.98 |

Single-request TG128 and TG512 throughput was comparable. At concurrency 2 and 4, TG512 produced higher total throughput in every cell, with the gap increasing at longer context depth. This reflects generation length and scheduling duration rather than a server configuration difference.

### Spark versus non-Spark checkpoint

Both checkpoints used the same R26.3 image and configuration; only the model checkpoint changed.

| Depth | Concurrency | Spark PP | Non-Spark PP | Spark TG | Non-Spark TG | Spark TTFR (ms) | Non-Spark TTFR (ms) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,760.59 | 1,678.19 | 28.57 | 31.09 | 3,667.78 | 3,855.86 |
| 4,096 | 2 | 1,807.96 | 1,760.55 | 25.84 | 29.09 | 5,090.11 | 5,240.97 |
| 4,096 | 4 | 1,802.43 | 1,727.87 | 25.12 | 27.98 | 8,478.03 | 8,964.70 |
| 8,192 | 1 | 1,901.81 | 1,873.13 | 29.47 | 31.62 | 5,549.01 | 5,659.05 |
| 8,192 | 2 | 1,843.96 | 1,809.84 | 22.79 | 24.26 | 8,710.05 | 8,872.79 |
| 8,192 | 4 | 1,796.82 | 1,740.44 | 20.36 | 21.34 | 14,334.43 | 14,890.66 |
| **Average** | | **1,818.93** | **1,765.00** | **25.36** | **27.56** | | |

The non-Spark checkpoint generated faster in all six cells, while Spark retained higher prefill and lower TTFR. Non-Spark MTP acceptance was commonly 52–65%, with the third draft position frequently accepted 31–52%. Both coherence checks passed.

## R28.1 display-reserved KV qualification

Date: 2026-09-22. This run used the unchanged R28 model/kernel stack with the
R28.1 allocator layer, 1,047,552-token context, 11,840 MiB FP8 KV per rank,
MTP3, split-page 1024 and the standard 4,096 batched-token limit. The allocator
placed 1,792 MiB of the KV tensor in the headless display reservation on each
rank. Coherence, text input, image input and all 27 performance requests passed
without CUDA, OOM or allocator errors.

| Depth | Concurrency | PP total (tokens/s) | TG total (tokens/s) | TTFR (ms) |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,886.49 ± 5.58 | 35.44 ± 3.35 | 3,360.35 ± 9.63 |
| 4,096 | 2 | 1,797.91 ± 2.76 | 36.97 ± 1.87 | 6,073.26 ± 761.23 |
| 4,096 | 4 | 1,856.01 ± 3.68 | 31.60 ± 0.77 | 10,485.66 ± 3,040.23 |
| 8,192 | 1 | 1,917.64 ± 6.42 | 32.09 ± 4.88 | 5,443.43 ± 17.88 |
| 8,192 | 2 | 1,879.63 ± 2.45 | 32.80 ± 0.28 | 9,565.38 ± 1,330.43 |
| 8,192 | 4 | 1,912.74 ± 0.85 | 24.82 ± 0.17 | 16,037.72 ± 5,178.39 |
| 16,384 | 1 | 1,945.65 ± 2.74 | 33.86 ± 2.04 | 9,576.93 ± 13.35 |
| 16,384 | 2 | 1,915.43 ± 0.76 | 20.97 ± 0.21 | 15,824.99 ± 3,420.65 |
| 16,384 | 4 | 1,925.90 ± 0.31 | 15.24 ± 0.07 | 26,756.21 ± 9,952.09 |

The initial post-boot `tool-eval-bench --perf-only` run finished 27/27 requests
in 6:11 with a 0.0 error rate. Its d8192 prefill results were 1,870, 1,878 and
1,912 tokens/s at c1/c2/c4. The exact allocator and memory evidence is recorded
in [`display-kv-r28.1.md`](display-kv-r28.1.md).

### Latest agent and tool quality evaluation

The latest full `tool-eval-bench` run used
`tool-eval-bench v2.6.1.dev65+g6be685f0e`, the R28.1 vLLM engine
`0.1.dev1+g22476af54.d20260920`, and the 1,047,552-token production context.
It completed in 969.5 seconds.

| Measure | Result |
|---|---:|
| Overall score | **94 / 100** |
| Rating | **Excellent (5/5)** |
| Scenario points | 166 / 176 |
| Passed | 82 |
| Partial | 2 |
| Failed | 4 |
| Quality | 94 / 100 |
| Responsiveness | 15 / 100 |
| Median turn time | 9.6 s |
| Deployability (`0.7 × quality + 0.3 × responsiveness`) | 70 / 100 |
| Total token usage | 568,554 |
| Efficiency | 0.3 points / 1K tokens |

The weakest category was **M — Autonomous Planning** at 67%. The evaluator
reported one safety/ordering warning in TC-51 (Goal-Level Planning): the model
called `send_email` before observing the result of `create_calendar_event`.
This is retained as an actionable agent-orchestration limitation even though
the overall quality score was excellent.

## Historical image qualification

### R26.2 B12X isolation

Date: 2026-09-11. All arms used the same model revision, 512K context, four maximum sequences, MTP3, BF16 draft head, 4,096 maximum batched tokens, and 512-token split pages.

| Case | R26.1 PP | B12X #353/#354 PP | Qualified R26.2 PP | R26.1 TG | B12X #353/#354 TG | Qualified R26.2 TG |
|---|---:|---:|---:|---:|---:|---:|
| 4,096 c1 | 1,693.46 | 1,293.33 | 1,693.10 | 27.62 | 26.59 | 28.57 |
| 4,096 c2 | 1,730.13 | 1,288.57 | 1,667.77 | 26.91 | 23.31 | 24.95 |
| 4,096 c4 | 1,727.59 | 1,304.26 | 1,750.94 | 26.46 | 23.18 | 26.95 |
| 8,192 c1 | 1,842.90 | 1,366.90 | 1,856.59 | 24.80 | 29.07 | 27.67 |
| 8,192 c2 | 1,775.23 | 1,327.58 | 1,801.05 | 23.27 | 19.60 | 23.82 |
| 8,192 c4 | 1,806.12 | 1,346.29 | 1,826.47 | 20.65 | 17.02 | 21.11 |

Restoring the R26.1 B12X package recovered 379–490 prefill tokens/s relative to the B12X #353/#354 arm. The qualified R26.2 image retained vLLM #665, #701, #706, and #715 while excluding vLLM #727 and B12X #353/#354.

### R26.3 patch qualification

On 2026-09-16, the R26.3 candidate added vLLM #767/#769 and B12X #362 to the qualified R26.2 image. The model and serving configuration were unchanged. Both R26.3 sweeps passed coherence and completed without runtime errors.

| Case | R26.2 PP | R26.3 PP run 1 | R26.3 PP run 2 | R26.2 TG | R26.3 TG run 1 | R26.3 TG run 2 |
|---|---:|---:|---:|---:|---:|---:|
| 4,096 c1 | 1,857.03 | 1,680.59 | 1,857.65 | 27.91 | 25.13 | 26.49 |
| 4,096 c2 | 1,749.94 | 1,739.94 | 1,712.27 | 26.15 | 26.51 | 25.34 |
| 4,096 c4 | 1,759.26 | 1,724.75 | 1,755.87 | 26.68 | 27.19 | 24.31 |
| 8,192 c1 | 1,867.49 | 1,834.96 | 1,855.45 | 27.36 | 25.31 | 29.21 |
| 8,192 c2 | 1,791.68 | 1,764.13 | 1,761.08 | 24.15 | 23.51 | 22.91 |
| 8,192 c4 | 1,796.45 | 1,807.45 | 1,792.02 | 19.65 | 18.66 | 19.99 |

The warm R26.3 run roughly matched R26.2 prefill. Generation was mixed and lower in four of six cells, so vLLM #769 was compatible on TP2 GB10 but did not demonstrate an end-to-end speed gain. The candidate retained the vLLM #767 tool-truncation and B12X #362 MXFP8 bounds fixes.

## Tool-use quality

The qualified R26.2 deployment was evaluated with `tool-eval-bench 2.6.1.dev65+g6be685f0e`. The server reported vLLM `0.26.1rc0+jj.glm53.r26.universal.arm64.sm121.cu132.20260905` and 524,288-token maximum context.

| Metric | Result |
|---|---:|
| Overall quality score | 93 / 100 |
| Rating | 5 / 5 |
| Passed / partial / failed | 80 / 3 / 5 |
| Points | 163 / 176 |
| Median turn time | 5.7 s |
| Responsiveness score | 28 / 100 |
| Deployability score | 74 / 100 |
| Weakest category | G Structured Reasoning (67%) |

The deployability score is `0.7 × quality + 0.3 × responsiveness`. Tool quality has not yet been rerun on the final R26.3 production profile.
