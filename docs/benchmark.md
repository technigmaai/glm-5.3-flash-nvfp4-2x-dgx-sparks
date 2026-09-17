# R26.2 quality isolation benchmark

Date: 2026-09-11

The test was run with llama-benchy 0.4.0 from a separate RTX client. All arms used the same GLM-5.3-Flash-NVFP4 revision, 512K maximum context, four maximum sequences, MTP3, BF16 draft head, 4,096 maximum batched tokens, and 512-token split pages. Every coherence check passed.

```bash
uvx --refresh llama-benchy \
  --base-url http://HEAD_IP:8000/v1 \
  --depth 4096 8192 \
  --latency-mode generation \
  --concurrency 1 2 4 \
  --tg 128 \
  --model local-inference-lab/GLM-5.3-Flash-NVFP4
```

## Prefill throughput

Total prompt-processing tokens per second.

| Depth | Concurrency | R26.1 BF16 | R26.2 with B12X #353/#354, BF16 | Qualified R26.2 quality |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,693.46 | 1,293.33 | 1,693.10 |
| 4,096 | 2 | 1,730.13 | 1,288.57 | 1,667.77 |
| 4,096 | 4 | 1,727.59 | 1,304.26 | 1,750.94 |
| 8,192 | 1 | 1,842.90 | 1,366.90 | 1,856.59 |
| 8,192 | 2 | 1,775.23 | 1,327.58 | 1,801.05 |
| 8,192 | 4 | 1,806.12 | 1,346.29 | 1,826.47 |

## Generation throughput

Total generation tokens per second.

| Depth | Concurrency | R26.1 BF16 | R26.2 with B12X #353/#354, BF16 | Qualified R26.2 quality |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 27.62 | 26.59 | 28.57 |
| 4,096 | 2 | 26.91 | 23.31 | 24.95 |
| 4,096 | 4 | 26.46 | 23.18 | 26.95 |
| 8,192 | 1 | 24.80 | 29.07 | 27.67 |
| 8,192 | 2 | 23.27 | 19.60 | 23.82 |
| 8,192 | 4 | 20.65 | 17.02 | 21.11 |

## Production verification runs

These results were collected from the qualified R26.2 quality deployment. The first run measures one request at progressively larger context depths.

| Model | Test | t/s | Peak t/s | TTFR (ms) | Estimated PPT (ms) | E2E TTFT (ms) |
|---|---:|---:|---:|---:|---:|---:|
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d4096 | 1857.22 ± 2.62 | | 3533.89 ± 4.67 | 3308.17 ± 4.67 | 3533.89 ± 4.67 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d4096 | 26.10 ± 1.69 | 32.67 ± 1.25 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d8192 | 1859.57 ± 2.61 | | 5732.39 ± 7.72 | 5506.66 ± 7.72 | 5732.39 ± 7.72 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d8192 | 31.15 ± 3.60 | 37.00 ± 1.41 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 | 1865.72 ± 5.26 | | 10105.11 ± 27.80 | 9879.38 ± 27.80 | 10105.11 ± 27.80 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d16384 | 27.65 ± 0.55 | 35.67 ± 1.25 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d32768 | 1856.12 ± 0.76 | | 18983.09 ± 7.71 | 18757.37 ± 7.71 | 19004.90 ± 25.24 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d32768 | 24.39 ± 5.25 | 31.45 ± 7.89 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d65536 | 1835.26 ± 2.26 | | 37051.08 ± 45.25 | 36825.36 ± 45.25 | 37068.98 ± 65.55 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d65536 | 27.94 ± 5.87 | 34.33 ± 4.50 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d131072 | 1808.52 ± 1.43 | | 73832.76 ± 58.39 | 73607.04 ± 58.39 | 73834.79 ± 57.05 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d131072 | 23.07 ± 3.56 | 29.67 ± 3.30 | | | |

