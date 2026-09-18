# Benchmark results

This document keeps the qualified production measurements and the historical comparisons that explain the selected image and model. Unless stated otherwise, performance tests used `llama-benchy 0.4.0` from a separate RTX client. PP is total prompt-processing throughput, TG is generation throughput, and TTFR is time to first response.

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
