# OpenCode (Docker)

Interactive OpenCode environment with Docker socket access for running sibling containers.

```bash
docker compose up -d --build
docker exec -it opencode-ai bash
```

Adjust volume mounts in `compose.yaml` for your workspace paths.
