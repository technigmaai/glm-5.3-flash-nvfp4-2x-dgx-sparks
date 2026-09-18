# Benchmark results

## R26.2 quality isolation benchmark

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

### Prefill throughput

Total prompt-processing tokens per second.

| Depth | Concurrency | R26.1 BF16 | R26.2 with B12X #353/#354, BF16 | Qualified R26.2 quality |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,693.46 | 1,293.33 | 1,693.10 |
| 4,096 | 2 | 1,730.13 | 1,288.57 | 1,667.77 |
| 4,096 | 4 | 1,727.59 | 1,304.26 | 1,750.94 |
| 8,192 | 1 | 1,842.90 | 1,366.90 | 1,856.59 |
| 8,192 | 2 | 1,775.23 | 1,327.58 | 1,801.05 |
| 8,192 | 4 | 1,806.12 | 1,346.29 | 1,826.47 |

### Generation throughput

Total generation tokens per second.

| Depth | Concurrency | R26.1 BF16 | R26.2 with B12X #353/#354, BF16 | Qualified R26.2 quality |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 27.62 | 26.59 | 28.57 |
| 4,096 | 2 | 26.91 | 23.31 | 24.95 |
| 4,096 | 4 | 26.46 | 23.18 | 26.95 |
| 8,192 | 1 | 24.80 | 29.07 | 27.67 |
| 8,192 | 2 | 23.27 | 19.60 | 23.82 |
| 8,192 | 4 | 20.65 | 17.02 | 21.11 |

### Production verification runs

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

### Tool-use quality benchmark

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

### Qualification result

Restoring the exact R26.1 B12X package recovered 379–490 total prefill tokens/s relative to the R26.2 BF16 arm. The qualified image retains vLLM #665, #701, #706, and #715 while excluding vLLM #727 and B12X #353/#354. It matched or exceeded R26.1 prefill in four of six cells and generation in five of six cells.

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

### Matched Spark and non-Spark comparison

The Spark and non-Spark arms used the same R26.3 image and configuration. Only the model checkpoint changed.

| Depth | Concurrency | Spark PP | Non-Spark PP | Spark TG | Non-Spark TG | Spark TTFR (ms) | Non-Spark TTFR (ms) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4,096 | 1 | 1,760.59 | 1,678.19 | 28.57 | 31.09 | 3,667.78 | 3,855.86 |
| 4,096 | 2 | 1,807.96 | 1,760.55 | 25.84 | 29.09 | 5,090.11 | 5,240.97 |
| 4,096 | 4 | 1,802.43 | 1,727.87 | 25.12 | 27.98 | 8,478.03 | 8,964.70 |
| 8,192 | 1 | 1,901.81 | 1,873.13 | 29.47 | 31.62 | 5,549.01 | 5,659.05 |
| 8,192 | 2 | 1,843.96 | 1,809.84 | 22.79 | 24.26 | 8,710.05 | 8,872.79 |
| 8,192 | 4 | 1,796.82 | 1,740.44 | 20.36 | 21.34 | 14,334.43 | 14,890.66 |
| **Average** | | **1,818.93** | **1,765.00** | **25.36** | **27.56** | | |

The non-Spark checkpoint generated faster in all six cells. Spark retained higher prefill and lower TTFR. Non-Spark MTP draft acceptance was commonly 52–65%, with the third draft position frequently accepted 31–52%; this made MTP3 materially more effective for decode than on the Spark checkpoint. Both coherence checks passed and neither arm produced CUDA, OOM, traceback or service errors.

### Non-Spark long-context run

These results were collected from the qualified R26.3 non-Spark deployment. This run measures one request at progressively larger context depths, using a 2,048-token prompt-processing sample and 512 generated tokens.

