# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=nvcr.io/nvidia/pytorch:26.08-py3
FROM ${BASE_IMAGE}

ARG BUILD_DATE
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:${PATH} \
    TORCH_CUDA_ARCH_LIST=12.1a \
    CMAKE_CUDA_ARCHITECTURES=121a \
    FLASHINFER_CUDA_ARCH_LIST=12.1f \
    CUTE_DSL_ARCH=sm_121a \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    FLASHINFER_DISABLE_VERSION_CHECK=1 \
    VLLM_ENABLE_PCIE_ALLREDUCE=1 \
    VLLM_PCIE_ALLREDUCE_BACKEND=cpp \
    HF_HOME=/root/.cache/huggingface

RUN python -m venv --system-site-packages /opt/venv \
 && python -m pip install --upgrade 'pip<27' 'setuptools>=77,<81' wheel

COPY vllm-common.txt /tmp/vllm-common.txt
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    python -m pip install -r /tmp/vllm-common.txt \
 && python -m pip install \
      'numba==0.65.0' \
      'apache-tvm-ffi==0.1.13.post3' \
      'nvidia-cudnn-frontend>=1.19.1' \
      'nvtx==0.2.15' \
      'fastsafetensors>=0.3.3' \
      'nvidia-cutlass-dsl[cu13]==4.6.2' \
      'nvidia-modelopt==0.46.1' \
      'nccl4py==0.3.1' \
 && python -m pip install --no-deps \
      'tokenspeed-mla==0.1.8' \
      'humming-kernels[cu13]==0.1.12' \
      'tilelang==0.1.12' \
      'quack-kernels==0.6.4'

COPY wheelhouse /tmp/wheelhouse
RUN python -m pip uninstall --yes vllm b12x flashinfer-python flashinfer-jit-cache \
      lmcache instanttensor local-inference-nccl-cu134 || true \
 && python -m pip install --no-deps --force-reinstall /tmp/wheelhouse/*.whl \
 && test "$(python -c 'import torch; print(torch.version.cuda)')" = 13.4 \
 && python -m pip check || true \
 && mkdir -p /opt/nccl \
 && ln -sf /opt/venv/lib/python3.12/site-packages/local_inference_nccl/lib/libnccl.so.2.31.2 \
      /opt/nccl/libnccl.so.2.31.2 \
 && rm -rf /tmp/wheelhouse

ENV LD_PRELOAD=/opt/nccl/libnccl.so.2.31.2 \
    VLLM_NCCL_SO_PATH=/opt/nccl/libnccl.so.2.31.2

COPY community-assembly.json upstream-runtime-manifest.json /opt/glm53-karmic/

LABEL org.opencontainers.image.title="Karmic Kraken ARM64 SM121a inference runtime" \
      org.opencontainers.image.description="Source-locked CUDA 13.4.1 / PyTorch 2.14 Karmic Kraken build for two DGX Spark nodes" \
      org.opencontainers.image.source="https://github.com/technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks" \
      local-inference.upstream.recipe="https://github.com/local-inference-lab/blackwell-llm-docker/commit/23d674e8f658dae2db75399c48430693c196b258" \
      local-inference.runtime.cuda="13.4.1" \
      local-inference.runtime.pytorch="2.14.0a0+4fdf77b940.nv26.08" \
      local-inference.runtime.arch="sm_121a" \
      local-inference.vllm.commit="22476af54c637cbb7c7d8193addd160da83a5ce3" \
      local-inference.b12x.commit="f6d8b8eb94cdeb4e652652f925a494c6fc86f101" \
      local-inference.build.date="${BUILD_DATE}"

WORKDIR /workspace
ENTRYPOINT []
CMD ["/bin/bash"]
