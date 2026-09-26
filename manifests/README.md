# Published image manifests

These files were captured from the exact local image tagged for the R28 Docker
Hub release before publication:

```text
local/vllm:glm53-karmic-r28-arm64-sm121-cu134
sha256:7024cd1b8bf30be1728a7fe5f26ff777bb5b361df9216ba31caf4878452f13b6
```

Docker Hub published that value as the OCI index digest. The Linux ARM64
manifest digest is
`sha256:610d5a75e16e574109987093a7894fea926e3ec400b7c2eefa7ab74bfc6b5c06`.

- `image-identity.txt` records the local image ID, platform, creation time and
  uncompressed image size reported by Docker.
- `image-labels.json` records the OCI and NVIDIA base-image labels.
- `pip-freeze.txt` records the Python environment in `/opt/venv`.
- `debian-packages.txt` records the installed Debian package versions.

The build recipe's upstream component and file-level provenance are stored in
[`image/r28-karmic-kraken-arm64/`](../image/r28-karmic-kraken-arm64/).

The R28.2 release adds `r28.2-image-identity.txt` and
`r28.2-image-labels.json`. They capture the exact qualified B12X TG3 overlay,
including its Docker Hub digest and three pinned B12X backports. Its complete
rebuild recipe is in
[`image/r28.2-b12x-tg3-arm64/`](../image/r28.2-b12x-tg3-arm64/).

The R28.3-A release adds `r28.3-a-image-identity.txt` and
`r28.3-a-image-labels.json`. They identify the exact production overlay for
vLLM PR #58454. Its fail-closed source recipe and patch provenance are in
[`image/r28.3-a-pr58454/`](../image/r28.3-a-pr58454/).

The R28.4-A release adds `r28.4-a-image-identity.txt` and
`r28.4-a-image-labels.json`. They capture the native ARM64/SM121 vLLM rebuild
that retains PR #58454 and adds PR #58785's exact persistent-top-k overflow
fallback. The wheel hash, cumulative source tree and GPU regression evidence
are recorded in
[`image/r28.4-a-pr58785/`](../image/r28.4-a-pr58785/).

The R28.5-A release adds `r28.5-a-image-identity.txt` and
`r28.5-a-image-labels.json`. It is the production Python-only overlay for
merged PR #58779 and is also the current `latest` image. Its fail-closed patch
recipe is in
[`image/r28.5-a-pr58779/`](../image/r28.5-a-pr58779/).
