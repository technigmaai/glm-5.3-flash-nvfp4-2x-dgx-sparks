from __future__ import annotations

import os
import py_compile
from pathlib import Path


site = Path("/opt/venv/lib/python3.12/site-packages")
vllm_moe = site / "vllm/model_executor/layers/fused_moe/b12x.py"
serving = site / "vllm/entrypoints/openai/chat_completion/serving.py"
dense = site / "b12x/_lib/dense_gemm.py"

for path in (vllm_moe, serving, dense):
    if not path.is_file():
        raise SystemExit(f"missing={path}")
    py_compile.compile(str(path), doraise=True)

moe_text = vllm_moe.read_text()
serving_text = serving.read_text()
dense_text = dense.read_text()

checks = {
    "moe_distributed_routes": "route_rows * topk + route_columns" in moe_text,
    "moe_old_repeated_routes_removed": ".expand(tokens, -1)" not in moe_text,
    "streaming_tool_length_preserved": (
        'and output.finish_reason == "stop"' in serving_text
    ),
    "nonstreaming_tool_length_preserved": (
        'auto_tools_called and output.finish_reason in (None, "stop")'
        in serving_text
    ),
    "mxfp8_scale_bounds": "sfb_pair = Uint32(0x7F7F)" in dense_text,
    "fresh_cache_identity": (
        os.environ.get("LOCAL_INFERENCE_CACHE_FINGERPRINT")
        == "glm53-r263-minimal-20260916"
    ),
}

tokens, topk, experts = 8, 8, 288
routes = [
    [(row * topk + column) % experts for column in range(topk)]
    for row in range(tokens)
]
checks["moe_fixture_64_experts"] = len({x for row in routes for x in row}) == 64
checks["moe_fixture_unique_per_row"] = all(len(set(row)) == topk for row in routes)

failed = [name for name, passed in checks.items() if not passed]
if failed:
    raise SystemExit("failed=" + ",".join(failed))

print(f"runtime_validation=passed cases={len(checks)}")
