#!/usr/bin/env bash
set -euo pipefail

recipe=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$recipe/../.." && pwd)
work=${WORK_DIR:-"$root/tmp/build-r28-karmic"}
sources="$work/sources"
wheels="$recipe/wheelhouse"
generated="$recipe/generated"
logs="$work/logs"

base_image=${BASE_IMAGE:-nvcr.io/nvidia/pytorch:26.08-py3}
uv_image=${UV_IMAGE:-ghcr.io/astral-sh/uv:0.11.30}
rust_image=${RUST_IMAGE:-rust:1.95.0-slim}
build_jobs=${BUILD_JOBS:-12}
nvcc_threads=${NVCC_THREADS:-1}
final_image=${FINAL_IMAGE:-local/vllm:glm53-karmic-r28-arm64-sm121-cu134}
resume=${RESUME:-0}

vllm_commit=22476af54c637cbb7c7d8193addd160da83a5ce3
b12x_commit=f6d8b8eb94cdeb4e652652f925a494c6fc86f101
flashinfer_commit=2206a14e46387a56c093860a46bbbdd00596b75b
lmcache_commit=688bee14e157b64623d93c07fc0d4db93470e12f
instanttensor_commit=95d4729b6d6a991bb8de61877147a9d9d9100b23
nccl_commit=93fe05d9f9b6963ef841166a69cd0b30e4efe97b

prepare_source() {
  local name=$1 repository=$2 commit=$3 destination="$sources/$1"
  if [[ ! -d "$destination/.git" ]]; then
    rm -rf "$destination"
    git clone --filter=blob:none --no-checkout "$repository" "$destination"
  fi
  git -C "$destination" fetch --force origin "$commit"
  git -C "$destination" checkout --detach --force "$commit"
  git -C "$destination" submodule sync --recursive
  git -C "$destination" submodule update --init --recursive --force
  test "$(git -C "$destination" rev-parse HEAD)" = "$commit"
}

