# Gateway Services

Gateway services are the foundation of the Homelab setup. They handle routing, security, and DNS.

## Services

- [Traefik](./traefik.md) - Reverse Proxy & Load Balancer
- [CrowdSec](./crowdsec.md) - Security & Threat Detection
- [DDNS Updater](./ddns-updater.md) - Dynamic DNS Updates

## Dependencies

1. **Traefik** must run first (all other services depend on it)
2. **CrowdSec** should run with Traefik (security)
3. **DDNS Updater** is optional (only needed with dynamic IP)

## Setup Order

1. Deploy Traefik
2. Deploy CrowdSec
3. Deploy DDNS Updater (optional)

