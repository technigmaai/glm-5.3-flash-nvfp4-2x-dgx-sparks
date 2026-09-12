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

## Result

Restoring the exact R26.1 B12X package recovered 379–490 total prefill tokens/s relative to the R26.2 BF16 arm. The qualified image retains vLLM #665, #701, #706, and #715 while excluding vLLM #727 and B12X #353/#354. It matched or exceeded R26.1 prefill in four of six cells and generation in five of six cells.
