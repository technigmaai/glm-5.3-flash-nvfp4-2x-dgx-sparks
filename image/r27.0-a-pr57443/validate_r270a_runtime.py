#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path


roots = [
    Path("/opt/vllm/vllm"),
    Path("/opt/venv/lib/python3.12/site-packages/vllm"),
]
relative_files = [
    Path("v1/attention/backends/mla/indexer.py"),
    Path("v1/attention/backends/mla/flashattn_mla_sparse.py"),
    Path("v1/worker/gpu/spec_decode/speculator.py"),
]
markers = {
    relative_files[0]: [
        "supports_draft_decode_metadata_update = self.dcp_world_size == 1",
        "def update_draft_decode_metadata(",
        "positions=common_attn_metadata.positions",
        "decode.schedule_metadata.copy_(schedule_metadata)",
    ],
    relative_files[1]: [
        "supports_draft_decode_metadata_update = self.dcp_world_size == 1",
        "def update_draft_decode_metadata(",
    ],
    relative_files[2]: [
        "positions=self.input_buffers.positions[:num_tokens_padded]",
    ],
}

for relative in relative_files:
    contents = [(root / relative).read_bytes() for root in roots]
    if contents[0] != contents[1]:
        raise SystemExit(f"runtime/source mismatch: {relative}")
    text = contents[0].decode()
    for marker in markers[relative]:
        if marker not in text:
            raise SystemExit(f"missing marker {marker!r} in {relative}")
    print(relative, hashlib.sha256(contents[0]).hexdigest())

print("r27.0-a PR #57443 runtime validation: ok")
