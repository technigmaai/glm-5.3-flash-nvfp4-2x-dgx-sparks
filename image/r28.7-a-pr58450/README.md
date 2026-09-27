# R28.7-A GLM metadata construction optimization

R28.7-A is a Python-only overlay over R28.5-A. It applies merged vLLM PR
[#58450](https://github.com/vllm-project/vllm/pull/58450), reducing sparse-MLA
metadata construction overhead for GLM-5.3.

The runtime patch changes:

```text
vllm/model_executor/layers/attention/sparse_mla_attention.py
vllm/v1/attention/backends/mla/flashattn_mla_sparse.py
vllm/v1/attention/backends/mla/flashinfer_mla_sparse.py
```

The recipe verifies exact pre-images, patch input and post-images before syntax
and cumulative runtime validation. CUDA, PyTorch, native extensions, B12X,
model weights and serving parameters are unchanged.

Published image:

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.7-a-pr58454-pr58785-pr58779-pr58450-arm64-sm121-cu134
```

Qualification used one cold and two warm sequential `tool-eval-bench` sweeps.
All passed; wall times were 9:22, 8:47 and 8:45. The chat smoke returned HTTP
200 and exact `SMOKE_OK` content.

