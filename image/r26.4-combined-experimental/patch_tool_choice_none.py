#!/usr/bin/env python3
"""Honor ``tool_choice:"none"`` at decode time (glm47 parser).

The base image keeps the tool block in the prompt for ``tool_choice:"none"``
(that shared prefix is the point of the workload), and its API layer already
strips ``tool_calls`` three ways (``abstract_parser.py`` 427/662,
``parser_engine.py`` 404-414 -> tool events dropped in ``_events_to_delta``).
Nothing stops the model from *generating* ``<tool_call>...``; the answer step
then has no text and the strict collector fails closed (thegrill #55).

``ParserEngine.adjust_request`` is the hook upstream itself uses for
"none must not leak the tool special token" (Mistral grammar,
``renderers/online_renderer.py`` 442-460), and it runs for every chat request
here because ``--reasoning-parser glm45`` is set — if that flag ever
disappears, this fix goes inert and the live probe in
``docs/tool-choice-none.md`` catches it. The override appends the parser's
own ``TOOL_CALL_START`` to ``request.bad_words``: the sampler masks the
opener at every position (``v1/sample/ops/bad_words.py``), including every
spec-decode draft position on the verify path (``rejection_sampler.py``
329-332; the DFlash2/EAGLE3 drafters never see ``bad_words``, a drafted
opener is simply rejected). Prompt bytes and usage accounting are unchanged;
client-supplied ``bad_words`` survive (deduped downstream).

``--exclude-tools-when-tool-choice-none`` was considered and rejected: it
drops the tool block from the prompt, which destroys the shared-prefix
retention this deployment needs (168-vs-17 prompt-token class).

Anchor is this image's ``vllm/parser/glm47_moe.py``. Fail closed on drift.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

P = Path(
    os.environ.get(
        "GLM53_TOOL_CHOICE_NONE_PY",
        "/usr/local/lib/python3.12/dist-packages/vllm/parser/glm47_moe.py",
    )
)
MARK = "# [glm53-tool-choice-none]"
OLD = """    def _handle_tool_end(self, event, deltas) -> None:
        idx = event.tool_index
        if 0 <= idx < len(self._tool_slots):
            self._tool_slots[idx].name = self._tool_slots[idx].name.strip()
        super()._handle_tool_end(event, deltas)
"""

NEW = """    def adjust_request(
        self, request: ChatCompletionRequest | ResponsesRequest
    ) -> ChatCompletionRequest | ResponsesRequest:
        request = super().adjust_request(request)
        # [glm53-tool-choice-none] tools stay in the prompt; keep the model
        # from opening a call by masking the opener at decode time.
        if (
            isinstance(request, ChatCompletionRequest)
            and request.tool_choice == "none"
            and request.tools
        ):
            request.bad_words.append(TOOL_CALL_START)
        return request

""" + OLD


def apply_text(src: str) -> tuple[str, str]:
    """Return (new_source, status): applied|skipped|missing:..."""
    if MARK in src:
        return src, "skipped"
    if OLD not in src or 'TOOL_CALL_START = "<tool_call>"' not in src:
        return src, "missing:anchor"
    return src.replace(OLD, NEW, 1), "applied"


def apply_file(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    new, status = apply_text(text)
    if status == "applied":
        compile(new, str(path), "exec")
        path.write_text(new, encoding="utf-8")
    return status


def main(argv: list[str] | None = None) -> int:
    argv = sys.argv if argv is None else argv
    if len(argv) > 1 and argv[1] == "--status":
        target = Path(argv[2]) if len(argv) > 2 else P
        applied = target.is_file() and MARK in target.read_text(encoding="utf-8")
        print("tool-choice-none               :", "APPLIED" if applied else "NOT APPLIED")
        return 0
    target = Path(argv[1]) if len(argv) > 1 else P
    if not target.is_file():
        print(f"[tool-choice-none] missing {target}", file=sys.stderr)
        return 1
    status = apply_file(target)
    print(f"[tool-choice-none] {status}: {target}")
    return 0 if status in ("applied", "skipped") else 1


if __name__ == "__main__":
    sys.exit(main())
