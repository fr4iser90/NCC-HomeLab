# ComfyUI + Trellis2 custom nodes — aarch64 / Jetson (extends catalog/compute/comfyui/arm pattern).
# CuMesh / ovoxel native builds are large and host-specific; see README for post-build steps.
FROM nvidia/cuda:12.3.2-cudnn9-devel-ubuntu22.04

ARG COMFYUI_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFYUI_REF=v0.18.2
ARG TRELLIS2_REPO=https://github.com/visualbruno/ComfyUI-Trellis2.git
ARG TRELLIS2_GGUF_REPO=https://github.com/Aero-Ex/ComfyUI-Trellis2-GGUF.git

ENV DEBIAN_FRONTEND=noninteractive

RUN printf '%s\n' 'numpy>=1.25.0,<2' > /constraints.txt
ENV PIP_CONSTRAINT=/constraints.txt

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-pip \
    python3-dev \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libopenblas-dev \
    build-essential \
    ninja-build \
    cmake \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN set -eux; \
    if [ -n "${COMFYUI_REF}" ]; then \
      git clone --depth 1 --branch "${COMFYUI_REF}" "${COMFYUI_REPO}" /app; \
    else \
      git clone --depth 1 "${COMFYUI_REPO}" /app; \
    fi

RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

RUN rm -rf /app/custom_nodes/ComfyUI-Manager /app/custom_nodes/ComfyUI-GGUF \
    && git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git /app/custom_nodes/ComfyUI-Manager \
    && pip install --no-cache-dir -r /app/custom_nodes/ComfyUI-Manager/requirements.txt \
    && git clone --depth 1 https://github.com/city96/ComfyUI-GGUF.git /app/custom_nodes/ComfyUI-GGUF \
    && pip install --no-cache-dir --upgrade gguf \
    && git clone --depth 1 "${TRELLIS2_REPO}" /app/custom_nodes/ComfyUI-Trellis2 \
    && git clone --depth 1 "${TRELLIS2_GGUF_REPO}" /app/custom_nodes/ComfyUI-Trellis2-GGUF \
    && if [ -f /app/custom_nodes/ComfyUI-Trellis2/requirements.txt ]; then \
         pip install --no-cache-dir -r /app/custom_nodes/ComfyUI-Trellis2/requirements.txt || true; \
       fi \
    && if [ -f /app/custom_nodes/ComfyUI-Trellis2-GGUF/requirements.txt ]; then \
         pip install --no-cache-dir -r /app/custom_nodes/ComfyUI-Trellis2-GGUF/requirements.txt || true; \
       fi

ARG NV_TORCH_WHEEL=https://developer.download.nvidia.com/compute/redist/jp/v61/pytorch/torch-2.5.0a0+872d972e41.nv24.08.17622132-cp310-cp310-linux_aarch64.whl
ARG TORCH_CUDA_ARCH_LIST=8.7
ARG COMPILE_JOBS=2

RUN pip uninstall -y torch torchvision torchaudio 2>/dev/null || true \
    && pip install --no-cache-dir "${NV_TORCH_WHEEL}" \
    && pip install --no-cache-dir "nvidia-cusparselt-cu12" \
    && CUPLIB="$(dirname "$(find /usr/local/lib/python3.10/dist-packages/nvidia/cusparselt -name 'libcusparseLt.so*' -print -quit)")" \
    && test -n "$CUPLIB" && test "$CUPLIB" != "." \
    && echo "$CUPLIB" > /etc/ld.so.conf.d/nvidia-cusparselt.conf && ldconfig \
    && python3 -c "import ctypes; ctypes.CDLL('libcusparseLt.so.0'); import torch; print('torch+cusparselt: OK')" \
    && pip install --no-cache-dir "numpy>=1.25.0,<2" \
    && export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}" \
    && if [ "${COMPILE_JOBS}" -gt 0 ] 2>/dev/null; then J="${COMPILE_JOBS}"; else J="$(nproc)"; fi \
    && export MAX_JOBS="$J" CMAKE_BUILD_PARALLEL_LEVEL="$J" NINJA_STATUS='[%f/%t] ' \
    && pip install -v --no-cache-dir --no-build-isolation "git+https://github.com/pytorch/vision@v0.20.0" --no-deps \
    && USE_CUDA=0 pip install -v --no-cache-dir --no-build-isolation "git+https://github.com/pytorch/audio@v2.5.0" --no-deps \
    && python3 -c "import numpy; import torch; import torchvision; import torchaudio; print('numpy', numpy.__version__, 'torch', torch.__version__, 'tv', torchvision.__version__, 'ta', torchaudio.__version__)"

ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

EXPOSE 8188

CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
