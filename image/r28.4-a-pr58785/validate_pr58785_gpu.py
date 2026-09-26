from __future__ import annotations

import torch
import vllm  # noqa: F401 - imports and registers the compiled vLLM operators


ROW_LENGTHS = [6000, 8192, 10500, 20000, 32768]
WORKSPACE_BYTES = 1024 * 1024


@torch.inference_mode()
def validate(top_k: int, distribution: str) -> None:
    torch.manual_seed(0)
    lengths = torch.tensor(ROW_LENGTHS, dtype=torch.int32, device="cuda")
    num_rows, width = len(ROW_LENGTHS), max(ROW_LENGTHS)

    if distribution == "normal":
        logits = torch.randn(num_rows, width, device="cuda") * 0.5 + 5.0
    else:
        logits = 4.0 + torch.rand(num_rows, width, device="cuda") * 0.12
        if distribution == "one_bin_ties":
            logits = logits.mul(1000).round().div(1000)

    positions = torch.arange(width, device="cuda")
    logits.masked_fill_(positions[None] >= lengths[:, None], float("-inf"))
    indices = torch.full((num_rows, top_k), -2, dtype=torch.int32, device="cuda")
    workspace = torch.empty(WORKSPACE_BYTES, dtype=torch.uint8, device="cuda")

    torch.ops._C.persistent_topk(logits, lengths, indices, workspace, top_k, width)
    torch.cuda.synchronize()

    if not torch.all((indices >= 0) & (indices < lengths[:, None])):
        raise AssertionError(f"out-of-range index for top_k={top_k}, {distribution}")
    ordered = indices.sort(dim=1).values
    if not torch.all(ordered[:, 1:] != ordered[:, :-1]):
        raise AssertionError(f"duplicate index for top_k={top_k}, {distribution}")

    selected = logits.gather(1, indices.long()).sort(dim=1, descending=True).values
    expected = logits.topk(top_k, dim=1).values
    torch.testing.assert_close(selected, expected, atol=0, rtol=0)
    print(f"PASS top_k={top_k} distribution={distribution}")


if torch.cuda.get_device_capability(0) != (12, 1):
    raise RuntimeError(f"expected SM121 GB10, got {torch.cuda.get_device_capability(0)}")

for candidate_top_k in (512, 1024, 2048):
    for candidate_distribution in ("one_bin", "one_bin_ties", "normal"):
        validate(candidate_top_k, candidate_distribution)

print("PR #58785 GPU regression passed: 9/9 overflow cases exact on SM121")
