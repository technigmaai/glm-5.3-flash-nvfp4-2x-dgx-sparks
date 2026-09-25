# Patch manifest

| Component | Value |
|---|---|
| Base image | `local/vllm:glm53-r28.2-b12x-tg3-arm64-sm121-cu134` |
| Base image digest | `sha256:b895b0c0b86dfeab192b01d785b784698e04b7a75e8f02c1d57355c3d6e45d08` |
| Upstream PR | `vllm-project/vllm#58454` |
| Approved PR head | `8408acad51384ff283acafa8ed486cb7417521b7` |
| Runtime patch SHA-256 | `e05098d0687bd9ea79f2e372643fa11054765e5ac58b5e13cce113978cd09a8b` |
| R28.2 attention input SHA-256 | `362bbf0e6c50cdfa446c6551b9b1ddff425e08f88e3d4140fd8db88f8a619e0c` |
| R28.2 NVIDIA k-pool input SHA-256 | `bd6f1d7b5e88a10d9756799a744d3e201421b6caabd32f7b3319d31904a91a0a` |

Tests from the upstream PR are not copied into the runtime image. The recipe
retains the exact two-file runtime diff and runs structural and syntax checks
during the image build and again in a clean container. The exact-anchor
`apply_pr58454_r28.py` adapter expresses the same ring addressing against the
R28 seed kernel's contiguous `[block, 2, ring, head_dim]` layout.
