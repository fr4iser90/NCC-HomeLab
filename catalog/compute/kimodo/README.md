# Kimodo

NVIDIA text-to-motion (interactive demo + text-encoder). Build clones [Aero-Ex/kimodo](https://github.com/Aero-Ex/kimodo).

| Target | Notes |
|--------|--------|
| x86_64 + NVIDIA GPU | NGC `pytorch:24.10-py3` base |
| Jetson / aarch64 | **Not supported** here (~17GB VRAM + x86 NGC image) |

```bash
docker network create ai-net
mkdir -p checkpoints hf-cache
# Place HF checkpoints (nvidia/Kimodo-*) under ./checkpoints
docker compose up -d --build
# Demo: http://localhost:7860  text-encoder: :9550
```

Docs: https://research.nvidia.com/labs/sil/projects/kimodo/docs
