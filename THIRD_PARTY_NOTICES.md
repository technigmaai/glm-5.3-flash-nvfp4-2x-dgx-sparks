# Third-party notices

This repository contains selected source files derived from vLLM. vLLM is licensed under the Apache License 2.0:

- Project: https://github.com/vllm-project/vllm
- License: https://github.com/vllm-project/vllm/blob/main/LICENSE

The deployment downloads or runs other third-party projects and packages. Their licenses remain with their respective projects, including local-inference-lab/vLLM, local-inference-lab/B12X, PyTorch, NVIDIA CUDA, FlashInfer, InstantTensor, LMCache, Triton, transformers, safetensors, and xgrammar.

No license is granted for model weights by this repository. Review the model repository's license and terms before downloading or distributing the checkpoint.

The R28.1 display-reserved KV allocator is derived from selected files in
[`coolbho3k/DeepSeek-v4.1-Flash-2x-DGX-Spark`](https://github.com/coolbho3k/DeepSeek-v4.1-Flash-2x-DGX-Spark)
at commit `878e0eecd893fadc69ad2d58b2df0fabb0fae2ee`. Those files and the local
adaptation are distributed under AGPL-3.0-only. The corresponding source and
license are included in `files/display-kv-r28/` and in the R28.1 image.