mkdir -p "$sources" "$wheels" "$generated" "$logs"
if [[ "$resume" != 1 ]]; then
  rm -f "$wheels"/*.whl
fi

prepare_source nccl-canonical https://github.com/local-inference-lab/nccl-canonical.git "$nccl_commit"
prepare_source b12x https://github.com/local-inference-lab/b12x.git "$b12x_commit"
prepare_source InstantTensor https://github.com/local-inference-lab/InstantTensor.git "$instanttensor_commit"
prepare_source LMCache https://github.com/local-inference-lab/LMCache.git "$lmcache_commit"
prepare_source flashinfer https://github.com/local-inference-lab/flashinfer.git "$flashinfer_commit"
prepare_source vllm https://github.com/local-inference-lab/vllm.git "$vllm_commit"

copy_and_adapt() {
  local source=$1 destination=$2
  python3 - "$source" "$destination" <<'PY'
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
text = source.read_text()
for old, new in (
    ("12.0a", "12.1a"),
    ("12.0f", "12.1f"),
    ("compute_120", "compute_121"),
    ("sm_120", "sm_121"),
    ("120a", "121a"),
    ("sm120", "sm121"),
):
    text = text.replace(old, new)
destination.write_text(text)
PY
}

copy_and_adapt "$sources/nccl-canonical/ci/lil_wheels/Dockerfile" "$generated/Dockerfile.nccl"
copy_and_adapt "$sources/b12x/ci/lil_wheels/Dockerfile" "$generated/Dockerfile.b12x"
copy_and_adapt "$sources/InstantTensor/ci/lil_wheels/Dockerfile" "$generated/Dockerfile.instanttensor"
copy_and_adapt "$sources/LMCache/ci/lil_wheels/Dockerfile" "$generated/Dockerfile.lmcache"
copy_and_adapt "$sources/flashinfer/ci/lil_wheels/Dockerfile" "$generated/Dockerfile.flashinfer"
copy_and_adapt "$sources/vllm/tools/jovian_wheel_release/Dockerfile" "$generated/Dockerfile.vllm"
copy_and_adapt "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.sh" \
  "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.arm64.sh"

# The release locks were generated for Linux x86_64 and therefore pin the
# x86_64 hashes of native build tools such as ninja.  Keep the exact package
# versions, but let uv select their Linux aarch64 distributions.
make_arm64_build_lock() {
  local source=$1 destination=$2
  python3 - "$source" "$destination" <<'PY'
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
requirements = []
for raw in source.read_text().splitlines():
    stripped = raw.strip()
    if not stripped or stripped.startswith("#") or stripped.startswith("--hash="):
        continue
    requirements.append(stripped.removesuffix("\\").rstrip())
destination.write_text(
    "# Exact upstream versions; hashes omitted because the release lock targets x86_64.\n"
    + "\n".join(requirements)
    + "\n"
)
PY
}

lmcache_arm_lock="$sources/LMCache/ci/lil_wheels/build-requirements.arm64.txt"
vllm_arm_lock="$sources/vllm/tools/jovian_wheel_release/build-requirements.arm64.txt"
make_arm64_build_lock \
  "$sources/LMCache/ci/lil_wheels/build-requirements.lock" "$lmcache_arm_lock"
make_arm64_build_lock \
  "$sources/vllm/tools/jovian_wheel_release/build-requirements.lock" "$vllm_arm_lock"
python3 - "$generated/Dockerfile.lmcache" "$generated/Dockerfile.vllm" <<'PY'
from pathlib import Path
import sys

for name in sys.argv[1:]:
    path = Path(name)
    text = path.read_text()
    text = text.replace("build-requirements.lock", "build-requirements.arm64.txt")
    text = text.replace("--require-hashes --no-deps", "--no-deps")
    path.write_text(text)
PY

cp "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.sh" \
  "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.upstream.sh"
cp "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.arm64.sh" \
  "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.sh"

cleanup_vllm_script() {
  if [[ -f "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.upstream.sh" ]]; then
    mv "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.upstream.sh" \
      "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.sh"
    rm -f "$sources/vllm/tools/jovian_wheel_release/build_vllm_wheel.arm64.sh"
  fi
  rm -f "$lmcache_arm_lock" "$vllm_arm_lock"
}
trap cleanup_vllm_script EXIT

uv_container=$(docker create "$uv_image")
docker cp "$uv_container:/uv" "$work/uv"
docker rm "$uv_container" >/dev/null
uv_sha=$(sha256sum "$work/uv" | awk '{print $1}')
rm -f "$work/uv"
source_epoch() { git -C "$1" show -s --format=%ct HEAD; }

build_export() {
  local name=$1 context=$2 dockerfile=$3 target=$4
  shift 4
  if [[ "$resume" == 1 ]]; then
    case "$name" in
      nccl)
        if compgen -G "$wheels/local_inference_nccl_cu134-*.whl" >/dev/null; then
          echo "===== SKIP $name (wheel present) ====="; return
        fi
        ;;
      b12x)
        if compgen -G "$wheels/b12x-*.whl" >/dev/null; then
          echo "===== SKIP $name (wheel present) ====="; return
        fi
        ;;
      instanttensor)
        if compgen -G "$wheels/instanttensor-*.whl" >/dev/null; then
          echo "===== SKIP $name (wheel present) ====="; return
        fi
        ;;
      lmcache)
        if compgen -G "$wheels/lmcache-*.whl" >/dev/null; then
          echo "===== SKIP $name (wheel present) ====="; return
        fi
        ;;
      flashinfer)
        if compgen -G "$wheels/flashinfer_python-*.whl" >/dev/null \
          && compgen -G "$wheels/flashinfer_jit_cache-*.whl" >/dev/null; then
          echo "===== SKIP $name (wheels present) ====="
          return
        fi
        ;;
      vllm)
        if compgen -G "$wheels/vllm-*.whl" >/dev/null; then
          echo "===== SKIP $name (wheel present) ====="; return
        fi
        ;;
    esac
  fi
  local output="$work/output-$name"
  rm -rf "$output"
  mkdir -p "$output"
  echo "===== BUILD $name $(date -u +%FT%TZ) ====="
  DOCKER_BUILDKIT=1 docker buildx build --progress=plain \
    --file "$dockerfile" --target "$target" \
    --output "type=local,dest=$output" "$@" "$context"
  find "$output" -type f -name '*.whl' -exec cp -v {} "$wheels/" \;
  echo "===== DONE $name $(date -u +%FT%TZ) ====="
}

build_export nccl "$sources/nccl-canonical" "$generated/Dockerfile.nccl" artifacts \
  --build-arg "BUILDER_IMAGE=$base_image" \
  --build-arg "BUILD_JOBS=$build_jobs" \
  --build-arg "NCCL_PACKAGE_VERSION=2.31.2+lil.cu134.sm121.g${nccl_commit:0:12}" \
  --build-arg "NCCL_SOURCE_COMMIT=$nccl_commit" \
  --build-arg "NCCL_SOURCE_DATE_EPOCH=$(source_epoch "$sources/nccl-canonical")"

build_export b12x "$sources/b12x" "$generated/Dockerfile.b12x" export \
  --build-arg "BUILDER_IMAGE=$base_image" \
  --build-arg "SOURCE_DATE_EPOCH=$(source_epoch "$sources/b12x")" \
  --build-arg CXX11_ABI=1

build_export instanttensor "$sources/InstantTensor" "$generated/Dockerfile.instanttensor" export \
  --build-arg "UV_IMAGE=$uv_image" \
  --build-arg "BUILDER_IMAGE=$base_image" \
  --build-arg "UV_SHA256=$uv_sha" \
  --build-arg "SOURCE_COMMIT=$instanttensor_commit" \
  --build-arg "SOURCE_DATE_EPOCH=$(source_epoch "$sources/InstantTensor")"

build_export lmcache "$sources/LMCache" "$generated/Dockerfile.lmcache" export \
  --build-arg "UV_IMAGE=$uv_image" \
  --build-arg "BUILDER_IMAGE=$base_image" \
  --build-arg "UV_SHA256=$uv_sha" \
  --build-arg "BUILD_JOBS=$build_jobs" \
  --build-arg "SOURCE_COMMIT=$lmcache_commit" \
  --build-arg "SOURCE_DATE_EPOCH=$(source_epoch "$sources/LMCache")"

build_export flashinfer "$sources/flashinfer" "$generated/Dockerfile.flashinfer" wheels \
  --build-arg "BUILDER_IMAGE=$base_image" \
  --build-arg "FLASHINFER_LOCAL_VERSION=lil.cu134.sm121.g${flashinfer_commit:0:12}" \
  --build-arg "FLASHINFER_SOURCE_COMMIT=$flashinfer_commit" \
  --build-arg "FLASHINFER_SOURCE_DATE_EPOCH=$(source_epoch "$sources/flashinfer")" \
  --build-arg "MAX_JOBS=$build_jobs" \
  --build-arg "NVCC_THREADS=$nvcc_threads"

dependency_recipe=$(git -C "$sources/vllm" rev-parse HEAD:cmake/external_projects)
build_export vllm "$sources/vllm" "$generated/Dockerfile.vllm" export \
  --build-arg "UV_IMAGE=$uv_image" \
  --build-arg "RUST_IMAGE=$rust_image" \
  --build-arg "BUILDER_IMAGE=$base_image" \
  --build-arg "UV_SHA256=$uv_sha" \
  --build-arg "SOURCE_DATE_EPOCH=$(source_epoch "$sources/vllm")" \
  --build-arg "BUILD_JOBS=$build_jobs" \
  --build-arg "DEPENDENCY_RECIPE=$dependency_recipe" \
  --build-arg CUTLASS_DSL_VERSION=4.6.2 \
  --build-arg VLLM_BUILD_CUTLASS_SCALED_MM_C2X=OFF

cleanup_vllm_script
trap - EXIT

cp "$sources/vllm/requirements/common.txt" "$recipe/vllm-common.txt"
test -s "$recipe/community-assembly.json"
test -s "$recipe/upstream-runtime-manifest.json"

echo "===== BUILD FINAL IMAGE $(date -u +%FT%TZ) ====="
DOCKER_BUILDKIT=1 docker build --progress=plain \
  --build-arg "BASE_IMAGE=$base_image" \
  --build-arg "BUILD_DATE=$(date -u +%FT%TZ)" \
  --tag "$final_image" \
  --file "$recipe/Dockerfile" "$recipe"

echo "===== VALIDATE FINAL IMAGE $(date -u +%FT%TZ) ====="
docker run --rm -i --gpus all --entrypoint /opt/venv/bin/python "$final_image" - <<'PY'
import importlib.metadata as m
import torch
import vllm, b12x, flashinfer, instanttensor, lmcache

assert torch.version.cuda == "13.4"
assert torch.cuda.get_device_capability(0) == (12, 1)
print("torch", torch.__version__, torch.version.cuda)
print("gpu", torch.cuda.get_device_name(0), torch.cuda.get_device_capability(0))
for name in ("vllm", "b12x", "flashinfer-python", "instanttensor", "lmcache", "local-inference-nccl-cu134"):
    print(name, m.version(name))
PY
docker image inspect "$final_image" --format 'image={{.Id}} size={{.Size}} arch={{.Architecture}} created={{.Created}}'
echo "===== COMPLETE $final_image $(date -u +%FT%TZ) ====="