| model                                      |             test |              t/s |     peak t/s |            ttfr (ms) |         est_ppt (ms) |        e2e_ttft (ms) |
|:-------------------------------------------|-----------------:|-----------------:|-------------:|---------------------:|---------------------:|---------------------:|
| local-inference-lab/GLM-5.3-Flash-NVFP4    |   pp2048 @ d4096 |  1657.92 ± 78.56 |              |     3525.13 ± 141.52 |     3339.37 ± 141.52 |     3525.13 ± 141.52 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |    tg512 @ d4096 |     29.77 ± 2.26 | 42.67 ± 1.25 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |   pp2048 @ d8192 |  1766.63 ± 21.32 |              |      5310.22 ± 66.78 |      5124.46 ± 66.78 |      5310.22 ± 66.78 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |    tg512 @ d8192 |     30.85 ± 0.97 | 42.67 ± 2.49 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |  pp2048 @ d16384 | 1792.35 ± 178.22 |              |    9368.27 ± 1099.26 |    9182.51 ± 1099.26 |    9386.94 ± 1125.65 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |   tg512 @ d16384 |     26.80 ± 3.82 | 41.00 ± 2.45 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |  pp2048 @ d32768 |   1874.71 ± 1.40 |              |    16795.57 ± 104.70 |    16609.82 ± 104.70 |    16813.21 ± 122.06 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |   tg512 @ d32768 |     28.09 ± 3.60 | 39.67 ± 2.62 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |  pp2048 @ d65536 |   1862.19 ± 0.28 |              |     32366.90 ± 65.06 |     32181.14 ± 65.06 |    32440.13 ± 141.73 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |   tg512 @ d65536 |     27.23 ± 3.06 | 38.67 ± 4.11 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    | pp2048 @ d131072 |   1835.00 ± 1.42 |              |     64663.42 ± 15.21 |     64477.66 ± 15.21 |     64663.42 ± 15.21 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |  tg512 @ d131072 |     27.93 ± 1.09 | 41.33 ± 1.70 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    | pp2048 @ d262144 |   1775.35 ± 1.30 |              |   132001.31 ± 114.48 |   131815.55 ± 114.48 |   132001.31 ± 114.48 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |  tg512 @ d262144 |     38.04 ± 4.69 | 46.33 ± 1.70 |                      |                      |                      |
| local-inference-lab/GLM-5.3-Flash-NVFP4    | pp2048 @ d524288 |    388.42 ± 0.60 |              | 1201452.71 ± 2324.39 | 1201266.95 ± 2324.39 | 1201452.71 ± 2324.39 |
| local-inference-lab/GLM-5.3-Flash-NVFP4    |  tg512 @ d524288 |     28.95 ± 1.14 | 47.00 ± 5.66 |                      |                      |                      |

Prefill remained between 1,657.92 and 1,874.71 tokens/s through 262K depth, then fell to 388.42 tokens/s at 524K. Generation stayed between 26.80 and 38.04 tokens/s across the tested depths. The 524K prefill result should be treated as a distinct long-context behavior rather than combined with the shorter-depth average.

### Non-Spark concurrency run (TG512)

This run measures concurrency 1, 2, and 4 at 4K, 8K, and 16K depth, using a 2,048-token prompt-processing sample and 512 generated tokens.