The second run measures concurrency 1, 2, and 4 at 4K and 8K depth.

| Model | Test | t/s total | t/s per request | Peak t/s | Peak t/s per request | TTFR (ms) | Estimated PPT (ms) | E2E TTFT (ms) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d4096 (c1) | 1857.03 ± 19.30 | 1857.03 ± 19.30 | | | 3511.93 ± 34.16 | 3308.87 ± 34.16 | 3511.93 ± 34.16 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d4096 (c1) | 27.91 ± 2.05 | 27.91 ± 2.05 | 34.33 ± 1.70 | 34.33 ± 1.70 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d4096 (c2) | 1749.94 ± 10.43 | 1332.33 ± 451.07 | | | 5375.82 ± 1671.13 | 5172.76 ± 1671.13 | 5375.82 ± 1671.13 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d4096 (c2) | 26.15 ± 3.22 | 16.75 ± 4.52 | 54.33 ± 8.73 | 29.00 ± 3.16 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d4096 (c4) | 1759.26 ± 32.96 | 897.44 ± 516.41 | | | 9079.82 ± 3799.47 | 8876.76 ± 3799.47 | 9414.51 ± 3391.81 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d4096 (c4) | 26.68 ± 1.74 | 10.23 ± 2.66 | 67.33 ± 7.36 | 21.25 ± 2.95 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d8192 (c1) | 1867.49 ± 14.29 | 1867.49 ± 14.29 | | | 5686.67 ± 42.09 | 5483.61 ± 42.09 | 5686.67 ± 42.09 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d8192 (c1) | 27.36 ± 1.00 | 27.36 ± 1.00 | 34.00 ± 1.63 | 34.00 ± 1.63 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d8192 (c2) | 1791.68 ± 2.69 | 1270.07 ± 358.06 | | | 8961.61 ± 2468.98 | 8758.56 ± 2468.98 | 8961.61 ± 2468.98 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d8192 (c2) | 24.15 ± 0.20 | 17.64 ± 5.12 | 55.33 ± 4.19 | 30.50 ± 2.06 | | | |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d8192 (c4) | 1796.45 ± 17.23 | 857.08 ± 449.31 | | | 15191.66 ± 6132.97 | 14988.60 ± 6132.97 | 15191.66 ± 6132.97 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | tg128 @ d8192 (c4) | 19.65 ± 0.73 | 9.54 ± 3.80 | 72.33 ± 3.40 | 21.42 ± 1.75 | | | |

## Tool-use quality benchmark

The qualified deployment was also evaluated with `tool-eval-bench 2.6.1.dev65+g6be685f0e`. The server reported vLLM `0.26.1rc0+jj.glm53.r26.universal.arm64.sm121.cu132.20260905` and a 524,288-token maximum context.

| Metric | Result |
|---|---:|
| Overall quality score | 93 / 100 |
| Rating | 5 / 5 |
| Scenarios passed | 80 |
| Scenarios partially passed | 3 |
| Scenarios failed | 5 |
| Points | 163 / 176 |
| Responsiveness score | 28 / 100 |
| Median turn time | 5.7 s |
| Deployability score (`0.7 × quality + 0.3 × responsiveness`) | 74 / 100 |
| Weakest category | G Structured Reasoning (67%) |
| Total benchmark time | 2,292.0 s |
| Total token usage | 578,722 |
| Token efficiency | 0.3 points / 1K tokens |

Each scenario awards two points for a pass, one for a partial result, and zero for a failure. The quality score is the earned-point percentage. The responsiveness score follows the benchmark's logistic latency curve.

## R26.3 minimal candidate

On 2026-09-16, the R26.3 minimal candidate added vLLM #767/#769 and B12X #362 to the qualified R26.2 quality image. It retained the same model revision and serving configuration. Two full llama-benchy sweeps passed coherence and completed without runtime errors.

