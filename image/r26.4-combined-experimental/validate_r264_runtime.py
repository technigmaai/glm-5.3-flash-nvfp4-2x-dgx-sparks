#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path

import b12x.moe.fused_moe._impl as impl
from vllm.parser.glm47_moe import Glm47MoeParser


parser_source = Path(__import__("vllm.parser.glm47_moe", fromlist=["x"]).__file__).read_text()
route_source = Path(__import__("b12x.moe._shared.kernels.m8_route_pack", fromlist=["x"]).__file__).read_text()

assert "# [glm53-tool-choice-none]" in parser_source
assert "request.bad_words.append(TOOL_CALL_START)" in parser_source
assert "grid=(self.num_tokens, self.num_topk, 1)" in route_source
assert hasattr(Glm47MoeParser, "adjust_request")
assert hasattr(impl, "_get_m8_route_pack_kernel")

for name in (
    "B12X_DYNAMIC_SPLIT_ROUTE_COMPUTE",
    "B12X_DYNAMIC_SPLIT_FAST_PREPARE",
    "B12X_DYNAMIC_SPLIT_LOW_SMEM",
    "B12X_DYNAMIC_SKIP_SPLIT_BARRIER_RESET",
):
    assert os.environ.get(name) == "1", (name, os.environ.get(name))

assert os.environ.get("B12X_NVFP4_DYNAMIC_MATERIALIZED") in (None, "", "0")
print("r26.4 combined runtime validation: ok")
