# Ollama

| Directory | Target | Default port |
|-----------|--------|----------------|
| `cpu/` | x86_64 | 11434 |
| `rocm/` | x86_64 + AMD | 11435 |
| `arm/` | aarch64 (Jetson / ARM) | 11434 |

```bash
# picked automatically by init-compute / resolve_compose_context
COMPUTE_VARIANT=arm docker compose -f arm/compose.yaml up -d
cd cpu && docker compose up -d
cd rocm && docker compose up -d
```

Requires external network: `docker network create ai-net`
