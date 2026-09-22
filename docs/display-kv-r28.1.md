# R28.1 headless display-reserved KV

R28.1 uses 1.75 GiB of the GB10 firmware display reservation on each headless
DGX Spark as the suffix of vLLM's contiguous KV buffer. The qualified 11,840
MiB logical cache is therefore backed by 10,040 MiB of ordinary unified memory
plus 1,792 MiB of DRM scanout memory per rank. vLLM still sees one exact-size
CUDA tensor and reports 1,049,451 cache tokens, or 1.00x concurrency at the
1,047,552-token model limit.

The host configuration and the R28.1 image are both required. Merely changing
the `nvidia_drm` module options does not make the reserved memory available to
ordinary CUDA allocations.

## Host setup

Use this only on headless nodes with remote console or SSH access. Run on both
Sparks, then reboot:

```bash
sudo systemctl set-default multi-user.target
echo 'options nvidia_drm modeset=1 fbdev=0' \
  | sudo tee /etc/modprobe.d/zz-nvidia-drm-override.conf
sudo update-initramfs -u -k all
sudo reboot
```

After reboot, verify on both nodes:

```bash
systemctl get-default
systemctl is-active display-manager
sudo cat /sys/module/nvidia_drm/parameters/modeset
sudo cat /sys/module/nvidia_drm/parameters/fbdev
ls -l /dev/dri/card0
```

Expected values are `multi-user.target`, an inactive display manager,
`modeset=Y`, `fbdev=N`, and an existing `/dev/dri/card0`. The user running
Docker must be able to pass the card into the container; the supplied Compose
overlay also adds the card's default group ID 44, configurable with
`DRM_CARD_GID`.

Set these values in `.env` and launch normally with `./start.sh`:

```dotenv
IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.1-display-kv-arm64-sm121-cu134
DISPLAY_KV_ENABLE=1
DISPLAY_KV_MIN_BYTES=4294967296
DRM_CARD_GID=44
```

`start.sh` automatically adds `compose.display-kv.override.yaml` when
`DISPLAY_KV_ENABLE=1`. Successful startup prints
`"stage": "glm53_r28_display_kv_allocated"` on each rank. For the qualified
profile, the receipt must show `display_bytes=1879048192` and the server must
report at least 1,047,552 KV tokens.

## Validation on two DGX Sparks

The September 22 qualification covered exact-size allocation, CUDA writes at
both sides of the ordinary/display boundary, two-rank startup, RoCEnante,
piecewise and full CUDA-graph capture, text generation, image input, coherence,
and the normal c1/c2/c4 benchmark matrix. There were no CUDA, OOM, traceback or
allocator errors.

The display-backed warm run used `llama-benchy 0.4.0`, 2,048 prompt tokens and
128 generated tokens:

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

The independent `tool-eval-bench --perf-only` run completed all 27 requests in
6:11 with zero request errors. After the full test sequence, swap stood at
approximately 4.5 GiB on rank 0 and 1.8 GiB on rank 1, compared with roughly
6.2 GiB and 2.9 GiB before display-backed KV was enabled. Workload and kernel
page state affect exact swap readings.

## Rollback

Set `DISPLAY_KV_ENABLE=0`, restore the original R28 image tag, and start the
cluster. The host module setting can remain in place while the machines are
headless; the standard R28 allocator does not use `/dev/dri/card0`.

## Source and license

The allocator is derived from
[`coolbho3k/DeepSeek-v4.1-Flash-2x-DGX-Spark`](https://github.com/coolbho3k/DeepSeek-v4.1-Flash-2x-DGX-Spark)
commit `878e0eecd893fadc69ad2d58b2df0fabb0fae2ee` and is
AGPL-3.0-only. The modified C source, Python integration, license, exact
upstream origin and hashes are in `files/display-kv-r28/`.
