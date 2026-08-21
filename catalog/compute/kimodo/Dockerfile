# Kimodo — NVIDIA text-to-motion (clone + install during build).
# Upstream fork used on this homelab: Aero-Ex/kimodo (NVIDIA research lineage).
# Base image is x86_64 CUDA PyTorch from NGC — not for Jetson Orin Nano.
#
# Requires ~17GB VRAM for local generation (text encoder + demo).
ARG KIMODO_REPO=https://github.com/Aero-Ex/kimodo.git
ARG KIMODO_REF=main

FROM nvcr.io/nvidia/pytorch:24.10-py3

ARG KIMODO_REPO
ARG KIMODO_REF

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates \
      cmake build-essential \
      gosu \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/microsoft/scenepic.git /tmp/scenepic && \
    cd /tmp/scenepic && \
    npm install && npm run build && \
    pip install . && \
    cd / && rm -rf /tmp/scenepic

RUN rm -f /usr/local/bin/cmake || true

RUN git clone --depth 1 --branch "${KIMODO_REF}" "${KIMODO_REPO}" /tmp/kimodo-src \
    && cp -a /tmp/kimodo-src/. /workspace/ \
    && rm -rf /tmp/kimodo-src

RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --upgrade pip \
 && SKIP_MOTION_CORRECTION_IN_SETUP=1 python -m pip install -r docker_requirements.txt

RUN if [ -f /workspace/kimodo/scripts/docker-entrypoint.sh ]; then \
      cp /workspace/kimodo/scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint \
      && chmod +x /usr/local/bin/docker-entrypoint; \
    else \
      printf '%s\n' '#!/bin/bash' 'exec "$@"' > /usr/local/bin/docker-entrypoint \
      && chmod +x /usr/local/bin/docker-entrypoint; \
    fi

ENTRYPOINT ["docker-entrypoint"]
CMD ["bash"]