| Case | R26.2 production PP | R26.3 PP run 1 | R26.3 PP run 2 | R26.2 production TG | R26.3 TG run 1 | R26.3 TG run 2 |
|---|---:|---:|---:|---:|---:|---:|
| 4096 c1 | 1857.03 | 1680.59 | 1857.65 | 27.91 | 25.13 | 26.49 |
| 4096 c2 | 1749.94 | 1739.94 | 1712.27 | 26.15 | 26.51 | 25.34 |
| 4096 c4 | 1759.26 | 1724.75 | 1755.87 | 26.68 | 27.19 | 24.31 |
| 8192 c1 | 1867.49 | 1834.96 | 1855.45 | 27.36 | 25.31 | 29.21 |
| 8192 c2 | 1791.68 | 1764.13 | 1761.08 | 24.15 | 23.51 | 22.91 |
| 8192 c4 | 1796.45 | 1807.45 | 1792.02 | 19.65 | 18.66 | 19.99 |

The warm R26.3 run roughly matched R26.2 prefill, but generation was mixed and lower in four of six cells. vLLM #769 is therefore compatible on TP2 GB10 but is not a demonstrated end-to-end speed improvement for this deployment. The candidate remains valuable for the vLLM #767 tool-truncation and B12X #362 MXFP8 bounds fixes.

## Result

Restoring the exact R26.1 B12X package recovered 379–490 total prefill tokens/s relative to the R26.2 BF16 arm. The qualified image retains vLLM #665, #701, #706, and #715 while excluding vLLM #727 and B12X #353/#354. It matched or exceeded R26.1 prefill in four of six cells and generation in five of six cells.

## R26.3 one-million-context production profile

On 2026-09-17, the current non-Spark revision `175ae8ce3b5af842b0d0140dbeb43e9cfc557c49` was qualified with the following profile:

- maximum context: 1,047,552 tokens
- fixed FP8 KV cache: 11,700 MiB per rank
- measured KV capacity: 1,074,109 tokens, 1.03× the maximum request
- 1,024-token split target pages
- four maximum sequences and 4,096 maximum batched tokens
- MTP3 with Marlin MXFP8 draft experts
- draft-only NVFP4 vocabulary head; BF16 target verifier vocabulary head
- local argmax reduction and RoCEnante custom collectives up to 2 MiB
- B12X target attention, linear, MoE and KDA prefill
- full and piecewise CUDA graph capture

The Spark and non-Spark arms used the same R26.3 image and configuration. Only the model checkpoint changed.

| Depth | Concurrency | Spark PP | Non-Spark PP | Spark TG | Non-Spark TG | Spark TTFR ms | Non-Spark TTFR ms |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,760.59 | 1,678.19 | 28.57 | 31.09 | 3,667.78 | 3,855.86 |
| 4,096 | 2 | 1,807.96 | 1,760.55 | 25.84 | 29.09 | 5,090.11 | 5,240.97 |
| 4,096 | 4 | 1,802.43 | 1,727.87 | 25.12 | 27.98 | 8,478.03 | 8,964.70 |
| 8,192 | 1 | 1,901.81 | 1,873.13 | 29.47 | 31.62 | 5,549.01 | 5,659.05 |
| 8,192 | 2 | 1,843.96 | 1,809.84 | 22.79 | 24.26 | 8,710.05 | 8,872.79 |
| 8,192 | 4 | 1,796.82 | 1,740.44 | 20.36 | 21.34 | 14,334.43 | 14,890.66 |
| Average | | 1,818.93 | 1,765.00 | 25.36 | 27.56 | | |

The non-Spark checkpoint generated faster in all six cells. Spark retained higher prefill and lower TTFR. Non-Spark MTP draft acceptance was commonly 52–65%, with the third draft position frequently accepted 31–52%; this made MTP3 materially more effective for decode than on the Spark checkpoint. Both coherence checks passed and neither arm produced CUDA, OOM, traceback or service errors.