| model                                   |                 test |     t/s (total) |        t/s (req) |     peak t/s |   peak t/s (req) |           ttfr (ms) |        est_ppt (ms) |       e2e_ttft (ms) |
|:----------------------------------------|---------------------:|----------------:|-----------------:|-------------:|-----------------:|--------------------:|--------------------:|--------------------:|
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d4096 (c1) | 1869.30 ± 18.55 |  1869.30 ± 18.55 |              |                  |     3470.02 ± 32.46 |     3287.12 ± 32.46 |     3506.71 ± 22.35 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg512 @ d4096 (c1) |    26.36 ± 3.98 |     26.36 ± 3.98 | 37.67 ± 5.79 |     37.67 ± 5.79 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d4096 (c2) | 1772.59 ± 11.99 | 1274.10 ± 389.34 |              |                  |   5458.41 ± 1503.98 |   5275.51 ± 1503.98 |   5458.41 ± 1503.98 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg512 @ d4096 (c2) |    38.21 ± 0.60 |     20.89 ± 1.25 | 64.67 ± 2.05 |     33.17 ± 1.21 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d4096 (c4) |  1766.78 ± 1.66 |  918.14 ± 518.09 |              |                  |   8869.44 ± 3823.61 |   8686.54 ± 3823.61 |   9010.34 ± 3646.89 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg512 @ d4096 (c4) |    44.98 ± 3.45 |     13.52 ± 1.57 | 82.00 ± 7.79 |     24.08 ± 0.76 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d8192 (c1) | 1845.96 ± 18.87 |  1845.96 ± 18.87 |              |                  |     5730.73 ± 57.13 |     5547.83 ± 57.13 |     5730.73 ± 57.13 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg512 @ d8192 (c1) |    30.78 ± 1.39 |     30.78 ± 1.39 | 44.00 ± 0.00 |     44.00 ± 0.00 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d8192 (c2) |  1808.67 ± 2.70 | 1278.39 ± 359.21 |              |                  |   8879.60 ± 2443.67 |   8696.69 ± 2443.67 |   8879.60 ± 2443.67 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg512 @ d8192 (c2) |    35.43 ± 2.84 |     20.45 ± 2.32 | 60.33 ± 5.19 |     34.33 ± 1.49 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d8192 (c4) |  1765.40 ± 3.02 |  896.58 ± 457.35 |              |                  |  14553.52 ± 6202.62 |  14370.61 ± 6202.62 |  14712.28 ± 6047.03 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg512 @ d8192 (c4) |    40.15 ± 1.97 |     12.81 ± 1.85 | 82.67 ± 5.56 |     24.75 ± 1.42 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 (c1) |  1874.34 ± 1.21 |   1874.34 ± 1.21 |              |                  |     10016.78 ± 6.34 |      9833.88 ± 6.34 |     10016.78 ± 6.34 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  tg512 @ d16384 (c1) |    29.45 ± 1.04 |     29.45 ± 1.04 | 41.67 ± 2.36 |     41.67 ± 2.36 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 (c2) |  1790.21 ± 1.97 | 1317.40 ± 414.27 |              |                  |  15709.46 ± 4882.54 |  15526.55 ± 4882.54 |  15709.46 ± 4882.54 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  tg512 @ d16384 (c2) |    31.39 ± 1.62 |     19.87 ± 4.35 | 62.00 ± 0.82 |     32.67 ± 1.25 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 (c4) |  1766.36 ± 0.14 |  908.16 ± 503.22 |              |                  | 26453.85 ± 11567.27 | 26270.95 ± 11567.27 | 26453.85 ± 11567.27 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  tg512 @ d16384 (c4) |    32.65 ± 0.26 |     11.95 ± 2.80 | 85.67 ± 2.62 |     25.75 ± 2.35 |                     |                     |                     |

### Non-Spark concurrency run (TG128)

Date: 2026-09-18

This repeat uses the same deployment, prompt-processing sample, depths, and concurrency levels as the TG512 run, with generation shortened to 128 tokens.

```bash
uvx --refresh llama-benchy \
  --base-url http://HEAD_IP:8000/v1 \
  --depth 4096 8192 16384 \
  --latency-mode generation \
  --concurrency 1 2 4 \
  --tg 128 \
  --model local-inference-lab/GLM-5.3-Flash-NVFP4
```

The coherence test passed. The measured generation latency before the sweep was 217.50 ms.

