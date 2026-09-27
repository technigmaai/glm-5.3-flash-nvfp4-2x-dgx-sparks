from __future__ import annotations

import hashlib
import importlib.metadata
from pathlib import Path


ROOT = Path("/opt/venv/lib/python3.12/site-packages/vllm")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


expected = {
    ROOT / "models/deepseek_v32/attention.py": (
        "35781670cc16f0f02c051a0ef9c2a8b9e1c49ea402b1acfe72a4b12f7a1a03b9"
    ),
    ROOT / "v1/executor/multiproc_executor.py": (
        "86a5415fb39632e53738175392571190512ab45c52b2004d340d0b4de23d5d6c"
    ),
    ROOT / "v1/worker/utils.py": (
        "f8030342c9d02e95b737dd6f04dd5e4a3e2b409000460038e32ec4885b19bbf1"
    ),
    ROOT / "models/glm5next/common/attention.py": (
        "4c4e7cdc9b6565bcf8d53387edc29d130eedd044427e75bf3a446a3c657709d6"
    ),
    ROOT / "models/glm5next/nvidia/ops/kpool_compress.py": (
        "06a574eddf136e80f344c743f06a0abda55ff487735be6b91bb9c1c0b861bb3e"
    ),
}

for path, digest in expected.items():
    actual = sha256(path)
    if actual != digest:
        raise RuntimeError(f"unexpected hash for {path}: {actual} != {digest}")

attention = (ROOT / "models/deepseek_v32/attention.py").read_text()
needle = "topk_backend=self.indexer_op.topk_backend,"
if attention.count(needle) != 1:
    raise RuntimeError(f"expected one PR #58594 backend propagation, found {attention.count(needle)}")

indexer = (ROOT / "model_executor/layers/sparse_attn_indexer.py").read_text()
if 'topk_backend: str = "auto"' not in indexer:
    raise RuntimeError("pinned sparse_attn_indexer lacks the topk_backend compatibility argument")

version = importlib.metadata.version("vllm")
expected_version = "0.1.dev1+ga7b41c45a.d20260926.cu134"
if version != expected_version:
    raise RuntimeError(f"unexpected vLLM version: {version} != {expected_version}")

for relative in (
    "_C_stable_libtorch.abi3.so",
    "_moe_C_stable_libtorch.abi3.so",
    "_flashkda_C.abi3.so",
    "vllm-rs",
):
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f"missing native artifact: {path}")

print(
    "R28.6-A static validation passed: PR #58594 top-k backend propagation, "
    "R28.5-A patches, display-KV, and native artifacts are intact"
)
