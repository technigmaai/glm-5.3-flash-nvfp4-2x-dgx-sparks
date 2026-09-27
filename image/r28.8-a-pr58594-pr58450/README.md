# R28.8-A combined GLM sparse-attention optimizations

R28.8-A is the qualified production image. It combines the R28.6-A semantic
backport of merged vLLM PR
[#58594](https://github.com/vllm-project/vllm/pull/58594) with merged vLLM PR
[#58450](https://github.com/vllm-project/vllm/pull/58450) over R28.5-A.

The overlay changes four Python files and rebuilds no native component. Its
recipe verifies every base-file hash, both patch hashes and every resulting
file hash before running syntax, R28.5-A cumulative and R28.8-A validation.
CUDA, PyTorch, vLLM native extensions, B12X, model weights and all serving
parameters are unchanged.

Published images:

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.8-a-pr58454-pr58785-pr58779-pr58594-pr58450-arm64-sm121-cu134
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:latest
```

Qualification used one cold and two warm sequential `tool-eval-bench` sweeps.
All passed; wall times were 9:26, 8:47 and 8:50. The chat smoke returned HTTP
200 and exact `SMOKE_OK` content. Both nodes used the same image ID and had
zero restarts.

