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

## Result

Restoring the exact R26.1 B12X package recovered 379–490 total prefill tokens/s relative to the R26.2 BF16 arm. The qualified image retains vLLM #665, #701, #706, and #715 while excluding vLLM #727 and B12X #353/#354. It matched or exceeded R26.1 prefill in four of six cells and generation in five of six cells.