| model                                   |                 test |     t/s (total) |        t/s (req) |     peak t/s |   peak t/s (req) |           ttfr (ms) |        est_ppt (ms) |       e2e_ttft (ms) |
|:----------------------------------------|---------------------:|----------------:|-----------------:|-------------:|-----------------:|--------------------:|--------------------:|--------------------:|
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d4096 (c1) | 1898.20 ± 14.25 |  1898.20 ± 14.25 |              |                  |     3454.43 ± 24.42 |     3236.93 ± 24.42 |     3454.43 ± 24.42 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg128 @ d4096 (c1) |    30.21 ± 1.95 |     30.21 ± 1.95 | 38.33 ± 2.49 |     38.33 ± 2.49 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d4096 (c2) |  1766.26 ± 7.91 | 1276.15 ± 388.10 |              |                  |   5482.85 ± 1501.62 |   5265.34 ± 1501.62 |   5482.85 ± 1501.62 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg128 @ d4096 (c2) |    28.38 ± 0.47 |     19.38 ± 5.42 | 55.00 ± 4.32 |     29.17 ± 1.95 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d4096 (c4) |  1768.19 ± 3.90 |  975.00 ± 572.53 |              |                  |   8635.03 ± 3905.91 |   8417.53 ± 3905.91 |   8635.03 ± 3905.91 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg128 @ d4096 (c4) |    28.99 ± 0.62 |     11.92 ± 4.23 | 89.67 ± 6.34 |     24.50 ± 0.65 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d8192 (c1) | 1879.95 ± 11.71 |  1879.95 ± 11.71 |              |                  |     5664.68 ± 33.79 |     5447.18 ± 33.79 |     5699.87 ± 16.39 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg128 @ d8192 (c1) |    28.92 ± 2.21 |     28.92 ± 2.21 | 36.00 ± 1.41 |     36.00 ± 1.41 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d8192 (c2) |  1806.21 ± 0.99 | 1281.22 ± 360.45 |              |                  |   8896.83 ± 2441.78 |   8679.32 ± 2441.78 |   8896.83 ± 2441.78 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg128 @ d8192 (c2) |    24.41 ± 0.78 |     18.13 ± 5.06 | 60.00 ± 2.83 |     31.67 ± 1.60 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  pp2048 @ d8192 (c4) |  1762.06 ± 2.57 |  893.73 ± 455.93 |              |                  |  14633.69 ± 6220.29 |  14416.19 ± 6220.29 |  14920.55 ± 6242.42 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |   tg128 @ d8192 (c4) |    20.63 ± 0.65 |      9.89 ± 4.43 | 80.00 ± 6.68 |     23.25 ± 1.23 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 (c1) |  1877.83 ± 7.37 |   1877.83 ± 7.37 |              |                  |    10033.21 ± 38.61 |     9815.71 ± 38.61 |    10033.21 ± 38.61 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  tg128 @ d16384 (c1) |    30.98 ± 2.15 |     30.98 ± 2.15 | 41.33 ± 2.87 |     41.33 ± 2.87 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 (c2) |  1792.28 ± 1.96 | 1323.80 ± 418.08 |              |                  |  15683.62 ± 4884.46 |  15466.12 ± 4884.46 |  15683.62 ± 4884.46 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  tg128 @ d16384 (c2) |    17.30 ± 0.14 |     17.42 ± 8.48 | 60.00 ± 4.08 |     32.17 ± 1.95 |                     |                     |                     |
| local-inference-lab/GLM-5.3-Flash-NVFP4 | pp2048 @ d16384 (c4) |  1763.86 ± 1.84 |  908.39 ± 504.13 |              |                  | 26498.28 ± 11579.98 | 26280.78 ± 11579.98 | 26791.70 ± 11195.05 |
| local-inference-lab/GLM-5.3-Flash-NVFP4 |  tg128 @ d16384 (c4) |    13.48 ± 0.15 |      8.54 ± 5.77 | 79.33 ± 8.99 |     23.83 ± 1.52 |                     |                     |                     |

### TG128 versus TG512

Total generation throughput in tokens/s:

| Depth | Concurrency | TG128 | TG512 | Difference (TG128 − TG512) |
|---:|---:|---:|---:|---:|
| 4,096 | 1 | 30.21 | 26.36 | +3.85 |
| 4,096 | 2 | 28.38 | 38.21 | −9.83 |
| 4,096 | 4 | 28.99 | 44.98 | −15.99 |
| 8,192 | 1 | 28.92 | 30.78 | −1.86 |
| 8,192 | 2 | 24.41 | 35.43 | −11.02 |
| 8,192 | 4 | 20.63 | 40.15 | −19.52 |
| 16,384 | 1 | 30.98 | 29.45 | +1.53 |
| 16,384 | 2 | 17.30 | 31.39 | −14.09 |
| 16,384 | 4 | 13.48 | 32.65 | −19.17 |

Single-request TG128 and TG512 throughput was comparable: each generation length led in some cells. With concurrency 2 and 4, TG512 produced higher total throughput in every cell, with the gap increasing at longer context depth. Because the deployment was unchanged, this comparison measures the effect of benchmark generation length and scheduling duration rather than a server configuration change.
