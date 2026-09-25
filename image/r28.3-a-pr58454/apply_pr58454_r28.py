from __future__ import annotations

import os
from pathlib import Path


ROOT = Path(
    os.environ.get(
        "VLLM_PACKAGE_ROOT", "/opt/venv/lib/python3.12/site-packages/vllm"
    )
)
ATTENTION = ROOT / "models/glm5next/common/attention.py"
KPOOL = ROOT / "models/glm5next/nvidia/ops/kpool_compress.py"


def replace_exact(path: Path, old: str, new: str, expected: int = 1) -> None:
    text = path.read_text()
    count = text.count(old)
    if count != expected:
        raise RuntimeError(
            f"expected {expected} occurrence(s) in {path}, found {count}: {old!r}"
        )
    path.write_text(text.replace(old, new))


replace_exact(
    ATTENTION,
    "from vllm.utils.deep_gemm import PAGED_MQA_PAGE_SIZES\n",
    "from vllm.utils.deep_gemm import PAGED_MQA_PAGE_SIZES\n"
    "from vllm.utils.math_utils import cdiv, next_power_of_2\n",
)

replace_exact(
    ATTENTION,
    """    def get_kv_cache_spec(self, vllm_config: VllmConfig):
        # The two head slots form [K, gate score] in the generic
        # [block, head, state, content] cache view.
        return KpoolTailSpec(
            block_size=self._index_kpool,
            num_kv_heads=2,
            head_size=self.head_dim,
            head_size_v=0,
            dtype=torch.bfloat16,
            sliding_window=self._index_kpool,
        )
""",
    """    def get_kv_cache_spec(self, vllm_config: VllmConfig):
        # The two head slots form [K, gate score] in the generic
        # [block, head, state, content] cache view.
        # Drafts are stashed before acceptance. With a one-pool ring, the
        # drafts behind a rejected pool-completing draft overwrite the keys
        # read by its redo.
        span = self._index_kpool + vllm_config.num_speculative_tokens
        ring = self._index_kpool * next_power_of_2(cdiv(span, self._index_kpool))
        # ring must divide the attention block size (a multiple of 128).
        assert self.cache_config.block_size % ring == 0, (
            f"Glm5NextTailCache: cache_config.block_size "
            f"({self.cache_config.block_size}) must be a multiple of the "
            f"tail ring ({ring})"
        )
        return KpoolTailSpec(
            block_size=ring,
            num_kv_heads=2,
            head_size=self.head_dim,
            head_size_v=0,
            dtype=torch.bfloat16,
            sliding_window=ring,
        )
""",
)

replace_exact(
    KPOOL,
    "    HEAD_DIM: tl.constexpr,\n    KPOOL: tl.constexpr,\n    BLOCK_D: tl.constexpr,\n",
    "    HEAD_DIM: tl.constexpr,\n"
    "    KPOOL: tl.constexpr,\n"
    "    RING: tl.constexpr,\n"
    "    BLOCK_D: tl.constexpr,\n",
)
replace_exact(KPOOL, "    blk = t // KPOOL  # t >= 0 here, so trunc == floor\n", "    blk = t // RING  # t >= 0 here, so trunc == floor\n")
replace_exact(KPOOL, "    if ahead >= 0 and ahead // KPOOL == blk:\n", "    if ahead >= 0 and ahead // RING == blk:\n")
replace_exact(
    KPOOL,
    "    base = (blk * 2 * KPOOL + t % KPOOL) * HEAD_DIM\n",
    "    base = (blk * 2 * RING + t % RING) * HEAD_DIM\n",
)
replace_exact(
    KPOOL,
    "    tl.store(tail_ptr + base + KPOOL * HEAD_DIM + offs, s, mask=m)\n",
    "    tl.store(tail_ptr + base + RING * HEAD_DIM + offs, s, mask=m)\n",
)
replace_exact(
    KPOOL,
    "        HEAD_DIM=head_dim,\n        KPOOL=kpool,\n        BLOCK_D=triton.next_power_of_2(head_dim),\n",
    "        HEAD_DIM=head_dim,\n"
    "        KPOOL=kpool,\n"
    "        RING=tail_kv_cache.shape[2],\n"
    "        BLOCK_D=triton.next_power_of_2(head_dim),\n",
)

replace_exact(
    KPOOL,
    "    POOL_SIZE: tl.constexpr,\n    TAIL_BLOCK_ELEMS: tl.constexpr,\n",
    "    POOL_SIZE: tl.constexpr,\n"
    "    RING: tl.constexpr,\n"
    "    TAIL_BLOCK_ELEMS: tl.constexpr,\n",
)
replace_exact(KPOOL, "        phys_slot = safe_pos % POOL_SIZE\n", "        phys_slot = safe_pos % RING\n")
replace_exact(
    KPOOL,
    "        block = tl.maximum(tail_slot, 0).to(tl.int64) // POOL_SIZE\n",
    "        block = tl.maximum(tail_slot, 0).to(tl.int64) // RING\n",
)
replace_exact(
    KPOOL,
    "                phys = (pool_logical_start + pool_slot) % POOL_SIZE\n",
    "                phys = (pool_logical_start + pool_slot) % RING\n",
    expected=2,
)
replace_exact(
    KPOOL,
    "    assert tail_kv_cache.shape[2] == pool_size\n",
    "    ring = tail_kv_cache.shape[2]\n"
    "    assert ring >= pool_size and ring % pool_size == 0, (ring, pool_size)\n",
)
replace_exact(
    KPOOL,
    "        POOL_SIZE=pool_size,\n        TAIL_BLOCK_ELEMS=tail_kv_cache.stride(0),\n",
    "        POOL_SIZE=pool_size,\n"
    "        RING=ring,\n"
    "        TAIL_BLOCK_ELEMS=tail_kv_cache.stride(0),\n",
)

print(f"Applied the R28-compatible NVIDIA runtime backport of PR #58454 to {ROOT}")
