FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    git cmake ninja-build build-essential \
    libvulkan-dev mesa-vulkan-drivers vulkan-tools \
    glslc spirv-headers spirv-tools \
    curl ca-certificates

WORKDIR /workspace
RUN git clone --depth 1 --branch master https://github.com/ggml-org/llama.cpp.git
WORKDIR /workspace/llama.cpp
RUN cmake -S . -B build -G Ninja \
      -DGGML_VULKAN=ON \
      -DCMAKE_BUILD_TYPE=Release \
 && cmake --build build -j$(nproc)

CMD ["/workspace/llama.cpp/build/bin/llama-server"]
