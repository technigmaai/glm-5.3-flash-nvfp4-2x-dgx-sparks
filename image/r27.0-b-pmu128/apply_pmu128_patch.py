#!/usr/bin/env python3
"""Apply and verify the GLM-5.3 PMU128 overlay against R27.0-A.

The patch intentionally fails closed: every source replacement must occur
exactly once, and verification parses the resulting Python sources.
"""

from __future__ import annotations

import argparse
import ast
from pathlib import Path


SITE = Path("/opt/venv/lib/python3.12/site-packages")
SPEC = SITE / "vllm/config/speculative.py"
SCHED = SITE / "vllm/v1/core/sched/scheduler.py"


FIELD_OLD = '''    use_local_argmax_reduction: bool = False
    """Use vocab-parallel local argmax instead of all-gathering full logits
'''
FIELD_NEW = '''    disable_eagle_block_drop: bool = False
    """Keep the final reusable prefix-cache block for EAGLE-family methods.

    This is required when prefix-cache matching is finer than the physical
    KV-cache block geometry. It is opt-in to preserve upstream behavior.
    """

    use_local_argmax_reduction: bool = False
    """Use vocab-parallel local argmax instead of all-gathering full logits
'''

METHOD_OLD = '''    def use_eagle_preserves_target_kv_cache(self) -> bool:
        # Only eagle-family drafters share (and pollute via lookahead KV
        # write) the target's full-attention KV cache groups; DFlash/DSpark
        # draft from their own KV cache and never write target blocks.
        return self.method in ("eagle", "eagle3", "mtp")

    def use_dflash(self) -> bool:
'''
METHOD_NEW = '''    def use_eagle_preserves_target_kv_cache(self) -> bool:
        # Only eagle-family drafters share (and pollute via lookahead KV
        # write) the target's full-attention KV cache groups; DFlash/DSpark
        # draft from their own KV cache and never write target blocks.
        return self.method in ("eagle", "eagle3", "mtp")

    def use_eagle_block_drop(self) -> bool:
        return (
            self.use_eagle_preserves_target_kv_cache()
            and not self.disable_eagle_block_drop
        )

    def use_dflash(self) -> bool:
'''

DROP_OLD = '''            self.drop_last_prefix_cache_block = (
                speculative_config.use_eagle_preserves_target_kv_cache()
            )
'''
DROP_NEW = '''            self.drop_last_prefix_cache_block = (
                speculative_config.use_eagle_block_drop()
            )
'''

BLOCK_OLD = '''        block_size = self.cache_config.block_size
        # The last block-aligned position whose state can be cached.
'''
BLOCK_NEW = '''        # Use the scheduler's resolved match unit (the LCM across
        # participating cache groups), rather than the physical KV page size.
        block_size = self.block_size
        # The last block-aligned position whose state can be cached.
'''


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text:
        return
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one source match, found {count}")
    path.write_text(text.replace(old, new, 1))


def verify() -> None:
    checks = {
        SPEC: (
            "disable_eagle_block_drop: bool = False",
            "def use_eagle_block_drop(self) -> bool:",
        ),
        SCHED: (
            "speculative_config.use_eagle_block_drop()",
            "block_size = self.block_size",
        ),
    }
    for path, markers in checks.items():
        text = path.read_text()
        for marker in markers:
            if marker not in text:
                raise SystemExit(f"{path}: missing marker: {marker}")
        ast.parse(text, filename=str(path))
    print("PMU128 overlay verification passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    if not (args.apply or args.verify):
        parser.error("use --apply and/or --verify")
    if args.apply:
        replace_once(SPEC, FIELD_OLD, FIELD_NEW)
        replace_once(SPEC, METHOD_OLD, METHOD_NEW)
        replace_once(SCHED, DROP_OLD, DROP_NEW)
        replace_once(SCHED, BLOCK_OLD, BLOCK_NEW)
    verify()


if __name__ == "__main__":
    main()
