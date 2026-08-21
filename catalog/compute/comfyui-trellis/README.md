# ComfyUI-Trellis

ComfyUI with [ComfyUI-Trellis2](https://github.com/visualbruno/ComfyUI-Trellis2) + GGUF addon for image→3D workflows.

| Path | Arch | Notes |
|------|------|--------|
| `arm/` | aarch64 | Local JetPack/CUDA build (port **8189**) |

```bash
docker network create ai-net
# aarch64 picks arm/ via init-compute / resolve_compose_context
cd catalog/compute/comfyui-trellis
COMPUTE_VARIANT=arm docker compose -f arm/compose.yaml up -d --build
```

### After first start

- Place Trellis models under `arm/models/` (e.g. `Trellis2/`).
- Full mesh nodes often need **CuMesh** / ovoxel wheels built for Jetson — on the host that lived in `trellis-shell.nix` (`tcumesh`). The image ships the custom_nodes; native CUDA extensions may still need a one-time host or container build if GGUF-only nodes are not enough.

Do not run plain `comfyui` and `comfyui-trellis` on the same GPU with heavy jobs at once on Orin Nano.
