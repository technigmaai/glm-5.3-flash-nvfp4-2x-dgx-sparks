from __future__ import annotations

import ast
from pathlib import Path


ROOT = Path("/opt/venv/lib/python3.12/site-packages/vllm")
ATTENTION = ROOT / "models/glm5next/common/attention.py"
KPOOL = ROOT / "models/glm5next/nvidia/ops/kpool_compress.py"


def require(text: str, marker: str, source: Path) -> None:
    if marker not in text:
        raise RuntimeError(f"missing {marker!r} in {source}")


def reject(text: str, marker: str, source: Path) -> None:
    if marker in text:
        raise RuntimeError(f"obsolete {marker!r} remains in {source}")


attention = ATTENTION.read_text()
kpool = KPOOL.read_text()

ast.parse(attention, filename=str(ATTENTION))
ast.parse(kpool, filename=str(KPOOL))

for marker in (
    "from vllm.utils.math_utils import cdiv, next_power_of_2",
    "span = self._index_kpool + vllm_config.num_speculative_tokens",
    "ring = self._index_kpool * next_power_of_2(cdiv(span, self._index_kpool))",
    "block_size=ring",
    "sliding_window=ring",
):
    require(attention, marker, ATTENTION)

for marker in (
    "RING: tl.constexpr",
    "phys_slot = safe_pos % RING",
    "block = tl.maximum(tail_slot, 0).to(tl.int64) // RING",
    "phys = (pool_logical_start + pool_slot) % RING",
    "ring = tail_kv_cache.shape[2]",
    "assert ring >= pool_size and ring % pool_size == 0",
):
    require(kpool, marker, KPOOL)

reject(kpool, "assert tail_kv_cache.shape[2] == pool_size", KPOOL)

print("R28.3-A validation passed: PR #58454 NVIDIA runtime markers are present")
