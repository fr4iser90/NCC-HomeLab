# ComfyUI

| Path | Arch | Notes |
|------|------|--------|
| `compose.yaml` | x86_64 | `yanwk/comfyui-boot` + CDI GPU |
| `arm/` | aarch64 | Local Dockerfile (JetPack/CUDA build) |

```bash
docker network create ai-net   # x86 compose
# aarch64 picks arm/ automatically via init-compute
```
