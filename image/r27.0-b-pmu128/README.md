# R27.0-B PMU128 overlay

Published base: `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121`

Published image: `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-b-pmu128-arm64-sm121`

This is a Python-only image overlay. It does not rebuild CUDA, vLLM, B12X, or
model kernels.

Changes:

- Adds `SpeculativeConfig.disable_eagle_block_drop` and the corresponding
  scheduler decision from upstream vLLM PR #53388.
- Makes the GLM/Mamba aligned-prefill path use the scheduler's resolved cache
  match unit. With `--prefix-match-unit 128`, prefix hashes/checkpoints can be
  matched every 128 tokens while the physical KV-cache page size is unchanged.
- Keeps all R27.0-A CUDA, B12X, RoCEnante, model, and loading behavior.

The overlay is used with:

```text
--prefix-match-unit 128
--enable-prompt-tokens-details
--speculative-config ... "disable_eagle_block_drop":true ...
```

The implementation adapts the relevant behavior from upstream vLLM PR
[#53388](https://github.com/vllm-project/vllm/pull/53388) and the PMU128 recipe
in [`taoofshawn/spark-recipes`](https://github.com/taoofshawn/spark-recipes/tree/main/glm-v53-flash-intel-w4a16/mtp3-pmu128).

Build with:

```bash
./build.sh
```

The patcher fails closed if its R27.0-A source anchors differ, parses the
modified Python files, and validates the new config field during the build.
