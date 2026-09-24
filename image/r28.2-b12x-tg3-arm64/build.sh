#!/usr/bin/env bash
set -euo pipefail

recipe=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd "$recipe/../.." && pwd)
work=${WORK_DIR:-"$root/tmp/build-r28.2-b12x-tg3"}
source_dir="$work/b12x"
wheelhouse="$recipe/wheelhouse"
builder_image=${BUILDER_IMAGE:-nvcr.io/nvidia/pytorch:26.08-py3}
base_image=${BASE_IMAGE:-technigmaai/glm-5.3-flash-nvfp4-2x-dgx-sparks:r28.1-display-kv-arm64-sm121-cu134}
image_tag=${IMAGE_TAG:-local/vllm:glm53-r28.2-b12x-tg3-arm64-sm121-cu134}

b12x_base=f6d8b8eb94cdeb4e652652f925a494c6fc86f101
patches=(
  b294e69d8eba2ea56d2aed7cc359c0df4bcaa57d
  1dc77276e9d0ba297ad753eb3af04327759c1a3b
  4f3028b19c1d8290dc72b6f483aba40de23eae5a
)

rm -rf "$source_dir" "$work/output-b12x" "$wheelhouse"
mkdir -p "$work" "$work/output-b12x" "$wheelhouse"
git clone --filter=blob:none https://github.com/local-inference-lab/b12x.git "$source_dir"
git -C "$source_dir" checkout --detach "$b12x_base"
for patch in "${patches[@]}"; do
  git -C "$source_dir" fetch --force origin "$patch"
  git -C "$source_dir" cherry-pick "$patch"
done

DOCKER_BUILDKIT=1 docker buildx build --progress=plain \
  --file "$root/image/r28-karmic-kraken-arm64/generated/Dockerfile.b12x" \
  --target export \
  --output "type=local,dest=$work/output-b12x" \
  --build-arg "BUILDER_IMAGE=$builder_image" \
  --build-arg "SOURCE_DATE_EPOCH=$(git -C "$source_dir" show -s --format=%ct HEAD)" \
  --build-arg CXX11_ABI=1 \
  "$source_dir"

find "$work/output-b12x" -type f -name 'b12x-*.whl' -exec cp -v {} "$wheelhouse/" \;
test "$(find "$wheelhouse" -maxdepth 1 -name 'b12x-*.whl' | wc -l)" -eq 1

docker build \
  --build-arg "BASE_IMAGE=$base_image" \
  --file "$recipe/Dockerfile" \
  --tag "$image_tag" \
  "$recipe"

docker run --rm --entrypoint python "$image_tag" -c \
  'import importlib.metadata as m, b12x; print("b12x", m.version("b12x"), b12x.__file__)'
docker image inspect "$image_tag" --format 'image={{.Id}} size={{.Size}} arch={{.Architecture}} created={{.Created}}'
