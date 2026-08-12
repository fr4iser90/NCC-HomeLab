FROM nvidia/cuda:12.3.2-cudnn9-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git cmake build-essential ninja-build python3 curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Repo
RUN git clone https://github.com/TheTom/llama-cpp-turboquant.git .
RUN git checkout feature/turboquant-kv-cache

# CUDA ENV FIX (wichtig!)
ENV CUDAToolkit_ROOT=/usr/local/cuda
ENV CUDA_HOME=/usr/local/cuda
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/lib64/stubs:${LD_LIBRARY_PATH}


# 👉 WICHTIG: Stub libcuda für Linker verfügbar machen
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:${LIBRARY_PATH}

# Build mit CUDA
RUN cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_CUDA=ON \
    -DGGML_NATIVE=ON \
    -DCMAKE_EXE_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda"

RUN cmake --build build -j$(nproc)

EXPOSE 8080

CMD sh -c './build/bin/llama-server \
  --model-dir /models \
  --host 0.0.0.0 \
  --port 8080 \
  -c 4096 \
  -fa on \
  --cache-type-k turbo3 \
  --cache-type-v turbo3'
