# R28.5-A bounded MTP draft-token RPC waits

R28.5-A is a Python-only overlay over R28.4-A. It applies merged upstream vLLM
PR [#58779](https://github.com/vllm-project/vllm/pull/58779), which passes
`VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS` to MTP draft-token readback. If the
output-rank worker never replies, EngineCore now reaches its existing fatal
shutdown path instead of waiting forever.

The only runtime file changed by this release is:

```text
vllm/v1/executor/multiproc_executor.py
```

The recipe checks the exact R28.4-A pre-image hash, the patch hash and the
post-image hash before running syntax and cumulative runtime validation. CUDA,
PyTorch, native vLLM extensions, B12X, model weights and serving configuration
are unchanged.

## Published images

```text
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.5-a-pr58454-pr58785-pr58779-arm64-sm121-cu134
technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:latest
```

Both tags resolve to Docker Hub digest
`sha256:ca40c504b0fac78a92c929262dbe6236cfa07c6896f36f7d2679123262d27dd6`.

The two-rank deployment reached API readiness in 6 minutes 30 seconds with
1,049,451 KV-cache tokens and zero container restarts. A chat smoke returned
HTTP 200, `SMOKE_OK` and `finish_reason=stop`.

In the matched `tool-eval-bench --perf-only` sample, cold wall time was
effectively tied with R28.4-A (9:23 versus 9:28) while the warm run completed
in 8:43 versus 9:14. That is an observed operational result, not a claim that
the timeout-only patch accelerates the normal inference path.
