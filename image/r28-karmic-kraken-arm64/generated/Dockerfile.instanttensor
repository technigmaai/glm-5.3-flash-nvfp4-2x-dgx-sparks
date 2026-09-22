# syntax=docker/dockerfile:1.7

ARG UV_IMAGE
ARG BUILDER_IMAGE
FROM ${UV_IMAGE} AS uv
FROM ${BUILDER_IMAGE} AS wheels

ARG SOURCE_COMMIT
ARG SOURCE_DATE_EPOCH
ARG UV_SHA256
ENV PATH=/build-venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY --from=uv /uv /usr/local/bin/uv
COPY ci/lil_wheels/build-requirements.lock /tmp/build-requirements.lock
RUN test "$(sha256sum /usr/local/bin/uv | awk '{print $1}')" = "${UV_SHA256}" \
    && uv venv --python /usr/bin/python --system-site-packages /build-venv \
    && uv pip install --python /build-venv/bin/python \
      --require-hashes --no-deps -r /tmp/build-requirements.lock

COPY . /src/instanttensor
WORKDIR /src/instanttensor
RUN test -f csrc/third_party/libaio/src/libaio.h \
    && test -f csrc/third_party/liburing/src/include/liburing.h
RUN --mount=type=cache,id=lil-wheel-uv,target=/root/.cache/uv,sharing=locked \
    SOURCE_COMMIT="${SOURCE_COMMIT}" \
    SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH}" \
    ci/lil_wheels/build_wheel.sh

FROM scratch AS export
COPY --from=wheels /wheelhouse/ /wheels/
