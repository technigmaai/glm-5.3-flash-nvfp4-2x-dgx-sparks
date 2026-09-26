# R28.4-A persistent-top-k correctness rebuild

R28.4-A retains vLLM PR
[#58454](https://github.com/vllm-project/vllm/pull/58454) from R28.3-A and
adds the exact persistent-top-k overflow fallback from upstream PR
[#58785](https://github.com/vllm-project/vllm/pull/58785). The fallback keeps
all candidates when a threshold bin overflows instead of silently dropping
values.

PR #58785 changes native CUDA code, so this release uses a new ARM64/SM121
CUDA 13.4 vLLM wheel rather than a Python-only overlay. The wheel is not stored
in Git. Place this exact artifact in this directory before running `build.sh`:

```text
vllm-0.1.dev1+ga7b41c45a.d20260926.cu134-cp312-cp312-linux_aarch64.whl
SHA-256: 0254c4db71fa1186db64f2dcc9b64d6ba2a156f438589f0ca680ec65150348a9
```

The cumulative source is pinned in `PATCH-MANIFEST.md`. Reinstalling the wheel
would overwrite the display-reserved KV integration, so the recipe reapplies
the byte-identical public `display-kv-utils.py` overlay and then runs the R28.3
and R28.4 fail-closed validators.

The persistent-top-k GPU regression passed 9/9 cases on each GB10 GPU:
top-k 512, 1024 and 2048 across one-bin, tied-one-bin and normal inputs, with
`torch.topk` used only as the correctness oracle.

## Published image

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.4-a-pr58454-pr58785-arm64-sm121-cu134
```

Docker Hub digest:
`sha256:1e88fd52fbf61d9b4c2229013a1a1c6949fdea781883fe81d7df705e58c2f078`.

R28.4-A passed static validation on both nodes, the 9/9 GPU regression on both
nodes, normal two-rank startup and an HTTP 200 `SMOKE_OK` chat request. Serving
parameters and deployment configuration are unchanged from R28.3-A.
