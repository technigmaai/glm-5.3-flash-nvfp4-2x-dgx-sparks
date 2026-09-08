# syntax=docker/dockerfile:1.7
# GLM-5.3-Flash NVFP4 (local-inference-lab quant) on DGX Spark (SM121/GB10), TP=2.
#
# Same day-0 base + NoPE-MLA mod as docker-images/glm53-flash-nvfp4, PLUS the
# four lab-checkpoint patches from FujitsuPolycom/glm53-flash-tp2-spark
# (Apache-2.0, attribution in patches/UPSTREAM.md):
#   * model.patch               — checkpoint naming shim (attn_hc.* submodules,
#                                 forget_gate flatten, fused [3C,1,4] conv1d split)
#   * modelopt.patch            — MTP MIXED_PRECISION fix: the draft model
#                                 resolves quantization across the checkpoint /
#                                 target-mapper namespaces (without it:
#                                 KeyError model.layers.45.mtp_block...w2_weight_scale)
#   * sparse_attn_indexer*.patch — disable persistent_topk / cooperative
#                                 workspace on CC 12.x (requests 62 blocks vs 48,
#                                 128 KB smem vs GB10's 99 KB)
#
# NOT vendored (base-image or fabric specific, see recipe header): the upstream
# image-layer patches (flashkda prefill, mm-renderer) and their bundled NCCL
# 2.30.7 (direct-cabled ring).
#
# ADDED on top of the base image: the `instanttensor` wheel, which enables
# `--load-format instanttensor` (see LOAD_FORMAT in .env). The base image's vLLM
# already carries the loader hook; only the wheel was missing.
#
# Verification markers: `[quantprobe]` in modelopt.py (runtime log must show
# algo=MXFP8 for the MTP layer), `hc_attn_base` in model.py.

ARG BASE_IMAGE=vllm/vllm-openai:glm53-flash-arm64-cu130@sha256:905c02933be6021301db2dc284e24e3727467aa3a0f63b41d609885778a07bce
FROM ${BASE_IMAGE}

# 1) NoPE-MLA rope-pad + sm120 sparse-MLA topk mod (anchors self-assert).
COPY patch_mla.py /tmp/patch_mla.py

# 2) FujitsuPolycom lab-checkpoint patches (unmodified upstream .patch files).
COPY model.patch modelopt.patch \
     sparse_attn_indexer.patch sparse_attn_indexer_kpool.patch /tmp/

RUN set -eux; \
    B=/usr/local/lib/python3.12/dist-packages/vllm; \
    python3 /tmp/patch_mla.py; \
    patch "$B/models/glm5next/nvidia/model.py" /tmp/model.patch; \
    patch "$B/model_executor/layers/quantization/modelopt.py" /tmp/modelopt.patch; \
    patch "$B/model_executor/layers/sparse_attn_indexer.py" /tmp/sparse_attn_indexer.patch; \
    patch "$B/model_executor/layers/sparse_attn_indexer_kpool.py" /tmp/sparse_attn_indexer_kpool.patch; \
    grep -q quantprobe "$B/model_executor/layers/quantization/modelopt.py"; \
    grep -q hc_attn_base "$B/models/glm5next/nvidia/model.py"; \
    python3 -m py_compile \
        "$B/models/glm5next/nvidia/model.py" \
        "$B/model_executor/layers/quantization/modelopt.py" \
        "$B/model_executor/layers/sparse_attn_indexer.py" \
        "$B/model_executor/layers/sparse_attn_indexer_kpool.py"; \
    rm -f /tmp/patch_mla.py /tmp/*.patch

# 3) InstantTensor loader wheel — enables `--load-format instanttensor`.
#
# instanttensor's metadata depends on a bare `torch`, so a naive install
# re-resolves the whole CUDA stack. Two things break if you let it:
#   * torch 2.13.0+cu130 (aarch64/CUDA) is replaced by the generic PyPI CPU wheel;
#   * nvidia-nccl-cu13 is DOWNGRADED 2.30.7 -> 2.29.7 (and libnccl_device.bc is
#     dropped). 2.30.7 is the bundled NCCL this recipe's direct-cabled RoCE ring
#     is built around — and unlike eugr's image there is no system libnccl here
#     to symlink over it, so torch loads the pip copy directly. The downgrade
#     would be silent.
#
# So pin every already-installed torch* and nvidia-* distribution via
# `uv pip --override` (eugr's mods/use-official-vllm pins only the torch trio;
# their Dockerfile separately redirects libnccl.so.2 at the system copy, which
# is why the NCCL move is harmless for them and not for us). The libnccl.so.2
# digest is compared before/after so a future resolver change cannot slip past.
RUN <<'SH'
set -eux
PY=$(command -v python3)
NCCL_LIB=/usr/local/lib/python3.12/dist-packages/nvidia/nccl/lib/libnccl.so.2
sha256sum "$NCCL_LIB" | cut -d' ' -f1 > /tmp/nccl-before.sha

"$PY" - > /tmp/pin-override.txt <<'PYIN'
import importlib.metadata as m

for dist in sorted(m.distributions(), key=lambda d: d.name or ""):
    name = dist.name or ""
    if name.startswith("torch") or name.startswith("nvidia-"):
        print(f"{name}=={dist.version}")
PYIN
cat /tmp/pin-override.txt

uv pip install --python "$PY" instanttensor --override /tmp/pin-override.txt

test "$(sha256sum "$NCCL_LIB" | cut -d' ' -f1)" = "$(cat /tmp/nccl-before.sha)"
test -f /usr/local/lib/python3.12/dist-packages/nvidia/nccl/lib/libnccl_device.bc

"$PY" - <<'PYIN'
import importlib.metadata as m
import torch
import instanttensor  # noqa: F401

pinned = dict(
    line.split("==") for line in open("/tmp/pin-override.txt").read().split()
)
assert torch.__version__ == pinned["torch"], f"torch moved: {torch.__version__}"
assert torch.version.cuda, "torch lost CUDA support"
nccl = m.version("nvidia-nccl-cu13")
assert nccl == pinned["nvidia-nccl-cu13"], f"nccl moved: {nccl}"
print("instanttensor", m.version("instanttensor"),
      "| torch", torch.__version__, "| nccl", nccl)
PYIN
rm -f /tmp/pin-override.txt /tmp/nccl-before.sha
SH
