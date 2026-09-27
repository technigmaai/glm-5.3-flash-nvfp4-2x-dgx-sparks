from __future__ import annotations

import hashlib
import importlib.metadata
from pathlib import Path


ROOT = Path("/opt/venv/lib/python3.12/site-packages/vllm")


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


expected = {
    ROOT / "model_executor/layers/attention/sparse_mla_attention.py": (
        "6a03271a6438083e3fe01dbfd3d2fffaeed6874796c8cbb8d668df1126a6f79c"
    ),
    ROOT / "v1/attention/backends/mla/flashattn_mla_sparse.py": (
        "3267e8a298242d7131e54968ca160981d8a528c3d50662dfcb9216e6be44e2ad"
    ),
    ROOT / "v1/attention/backends/mla/flashinfer_mla_sparse.py": (
        "c86f67e11f9c8d6e69c67bf64fb422ede51f0c2f7da05784117d8c60b5f6b165"
    ),
    ROOT / "v1/attention/backend.py": (
        "6b4540893673f9dea51e44cba4704ddfbc5c3593bd337514e6e0d6a5bb7ef50f"
    ),
    ROOT / "models/deepseek_v32/attention.py": (
        "a3a3a784e798a3669e75527f724e9b2d549f0e4c025b2f4524026dc0244f0e39"
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

sparse = (ROOT / "model_executor/layers/attention/sparse_mla_attention.py").read_text()
mapping = "return common_attn_metadata.token_to_req_indices(self.req_id_per_token_buffer)"
if sparse.count(mapping) != 1:
    raise RuntimeError("PR #58450 device token-to-request mapping is not exact")

flashattn = (ROOT / "v1/attention/backends/mla/flashattn_mla_sparse.py").read_text()
for needle in (
    "self.cu_seqlens_q_buffer = torch.arange(",
    "cu_seqlens_q = self.cu_seqlens_q_buffer[: q_rope.shape[0] + 1]",
):
    if flashattn.count(needle) != 1:
        raise RuntimeError(f"PR #58450 persistent cu_seqlens buffer is not exact: {needle}")

flashinfer = (ROOT / "v1/attention/backends/mla/flashinfer_mla_sparse.py").read_text()
if "def _build_req_id_per_token(" in flashinfer:
    raise RuntimeError("redundant FlashInfer mapping override was not removed")

backend = (ROOT / "v1/attention/backend.py").read_text()
if "def token_to_req_indices(self, buffer: torch.Tensor)" not in backend:
    raise RuntimeError("pinned CommonAttentionMetadata lacks device mapping support")

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
    "R28.7-A static validation passed: PR #58450 metadata optimizations, "
    "R28.5-A patches, display-KV, and native artifacts are intact"
)
