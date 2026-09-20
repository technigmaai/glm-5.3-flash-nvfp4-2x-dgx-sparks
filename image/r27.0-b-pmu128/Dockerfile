ARG BASE_IMAGE=technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121
FROM ${BASE_IMAGE}

COPY apply_pmu128_patch.py /opt/glm53-patches/apply_pmu128_patch.py
RUN python3 /opt/glm53-patches/apply_pmu128_patch.py --apply --verify \
 && /opt/venv/bin/python -c "from vllm.config.speculative import SpeculativeConfig; assert 'disable_eagle_block_drop' in SpeculativeConfig.__annotations__; assert hasattr(SpeculativeConfig, 'use_eagle_block_drop')"

LABEL org.opencontainers.image.title="GLM-5.3 R27.0-B PMU128 ARM64" \
      org.opencontainers.image.description="R27.0-A plus fine-grained 128-token prefix-cache matching support for MTP" \
      org.opencontainers.image.base.name="technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r27.0-a-pr57443-arm64-sm121"
