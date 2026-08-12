# Portainer

## Security policy (default)

- Mounts `/var/run/docker.sock` → treat as **host root equivalent**.
- **`traefik.enable=false` by default** — no public DNS / Cloudflare companion registration.
- Preferred access: **WireGuard VPN** to the LAN/Docker IP, or SSH tunnel.
- If you enable Traefik: require `traefikAuth@file` **and** `admin-whitelist@file`. Never expose to the open internet.
