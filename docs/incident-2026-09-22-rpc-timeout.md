# September 22, 2026 distributed RPC timeout

The R28 TP2 service stopped at 11:10 CEST while processing one request with
97,080 computed prompt tokens and 513 generated tokens. KV usage was 11.08%,
with one running request and no waiting requests.

The first failure marker was a 60-second wait for a shared-memory broadcast
block. The engine then raised `TimeoutError: RPC call to sample_tokens timed
out`, shut down the API head, and left the remote rank running. The head
container exited with code 0 and `OOMKilled=false`.

No NVIDIA Xid, Linux OOM, RoCE link-down, CRC, CQE, WQE, or packet-discard
event was found. Both 200 Gb/s RoCE links remained active. The orphaned worker
held 119 of 121 GiB RAM and 3.9 GiB swap; approximately 3.77 GiB of that swap
belonged to vLLM processes. Memory pressure is therefore the leading cause of
the rank stall, although an internal vLLM/B12X deadlock cannot be excluded.

## Recovery and preventive changes

- Stopped both ranks and released the orphaned worker.
- Set `vm.swappiness=10` immediately and persistently on both nodes.
- Reduced `MM_PROCESSOR_CACHE_GB` from 2 to 1 while retaining 32 images and
  disabling video.
- Reduced fixed KV from 11,900 MiB to 11,840 MiB. This provides 1,049,451 KV
  tokens for a 1,047,552-token maximum sequence and reports 1.00x maximum
  context concurrency.
- Added a head-node watchdog. Three failed one-minute checks trigger a
  coordinated worker/head shutdown followed by the normal worker-first start.
  A 15-minute boot grace and 15-minute restart cooldown prevent restart loops.
- Prohibited builds, image pushes, model downloads, and compression work on
  the serving nodes while the deployment is live.

The first 11,820 MiB KV attempt was one 1,024-token page short and correctly
failed startup validation with an estimated maximum length of 1,046,528. It
was replaced by the validated 11,840 MiB setting.

## Validation

After the corrected 6m20s startup:

- Health endpoint returned HTTP 200.
- Text completion returned `OK` with HTTP 200.
- A data-URL image request returned HTTP 200 and recorded 16 image tokens,
  confirming that vision remained active.
- RoCEnante, B12X target/KDA, Marlin MTP3, and the pinned R28 image remained
  selected.
- The watchdog reported enabled/healthy with state `0 0`.

The settled measurement after ten minutes remained tight:

| Node | RAM used | Available | Swap used | vLLM swap |
|---|---:|---:|---:|---:|
| gx10 | 120 GiB | 1.61 GiB | 6.19 GiB | 4,626,296 KiB |
| gx10-2 | 120 GiB | 1.67 GiB | 2.90 GiB | 2,436,652 KiB |

The changes improve behavior and automate recovery but do not eliminate memory
pressure. Preserving materially more headroom while retaining the full context
would require a separately qualified DCP2 configuration. Reducing maximum
context and fixed KV remains the conservative fallback.
