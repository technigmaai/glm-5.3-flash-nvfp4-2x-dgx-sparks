# R26.4 combined experimental candidate

Base image: `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r26.3-minimal-arm64-sm121`.

This candidate adds MiaAI-Lab PR #215 to the GLM47 parser so chat requests with
tools and `tool_choice: "none"` mask the `<tool_call>` opener during decoding.
Prompt bytes, prefix-cache reuse, automatic tool choice and named tool choice are
unchanged.

The R26.3 B12X source already contains the functional PR #280 GLM M8 parallel
route packer (`grid=(num_tokens, num_topk, 1)`) and its preplanned split compute
path. R26.4 enables that existing path with the four narrow feature flags used
by the specialization. It does not copy the current PR branch and therefore
does not import B12X PR #353/#354 or unrelated newer B12X files.

CUDA, PyTorch, NCCL, FlashInfer, InstantTensor, compiled vLLM extensions, model
weights and the serving recipe are inherited unchanged from R26.3. A fresh JIT
cache namespace forces the newly enabled B12X plan to compile before capture.
