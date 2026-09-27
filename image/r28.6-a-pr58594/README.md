# R28.6-A sparse-indexer top-k backend fix

R28.6-A is a Python-only overlay over R28.5-A. It applies the GLM-relevant
call-site change from merged vLLM PR
[#58594](https://github.com/vllm-project/vllm/pull/58594), ensuring the
sparse indexer's top-k operation uses the selected backend implementation.

The only runtime file changed is:

```text
vllm/models/deepseek_v32/attention.py
```

The recipe fails closed on the base-file hash, patch hash and resulting-file
hash, then runs the R28.5-A cumulative validator and the R28.6-A validator.
CUDA, PyTorch, native extensions, B12X, model weights and serving parameters
are unchanged.

Published image:

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.6-a-pr58454-pr58785-pr58779-pr58594-arm64-sm121-cu134
```

Qualification used one cold and two warm sequential `tool-eval-bench` sweeps.
All passed; wall times were 9:26, 9:09 and 8:47. The chat smoke returned HTTP
200 and exact `SMOKE_OK` content.

