# R28.5-A patch manifest

| Component | Value |
|---|---|
| Base image | `technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.4-a-pr58454-pr58785-arm64-sm121-cu134` |
| Base image digest | `sha256:1e88fd52fbf61d9b4c2229013a1a1c6949fdea781883fe81d7df705e58c2f078` |
| Published image / `latest` digest | `sha256:ca40c504b0fac78a92c929262dbe6236cfa07c6896f36f7d2679123262d27dd6` |
| PR #58779 head | `fbb946710010ebb1e31c1bbf66cc338ecbc5e121` |
| PR #58779 upstream merge | `8a2364605c0b0581ea5d0d3720cb1125b47abc6f` |
| Cumulative source head | `41d28da376fe0b98546c5cc3533ccba5d44b3e71` |
| Cumulative source tree | `93473ceffede701f75866eca1f21da824cd12f5f` |
| Runtime patch SHA-256 | `5f53ac7b2f36abf1160a8aa8247c82f9c261e6ed976047e69fe80201df279588` |
| Executor pre-image SHA-256 | `17abd1dc68f1993b50b39350df017d22b59d0e1b6e998d4b9d0b2c1ef19e51b3` |
| Executor post-image SHA-256 | `86a5415fb39632e53738175392571190512ab45c52b2004d340d0b4de23d5d6c` |

R28.5-A is cumulative: it retains PRs #58454 and #58785, the display-KV
integration and every native artifact validated by R28.4-A.
